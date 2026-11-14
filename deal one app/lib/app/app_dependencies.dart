import 'package:flutter/widgets.dart';

import '../core/config/app_config.dart';
import '../core/localization/locale_controller.dart';
import '../core/logging/app_logger.dart';
import '../core/network/api_client.dart';
import '../core/network/network_info.dart';
import '../core/platform/platform_info.dart';
import '../core/security/token_provider.dart';
import '../core/storage/preferences_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../shared/state/sector_controller.dart';
import 'app_theme.dart';

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
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppDependenciesScope>();
    assert(scope != null, 'No AppDependenciesScope found in context');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppDependenciesScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
