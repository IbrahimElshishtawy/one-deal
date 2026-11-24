import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:market_space/core/logging/app_logger.dart';
import 'package:market_space/core/logging/log_sanitizer.dart';
import 'package:market_space/core/network/api_headers.dart';
import 'package:market_space/core/network/interceptors/logging_interceptor.dart';
import 'package:market_space/core/network/interceptors/request_id_interceptor.dart';

class _CapturedLog {
  final String level;
  final String message;
  final dynamic data;

  const _CapturedLog(this.level, this.message, this.data);
}

class _CapturingLogger implements AppLogger {
  final List<_CapturedLog> logs = [];

  @override
  void debug(String message, {dynamic data}) =>
      logs.add(_CapturedLog('DEBUG', message, data));

  @override
  void info(String message, {dynamic data}) =>
      logs.add(_CapturedLog('INFO', message, data));

  @override
  void warning(
    String message, {
    dynamic data,
    Object? error,
    StackTrace? stackTrace,
  }) => logs.add(_CapturedLog('WARNING', message, data));

  @override
  void error(
    String message, {
    dynamic data,
    Object? error,
    StackTrace? stackTrace,
  }) => logs.add(_CapturedLog('ERROR', message, data));
}

class _StubAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) onFetch;

  _StubAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) => onFetch(options);

  @override
  void close({bool force = false}) {}
}

void main() {
  group('LogSanitizer & NetworkLoggingInterceptor', () {
    test('redacts secrets and masks email/phone while truncating large payloads', () {
      final sanitized = LogSanitizer.sanitize({
        'password': 'SuperSecretPassword!',
        'accessToken': 'eyJ.access.token',
        'refreshToken': 'eyJ.refresh.token',
        'otp': '123456',
        'code': '654321',
        'error': {'code': 'INTERNAL_SERVER_ERROR', 'message': 'Failed'},
        'Authorization': 'Bearer top-secret',
        'email': 'ibrahim.test@gmail.com',
        'phone': '+201012345678',
        'items': List.generate(15, (i) => {'id': i}),
      }) as Map<String, dynamic>;

      expect(sanitized['password'], '[REDACTED]');
      expect(sanitized['accessToken'], '[REDACTED]');
      expect(sanitized['refreshToken'], '[REDACTED]');
      expect(sanitized['otp'], '[REDACTED]');
      expect(sanitized['code'], '[REDACTED]');
      expect(
        (sanitized['error'] as Map<String, dynamic>)['code'],
        'INTERNAL_SERVER_ERROR',
      );
      expect(sanitized['Authorization'], '[REDACTED]');
      expect(sanitized['email'], 'ibr***@gmail.com');
      expect(sanitized['phone'], '+2010***5678');
      expect((sanitized['items'] as List).length, 9);
    });

    test('emits clean boxed [API][REQUEST] and [API][RESPONSE] in development', () async {
      final logger = _CapturingLogger();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
        ..httpClientAdapter = _StubAdapter((options) async {
          expect(options.headers[ApiHeaders.requestId], isNotEmpty);
          expect(
            options.headers[RequestIdInterceptor.traceIdHeader],
            options.headers[ApiHeaders.requestId],
          );
          return ResponseBody.fromString(
            '{"success":true,"data":{"accessToken":"secret_tok"}}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        })
        ..interceptors.addAll([
          RequestIdInterceptor(),
          NetworkLoggingInterceptor(logger: logger, isProduction: false),
        ]);

      await dio.post(
        '/auth/otp/verify',
        data: {'phone': '+201012345678', 'code': '654321'},
      );

      expect(logger.logs.length, 2);
      expect(logger.logs[0].message, startsWith('┌'));
      expect(logger.logs[0].message, contains('[API][REQUEST]'));
      expect(logger.logs[0].message, contains('POST /auth/otp/verify'));
      expect(logger.logs[0].data['payload']['code'], '[REDACTED]');
      expect(logger.logs[0].data['payload']['phone'], '+2010***5678');

      expect(logger.logs[1].message, startsWith('┌'));
      expect(logger.logs[1].message, contains('[API][RESPONSE] 200 OK'));
      expect(logger.logs[1].message, contains('ms)'));
      expect(
        logger.logs[1].data['response']['data']['accessToken'],
        '[REDACTED]',
      );
    });

    test('summarizes large feed responses instead of dumping raw JSON walls', () async {
      final logger = _CapturingLogger();
      final largeItems = List.generate(
        12,
        (i) => {
          'id': 'item-$i',
          'title': 'Long product title number $i with extra details',
          'description': 'A very long description ' * 5,
        },
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
        ..httpClientAdapter = _StubAdapter((_) async {
          return ResponseBody.fromString(
            '{"success":true,"data":${largeItems.map((e) => '{"id":"${e['id']}","title":"${e['title']}","description":"${e['description']}"}').toList()},"meta":{"total":50,"hasMore":true}}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        })
        ..interceptors.addAll([
          RequestIdInterceptor(),
          NetworkLoggingInterceptor(logger: logger, isProduction: false),
        ]);

      await dio.get('/listings', queryParameters: {'limit': 12});

      expect(logger.logs.length, 2);
      expect(logger.logs[1].message, contains('success=true'));
      expect(logger.logs[1].message, contains('items='));
      expect(logger.logs[1].message.length, lessThan(500));
    });

    test('suppresses debug payloads in production while logging safe [API][ERROR]', () async {
      final logger = _CapturingLogger();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
        ..httpClientAdapter = _StubAdapter((_) async {
          return ResponseBody.fromString(
            '{"success":false,"error":{"code":"VALIDATION_FAILED","message":"Invalid input"}}',
            400,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        })
        ..interceptors.addAll([
          RequestIdInterceptor(),
          NetworkLoggingInterceptor(logger: logger, isProduction: true),
        ]);

      await expectLater(
        () => dio.post('/auth/otp/send', data: {'phone': 'bad'}),
        throwsA(isA<DioException>()),
      );

      // In production, request log is suppressed; only safe [API][ERROR] is recorded.
      expect(logger.logs.length, 1);
      expect(logger.logs[0].level, 'ERROR');
      expect(logger.logs[0].message, contains('[API][ERROR]'));
      expect(logger.logs[0].message, contains('400 • VALIDATION'));
      expect(logger.logs[0].message, contains('Error Code : VALIDATION_FAILED'));
      expect(logger.logs[0].message, contains('Message    : Invalid input'));
      expect(logger.logs[0].data.containsKey('response'), isFalse);
    });
  });
}
