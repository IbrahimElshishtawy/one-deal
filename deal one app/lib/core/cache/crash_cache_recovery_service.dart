import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:market_space/core/logging/app_logger.dart';
import 'package:market_space/core/storage/storage_keys.dart';

/// Automatically purges volatile/potentially corrupted caches whenever the app
/// hits an uncaught runtime crash, Flutter framework error, or startup crash loop.
///
/// Preserves safe user preferences (theme, language, onboarding) and secure
/// authentication tokens in FlutterSecureStorage so the user is never logged out
/// or reset unnecessarily.
class CrashCacheRecoveryService {
  static const String bootInProgressKey = 'd1_boot_in_progress';
  static const String lastCrashPurgeAtKey = 'd1_last_crash_cache_purge_at';

  static const Duration _defaultCooldown = Duration(seconds: 3);

  /// Volatile cache key prefixes that can safely be regenerated from the backend.
  static const List<String> _volatilePrefixes = <String>[
    'd1_cache_',
    'd1_last_viewed_',
    'd1_recently_viewed_',
  ];

  /// Exact volatile cache keys cleared on crash (never includes theme/locale/auth tokens).
  static const Set<String> _volatileExactKeys = <String>{
    StorageKeys.cachedUser,
    'd1_search_history_v1',
    'd1_recently_viewed_v1',
    'd1_last_viewed_v1',
  };

  static final Set<void Function()> _memoryCacheClearHooks = <void Function()>{};

  final AppLogger logger;
  final Future<SharedPreferences> Function() _prefsLoader;
  final Duration cooldown;

  DateTime? _lastPurgeAt;
  bool _isPurging = false;

  CrashCacheRecoveryService({
    required this.logger,
    Future<SharedPreferences> Function()? prefsLoader,
    this.cooldown = _defaultCooldown,
  }) : _prefsLoader = prefsLoader ?? SharedPreferences.getInstance;

  /// Registers an in-memory cache clear callback (e.g. [HybridCacheManager.clearMemory]).
  /// Returns an unregister callback suitable for Riverpod `ref.onDispose`.
  static void Function() registerMemoryCacheCleaner(void Function() onClear) {
    _memoryCacheClearHooks.add(onClear);
    return () => _memoryCacheClearHooks.remove(onClear);
  }

  /// Returns true if [key] is a volatile/regenerable cache key that should be
  /// purged when a crash occurs.
  static bool isVolatileCacheKey(String key) {
    if (_volatileExactKeys.contains(key)) return true;
    for (final prefix in _volatilePrefixes) {
      if (key.startsWith(prefix)) return true;
    }
    return false;
  }

  /// Checks whether the previous launch crashed before rendering its first frame.
  /// If so, purges volatile caches immediately before controllers initialize.
  Future<int> checkAndRecoverFromPreviousStartupCrash() async {
    try {
      final prefs = await _prefsLoader();
      final crashedDuringLastBoot = prefs.getBool(bootInProgressKey) ?? false;
      if (!crashedDuringLastBoot) return 0;

      logger.warning(
        'Detected incomplete previous startup — purging volatile caches before boot.',
      );
      return await purgeVolatileCaches(
        reason: 'previous_startup_crash',
        bypassCooldown: true,
      );
    } catch (e, st) {
      logger.error(
        'Failed checking previous startup crash state: $e',
        error: e,
        stackTrace: st,
      );
      return 0;
    }
  }

  /// Marks that app startup is in progress. Cleared by [markBootCompleted]
  /// once the first frame renders cleanly.
  Future<void> markBootStarted() async {
    try {
      final prefs = await _prefsLoader();
      await prefs.setBool(bootInProgressKey, true);
    } catch (_) {
      // Never block app boot on flag write failure.
    }
  }

  /// Marks that app startup succeeded cleanly (first frame rendered).
  Future<void> markBootCompleted() async {
    try {
      final prefs = await _prefsLoader();
      await prefs.setBool(bootInProgressKey, false);
    } catch (_) {
      // Best-effort only.
    }
  }

  /// Immediately clears in-memory caches, Flutter's image cache, and all
  /// volatile persistent cache keys in SharedPreferences.
  ///
  /// Returns the number of persistent keys removed.
  Future<int> purgeVolatileCaches({
    required String reason,
    bool bypassCooldown = false,
  }) async {
    if (_isPurging) return 0;
    final now = DateTime.now();
    if (!bypassCooldown &&
        _lastPurgeAt != null &&
        now.difference(_lastPurgeAt!) < cooldown) {
      return 0;
    }

    _isPurging = true;
    _lastPurgeAt = now;

    // 1. Clear all registered L1 in-memory caches immediately (synchronous).
    for (final clearHook in List<void Function()>.from(_memoryCacheClearHooks)) {
      try {
        clearHook();
      } catch (_) {}
    }

    // 2. Clear Flutter's decoded image cache safely.
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      imageCache.clear();
      imageCache.clearLiveImages();
    } catch (_) {
      // Binding may not be initialized in pure unit tests.
    }

    // 3. Remove volatile L2 persistent cache keys from SharedPreferences.
    var removedCount = 0;
    try {
      final prefs = await _prefsLoader();
      final keysToRemove = prefs
          .getKeys()
          .where(isVolatileCacheKey)
          .toList(growable: false);

      for (final key in keysToRemove) {
        final removed = await prefs.remove(key);
        if (removed) removedCount++;
      }

      await prefs.setString(lastCrashPurgeAtKey, now.toIso8601String());

      logger.warning(
        'Crash cache recovery purged $removedCount volatile cache entries (reason: $reason).',
      );
    } catch (e, st) {
      logger.error(
        'Crash cache recovery failed while purging persistent cache: $e',
        error: e,
        stackTrace: st,
      );
    } finally {
      _isPurging = false;
    }

    return removedCount;
  }

  /// Static emergency helper used when `bootstrap()` fails before DI finishes.
  static Future<int> emergencyPurgeVolatileCaches({
    required AppLogger logger,
    required String reason,
    Future<SharedPreferences> Function()? prefsLoader,
  }) {
    final service = CrashCacheRecoveryService(
      logger: logger,
      prefsLoader: prefsLoader,
    );
    return service.purgeVolatileCaches(reason: reason, bypassCooldown: true);
  }
}
