import 'package:dio/dio.dart';

import 'package:market_space/core/logging/app_logger.dart';
import 'package:market_space/core/logging/log_sanitizer.dart';

class NetworkLoggingInterceptor extends Interceptor {
  final AppLogger logger;

  NetworkLoggingInterceptor({required this.logger});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final sanitizedHeaders = LogSanitizer.sanitize(options.headers);
    final sanitizedData = LogSanitizer.sanitize(options.data);

    logger.debug(
      'HTTP Request [${options.method}] ${options.uri}',
      data: {
        'headers': sanitizedHeaders,
        'queryParameters': options.queryParameters,
        'body': sanitizedData,
      },
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final sanitizedData = LogSanitizer.sanitize(response.data);

    logger.info(
      'HTTP Response [${response.statusCode}] ${response.requestOptions.uri}',
      data: {'data': sanitizedData},
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sanitizedResponse = LogSanitizer.sanitize(err.response?.data);

    logger.error(
      'HTTP Error [${err.response?.statusCode}] ${err.requestOptions.uri} (${err.type.name})',
      data: {'message': err.message, 'response': sanitizedResponse},
      error: err,
    );
    handler.next(err);
  }
}
