import 'package:flutter/foundation.dart';

import 'package:market_space/core/logging/app_logger.dart';

class BootstrapObserver {
  final AppLogger logger;

  BootstrapObserver({required this.logger});

  void attachGlobalErrorHooks() {
    FlutterError.onError = (FlutterErrorDetails details) {
      logger.error(
        'Flutter UI Framework Error: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    PlatformDispatcher.instance.onError =
        (Object error, StackTrace stackTrace) {
          logger.error(
            'Platform Dispatcher Uncaught Error: $error',
            error: error,
            stackTrace: stackTrace,
          );
          return true;
        };
  }
}
