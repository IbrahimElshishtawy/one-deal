import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:market_space/core/home/providers/category_business_overview_provider.dart';
import 'package:market_space/core/home/providers/recently_viewed_provider.dart';
import 'package:market_space/core/home/widgets/role_based_business_section.dart';
import 'package:market_space/core/home/widgets/recently_viewed_section_widget.dart';
import 'package:market_space/core/home/widgets/suppliers_strip_section.dart';
import 'package:market_space/core/marketplace/section_home_models.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/navigation/providers/section_navigation_provider.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/security/session_state.dart';
import 'package:market_space/core/theme/app_theme_data.dart';
import 'package:market_space/features/accounts/domain/entities/account_entity.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/listings/presentation/providers/seller_management_providers.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

class _FixedSessionNotifier extends SessionNotifier {
  final SessionState initial;
  _FixedSessionNotifier(this.initial);

  @override
  SessionState build() => initial;
}

class _StubSellerListingsController extends SellerListingsController {
  _StubSellerListingsController(super.ref, super.slug, SellerListingsState fixed) {
    state = fixed;
  }

  @override
  Future<void> loadInitial() async {}
}

UserAccountEntity _account({
  required String id,
  required String type,
  String verification = 'approved',
  bool isActive = true,
  String role = 'owner',
  String name = 'DealOne Partner',
}) {
  return UserAccountEntity(
    id: id,
    accountType: type,
    displayName: name,
    slug: 'slug-$id',
    verificationStatus: verification,
    isActive: isActive,
    role: role,
  );
}

ListingItem _listing({
  required String id,
  required String slug,
  String moderationStatus = 'approved',
  String publicationStatus = 'published',
  String availabilityStatus = 'available',
  int viewsCount = 0,
}) {
  return ListingItem(
    id: id,
    title: 'Listing $id',
    description: 'Description',
    price: 1500,
    categoryId: 'cat-1',
    categoryNameAr: 'قسم',
    categoryNameEn: 'Category',
    categorySlug: slug,
    areaNameAr: 'طنطا',
    cityNameAr: 'طنطا',
    governorateNameAr: 'الغربية',
    sellerName: 'DealOne Partner',
    moderationStatus: moderationStatus,
    publicationStatus: publicationStatus,
    availabilityStatus: availabilityStatus,
    viewsCount: viewsCount,
  );
}

List<Override> _baseOverrides({
  required AccountCapabilities capabilities,
  required String slug,
  List<ListingItem> listings = const [],
  List<BookingEntity> incomingBookings = const [],
  List<RfqRequestEntity> openRfqs = const [],
}) {
  return [
    sessionProvider.overrideWith(
      () => _FixedSessionNotifier(
        capabilities.isAuthenticated
            ? const SessionState(status: SessionStatus.authenticated, userId: 'u1')
            : const SessionState.unauthenticated(),
      ),
    ),
    accountCapabilitiesProvider.overrideWithValue(capabilities),
    sellerListingsControllerProvider(slug).overrideWith(
      (ref) => _StubSellerListingsController(
        ref,
        slug,
        SellerListingsState(items: listings, isLoading: false),
      ),
    ),
    conversationsListProvider.overrideWith((ref) async => const []),
    providerIncomingBookingsProvider(slug).overrideWith(
      (ref) async => incomingBookings,
    ),
    supplierOpenRfqsProvider(slug).overrideWith((ref) async => openRfqs),
  ];
}

