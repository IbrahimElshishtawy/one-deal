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
    final sanitizedData = data != null ? LogSanitizer.sanitize(data) : null;
    final buffer = StringBuffer('[$level] $message');

    if (sanitizedData != null) {
      buffer.write(' | data: $sanitizedData');
    }
    if (error != null) {
      buffer.write(' | error: $error');
    }

    developer.log(
      buffer.toString(),
      name: 'MarketSpace',
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }
}
