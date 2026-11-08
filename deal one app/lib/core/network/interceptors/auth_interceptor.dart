import 'dart:async';
import 'package:dio/dio.dart';

import '../../security/token_provider.dart';
import '../api_endpoints.dart';
import '../api_headers.dart';

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
      // Avoid recursive refresh if the failed request was the refresh endpoint itself
      if (request.path.contains(ApiEndpoints.refreshToken) ||
          request.path.contains(ApiEndpoints.login) ||
          request.path.contains(ApiEndpoints.verifyOtp)) {
        await _handleSessionExpired();
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
        final newAccessToken = await _performTokenRefresh();
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          // Clone and retry original request with new token
          final retryOptions = request.copyWith(
            headers: {
              ...request.headers,
              ApiHeaders.authorization:
                  '${ApiHeaders.bearerPrefix}$newAccessToken',
            },
            extra: {...request.extra, 'is_retry': true},
          );

          final retryResponse = await dio.fetch(retryOptions);
          return handler.resolve(retryResponse);
        } else {
          await _handleSessionExpired();
          return handler.next(err);
        }
      } catch (refreshError) {
        await _handleSessionExpired();
        return handler.next(err);
      }
    }

    handler.next(err);
  }

  Future<String?> _performTokenRefresh() async {
    if (_isRefreshing) {
      // Another request is already refreshing, await its completion
      return _refreshCompleter?.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final currentRefreshToken = await tokenProvider.getRefreshToken();
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        _refreshCompleter?.complete(null);
        return null;
      }

      // Execute unauthenticated raw refresh call
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': currentRefreshToken},
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final newAccessToken = data?['accessToken']?.toString();
        final newRefreshToken = data?['refreshToken']?.toString();

        if (newAccessToken != null && newRefreshToken != null) {
          await tokenProvider.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          _refreshCompleter?.complete(newAccessToken);
          return newAccessToken;
        }
      }

      _refreshCompleter?.complete(null);
      return null;
    } catch (_) {
      _refreshCompleter?.complete(null);
      return null;
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
