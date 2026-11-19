import 'dart:convert';

import '../storage/preferences_service.dart';

/// Cache TTL presets per domain entity type.
class CacheTtlPolicy {
  static const Duration categories = Duration(minutes: 10);
  static const Duration homeFeed = Duration(minutes: 3);
  static const Duration sectionFeed = Duration(minutes: 3);
  static const Duration filterConfig = Duration(minutes: 15);
  static const Duration searchResults = Duration(minutes: 2);
  static const Duration priceFreshness = Duration(seconds: 60);
  static const Duration maxStaleOffline = Duration(days: 7);
}

class CacheRecord {
  final Map<String, dynamic> payload;
  final DateTime cachedAt;
  final Duration ttl;
  final int version;

  const CacheRecord({
    required this.payload,
    required this.cachedAt,
    required this.ttl,
    required this.version,
  });

  bool get isFresh => DateTime.now().difference(cachedAt) <= ttl;

  bool get isUsableStale =>
      DateTime.now().difference(cachedAt) <= CacheTtlPolicy.maxStaleOffline;

  Map<String, dynamic> toJson() => {
        'v': version,
        'cachedAt': cachedAt.toIso8601String(),
        'ttlMs': ttl.inMilliseconds,
        'payload': payload,
      };

  static CacheRecord? tryParse(String raw, int expectedVersion) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final version = (decoded['v'] as num?)?.toInt() ?? 0;
      if (version != expectedVersion) return null;
      final cachedAtStr = decoded['cachedAt']?.toString();
      final ttlMs = (decoded['ttlMs'] as num?)?.toInt() ?? 0;
      final payload = decoded['payload'];
      if (cachedAtStr == null || payload is! Map) return null;
      final cachedAt = DateTime.tryParse(cachedAtStr);
      if (cachedAt == null) return null;
      return CacheRecord(
        payload: Map<String, dynamic>.from(payload),
        cachedAt: cachedAt,
        ttl: Duration(milliseconds: ttlMs),
        version: version,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Two-tier Hybrid Local Cache (L1 Memory + L2 Persistent Storage)
/// supporting Stale-While-Revalidate, Cache Versioning, Per-Domain TTLs,
/// Search History, and Last Viewed Products.
class HybridCacheManager {
  static const int currentSchemaVersion = 2;
  static const String _keyPrefix = 'd1_cache_v2:';
  static const String _searchHistoryKey = 'd1_search_history_v1';
  static const String _lastViewedKey = 'd1_last_viewed_v1';
  static const int _maxHistoryItems = 15;
  static const int _maxMemoryEntries = 80;

  final PreferencesService _prefs;
  final Map<String, CacheRecord> _memory = {};

  HybridCacheManager({required PreferencesService preferencesService})
      : _prefs = preferencesService;

  String _storageKey(String key) => '$_keyPrefix$key';

  /// Reads from L1 memory first, then L2 persistent storage.
  /// Returns null only if missing, corrupt, or older than maxStaleOffline.
  Future<CacheRecord?> read(String key) async {
    final mem = _memory[key];
    if (mem != null) {
      if (mem.isUsableStale) return mem;
      _memory.remove(key);
    }

    try {
      final raw = await _prefs.getString(_storageKey(key));
      if (raw == null || raw.isEmpty) return null;
      final parsed = CacheRecord.tryParse(raw, currentSchemaVersion);
      if (parsed == null || !parsed.isUsableStale) {
        await _prefs.remove(_storageKey(key));
        return null;
      }
      _putMemory(key, parsed);
      return parsed;
    } catch (_) {
      return null;
    }
  }

  /// Writes JSON payload to both L1 memory and L2 persistent storage.
  Future<void> write(
    String key,
    Map<String, dynamic> payload, {
    required Duration ttl,
  }) async {
    final record = CacheRecord(
      payload: payload,
      cachedAt: DateTime.now(),
      ttl: ttl,
      version: currentSchemaVersion,
    );
    _putMemory(key, record);
    try {
      await _prefs.setString(_storageKey(key), jsonEncode(record.toJson()));
    } catch (_) {
      // Never crash the app on cache write failure.
    }
  }

  /// Invalidates a single key without wiping unrelated cache entries.
  Future<void> invalidate(String key) async {
    _memory.remove(key);
    try {
      await _prefs.remove(_storageKey(key));
    } catch (_) {}
  }

  /// Invalidates all in-memory keys matching a prefix (e.g. `section:real-estate`).
  void invalidateMemoryPrefix(String prefix) {
    _memory.removeWhere((k, _) => k.startsWith(prefix));
  }

  void _putMemory(String key, CacheRecord record) {
    if (_memory.length >= _maxMemoryEntries && !_memory.containsKey(key)) {
      _memory.remove(_memory.keys.first);
    }
    _memory[key] = record;
  }

  // ---- Search History ----

  Future<List<String>> getSearchHistory() async {
    try {
      final raw = await _prefs.getString(_searchHistoryKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<void> addSearchHistory(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return;
    final current = List<String>.from(await getSearchHistory());
    current.removeWhere((e) => e.toLowerCase() == trimmed.toLowerCase());
    current.insert(0, trimmed);
    if (current.length > _maxHistoryItems) {
      current.removeRange(_maxHistoryItems, current.length);
    }
    try {
      await _prefs.setString(_searchHistoryKey, jsonEncode(current));
    } catch (_) {}
  }

  Future<void> clearSearchHistory() async {
    try {
      await _prefs.remove(_searchHistoryKey);
    } catch (_) {}
  }

  // ---- Last Viewed Products ----

  Future<List<Map<String, dynamic>>> getLastViewedListings() async {
    try {
      final raw = await _prefs.getString(_lastViewedKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<void> recordViewedListing({
    required String id,
    required String title,
    required double price,
    required String currency,
    String? imageUrl,
    String? categorySlug,
  }) async {
    final current = List<Map<String, dynamic>>.from(
      await getLastViewedListings(),
    );
    current.removeWhere((e) => e['id'] == id);
    current.insert(0, {
      'id': id,
      'title': title,
      'price': price,
      'currency': currency,
      'imageUrl': imageUrl,
      'categorySlug': categorySlug,
      'viewedAt': DateTime.now().toIso8601String(),
    });
    if (current.length > _maxHistoryItems) {
      current.removeRange(_maxHistoryItems, current.length);
    }
    try {
      await _prefs.setString(_lastViewedKey, jsonEncode(current));
    } catch (_) {}
  }
}
