import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:market_space/core/logging/app_logger.dart';
import 'package:market_space/core/logging/log_sanitizer.dart';
import 'package:market_space/core/network/api_headers.dart';
import 'package:market_space/core/network/interceptors/request_id_interceptor.dart';

/// Centralized Dio observability interceptor emitting clean, structured
/// `[API][REQUEST]`, `[API][RESPONSE]`, and `[API][ERROR]` blocks.
///
/// Strict environment separation:
/// - Development: logs formatted request summary, concise response summary or
///   compact JSON, duration, and Request ID.
/// - Production: suppresses debug request/response payloads and logs only safe
///   error summaries.
class NetworkLoggingInterceptor extends Interceptor {
  static const String _topBorder =
      '┌────────────────────────────────────────────────────────────';
  static const String _bottomBorder =
      '└────────────────────────────────────────────────────────────';
  static const int _inlineJsonMaxChars = 360;

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

  String _extractErrorMessage(DioException err) {
    final data = err.response?.data;
    if (data is Map) {
      final nestedError = data['error'];
      if (nestedError is Map && nestedError['message'] != null) {
        return nestedError['message'].toString();
      }
      if (data['message'] != null) {
        return data['message'].toString();
      }
    }
    return err.message ?? 'Unexpected network error';
  }

  String _formatHeadersSummary(Map<String, dynamic> headers) {
    final lang = headers[ApiHeaders.acceptLanguage]?.toString();
    final hasAuth = headers.keys.any(
      (k) => k.toLowerCase() == 'authorization' && headers[k] != null,
    );
    final parts = <String>[];
    if (lang != null && lang.isNotEmpty) parts.add('Lang: $lang');
    parts.add(hasAuth ? 'Auth: Bearer [REDACTED]' : 'Auth: Guest');
    return parts.join(' | ');
  }

  String _formatQuerySummary(Map<String, dynamic> query) {
    return query.entries.map((e) => '${e.key}=${e.value}').join(', ');
  }

  String _formatCompactOrSummary(dynamic sanitizedData) {
    if (sanitizedData == null) return 'null';

    try {
      final compact = jsonEncode(sanitizedData);
      if (compact.length <= _inlineJsonMaxChars) {
        return compact;
      }
    } catch (_) {
      final text = sanitizedData.toString();
      if (text.length <= _inlineJsonMaxChars) {
        return text;
      }
    }

    return _summarizeLargePayload(sanitizedData);
  }

  String _summarizeLargePayload(dynamic data) {
    if (data is List) {
      return 'List(${data.length} items)';
    }

    if (data is Map) {
      final parts = <String>[];
      if (data.containsKey('success')) {
        parts.add('success=${data['success']}');
      }

      final payload = data['data'];
      if (payload is List) {
        parts.add('items=${payload.length}');
      } else if (payload is Map) {
        final sectionCounts = <String>[];
        for (final entry in payload.entries) {
          final v = entry.value;
          if (v is List) {
            sectionCounts.add('${entry.key}=${v.length}');
          } else if (v is Map) {
            sectionCounts.add('${entry.key}={${v.length} keys}');
          } else if (v != null) {
            final str = v.toString();
            sectionCounts.add(
              '${entry.key}=${str.length > 28 ? '${str.substring(0, 28)}…' : str}',
            );
          }
        }
        if (sectionCounts.isNotEmpty) {
          parts.add(sectionCounts.take(6).join(', '));
          if (sectionCounts.length > 6) {
            parts.add('+${sectionCounts.length - 6} more fields');
          }
        }
      }

      final meta = data['meta'];
      if (meta is Map && meta.isNotEmpty) {
        final metaStr = meta.entries
            .take(4)
            .map((e) => '${e.key}=${e.value}')
            .join(', ');
        parts.add('meta($metaStr)');
      }

      if (parts.isNotEmpty) {
        return parts.join(' | ');
      }
      return 'Map(${data.keys.take(6).join(', ')})';
    }

    final text = data.toString();
    return text.length > _inlineJsonMaxChars
        ? '${text.substring(0, _inlineJsonMaxChars)}…'
        : text;
  }

  String _buildBox(List<String> lines) {
    final buffer = StringBuffer(_topBorder);
    for (final line in lines) {
      buffer.write('\n│ $line');
    }
    buffer.write('\n$_bottomBorder');
    return buffer.toString();
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!isProduction) {
      final requestId = _resolveRequestId(options);
      final sanitizedHeaders = LogSanitizer.sanitize(options.headers);
      final sanitizedPayload = LogSanitizer.sanitize(options.data);

      final lines = <String>[
        '[API][REQUEST]  ${options.method.toUpperCase()} ${options.path}',
        'Request ID : $requestId',
        'Headers    : ${_formatHeadersSummary(options.headers)}',
        if (options.queryParameters.isNotEmpty)
          'Query      : ${_formatQuerySummary(options.queryParameters)}',
        if (sanitizedPayload != null)
          'Payload    : ${_formatCompactOrSummary(sanitizedPayload)}',
      ];

      logger.debug(
        _buildBox(lines),
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
      final method = response.requestOptions.method.toUpperCase();
      final status = response.statusCode ?? 0;

      final lines = <String>[
        '[API][RESPONSE] $status OK (${durationMs}ms) • $method ${response.requestOptions.path}',
        'Request ID : $requestId',
        'Body       : ${_formatCompactOrSummary(sanitizedResponse)}',
      ];

      logger.info(
        _buildBox(lines),
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
    final errorMessage = _extractErrorMessage(err);
    final method = err.requestOptions.method.toUpperCase();

    final lines = <String>[
      '[API][ERROR]    $status • $layer (${durationMs}ms) • $method ${err.requestOptions.path}',
      'Request ID : $requestId',
      'Error Code : $errorCode',
      'Message    : $errorMessage',
    ];

    logger.error(
      _buildBox(lines),
      data: isProduction
          ? {'code': errorCode, 'layer': layer, 'requestId': requestId}
          : {
              'code': errorCode,
              'layer': layer,
              'requestId': requestId,
              'message': errorMessage,
              'response': LogSanitizer.sanitize(err.response?.data),
            },
    );
    handler.next(err);
  }
}
