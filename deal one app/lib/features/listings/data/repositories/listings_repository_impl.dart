import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/listings/data/dto/listing_dto.dart';
import 'package:market_space/features/listings/data/mappers/listing_mapper.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/listings/domain/repositories/listings_repository.dart';

class ListingsRepositoryImpl implements ListingsRepository {
  final ApiClient apiClient;

  ListingsRepositoryImpl({required this.apiClient});

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

  List<dynamic> _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      if (raw['data'] is List) return raw['data'] as List;
      if (raw['items'] is List) return raw['items'] as List;
    }
    return const [];
  }

  @override
  Future<ListingFeed> getListingsFeed(FilterListingsDto filters) async {
    final response = await apiClient.get(
      ApiEndpoints.listings,
      queryParameters: filters.toQueryParams(),
    );

    final data = response.data;
    if (data is Map) {
      final feedDto = ListingFeedResponseDto.fromJson(
        Map<String, dynamic>.from(data),
      );
      return ListingMapper.toFeedEntity(feedDto);
    } else if (data is List) {
      final feedDto = ListingFeedResponseDto.fromJson({'items': data});
      return ListingMapper.toFeedEntity(feedDto);
    }

    return const ListingFeed(items: []);
  }

  @override
  Future<List<ListingItem>> getFeaturedListings({
    int? governorateId,
    int? cityId,
    String? categorySlug,
    int limit = 10,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.homeFeatured,
      queryParameters: {
        'limit': limit,
        'governorateId': ?governorateId,
        'cityId': ?cityId,
        if (categorySlug != null && categorySlug.isNotEmpty)
          'categorySlug': categorySlug,
      },
    );
    return _unwrapList(response.data)
        .map(
          (e) => ListingMapper.toItemEntity(
            ListingItemDto.fromJson(Map<String, dynamic>.from(e as Map)),
          ),
        )
        .toList();
  }

  @override
  Future<List<ListingItem>> getRecommendedListings({
    int? governorateId,
    int? cityId,
    String? categorySlug,
    int limit = 10,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.homeRecommended,
      queryParameters: {
        'limit': limit,
        'governorateId': ?governorateId,
        'cityId': ?cityId,
        if (categorySlug != null && categorySlug.isNotEmpty)
          'categorySlug': categorySlug,
      },
    );
    return _unwrapList(response.data)
        .map(
          (e) => ListingMapper.toItemEntity(
            ListingItemDto.fromJson(Map<String, dynamic>.from(e as Map)),
          ),
        )
        .toList();
  }

  @override
  Future<List<HomePromotion>> getHomePromotions() async {
    final response = await apiClient.get(
      ApiEndpoints.home,
      queryParameters: const {'limit': 1},
    );
    final payload = _unwrapObject(response.data);
    final rawPromos = payload['promotions'] as List? ?? const [];
    return rawPromos.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return HomePromotion(
        id: m['id']?.toString() ?? '',
        badgeAr: m['badgeAr']?.toString() ?? '',
        badgeEn: m['badgeEn']?.toString() ?? '',
        titleAr: m['titleAr']?.toString() ?? '',
        titleEn: m['titleEn']?.toString() ?? '',
        subtitleAr: m['subtitleAr']?.toString() ?? '',
        subtitleEn: m['subtitleEn']?.toString() ?? '',
        ctaAr: m['ctaAr']?.toString() ?? '',
        ctaEn: m['ctaEn']?.toString() ?? '',
        categorySlug: m['categorySlug']?.toString() ?? '',
        imageUrl: m['imageUrl']?.toString() ?? '',
      );
    }).toList();
  }

  @override
  Future<ListingItem> getListingDetails(String id) async {
    final response = await apiClient.get(ApiEndpoints.listingDetails(id));
    final unwrapped = _unwrapObject(response.data);
    final itemDto = ListingItemDto.fromJson(unwrapped);
    return ListingMapper.toItemEntity(itemDto);
  }

  @override
  Future<ContactRevealResult> revealContact(String listingId) async {
    final response = await apiClient.post(ApiEndpoints.revealContact(listingId));
    final unwrapped = _unwrapObject(response.data);
    final revealDto = ContactRevealDto.fromJson(unwrapped);
    return ListingMapper.toContactRevealResult(revealDto);
  }

  @override
  Future<ListingItem> createListing(CreateListingDto dto) async {
    final response = await apiClient.post(
      ApiEndpoints.listings,
      data: dto.toJson(),
    );
    final unwrapped = _unwrapObject(response.data);
    final itemDto = ListingItemDto.fromJson(unwrapped);
    return ListingMapper.toItemEntity(itemDto);
  }

  @override
  Future<void> updateListingPublicationStatus(String id, String status) async {
    await apiClient.patch(
      ApiEndpoints.listingStatus(id),
      data: {'status': status},
    );
  }

  @override
  Future<void> updateListingAvailability(
    String id,
    String availabilityStatus,
  ) async {
    await apiClient.patch(
      ApiEndpoints.listingAvailability(id),
      data: {'availabilityStatus': availabilityStatus},
    );
  }

  @override
  Future<void> submitListingForModeration(String id) async {
    await apiClient.post(
      ApiEndpoints.submitForModeration(id),
      data: const <String, dynamic>{},
    );
  }

  @override
  Future<void> deleteListing(String id) async {
    await apiClient.delete(ApiEndpoints.listingDetails(id));
  }
}
