import 'package:dio/dio.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/listings/data/dto/listing_dto.dart';
import 'package:market_space/features/maps/data/models/map_place_mapper.dart';
import 'package:market_space/features/maps/domain/entities/map_place_entity.dart';
import 'package:market_space/features/maps/domain/repositories/category_map_repository.dart';

/// Remote data source querying the real Deal One backend `/api/v1/search`
/// endpoint with per-section request cancellation via Dio [CancelToken].
class CategoryMapRemoteDataSource {
  final ApiClient apiClient;
  final Map<String, CancelToken> _activeTokens = {};

  CategoryMapRemoteDataSource({required this.apiClient});

  void cancelInFlight(String requestScopeKey) {
    final existing = _activeTokens.remove(requestScopeKey);
    if (existing != null && !existing.isCancelled) {
      existing.cancel('Superseded by newer map request');
    }
  }

  Future<MapPlacesPage> searchMapPlaces({
    required String requestScopeKey,
    required MapPlacesQuery query,
  }) async {
    cancelInFlight(requestScopeKey);
    final cancelToken = CancelToken();
    _activeTokens[requestScopeKey] = cancelToken;

    try {
      final response = await apiClient.get(
        ApiEndpoints.search,
        queryParameters: query.toQueryParams(),
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final rawList = map['data'] is List
            ? map['data'] as List
            : (map['items'] as List? ?? const []);

        final places = <MapPlaceEntity>[];
        for (final raw in rawList) {
          if (raw is! Map) continue;
          final json = Map<String, dynamic>.from(raw);
          final dto = ListingItemDto.fromJson(json);
          final rawAddr = json['address']?.toString() ?? json['location']?.toString();
          places.add(MapPlaceMapper.fromListingDto(dto, rawAddress: rawAddr));
        }

        final meta = map['meta'] is Map
            ? Map<String, dynamic>.from(map['meta'] as Map)
            : const <String, dynamic>{};
        final total = (meta['total'] as num?)?.toInt() ?? places.length;
        final currentPage = (meta['page'] as num?)?.toInt() ?? query.page;
        final totalPages = (meta['totalPages'] ?? meta['total_pages'] as num?)?.toInt() ?? 1;

        return MapPlacesPage(
          items: places,
          totalCount: total,
          page: currentPage,
          totalPages: totalPages < 1 ? 1 : totalPages,
        );
      }

      return MapPlacesPage(
        items: const [],
        totalCount: 0,
        page: query.page,
        totalPages: 1,
      );
    } finally {
      if (identical(_activeTokens[requestScopeKey], cancelToken)) {
        _activeTokens.remove(requestScopeKey);
      }
    }
  }
}
