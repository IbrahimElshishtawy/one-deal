import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:market_space/core/config/app_config.dart';
import 'package:market_space/core/errors/app_exception.dart';
import 'package:market_space/core/errors/error_mapper.dart';
import 'package:market_space/core/logging/app_logger.dart';
import 'package:market_space/core/security/token_provider.dart';
import 'package:market_space/core/network/api_headers.dart';
import 'package:market_space/core/network/interceptors/auth_interceptor.dart';
import 'package:market_space/core/network/interceptors/logging_interceptor.dart';
import 'package:market_space/core/network/interceptors/request_id_interceptor.dart';
import 'package:market_space/core/network/interceptors/retry_interceptor.dart';
import 'package:market_space/core/network/network_info.dart';

abstract class ApiClient {
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });
}

/// Async semaphore to cap concurrent in-flight HTTP requests.
class _ConcurrencyLimiter {
  final int maxConcurrent;
  int _active = 0;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  _ConcurrencyLimiter({this.maxConcurrent = 6});

  Future<T> run<T>(Future<T> Function() task) async {
    if (_active >= maxConcurrent) {
      final completer = Completer<void>();
      _waiters.addLast(completer);
      await completer.future;
    }
    _active++;
    try {
      return await task();
    } finally {
      _active--;
      if (_waiters.isNotEmpty) {
        _waiters.removeFirst().complete();
      }
    }
  }
}

class DioApiClient implements ApiClient {
  final Dio dio;
  final NetworkInfo networkInfo;
  final _ConcurrencyLimiter _limiter;
  final Map<String, Future<Response<dynamic>>> _inFlightGets = {};

  DioApiClient({
    required this.dio,
    required this.networkInfo,
    int maxConcurrentRequests = 6,
  }) : _limiter = _ConcurrencyLimiter(maxConcurrent: maxConcurrentRequests);

  factory DioApiClient.create({
    required AppConfig appConfig,
    required NetworkInfo networkInfo,
    required TokenProvider tokenProvider,
    required AppLogger logger,
    void Function()? onSessionExpired,
    int maxConcurrentRequests = 6,
  }) {
    final baseOptions = BaseOptions(
      baseUrl: appConfig.apiBaseUrl,
      connectTimeout: appConfig.connectTimeout,
      receiveTimeout: appConfig.receiveTimeout,
      sendTimeout: appConfig.connectTimeout,
      headers: ApiHeaders.defaultHeaders(),
      responseType: ResponseType.json,
    );

    final dioInstance = Dio(baseOptions);

    dioInstance.interceptors.addAll([
      RequestIdInterceptor(),
      AuthInterceptor(
        dio: dioInstance,
        tokenProvider: tokenProvider,
        trustedOrigin: appConfig.apiBaseUrl,
        onSessionExpired: onSessionExpired,
      ),
      NetworkLoggingInterceptor(
        logger: logger,
        isProduction: appConfig.environment.isProduction || !appConfig.enableLogging,
      ),
      RetryInterceptor(dio: dioInstance),
    ]);

    return DioApiClient(
      dio: dioInstance,
      networkInfo: networkInfo,
      maxConcurrentRequests: maxConcurrentRequests,
    );
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      throw const NetworkException();
    }
  }

  String _buildGetKey(String path, Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return path;
    }
    final sortedKeys = queryParameters.keys.toList()..sort();
    final canonical = <String, dynamic>{
      for (final k in sortedKeys) k: queryParameters[k],
    };
    return '$path?${jsonEncode(canonical)}';
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();

    // Deduplicate identical concurrent GET requests when no caller-specific CancelToken is attached.
    if (cancelToken == null && options == null) {
      final key = _buildGetKey(path, queryParameters);
      final existing = _inFlightGets[key];
      if (existing != null) {
        final response = await existing;
        return response as Response<T>;
      }

      final future = _limiter.run(() async {
        try {
          return await dio.get<T>(
            path,
            queryParameters: queryParameters,
          );
        } catch (error) {
          throw ErrorMapper.map(error);
        }
      });

      _inFlightGets[key] = future;
      try {
        return await future;
      } finally {
        _inFlightGets.remove(key);
      }
    }

    return _limiter.run(() async {
      try {
        return await dio.get<T>(
          path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        );
      } catch (error) {
        throw ErrorMapper.map(error);
      }
    });
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    return _limiter.run(() async {
      try {
        return await dio.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        );
      } catch (error) {
        throw ErrorMapper.map(error);
      }
    });
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    return _limiter.run(() async {
      try {
        return await dio.put<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        );
      } catch (error) {
        throw ErrorMapper.map(error);
      }
    });
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    return _limiter.run(() async {
      try {
        return await dio.patch<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        );
      } catch (error) {
        throw ErrorMapper.map(error);
      }
    });
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    return _limiter.run(() async {
      try {
        return await dio.delete<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        );
      } catch (error) {
        throw ErrorMapper.map(error);
      }
    });
  }
}
