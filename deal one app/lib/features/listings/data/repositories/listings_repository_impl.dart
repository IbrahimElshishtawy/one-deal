import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/listings/data/dto/listing_dto.dart';
import 'package:market_space/features/listings/data/mappers/listing_mapper.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/listings/domain/repositories/listings_repository.dart';

class ListingsRepositoryImpl implements ListingsRepository {
  final ApiClient apiClient;

  ListingsRepositoryImpl({required this.apiClient});

  @override
  Future<ListingFeed> getListingsFeed(FilterListingsDto filters) async {
    final response = await apiClient.get(
      ApiEndpoints.listings,
      queryParameters: filters.toQueryParams(),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final feedDto = ListingFeedResponseDto.fromJson(data);
      return ListingMapper.toFeedEntity(feedDto);
    } else if (data is List) {
      final feedDto = ListingFeedResponseDto.fromJson({'items': data});
      return ListingMapper.toFeedEntity(feedDto);
    }

    return const ListingFeed(items: []);
  }

  @override
  Future<ListingItem> getListingDetails(String id) async {
    final response = await apiClient.get(ApiEndpoints.listingDetails(id));
    final data = response.data;
    final itemDto = ListingItemDto.fromJson(Map<String, dynamic>.from(data as Map));
    return ListingMapper.toItemEntity(itemDto);
  }

  @override
  Future<ContactRevealResult> revealContact(String listingId) async {
    final response = await apiClient.post(ApiEndpoints.revealContact(listingId));
    final data = response.data;
    final revealDto = ContactRevealDto.fromJson(Map<String, dynamic>.from(data as Map));
    return ListingMapper.toContactRevealResult(revealDto);
  }

  @override
  Future<ListingItem> createListing(CreateListingDto dto) async {
    final response = await apiClient.post(
      ApiEndpoints.listings,
      data: dto.toJson(),
    );
    final data = response.data;
    final itemDto = ListingItemDto.fromJson(Map<String, dynamic>.from(data as Map));
    return ListingMapper.toItemEntity(itemDto);
  }

  @override
  Future<void> deleteListing(String id) async {
    await apiClient.delete(ApiEndpoints.listingDetails(id));
  }
}
