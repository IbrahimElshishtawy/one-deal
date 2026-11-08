import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../errors/error_mapper.dart';
import '../logging/app_logger.dart';
import '../security/token_provider.dart';
import 'api_headers.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/request_id_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'network_info.dart';

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

class DioApiClient implements ApiClient {
  final Dio dio;
  final NetworkInfo networkInfo;

  DioApiClient({required this.dio, required this.networkInfo});

  factory DioApiClient.create({
    required AppConfig appConfig,
    required NetworkInfo networkInfo,
    required TokenProvider tokenProvider,
    required AppLogger logger,
    void Function()? onSessionExpired,
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
      if (appConfig.enableLogging) NetworkLoggingInterceptor(logger: logger),
      RetryInterceptor(dio: dioInstance),
    ]);

    return DioApiClient(dio: dioInstance, networkInfo: networkInfo);
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      throw const NetworkException();
    }
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
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
  }
}
