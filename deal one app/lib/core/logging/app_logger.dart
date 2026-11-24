import 'dart:convert';
import 'dart:developer' as developer;

import 'package:market_space/core/logging/log_sanitizer.dart';

abstract class AppLogger {
  void debug(String message, {dynamic data});
  void info(String message, {dynamic data});
  void warning(
    String message, {
    dynamic data,
    Object? error,
    StackTrace? stackTrace,
  });
  void error(
    String message, {
    dynamic data,
    Object? error,
    StackTrace? stackTrace,
  });
}

class AppLoggerImpl implements AppLogger {
  final bool isLoggingEnabled;

  const AppLoggerImpl({required this.isLoggingEnabled});

  @override
  void debug(String message, {dynamic data}) {
    if (!isLoggingEnabled) return;
    _writeLog(level: 'DEBUG', message: message, data: data);
  }

  @override
  void info(String message, {dynamic data}) {
    if (!isLoggingEnabled) return;
    _writeLog(level: 'INFO', message: message, data: data);
  }

  @override
  void warning(
    String message, {
    dynamic data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!isLoggingEnabled) return;
    _writeLog(
      level: 'WARNING',
      message: message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void error(
    String message, {
    dynamic data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _writeLog(
      level: 'ERROR',
      message: message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _writeLog({
    required String level,
    required String message,
    dynamic data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final bool isPreformattedBlock = message.startsWith('┌');
    final buffer = StringBuffer();

    if (isPreformattedBlock) {
      buffer.write('\n$message');
    } else {
      buffer.write('[$level] $message');
      if (data != null) {
        final sanitizedData = LogSanitizer.sanitize(data);
        buffer.write('\n${_formatData(sanitizedData)}');
      }
      if (error != null) {
        buffer.write('\n  Error: $error');
      }
    }

    developer.log(
      buffer.toString(),
      name: 'DealOne',
      time: DateTime.now(),
      stackTrace: stackTrace,
    );
  }

  String _formatData(dynamic sanitizedData) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final encoded = encoder.convert(sanitizedData);
      if (encoded.length <= 600) {
        return encoded;
      }
      return '${encoded.substring(0, 600)}\n  ... [truncated]';
    } catch (_) {
      final text = sanitizedData.toString();
      if (text.length <= 600) {
        return '  $text';
      }
      return '  ${text.substring(0, 600)}... [truncated]';
    }
  }
}
