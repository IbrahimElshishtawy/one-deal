import 'package:market_space/features/listings/data/dto/listing_dto.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';

abstract class ListingsRepository {
  /// Fetches listings feed with filter and cursor pagination
  Future<ListingFeed> getListingsFeed(FilterListingsDto filters);

  /// Fetches featured listings for Home screen
  Future<List<ListingItem>> getFeaturedListings({
    int? governorateId,
    int? cityId,
    String? categorySlug,
    int limit = 10,
  });

  /// Fetches recommended listings for Home screen
  Future<List<ListingItem>> getRecommendedListings({
    int? governorateId,
    int? cityId,
    String? categorySlug,
    int limit = 10,
  });

  /// Fetches promotional hero banners from Home API
  Future<List<HomePromotion>> getHomePromotions();

  /// Fetches single listing details by ID
  Future<ListingItem> getListingDetails(String id);

  /// Reveals contact information (phone & whatsapp) for a listing
  /// Enforces daily Cairo quota (5/day) and IP rate limits on backend
  Future<ContactRevealResult> revealContact(String listingId);

  /// Creates a new listing
  Future<ListingItem> createListing(CreateListingDto dto);

  /// Soft-deletes a listing
  Future<void> deleteListing(String id);
}
