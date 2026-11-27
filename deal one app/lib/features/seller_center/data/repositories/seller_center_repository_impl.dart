import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/seller_center/domain/entities/seller_center_entities.dart';
import 'package:market_space/features/seller_center/domain/repositories/seller_center_repository.dart';

class SellerCenterRepositoryImpl implements SellerCenterRepository {
  final ApiClient apiClient;

  const SellerCenterRepositoryImpl({required this.apiClient});

  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map) {
      final inner = raw['data'] is Map ? raw['data'] as Map : raw;
      return Map<String, dynamic>.from(inner);
    }
    return const {};
  }

  @override
  Future<SellerDashboardEntity> getDashboard() async {
    final res = await apiClient.get(ApiEndpoints.sellerCenterDashboard);
    return SellerDashboardEntity.fromJson(_unwrapMap(res.data));
  }

  @override
  Future<({List<SellerListingItemEntity> items, int total, int totalPages})>
      getSellerListings({
    String? status,
    String? availability,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await apiClient.get(
      ApiEndpoints.sellerCenterListings,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty && status != 'all')
          'status': status,
        if (availability != null &&
            availability.isNotEmpty &&
            availability != 'all')
          'availability': availability,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = _unwrapMap(res.data);
    final rawItems = data['items'] is List ? data['items'] as List : const [];
    final items = rawItems
        .whereType<Map>()
        .map((m) =>
            SellerListingItemEntity.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    final meta = data['meta'] is Map
        ? Map<String, dynamic>.from(data['meta'] as Map)
        : const <String, dynamic>{};
    return (
      items: items,
      total: (meta['total'] is num) ? (meta['total'] as num).toInt() : items.length,
      totalPages:
          (meta['totalPages'] is num) ? (meta['totalPages'] as num).toInt() : 1,
    );
  }

  @override
  Future<void> updateListingPublicationStatus(
    String listingId,
    String status,
  ) async {
    await apiClient.patch(
      '${ApiEndpoints.listings}/$listingId/status',
      data: {'status': status},
    );
  }

  @override
  Future<void> updateListingAvailability(
    String listingId,
    String availability,
  ) async {
    await apiClient.patch(
      '${ApiEndpoints.listings}/$listingId/availability',
      data: {'availabilityStatus': availability},
    );
  }

  @override
  Future<void> deleteListing(String listingId) async {
    await apiClient.delete('${ApiEndpoints.listings}/$listingId');
  }

  @override
  Future<SellerInteractionsResultEntity> getInteractions({
    String? listingId,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await apiClient.get(
      ApiEndpoints.sellerCenterInteractions,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (listingId != null && listingId.isNotEmpty) 'listingId': listingId,
        if (type != null && type.isNotEmpty && type != 'all') 'type': type,
      },
    );
    return SellerInteractionsResultEntity.fromJson(_unwrapMap(res.data));
  }

  @override
  Future<List<SellerInboxConversationEntity>> getSellerConversations({
    String? listingId,
    String? search,
    bool unreadOnly = false,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await apiClient.get(
      ApiEndpoints.sellerCenterConversations,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (listingId != null && listingId.isNotEmpty) 'listingId': listingId,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (unreadOnly) 'unreadOnly': 'true',
      },
    );
    final data = _unwrapMap(res.data);
    final rawItems = data['items'] is List ? data['items'] as List : const [];
    return rawItems
        .whereType<Map>()
        .map((m) => SellerInboxConversationEntity.fromJson(
              Map<String, dynamic>.from(m),
            ))
        .toList();
  }

  @override
  Future<List<SellerDealEntity>> getDeals({
    SellerDealStatus? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await apiClient.get(
      ApiEndpoints.sellerCenterDeals,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status.apiValue,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = _unwrapMap(res.data);
    final rawItems = data['items'] is List ? data['items'] as List : const [];
    return rawItems
        .whereType<Map>()
        .map((m) => SellerDealEntity.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  Future<SellerDealEntity> createDeal({
    required String listingId,
    required String customerName,
    String? customerReference,
    double? agreedPrice,
    SellerDealStatus status = SellerDealStatus.newInquiry,
    String? notes,
  }) async {
    final res = await apiClient.post(
      ApiEndpoints.sellerCenterDeals,
      data: {
        'listingId': listingId,
        'customerName': customerName.trim(),
        if (customerReference != null && customerReference.trim().isNotEmpty)
          'customerReference': customerReference.trim(),
        'agreedPrice': ?agreedPrice,
        'status': status.apiValue,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return SellerDealEntity.fromJson(_unwrapMap(res.data));
  }

  @override
  Future<SellerDealEntity> updateDeal(
    String dealId, {
    SellerDealStatus? status,
    double? agreedPrice,
    String? notes,
  }) async {
    final res = await apiClient.patch(
      ApiEndpoints.sellerCenterDealById(dealId),
      data: {
        if (status != null) 'status': status.apiValue,
        'agreedPrice': ?agreedPrice,
        'notes': ?notes,
      },
    );
    return SellerDealEntity.fromJson(_unwrapMap(res.data));
  }

  @override
  Future<void> deleteDeal(String dealId) async {
    await apiClient.delete(ApiEndpoints.sellerCenterDealById(dealId));
  }

  @override
  Future<SellerAnalyticsEntity> getAnalytics({String range = '30d'}) async {
    final res = await apiClient.get(
      ApiEndpoints.sellerCenterAnalytics,
      queryParameters: {'range': range},
    );
    return SellerAnalyticsEntity.fromJson(_unwrapMap(res.data));
  }
}
