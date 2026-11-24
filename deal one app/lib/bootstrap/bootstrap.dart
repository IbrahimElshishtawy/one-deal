import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:market_space/app/app.dart';
import 'package:market_space/app/app_dependencies.dart';
import 'package:market_space/app/app_theme.dart';
import 'package:market_space/core/cache/crash_cache_recovery_service.dart';
import 'package:market_space/core/config/app_config.dart';
import 'package:market_space/core/config/config_validator.dart';
import 'package:market_space/core/localization/locale_controller.dart';
import 'package:market_space/core/logging/app_logger.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/network_info.dart';
import 'package:market_space/core/platform/platform_info.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/security/secure_token_provider.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/core/storage/secure_storage_service.dart';
import 'package:market_space/core/storage/storage_keys.dart';
import 'package:market_space/shared/state/sector_controller.dart';
import 'package:market_space/bootstrap/bootstrap_observer.dart';

Future<AppDependencies> initializeDependencies(AppConfig config) async {
  ConfigValidator.validate(config);

  final logger = AppLoggerImpl(isLoggingEnabled: config.enableLogging);
  final crashRecovery = CrashCacheRecoveryService(logger: logger);
  final observer = BootstrapObserver(
    logger: logger,
    crashRecovery: crashRecovery,
  );
  observer.attachGlobalErrorHooks();

  // If the previous launch crashed before finishing boot, purge volatile caches
  // immediately before loading any cached state or controllers.
  await crashRecovery.checkAndRecoverFromPreviousStartupCrash();
  await crashRecovery.markBootStarted();

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

  final onboardingCompleted =
      await preferencesService.getBool(StorageKeys.onboardingCompleted) ??
      false;

  return AppDependencies(
    appConfig: config,
    logger: logger,
    networkInfo: networkInfo,
    preferencesService: preferencesService,
    secureStorageService: secureStorageService,
    tokenProvider: tokenProvider,
    apiClient: apiClient,
    platformInfo: platformInfo,
    localeController: localeController,
    themeController: themeController,
    sectorController: sectorController,
    onboardingCompleted: onboardingCompleted,
  );
}

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final dependencies = await initializeDependencies(config);
    runApp(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(dependencies.appConfig),
          networkInfoProvider.overrideWithValue(dependencies.networkInfo),
          preferencesServiceProvider.overrideWithValue(
            dependencies.preferencesService,
          ),
          secureStorageServiceProvider.overrideWithValue(
            dependencies.secureStorageService,
          ),
          sessionValidatorProvider.overrideWith((ref) {
            final apiClient = ref.watch(apiClientProvider);
            return () => validateSessionViaBackend(apiClient);
          }),
        ],
        child: MarketSpaceApp(dependencies: dependencies),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CrashCacheRecoveryService(logger: dependencies.logger).markBootCompleted();
    });
  } catch (error, stackTrace) {
    final fallbackLogger = AppLoggerImpl(isLoggingEnabled: true);
    fallbackLogger.error(
      'Fatal bootstrap initialization error: $error',
      error: error,
      stackTrace: stackTrace,
    );
    await CrashCacheRecoveryService.emergencyPurgeVolatileCaches(
      logger: fallbackLogger,
      reason: 'bootstrap_fatal_error',
    );

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cleaning_services_rounded,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تم مسح الكاش المؤقت تلقائيًا بعد حدوث خطأ غير متوقع.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => bootstrap(config),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة التشغيل'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
