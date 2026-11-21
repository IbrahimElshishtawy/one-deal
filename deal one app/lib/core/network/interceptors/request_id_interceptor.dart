import 'dart:math';

import 'package:dio/dio.dart';

import 'package:market_space/core/network/api_headers.dart';

class RequestIdInterceptor extends Interceptor {
  final Random _randomGenerator = Random();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.headers.containsKey(ApiHeaders.requestId)) {
      final generatedRequestId = _generateUniqueRequestId();
      options.headers[ApiHeaders.requestId] = generatedRequestId;
    }
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
