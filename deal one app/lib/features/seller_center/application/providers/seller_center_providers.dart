import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/seller_center/data/repositories/seller_center_repository_impl.dart';
import 'package:market_space/features/seller_center/domain/entities/seller_center_entities.dart';
import 'package:market_space/features/seller_center/domain/repositories/seller_center_repository.dart';
import 'package:market_space/features/seller_verification/application/providers/seller_verification_providers.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';

final sellerCenterRepositoryProvider = Provider<SellerCenterRepository>((ref) {
  return SellerCenterRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});

/// Authoritative backend-derived seller center access flag.
/// Never relies on a local boolean — derives strictly from `GET /seller-applications/me/status`.
final hasSellerCenterAccessProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider);
  if (!session.isAuthenticated) return false;
  final verification = ref.watch(sellerVerificationBadgeProvider).valueOrNull;
  if (verification == null) return false;
  return verification.sellerStatus == VerificationStatus.approved &&
      verification.capabilities.canAccessSellerDashboard;
});

final sellerDashboardProvider =
    FutureProvider.autoDispose<SellerDashboardEntity>((ref) async {
  return ref.watch(sellerCenterRepositoryProvider).getDashboard();
});

final sellerAnalyticsRangeProvider = StateProvider<String>((ref) => '30d');

final sellerAnalyticsProvider =
    FutureProvider.autoDispose<SellerAnalyticsEntity>((ref) async {
  final range = ref.watch(sellerAnalyticsRangeProvider);
  return ref.watch(sellerCenterRepositoryProvider).getAnalytics(range: range);
});

final sellerInteractionsTypeFilterProvider =
    StateProvider<String>((ref) => 'all');

final sellerInteractionsProvider =
    FutureProvider.autoDispose<SellerInteractionsResultEntity>((ref) async {
  final type = ref.watch(sellerInteractionsTypeFilterProvider);
  return ref.watch(sellerCenterRepositoryProvider).getInteractions(type: type);
});

final sellerInboxUnreadOnlyProvider = StateProvider<bool>((ref) => false);
final sellerInboxSearchProvider = StateProvider<String>((ref) => '');

final sellerInboxConversationsProvider =
    FutureProvider.autoDispose<List<SellerInboxConversationEntity>>((ref) async {
  final unreadOnly = ref.watch(sellerInboxUnreadOnlyProvider);
  final search = ref.watch(sellerInboxSearchProvider);
  return ref.watch(sellerCenterRepositoryProvider).getSellerConversations(
        unreadOnly: unreadOnly,
        search: search,
      );
});

final sellerDealsStatusFilterProvider =
    StateProvider<SellerDealStatus?>((ref) => null);

final sellerDealsProvider =
    FutureProvider.autoDispose<List<SellerDealEntity>>((ref) async {
  final status = ref.watch(sellerDealsStatusFilterProvider);
  return ref.watch(sellerCenterRepositoryProvider).getDeals(status: status);
});

final sellerAdsStatusFilterProvider = StateProvider<String>((ref) => 'all');
final sellerAdsSearchProvider = StateProvider<String>((ref) => '');

final sellerCenterListingsProvider = FutureProvider.autoDispose<
    ({List<SellerListingItemEntity> items, int total, int totalPages})>(
  (ref) async {
    final status = ref.watch(sellerAdsStatusFilterProvider);
    final search = ref.watch(sellerAdsSearchProvider);
    return ref.watch(sellerCenterRepositoryProvider).getSellerListings(
          status: status,
          search: search,
        );
  },
);