void main() {
  const allSixSlugs = [
    MapCategoryRegistry.realEstateSlug,
    MapCategoryRegistry.servicesSlug,
    MapCategoryRegistry.buildingMaterialsSlug,
    MapCategoryRegistry.homeAppliancesSlug,
    MapCategoryRegistry.carsSlug,
    MapCategoryRegistry.fashionSlug,
  ];

  group('Phase 05 & 11 — Capability Matrix Across All 10 Account Types', () {
    test('1. Buyer/Guest account has zero business overviews in all 6 categories', () {
      for (final slug in allSixSlugs) {
        final container = ProviderContainer(
          overrides: _baseOverrides(
            capabilities: const AccountCapabilities.guest(),
            slug: slug,
          ),
        );
        addTearDown(container.dispose);
        expect(container.read(categoryBusinessOverviewProvider(slug)), isNull);
      }
    });

    test('2. Account without activated capabilities (pending/loading) shows zero flicker & null overview', () {
      final pendingCaps = AccountCapabilities(
        isAuthenticated: true,
        activeAccount: _account(id: 'a1', type: 'company', verification: 'pending'),
      );
      const loadingCaps = AccountCapabilities.loading();

      for (final slug in allSixSlugs) {
        final c1 = ProviderContainer(
          overrides: _baseOverrides(capabilities: pendingCaps, slug: slug),
        );
        final c2 = ProviderContainer(
          overrides: _baseOverrides(capabilities: loadingCaps, slug: slug),
        );
        addTearDown(c1.dispose);
        addTearDown(c2.dispose);
        expect(c1.read(categoryBusinessOverviewProvider(slug)), isNull);
        expect(c2.read(categoryBusinessOverviewProvider(slug)), isNull);
      }
    });

    test('3 & 4. Real Estate Seller & Engineering Service Provider capabilities', () {
      final officeCaps = AccountCapabilities(
        isAuthenticated: true,
        activeAccount: _account(id: 'o1', type: 'office', name: 'Al-Nour Office'),
      );

      final reContainer = ProviderContainer(
        overrides: _baseOverrides(
          capabilities: officeCaps,
          slug: MapCategoryRegistry.realEstateSlug,
          listings: [
            _listing(
              id: 'l1',
              slug: 'real-estate',
              publicationStatus: 'published',
              moderationStatus: 'approved',
              viewsCount: 42,
            ),
            _listing(
              id: 'l2',
              slug: 'real-estate',
              publicationStatus: 'unpublished',
              moderationStatus: 'pending',
              viewsCount: 0,
            ),
          ],
        ),
      );
      addTearDown(reContainer.dispose);

      final reOverview = reContainer.read(
        categoryBusinessOverviewProvider(MapCategoryRegistry.realEstateSlug),
      );
      expect(reOverview, isNotNull);
      expect(reOverview!.totalListings, 2);
      expect(reOverview.publishedListings, 1);
      expect(reOverview.pendingModerationListings, 1);
      expect(reOverview.totalViews, 42);

      // Office cannot act as Building Materials supplier
      final bmContainer = ProviderContainer(
        overrides: _baseOverrides(
          capabilities: officeCaps,
          slug: MapCategoryRegistry.buildingMaterialsSlug,
        ),
      );
      addTearDown(bmContainer.dispose);
      expect(
        bmContainer.read(
          categoryBusinessOverviewProvider(
            MapCategoryRegistry.buildingMaterialsSlug,
          ),
        ),
        isNull,
      );
    });

    test('5. Building Materials Supplier (factory) sees RFQs & Quotations, not Real Estate', () {
      final factoryCaps = AccountCapabilities(
        isAuthenticated: true,
        activeAccount: _account(id: 'f1', type: 'factory', name: 'Delta Steel'),
      );

      final bmContainer = ProviderContainer(
        overrides: _baseOverrides(
          capabilities: factoryCaps,
          slug: MapCategoryRegistry.buildingMaterialsSlug,
          openRfqs: [
            RfqRequestEntity(
              id: 'rfq1',
              title: 'Steel Rebar 10 Tons',
              referenceNumber: 'RFQ-1',
              submittedAt: DateTime(2026, 11, 20),
              requestedItemsCount: 1,
              materialsSummary: 'Steel',
              quantitySummary: '10 Tons',
              deliveryLocation: 'Cairo',
              status: RfqStatus.submitted,
              rawStatus: 'submitted',
              quotations: const [
                RfqQuotationEntity(
                  id: 'q1',
                  rfqId: 'rfq1',
                  supplierName: 'Delta Steel',
                  totalPrice: 400000,
                  rawStatus: 'submitted',
                ),
              ],
            ),
          ],
        ),
      );
      addTearDown(bmContainer.dispose);

      // Prime async provider
      bmContainer.read(
        supplierOpenRfqsProvider(MapCategoryRegistry.buildingMaterialsSlug),
      );

      final overview = bmContainer.read(
        categoryBusinessOverviewProvider(
          MapCategoryRegistry.buildingMaterialsSlug,
        ),
      );
      expect(overview, isNotNull);
      expect(overview!.totalViews, isNull); // Hidden when 0

      // Factory does NOT see Real Estate seller widgets
      final reContainer = ProviderContainer(
        overrides: _baseOverrides(
          capabilities: factoryCaps,
          slug: MapCategoryRegistry.realEstateSlug,
        ),
      );
      addTearDown(reContainer.dispose);
      expect(
        reContainer.read(
          categoryBusinessOverviewProvider(MapCategoryRegistry.realEstateSlug),
        ),
        isNull,
      );
    });

    test('6, 7, 8, 9, 10. Automotive Seller vs Maintenance Provider strict separation + Multi-Capability', () {
      // 7. Automotive Seller ONLY (individual/store)
      final carSellerCaps = AccountCapabilities(
        isAuthenticated: true,
        activeAccount: _account(id: 's1', type: 'store', name: 'Cairo Motors'),
      );
      final sellerContainer = ProviderContainer(
        overrides: _baseOverrides(
          capabilities: carSellerCaps,
          slug: MapCategoryRegistry.carsSlug,
        ),
      );
      addTearDown(sellerContainer.dispose);
      final sellerOverview = sellerContainer.read(
        categoryBusinessOverviewProvider(MapCategoryRegistry.carsSlug),
      );
      expect(sellerOverview, isNotNull);
      expect(sellerOverview!.showAutomotiveSales, isTrue);
      expect(sellerOverview.showAutomotiveMaintenance, isFalse);

      // 8. Automotive Maintenance Provider ONLY (office)
      final maintProviderCaps = AccountCapabilities(
        isAuthenticated: true,
        activeAccount: _account(id: 'm1', type: 'office', name: 'Pro Auto Care'),
      );
      final maintContainer = ProviderContainer(
        overrides: _baseOverrides(
          capabilities: maintProviderCaps,
          slug: MapCategoryRegistry.carsSlug,
        ),
      );
      addTearDown(maintContainer.dispose);
      final maintOverview = maintContainer.read(
        categoryBusinessOverviewProvider(MapCategoryRegistry.carsSlug),
      );
      expect(maintOverview, isNotNull);
      expect(maintOverview!.showAutomotiveSales, isFalse);
      expect(maintOverview.showAutomotiveMaintenance, isTrue);

      // 10. Multi-Capability Account (company) sees BOTH car sales & maintenance
      final multiCaps = AccountCapabilities(
        isAuthenticated: true,
        activeAccount: _account(id: 'c1', type: 'company', name: 'DealOne Auto Group'),
      );
      final multiContainer = ProviderContainer(
        overrides: _baseOverrides(
          capabilities: multiCaps,
          slug: MapCategoryRegistry.carsSlug,
        ),
      );
      addTearDown(multiContainer.dispose);
      final multiOverview = multiContainer.read(
        categoryBusinessOverviewProvider(MapCategoryRegistry.carsSlug),
      );
      expect(multiOverview, isNotNull);
      expect(multiOverview!.showAutomotiveSales, isTrue);
      expect(multiOverview.showAutomotiveMaintenance, isTrue);
    });
  });

  group('Phase 06 & 09 — Widget Visibility, Separation, RTL/LTR, Dark/Light', () {
    testWidgets('Cars Home renders ONLY Automotive Sales card for store seller (no maintenance)', (
      tester,
    ) async {
      final storeCaps = AccountCapabilities(
        isAuthenticated: true,
        activeAccount: _account(id: 's1', type: 'store', name: 'Cairo Motors'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(
            capabilities: storeCaps,
            slug: MapCategoryRegistry.carsSlug,
          ),
          child: MaterialApp(
            theme: AppThemeData.lightTheme,
            darkTheme: AppThemeData.darkTheme,
            themeMode: ThemeMode.dark,
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: RoleBasedBusinessSection(
                    categorySlug: MapCategoryRegistry.carsSlug,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('business_overview_card_cars_sales')), findsOneWidget);
      expect(find.byKey(const Key('business_overview_card_cars_maintenance')), findsNothing);
    });

    testWidgets('Cars Home renders ONLY Maintenance card for office service center (no car sales)', (
      tester,
    ) async {
      final officeCaps = AccountCapabilities(
        isAuthenticated: true,
        activeAccount: _account(id: 'm1', type: 'office', name: 'Pro Auto Care'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(
            capabilities: officeCaps,
            slug: MapCategoryRegistry.carsSlug,
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RoleBasedBusinessSection(
                  categorySlug: MapCategoryRegistry.carsSlug,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('business_overview_card_cars_sales')), findsNothing);
      expect(find.byKey(const Key('business_overview_card_cars_maintenance')), findsOneWidget);
    });

    testWidgets('Buyer sees zero business widgets in RoleBasedBusinessSection', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(
            capabilities: const AccountCapabilities.guest(),
            slug: MapCategoryRegistry.realEstateSlug,
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: RoleBasedBusinessSection(
                categorySlug: MapCategoryRegistry.realEstateSlug,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('role_based_business_section_real-estate')), findsNothing);
    });

    testWidgets('RecentlyViewedSectionWidget hides when empty and renders when items exist', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: RecentlyViewedSectionWidget(categorySlug: 'real-estate'),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('recently_viewed_section_real-estate')), findsNothing);

      await container.read(recentlyViewedProvider.notifier).recordView(
        _listing(id: 're-99', slug: 'real-estate'),
        sectionSlug: 'real-estate',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recently_viewed_section_real-estate')), findsOneWidget);
      expect(find.text('Listing re-99'), findsOneWidget);
    });

    testWidgets('SuppliersStripSection renders verified provider cards cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuppliersStripSection(
              sectionKey: 'test_suppliers',
              title: 'Nearby Suppliers',
              providers: [
                SectionProviderItem(
                  id: 'p1',
                  displayName: 'Al-Ezz Steel Hub',
                  slug: 'al-ezz',
                  accountType: 'factory',
                  isVerified: true,
                  specialtyAr: 'حديد تسليح',
                  specialtyEn: 'Steel Rebar',
                  listingsCount: 14,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('suppliers_strip_test_suppliers')), findsOneWidget);
      expect(find.text('Al-Ezz Steel Hub'), findsOneWidget);
    });
  });
}
