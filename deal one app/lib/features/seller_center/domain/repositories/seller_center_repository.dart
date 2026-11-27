import 'package:market_space/features/seller_center/domain/entities/seller_center_entities.dart';

abstract class SellerCenterRepository {
  Future<SellerDashboardEntity> getDashboard();

  Future<({List<SellerListingItemEntity> items, int total, int totalPages})>
      getSellerListings({
    String? status,
    String? availability,
    String? search,
    int page = 1,
    int limit = 20,
  });

  Future<void> updateListingPublicationStatus(String listingId, String status);
  Future<void> updateListingAvailability(String listingId, String availability);
  Future<void> deleteListing(String listingId);

  Future<SellerInteractionsResultEntity> getInteractions({
    String? listingId,
    String? type,
    int page = 1,
    int limit = 20,
  });

  Future<List<SellerInboxConversationEntity>> getSellerConversations({
    String? listingId,
    String? search,
    bool unreadOnly = false,
    int page = 1,
    int limit = 20,
  });

  Future<List<SellerDealEntity>> getDeals({
    SellerDealStatus? status,
    String? search,
    int page = 1,
    int limit = 20,
  });

  Future<SellerDealEntity> createDeal({
    required String listingId,
    required String customerName,
    String? customerReference,
    double? agreedPrice,
    SellerDealStatus status = SellerDealStatus.newInquiry,
    String? notes,
  });

  Future<SellerDealEntity> updateDeal(
    String dealId, {
    SellerDealStatus? status,
    double? agreedPrice,
    String? notes,
  });

  Future<void> deleteDeal(String dealId);

  Future<SellerAnalyticsEntity> getAnalytics({String range = '30d'});
}
