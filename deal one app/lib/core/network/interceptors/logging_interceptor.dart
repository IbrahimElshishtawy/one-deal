import 'package:dio/dio.dart';

import 'package:market_space/core/logging/app_logger.dart';
import 'package:market_space/core/logging/log_sanitizer.dart';
import 'package:market_space/core/network/api_headers.dart';
import 'package:market_space/core/network/interceptors/request_id_interceptor.dart';

/// Centralized Dio observability interceptor emitting structured
/// `[API][REQUEST]`, `[API][RESPONSE]`, and `[API][ERROR]` telemetry.
///
/// Strict environment separation:
/// - Development: logs sanitized request headers/body, response summary, duration, and Request ID.
/// - Production: suppresses debug request/response payloads and logs only safe error summaries.
class NetworkLoggingInterceptor extends Interceptor {
  final AppLogger logger;
  final bool isProduction;

  NetworkLoggingInterceptor({
    required this.logger,
    this.isProduction = false,
  });

  String _resolveRequestId(RequestOptions options) {
    return options.headers[ApiHeaders.requestId]?.toString() ??
        options.headers[RequestIdInterceptor.traceIdHeader]?.toString() ??
        'unknown';
  }

  int _resolveDurationMs(RequestOptions options) {
    final startedAt = options.extra[RequestIdInterceptor.requestStartMsExtraKey];
    if (startedAt is int) {
      return (DateTime.now().millisecondsSinceEpoch - startedAt).clamp(0, 600000);
    }
    return 0;
  }

  String _classifyErrorLayer(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'TIMEOUT';
      case DioExceptionType.connectionError:
        return 'NETWORK';
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 500;
        if (status == 400 || status == 422) return 'VALIDATION';
        if (status == 401) return 'AUTH';
        if (status == 403) return 'AUTHORIZATION';
        if (status == 429) return 'RATE_LIMIT';
        return 'SERVER';
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return 'NETWORK';
      default:
        return 'TIMEOUT';
    }
  }

  String _extractErrorCode(DioException err) {
    final data = err.response?.data;
    if (data is Map) {
      final nestedError = data['error'];
      if (nestedError is Map && nestedError['code'] != null) {
        return nestedError['code'].toString();
      }
      if (data['code'] != null) {
        return data['code'].toString();
      }
    }
    return err.type.name.toUpperCase();
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!isProduction) {
      final requestId = _resolveRequestId(options);
      final sanitizedHeaders = LogSanitizer.sanitize(options.headers);
      final sanitizedPayload = LogSanitizer.sanitize(options.data);

      logger.debug(
        '[API][REQUEST] Method: ${options.method} | Endpoint: ${options.path} | Request ID: $requestId',
        data: {
          'headers': sanitizedHeaders,
          if (options.queryParameters.isNotEmpty)
            'query': options.queryParameters,
          'payload': ?sanitizedPayload,
        },
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!isProduction) {
      final requestId = _resolveRequestId(response.requestOptions);
      final durationMs = _resolveDurationMs(response.requestOptions);
      final sanitizedResponse = LogSanitizer.sanitize(response.data);

      logger.info(
        '[API][RESPONSE] Status: ${response.statusCode} | Duration: ${durationMs}ms | Endpoint: ${response.requestOptions.path} | Request ID: $requestId',
        data: {'response': sanitizedResponse},
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestId = _resolveRequestId(err.requestOptions);
    final durationMs = _resolveDurationMs(err.requestOptions);
    final status = err.response?.statusCode ?? 0;
    final layer = _classifyErrorLayer(err);
    final errorCode = _extractErrorCode(err);

    logger.error(
      '[API][ERROR] Status: $status | Duration: ${durationMs}ms | Layer: $layer | Error: $errorCode | Endpoint: ${err.requestOptions.path} | Request ID: $requestId',
      data: isProduction
          ? {'code': errorCode, 'layer': layer, 'requestId': requestId}
          : {
              'code': errorCode,
              'layer': layer,
              'requestId': requestId,
              'response': LogSanitizer.sanitize(err.response?.data),
            },
      error: isProduction ? null : err,
    );
    handler.next(err);
  }
}
