import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:market_space/core/cache/crash_cache_recovery_service.dart';
import 'package:market_space/core/logging/app_logger.dart';

class BootstrapObserver {
  final AppLogger logger;
  final CrashCacheRecoveryService? crashRecovery;

  BootstrapObserver({
    required this.logger,
    this.crashRecovery,
  });

  void attachGlobalErrorHooks() {
    FlutterError.onError = (FlutterErrorDetails details) {
      logger.error(
        'Flutter UI Framework Error: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
      );
      if (crashRecovery != null) {
        unawaited(
          crashRecovery!.purgeVolatileCaches(reason: 'flutter_framework_error'),
        );
      }
    };

    PlatformDispatcher.instance.onError =
        (Object error, StackTrace stackTrace) {
          logger.error(
            'Platform Dispatcher Uncaught Error: $error',
            error: error,
            stackTrace: stackTrace,
          );
          if (crashRecovery != null) {
            unawaited(
              crashRecovery!.purgeVolatileCaches(
                reason: 'platform_uncaught_error',
              ),
            );
          }
          return true;
        };
  }
}
