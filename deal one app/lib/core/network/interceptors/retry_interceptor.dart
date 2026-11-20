import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.retryDelay = const Duration(milliseconds: 1000),
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final isIdempotentMethod =
        requestOptions.method.toUpperCase() == 'GET' ||
        requestOptions.method.toUpperCase() == 'HEAD';

    final isTransientError =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;

    // Android Emulator automatic bridge fallback:
    // If localhost/127.0.0.1 refuses connection (when adb reverse is not set),
    // transparently switch to 10.0.2.2 (host loopback on Android Emulator) and retry immediately.
    if (err.type == DioExceptionType.connectionError &&
        requestOptions.extra['emulator_host_fallback_tried'] != true) {
      final base = requestOptions.baseUrl;
      String? fallbackBase;
      if (base.contains('://localhost:')) {
        fallbackBase = base.replaceFirst('://localhost:', '://10.0.2.2:');
      } else if (base.contains('://127.0.0.1:')) {
        fallbackBase = base.replaceFirst('://127.0.0.1:', '://10.0.2.2:');
      } else if (base.contains('://10.0.2.2:')) {
        fallbackBase = base.replaceFirst('://10.0.2.2:', '://localhost:');
      }

      if (fallbackBase != null) {
        requestOptions.extra['emulator_host_fallback_tried'] = true;
        requestOptions.baseUrl = fallbackBase;
        dio.options.baseUrl = fallbackBase;
        try {
          final response = await dio.fetch(requestOptions);
          return handler.resolve(response);
        } on DioException catch (fallbackErr) {
          err = fallbackErr;
        }
      }
    }

    final currentRetryCount = requestOptions.extra['retry_count'] as int? ?? 0;

    if (isIdempotentMethod &&
        isTransientError &&
        currentRetryCount < maxRetries) {
      requestOptions.extra['retry_count'] = currentRetryCount + 1;
      await Future.delayed(retryDelay * (currentRetryCount + 1));

      try {
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryError) {
        return handler.next(retryError);
      }
    }

    return handler.next(err);
  }
}
