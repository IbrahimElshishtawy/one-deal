import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/app.dart';
import '../app/app_dependencies.dart';
import '../app/app_theme.dart';
import '../core/config/app_config.dart';
import '../core/config/config_validator.dart';
import '../core/localization/locale_controller.dart';
import '../core/logging/app_logger.dart';
import '../core/mock_data/mock_data_provider.dart';
import '../core/network/api_client.dart';
import '../core/network/network_info.dart';
import '../core/platform/platform_info.dart';
import '../core/security/secure_token_provider.dart';
import '../core/storage/preferences_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../shared/state/sector_controller.dart';
import 'bootstrap_observer.dart';

Future<AppDependencies> initializeDependencies(AppConfig config) async {
  ConfigValidator.validate(config);

  final logger = AppLoggerImpl(isLoggingEnabled: config.enableLogging);
  final observer = BootstrapObserver(logger: logger);
  observer.attachGlobalErrorHooks();

  final sharedPreferences = await SharedPreferences.getInstance();
  final preferencesService = SharedPreferencesServiceImpl(
    sharedPreferences: sharedPreferences,
  );

  const flutterSecureStorage = FlutterSecureStorage();
  final secureStorageService = FlutterSecureStorageServiceImpl(
    secureStorage: flutterSecureStorage,
  );

  final tokenProvider = SecureTokenProvider(
    secureStorageService: secureStorageService,
  );

  final networkInfo = NetworkInfoImpl(connectivity: Connectivity());

  final apiClient = DioApiClient.create(
    appConfig: config,
    networkInfo: networkInfo,
    tokenProvider: tokenProvider,
    logger: logger,
  );

  final mockDataProvider = MockDataProvider();
  const platformInfo = PlatformInfoImpl();

  final localeController = LocaleController(
    preferencesService: preferencesService,
  );
  await localeController.loadSavedLocale();

  final themeController = ThemeController(
    preferencesService: preferencesService,
  );
  await themeController.loadSavedTheme();

  final sectorController = SectorController(
    preferencesService: preferencesService,
  );
  await sectorController.loadSavedSector();

  return AppDependencies(
    appConfig: config,
    logger: logger,
    networkInfo: networkInfo,
    preferencesService: preferencesService,
    secureStorageService: secureStorageService,
    tokenProvider: tokenProvider,
    apiClient: apiClient,
    mockDataProvider: mockDataProvider,
    platformInfo: platformInfo,
    localeController: localeController,
    themeController: themeController,
    sectorController: sectorController,
  );
}

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final dependencies = await initializeDependencies(config);
    runApp(
      ProviderScope(
        child: MarketSpaceApp(dependencies: dependencies),
      ),
    );
  } catch (error, stackTrace) {
    final fallbackLogger = AppLoggerImpl(isLoggingEnabled: true);
    fallbackLogger.error(
      'Fatal bootstrap initialization error: $error',
      error: error,
      stackTrace: stackTrace,
    );

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Fatal initialization error: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
