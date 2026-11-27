import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/features/seller_center/application/providers/seller_center_providers.dart';
import 'package:market_space/features/seller_center/domain/entities/seller_center_entities.dart';
import 'package:market_space/features/seller_center/domain/repositories/seller_center_repository.dart';
import 'package:market_space/features/seller_center/presentation/pages/seller_center_page.dart';
import 'package:market_space/features/seller_verification/application/providers/seller_verification_providers.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';

class _FakeSellerCenterRepo implements SellerCenterRepository {
  @override
  Future<SellerDashboardEntity> getDashboard() async =>
      const SellerDashboardEntity(
        summary: SellerDashboardSummaryEntity(
          totalAds: 4,
          activeAds: 3,
          totalViews: 420,
          totalFavorites: 18,
          totalContacts: 9,
          totalConversations: 6,
          unreadConversations: 2,
          pendingInquiries: 3,
          completedDealsCount: 2,
          totalDealsCount: 5,
        ),
        topListings: [],
        recentConversations: [],
        recentActivities: [],
      );

  @override
  Future<({List<SellerListingItemEntity> items, int total, int totalPages})>
      getSellerListings({
    String? status,
    String? availability,
    String? search,
    int page = 1,
    int limit = 20,
  }) async =>
          (items: const <SellerListingItemEntity>[], total: 0, totalPages: 1);

  @override
  Future<void> updateListingPublicationStatus(
    String listingId,
    String status,
  ) async {}

  @override
  Future<void> updateListingAvailability(
    String listingId,
    String availability,
  ) async {}

  @override
  Future<void> deleteListing(String listingId) async {}

  @override
  Future<SellerInteractionsResultEntity> getInteractions({
    String? listingId,
    String? type,
    int page = 1,
    int limit = 20,
  }) async =>
      const SellerInteractionsResultEntity(
        views: 420,
        contactRequests: 9,
        favorites: 18,
        inquiries: 6,
        bookings: 2,
        items: [],
        total: 0,
      );

  @override
  Future<List<SellerInboxConversationEntity>> getSellerConversations({
    String? listingId,
    String? search,
    bool unreadOnly = false,
    int page = 1,
    int limit = 20,
  }) async =>
      const [];

  @override
  Future<List<SellerDealEntity>> getDeals({
    SellerDealStatus? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async =>
      const [];

  @override
  Future<SellerDealEntity> createDeal({
    required String listingId,
    required String customerName,
    String? customerReference,
    double? agreedPrice,
    SellerDealStatus status = SellerDealStatus.newInquiry,
    String? notes,
  }) =>
      throw UnimplementedError();

  @override
  Future<SellerDealEntity> updateDeal(
    String dealId, {
    SellerDealStatus? status,
    double? agreedPrice,
    String? notes,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteDeal(String dealId) async {}

  @override
  Future<SellerAnalyticsEntity> getAnalytics({String range = '30d'}) async =>
      const SellerAnalyticsEntity(
        range: '30d',
        totalAds: 4,
        activeAds: 3,
        totalViews: 420,
        totalFavorites: 18,
        customerInquiries: 17,
        conversationsCount: 6,
        completedSellerReportedDeals: 2,
        responseRatePercent: 83,
        topPerformingAds: [],
        dailySeries: [],
      );
}

VerificationStatusSnapshot _snapshot(
  VerificationStatus status, {
  bool canAccessDashboard = false,
}) {
  return VerificationStatusSnapshot(
    userId: 'user-1',
    sellerStatus: status,
    verificationTier: status == VerificationStatus.approved
        ? VerificationTier.businessVerified
        : VerificationTier.none,
    capabilities: SellerCapabilitiesEntity(
      canCreateListing: canAccessDashboard,
      canAccessSellerDashboard: canAccessDashboard,
      canSubmitSellerApplication: status == VerificationStatus.notSubmitted,
      canUpgradeToBusiness: false,
    ),
  );
}

void main() {
  group('SellerCenterPage Access Control & Tabs', () {
    testWidgets('blocks normal unverified user from Seller Center tools', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sellerVerificationBadgeProvider.overrideWith(
              (ref) async => _snapshot(VerificationStatus.notSubmitted),
            ),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: SellerCenterPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مركز البائع للحسابات الموثقة فقط'), findsOneWidget);
      expect(find.text('لوحة التحكم'), findsNothing);
    });

    testWidgets('blocks pending seller until approved', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sellerVerificationBadgeProvider.overrideWith(
              (ref) async => _snapshot(VerificationStatus.pending),
            ),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: SellerCenterPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('طلب التوثيق قيد المراجعة'), findsOneWidget);
      expect(find.text('سجل المبيعات'), findsNothing);
    });

    testWidgets('blocks suspended seller immediately', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sellerVerificationBadgeProvider.overrideWith(
              (ref) async => _snapshot(VerificationStatus.suspended),
            ),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: SellerCenterPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تم إيقاف صلاحيات البائع'), findsOneWidget);
    });

    testWidgets(
      'grants approved verified seller full 7-tab Seller Center & dashboard KPIs',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sellerVerificationBadgeProvider.overrideWith(
                (ref) async => _snapshot(
                  VerificationStatus.approved,
                  canAccessDashboard: true,
                ),
              ),
              sellerCenterRepositoryProvider.overrideWithValue(
                _FakeSellerCenterRepo(),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: const Directionality(
                textDirection: TextDirection.rtl,
                child: SellerCenterPage(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('لوحة التحكم'), findsOneWidget);
        expect(find.text('إعلاناتي'), findsOneWidget);
        expect(find.text('المنشورات'), findsOneWidget);
        expect(find.text('التفاعلات'), findsOneWidget);
        expect(find.text('المحادثات'), findsOneWidget);
        expect(find.text('سجل المبيعات'), findsAtLeastNWidgets(1));
        expect(find.text('التحليلات'), findsOneWidget);
        expect(find.text('420'), findsOneWidget);
        expect(find.text('3 / 4'), findsOneWidget);
      },
    );
  });
}
