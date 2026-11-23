import 'package:market_space/features/maps/domain/entities/map_place_entity.dart';

/// Query parameters for fetching map places from the backend.
class MapPlacesQuery {
  final String? categorySlug;
  final bool searchAllCategories;
  final String query;
  final String? listingKind;
  final String? condition;
  final bool featuredOnly;
  final bool verifiedOnly;
  final double? minPrice;
  final double? maxPrice;
  final int? governorateId;
  final int? cityId;
  final double? centerLat;
  final double? centerLng;
  final double? radiusKm;
  final int page;
  final int limit;

  const MapPlacesQuery({
    this.categorySlug,
    this.searchAllCategories = false,
    this.query = '',
    this.listingKind,
    this.condition,
    this.featuredOnly = false,
    this.verifiedOnly = false,
    this.minPrice,
    this.maxPrice,
    this.governorateId,
    this.cityId,
    this.centerLat,
    this.centerLng,
    this.radiusKm,
    this.page = 1,
    this.limit = 40,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort': (centerLat != null && centerLng != null) ? 'nearest' : 'newest',
    };
    if (!searchAllCategories &&
        categorySlug != null &&
        categorySlug!.trim().isNotEmpty) {
      params['categorySlug'] = categorySlug!.trim();
    }
    if (query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }
    if (listingKind != null && listingKind!.isNotEmpty) {
      params['listingKind'] = listingKind;
    }
    if (condition != null && condition!.isNotEmpty) {
      params['condition'] = condition;
    }
    if (featuredOnly) {
      params['featured'] = true;
    }
    if (minPrice != null) {
      params['minPrice'] = minPrice;
    }
    if (maxPrice != null) {
      params['maxPrice'] = maxPrice;
    }
    if (governorateId != null) {
      params['governorateId'] = governorateId;
    }
    if (cityId != null) {
      params['cityId'] = cityId;
    }
    if (centerLat != null && centerLng != null) {
      params['lat'] = centerLat;
      params['lng'] = centerLng;
      if (radiusKm != null) {
        params['radiusKm'] = radiusKm!.clamp(1.0, 150.0);
      }
    }
    return params;
  }
}

/// Abstract repository contract for loading real category-scoped map places.
abstract class CategoryMapRepository {
  Future<MapPlacesPage> fetchPlaces({
    required String requestScopeKey,
    required MapPlacesQuery query,
  });

  /// Cancels any in-flight request for [requestScopeKey].
  void cancelInFlight(String requestScopeKey);
}
