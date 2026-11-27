import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

/// Compact locally persisted summary of a listing the user actually opened.
/// No mock data is ever generated; entries are added only when a user opens
/// a real listing detail screen.
class RecentlyViewedEntry {
  final String id;
  final String title;
  final double price;
  final String currency;
  final String? imageUrl;
  final String location;
  final String categorySlug;
  final DateTime viewedAt;

  const RecentlyViewedEntry({
    required this.id,
    required this.title,
    required this.price,
    this.currency = 'EGP',
    this.imageUrl,
    this.location = '',
    required this.categorySlug,
    required this.viewedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'currency': currency,
        'imageUrl': imageUrl,
        'location': location,
        'categorySlug': categorySlug,
        'viewedAt': viewedAt.toIso8601String(),
      };

  factory RecentlyViewedEntry.fromJson(Map<String, dynamic> json) {
    return RecentlyViewedEntry(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'EGP',
      imageUrl: json['imageUrl']?.toString(),
      location: json['location']?.toString() ?? '',
      categorySlug: json['categorySlug']?.toString() ?? '',
      viewedAt: DateTime.tryParse(json['viewedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  factory RecentlyViewedEntry.fromListing(
    ListingItem item, {
    required String sectionSlug,
    String localeCode = 'ar',
  }) {
    return RecentlyViewedEntry(
      id: item.id,
      title: item.title,
      price: item.price,
      currency: item.currency,
      imageUrl: item.primaryImageUrl,
      location: item.localizedLocation(localeCode),
      categorySlug: MapCategoryRegistry.normalizeSlug(sectionSlug),
      viewedAt: DateTime.now(),
    );
  }
}

class RecentlyViewedNotifier
    extends StateNotifier<Map<String, List<RecentlyViewedEntry>>> {
  static const String _storageKey = 'deal_one_recently_viewed_v1';
  static const int _maxPerCategory = 10;

  RecentlyViewedNotifier() : super(const {}) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final restored = <String, List<RecentlyViewedEntry>>{};
      for (final entry in decoded.entries) {
        if (entry.value is List) {
          restored[entry.key.toString()] = (entry.value as List)
              .whereType<Map>()
              .map(
                (e) =>
                    RecentlyViewedEntry.fromJson(Map<String, dynamic>.from(e)),
              )
              .where((e) => e.id.isNotEmpty)
              .toList();
        }
      }
      if (!mounted) return;
      // Merge restored entries with any views recorded before _restore() finished
      // so fast navigations never lose the most recent view.
      final merged = Map<String, List<RecentlyViewedEntry>>.from(restored);
      for (final currentEntry in state.entries) {
        final combined = List<RecentlyViewedEntry>.from(currentEntry.value);
        for (final oldItem in merged[currentEntry.key] ?? const <RecentlyViewedEntry>[]) {
          if (!combined.any((e) => e.id == oldItem.id)) {
            combined.add(oldItem);
          }
        }
        if (combined.length > _maxPerCategory) {
          combined.removeRange(_maxPerCategory, combined.length);
        }
        merged[currentEntry.key] = combined;
      }
      state = merged;
    } catch (_) {
      // Fail safely on corrupt local preferences without disrupting Home.
    }
  }

  Future<void> recordView(
    ListingItem item, {
    required String sectionSlug,
    String localeCode = 'ar',
  }) async {
    final normalized = MapCategoryRegistry.normalizeSlug(sectionSlug);
    final entry = RecentlyViewedEntry.fromListing(
      item,
      sectionSlug: normalized,
      localeCode: localeCode,
    );
    final current = List<RecentlyViewedEntry>.from(state[normalized] ?? const []);
    current.removeWhere((e) => e.id == item.id);
    current.insert(0, entry);
    if (current.length > _maxPerCategory) {
      current.removeRange(_maxPerCategory, current.length);
    }

    final next = Map<String, List<RecentlyViewedEntry>>.from(state)
      ..[normalized] = current;
    state = next;

    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        next.map(
          (key, list) => MapEntry(key, list.map((e) => e.toJson()).toList()),
        ),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      // Non-fatal persistence error.
    }
  }
}

final recentlyViewedProvider = StateNotifierProvider<
    RecentlyViewedNotifier, Map<String, List<RecentlyViewedEntry>>>(
  (ref) => RecentlyViewedNotifier(),
);

final categoryRecentlyViewedProvider =
    Provider.family<List<RecentlyViewedEntry>, String>((ref, sectionSlug) {
  final normalized = MapCategoryRegistry.normalizeSlug(sectionSlug);
  return ref.watch(
    recentlyViewedProvider.select((map) => map[normalized] ?? const []),
  );
});
