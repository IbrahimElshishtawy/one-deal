import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:market_space/core/cache/crash_cache_recovery_service.dart';
import 'package:market_space/core/cache/hybrid_cache_manager.dart';
import 'package:market_space/core/logging/app_logger.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/core/storage/storage_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const logger = AppLoggerImpl(isLoggingEnabled: false);

  group('CrashCacheRecoveryService', () {
    test('purges volatile cache keys while preserving user preferences', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'd1_cache_v2:home_main': '{"corrupt": true}',
        'd1_cache_v2:section:real-estate': 'not-valid-json{{{',
        'd1_last_viewed_v1': '[bad',
        'd1_recently_viewed_v1': '[bad',
        'd1_search_history_v1': '["q"]',
        StorageKeys.cachedUser: '{"id": "corrupt"}',
        // Safe user preferences that MUST be preserved:
        StorageKeys.themeMode: 'dark',
        StorageKeys.languageCode: 'ar',
        StorageKeys.onboardingCompleted: true,
      });

      final service = CrashCacheRecoveryService(logger: logger);
      final removed = await service.purgeVolatileCaches(
        reason: 'test_runtime_crash',
        bypassCooldown: true,
      );

      expect(removed, 6);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('d1_cache_v2:home_main'), isNull);
      expect(prefs.getString('d1_cache_v2:section:real-estate'), isNull);
      expect(prefs.getString('d1_last_viewed_v1'), isNull);
      expect(prefs.getString('d1_recently_viewed_v1'), isNull);
      expect(prefs.getString('d1_search_history_v1'), isNull);
      expect(prefs.getString(StorageKeys.cachedUser), isNull);
      expect(prefs.getString(CrashCacheRecoveryService.lastCrashPurgeAtKey), isNotNull);

      // Safe user preferences remain intact
      expect(prefs.getString(StorageKeys.themeMode), 'dark');
      expect(prefs.getString(StorageKeys.languageCode), 'ar');
      expect(prefs.getBool(StorageKeys.onboardingCompleted), isTrue);
    });

    test('detects incomplete previous boot and purges volatile caches automatically', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        CrashCacheRecoveryService.bootInProgressKey: true,
        'd1_cache_v2:home_main': 'corrupted_payload',
        StorageKeys.languageCode: 'ar',
      });

      final service = CrashCacheRecoveryService(logger: logger);
      final removed = await service.checkAndRecoverFromPreviousStartupCrash();
      expect(removed, 1);

      await service.markBootStarted();
      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(CrashCacheRecoveryService.bootInProgressKey), isTrue);

      await service.markBootCompleted();
      prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(CrashCacheRecoveryService.bootInProgressKey), isFalse);
      expect(prefs.getString('d1_cache_v2:home_main'), isNull);
      expect(prefs.getString(StorageKeys.languageCode), 'ar');
    });

    test('clears registered L1 HybridCacheManager memory on crash', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final memPrefs = InMemoryPreferencesService();
      final cacheManager = HybridCacheManager(preferencesService: memPrefs);
      await cacheManager.write(
        'home_main',
        {'ok': true},
        ttl: CacheTtlPolicy.homeFeed,
      );

      final unregister = CrashCacheRecoveryService.registerMemoryCacheCleaner(
        cacheManager.clearMemory,
      );
      addTearDown(unregister);

      final service = CrashCacheRecoveryService(logger: logger);
      await service.purgeVolatileCaches(
        reason: 'test_memory_clear',
        bypassCooldown: true,
      );

      // Remove persistent entry from InMemoryPreferencesService to prove L1 memory was cleared
      await memPrefs.remove('d1_cache_v2:home_main');
      final record = await cacheManager.read('home_main');
      expect(record, isNull);
    });
  });
}
