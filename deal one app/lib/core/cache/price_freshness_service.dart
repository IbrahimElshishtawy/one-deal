import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'hybrid_cache_manager.dart';

class LivePriceSnapshot {
  final String listingId;
  final double price;
  final String currency;
  final String availabilityStatus;
  final DateTime updatedAt;
  final DateTime fetchedAt;

  const LivePriceSnapshot({
    required this.listingId,
    required this.price,
    required this.currency,
    required this.availabilityStatus,
    required this.updatedAt,
    required this.fetchedAt,
  });

  bool isFresh({Duration ttl = CacheTtlPolicy.priceFreshness}) =>
      DateTime.now().difference(fetchedAt) <= ttl;
}

/// Manages authoritative batch price refreshing so visible listings never rely
/// indefinitely on cached prices and never fire N separate requests.
class LivePricesNotifier
    extends StateNotifier<Map<String, LivePriceSnapshot>> {
  final ApiClient _apiClient;
  final Set<String> _inFlightIds = {};

  LivePricesNotifier(this._apiClient) : super(const {});

  /// Refreshes any stale or unverified listing IDs in batches of up to 50.
  Future<void> refreshBatch(
    Iterable<String> listingIds, {
    Duration freshnessTtl = CacheTtlPolicy.priceFreshness,
    bool force = false,
  }) async {
    final staleIds = <String>[];
    for (final rawId in listingIds) {
      final id = rawId.trim();
      if (id.isEmpty || _inFlightIds.contains(id)) continue;
      final existing = state[id];
      if (force || existing == null || !existing.isFresh(ttl: freshnessTtl)) {
        staleIds.add(id);
      }
      if (staleIds.length >= 50) break;
    }

    if (staleIds.isEmpty) return;
    _inFlightIds.addAll(staleIds);

    try {
      final response = await _apiClient.post(
        ApiEndpoints.batchPrices,
        data: {'ids': staleIds},
      );
      final raw = response.data;
      final Map<String, dynamic> payload = raw is Map
          ? (raw['data'] is Map
                ? Map<String, dynamic>.from(raw['data'] as Map)
                : Map<String, dynamic>.from(raw))
          : const {};
      final items = payload['items'] as List? ?? const [];
      if (items.isEmpty || !mounted) return;

      final now = DateTime.now();
      final updated = Map<String, LivePriceSnapshot>.from(state);
      for (final entry in items) {
        if (entry is! Map) continue;
        final map = Map<String, dynamic>.from(entry);
        final id = map['id']?.toString() ?? '';
        final price = (map['price'] as num?)?.toDouble();
        if (id.isEmpty || price == null) continue;
        updated[id] = LivePriceSnapshot(
          listingId: id,
          price: price,
          currency: map['currency']?.toString() ?? 'EGP',
          availabilityStatus:
              map['availabilityStatus']?.toString() ?? 'available',
          updatedAt:
              DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? now,
          fetchedAt: now,
        );
      }
      if (mounted) {
        state = updated;
      }
    } catch (_) {
      // Fail gracefully: keep previously cached prices visible without crashing UI.
    } finally {
      _inFlightIds.removeAll(staleIds);
    }
  }

  /// Resolves the freshest known price for a listing, falling back to cachedPrice.
  double resolvePrice(String listingId, double cachedPrice) {
    return state[listingId]?.price ?? cachedPrice;
  }

  bool isPriceFresh(String listingId) {
    return state[listingId]?.isFresh() ?? false;
  }
}
