import 'dart:async';

import 'package:dio/dio.dart';

import 'package:market_space/core/security/token_provider.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/core/network/api_headers.dart';

/// Concurrency-safe authentication interceptor with single-flight token refresh,
/// trusted-origin token scoping, and automated session expiry triggers.
class AuthInterceptor extends Interceptor {
  final Dio dio;
  final TokenProvider tokenProvider;
  final String trustedOrigin;
  final void Function()? onSessionExpired;

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  AuthInterceptor({
    required this.dio,
    required this.tokenProvider,
    required this.trustedOrigin,
    this.onSessionExpired,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only attach bearer token to trusted API origin (prevents token leakage to S3/CDN)
    final uri = Uri.parse(options.uri.toString());
    final isTrusted = _isTrustedOrigin(uri);

    if (isTrusted && !options.headers.containsKey(ApiHeaders.authorization)) {
      if (_isRefreshing && _refreshCompleter != null) {
        await _refreshCompleter!.future;
      }
      final accessToken = await tokenProvider.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers[ApiHeaders.authorization] =
            '${ApiHeaders.bearerPrefix}$accessToken';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final request = err.requestOptions;

    // Check if failure is 401 Unauthorized
    if (response?.statusCode == 401) {
      // Avoid recursive refresh on public auth or logout endpoints
      if (request.path.contains(ApiEndpoints.refreshToken) ||
          request.path.contains(ApiEndpoints.login) ||
          request.path.contains(ApiEndpoints.verifyOtp) ||
          request.path.contains(ApiEndpoints.sendOtp) ||
          request.path.contains(ApiEndpoints.resendOtp) ||
          request.path.contains(ApiEndpoints.logout)) {
        if (request.path.contains(ApiEndpoints.refreshToken)) {
          await _handleSessionExpired();
        }
        return handler.next(err);
      }

      // Check if this request was already retried
      final alreadyRetried = request.extra['is_retry'] == true;
      if (alreadyRetried) {
        await _handleSessionExpired();
        return handler.next(err);
      }

      // Perform single-flight refresh with queued concurrent requests
      try {
        final refreshResult = await _performTokenRefresh();
        if (refreshResult.accessToken != null &&
            refreshResult.accessToken!.isNotEmpty) {
          // Clone and retry original request with new token
          final retryOptions = request.copyWith(
            headers: {
              ...request.headers,
              ApiHeaders.authorization:
                  '${ApiHeaders.bearerPrefix}${refreshResult.accessToken}',
            },
            extra: {...request.extra, 'is_retry': true},
          );

          final retryResponse = await dio.fetch(retryOptions);
          return handler.resolve(retryResponse);
        } else if (refreshResult.shouldInvalidateSession) {
          await _handleSessionExpired();
          return handler.next(err);
        } else {
          return handler.next(err);
        }
      } catch (refreshError) {
        await _handleSessionExpired();
        return handler.next(err);
      }
    }

    handler.next(err);
  }

  Future<_RefreshResult> _performTokenRefresh() async {
    if (_isRefreshing && _refreshCompleter != null) {
      // Another request is already refreshing, await its completion
      final token = await _refreshCompleter!.future;
      return _RefreshResult(
        accessToken: token,
        shouldInvalidateSession: token == null,
      );
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final currentRefreshToken = await tokenProvider.getRefreshToken();
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        _refreshCompleter?.complete(null);
        return const _RefreshResult(shouldInvalidateSession: true);
      }

      // Execute unauthenticated raw refresh call using the same adapter
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: ApiHeaders.defaultHeaders(),
        ),
      )..httpClientAdapter = dio.httpClientAdapter;

      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': currentRefreshToken},
      );

      if (response.statusCode == 200 && response.data is Map) {
        final payload = response.data as Map;
        final rawData = payload['data'];
        final data = rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : Map<String, dynamic>.from(payload);
        final nestedTokens = data['tokens'];
        final tokenSource = nestedTokens is Map
            ? Map<String, dynamic>.from(nestedTokens)
            : data;
        final newAccessToken = tokenSource['accessToken']?.toString();
        final newRefreshToken = tokenSource['refreshToken']?.toString();

        if (newAccessToken != null &&
            newAccessToken.isNotEmpty &&
            newRefreshToken != null &&
            newRefreshToken.isNotEmpty) {
          await tokenProvider.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          _refreshCompleter?.complete(newAccessToken);
          return _RefreshResult(accessToken: newAccessToken);
        }
      }

      _refreshCompleter?.complete(null);
      return const _RefreshResult(shouldInvalidateSession: true);
    } on DioException catch (dioErr) {
      final status = dioErr.response?.statusCode;
      final isAuthRejection = status == 400 || status == 401 || status == 403;
      _refreshCompleter?.complete(null);
      return _RefreshResult(shouldInvalidateSession: isAuthRejection);
    } catch (_) {
      _refreshCompleter?.complete(null);
      return const _RefreshResult(shouldInvalidateSession: true);
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  Future<void> _handleSessionExpired() async {
    await tokenProvider.clearTokens();
    onSessionExpired?.call();
  }

  bool _isTrustedOrigin(Uri uri) {
    if (trustedOrigin.isEmpty) return true;
    try {
      final trustedUri = Uri.parse(trustedOrigin);
      return uri.host.isEmpty || uri.host == trustedUri.host;
    } catch (_) {
      return false;
    }
  }
}

class _RefreshResult {
  final String? accessToken;
  final bool shouldInvalidateSession;

  const _RefreshResult({
    this.accessToken,
    this.shouldInvalidateSession = false,
  });
}
