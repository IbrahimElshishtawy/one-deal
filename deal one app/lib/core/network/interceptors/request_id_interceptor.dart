import 'dart:math';

import 'package:dio/dio.dart';

import 'package:market_space/core/network/api_headers.dart';

class RequestIdInterceptor extends Interceptor {
  static const String requestStartMsExtraKey = 'request_start_ms';
  static const String traceIdHeader = 'X-Trace-ID';

  final Random _randomGenerator = Random();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final existingId = options.headers[ApiHeaders.requestId]?.toString();
    final requestId = (existingId != null && existingId.isNotEmpty)
        ? existingId
        : _generateUniqueRequestId();
    options.headers[ApiHeaders.requestId] = requestId;
    options.headers[traceIdHeader] = requestId;
    options.extra[requestStartMsExtraKey] =
        DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  String _generateUniqueRequestId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomSuffix = _randomGenerator
        .nextInt(1000000)
        .toString()
        .padLeft(6, '0');
    return 'req-$timestamp-$randomSuffix';
  }
}
