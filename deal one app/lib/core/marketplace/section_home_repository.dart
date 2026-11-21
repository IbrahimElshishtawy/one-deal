import 'package:dio/dio.dart';

import 'package:market_space/features/listings/data/dto/listing_dto.dart';
import 'package:market_space/features/listings/data/mappers/listing_mapper.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/core/cache/hybrid_cache_manager.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/core/marketplace/section_home_models.dart';

/// Server-driven Home & Section Feed repository backed by Hybrid Local Cache
/// (Stale-While-Revalidate + Offline fallback).
class SectionHomeRepository {
  final ApiClient apiClient;
  final HybridCacheManager cache;

  SectionHomeRepository({
    required this.apiClient,
    required this.cache,
  });

  Map<String, dynamic> _unwrapObject(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }
    return const <String, dynamic>{};
  }

  String _mainHubCacheKey({int? governorateId, int? cityId}) =>
      'main_hub:g=${governorateId ?? 0}:c=${cityId ?? 0}';

  String _sectionCacheKey(
    String sectionSlug, {
    int? governorateId,
    int? cityId,
  }) =>
      'section:$sectionSlug:g=${governorateId ?? 0}:c=${cityId ?? 0}';

  Future<MainHubFeed?> readCachedMainHub({
    int? governorateId,
    int? cityId,
  }) async {
    final record = await cache.read(
      _mainHubCacheKey(governorateId: governorateId, cityId: cityId),
    );
    if (record == null) return null;
    return MainHubFeed.fromJson(record.payload, isFromCache: true);
  }

  Future<MainHubFeed> fetchMainHub({
    int? governorateId,
    int? cityId,
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.home,
      queryParameters: {
        'limit': limit,
        'governorateId': ?governorateId,
        'cityId': ?cityId,
      },
      cancelToken: cancelToken,
    );
    final payload = _unwrapObject(response.data);
    await cache.write(
      _mainHubCacheKey(governorateId: governorateId, cityId: cityId),
      payload,
      ttl: CacheTtlPolicy.homeFeed,
    );
    return MainHubFeed.fromJson(payload, isFromCache: false);
  }

  Future<SectionHomeFeed?> readCachedSectionHome(
    String sectionSlug, {
    int? governorateId,
    int? cityId,
  }) async {
    final record = await cache.read(
      _sectionCacheKey(
        sectionSlug,
        governorateId: governorateId,
        cityId: cityId,
      ),
    );
    if (record == null) return null;
    return SectionHomeFeed.fromJson(record.payload, isFromCache: true);
  }

  Future<SectionHomeFeed> fetchSectionHome(
    String sectionSlug, {
    int? governorateId,
    int? cityId,
    int limit = 12,
    CancelToken? cancelToken,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.homeSection(sectionSlug),
      queryParameters: {
        'limit': limit,
        'governorateId': ?governorateId,
        'cityId': ?cityId,
      },
      cancelToken: cancelToken,
    );
    final payload = _unwrapObject(response.data);
    await cache.write(
      _sectionCacheKey(
        sectionSlug,
        governorateId: governorateId,
        cityId: cityId,
      ),
      payload,
      ttl: CacheTtlPolicy.sectionFeed,
    );
    return SectionHomeFeed.fromJson(payload, isFromCache: false);
  }

  /// Fetches server-side filtered & cursor-paginated listings for a section.
  Future<ListingFeed> fetchFilteredSectionListings({
    required String sectionSlug,
    String? subcategorySlug,
    String? query,
    String? sort,
    int? governorateId,
    int? cityId,
    double? minPrice,
    double? maxPrice,
    String? listingKind,
    String? condition,
    Map<String, dynamic> dynamicFilters = const {},
    String? cursor,
    int limit = 12,
    CancelToken? cancelToken,
  }) async {
    final params = <String, dynamic>{
      'categorySlug':
          (subcategorySlug != null && subcategorySlug.isNotEmpty)
              ? subcategorySlug
              : sectionSlug,
      'limit': limit,
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      'governorateId': ?governorateId,
      'cityId': ?cityId,
      'minPrice': ?minPrice,
      'maxPrice': ?maxPrice,
      if (listingKind != null && listingKind.isNotEmpty)
        'listingKind': listingKind,
      if (condition != null && condition.isNotEmpty) 'condition': condition,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };

    // Map known top-level dynamic attributes supported by FilterListingsDto
    final extraAttrs = <String, dynamic>{};
    for (final entry in dynamicFilters.entries) {
      final v = entry.value;
      if (v == null || (v is String && v.trim().isEmpty)) continue;
      switch (entry.key) {
        case 'rooms':
        case 'baths':
        case 'finishing':
        case 'furnished':
        case 'brand':
        case 'model':
        case 'year':
        case 'transmission':
        case 'fuelType':
        case 'size':
        case 'color':
        case 'unitType':
          params[entry.key] = v;
          break;
        default:
          extraAttrs[entry.key] = v;
      }
    }
    if (extraAttrs.isNotEmpty) {
      params['attributes'] = extraAttrs;
    }

    final response = await apiClient.get(
      ApiEndpoints.listings,
      queryParameters: params,
      cancelToken: cancelToken,
    );

    final data = response.data;
    if (data is Map) {
      final dto = ListingFeedResponseDto.fromJson(
        Map<String, dynamic>.from(data),
      );
      return ListingMapper.toFeedEntity(dto);
    }
    return const ListingFeed(items: []);
  }
}
