import 'package:flutter/widgets.dart';

import 'package:market_space/core/config/app_config.dart';
import 'package:market_space/core/localization/locale_controller.dart';
import 'package:market_space/core/logging/app_logger.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/network_info.dart';
import 'package:market_space/core/platform/platform_info.dart';
import 'package:market_space/core/security/token_provider.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/core/storage/secure_storage_service.dart';
import 'package:market_space/shared/state/sector_controller.dart';
import 'package:market_space/app/app_theme.dart';

class AppDependencies {
  final AppConfig appConfig;
  final AppLogger logger;
  final NetworkInfo networkInfo;
  final PreferencesService preferencesService;
  final SecureStorageService secureStorageService;
  final TokenProvider tokenProvider;
  final ApiClient apiClient;
  final PlatformInfo platformInfo;
  final LocaleController localeController;
  final ThemeController themeController;
  final SectorController sectorController;
  final bool onboardingCompleted;

  AppDependencies({
    required this.appConfig,
    required this.logger,
    required this.networkInfo,
    required this.preferencesService,
    required this.secureStorageService,
    required this.tokenProvider,
    required this.apiClient,
    required this.platformInfo,
    required this.localeController,
    required this.themeController,
    required this.sectorController,
    this.onboardingCompleted = true,
  });

  static AppDependencies of(BuildContext context) =>
      AppDependenciesScope.of(context);
}

class AppDependenciesScope extends InheritedWidget {
  final AppDependencies dependencies;

  const AppDependenciesScope({
    super.key,
    required this.dependencies,
    required super.child,
  });

  static AppDependencies of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppDependenciesScope>();
    assert(scope != null, 'No AppDependenciesScope found in context');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppDependenciesScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
