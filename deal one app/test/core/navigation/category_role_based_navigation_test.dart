import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/navigation/config/section_navigation_registry.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/navigation/presentation/widgets/deal_one_section_bottom_nav.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/security/session_state.dart';
import 'package:market_space/features/accounts/domain/entities/account_entity.dart';
import 'package:market_space/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:market_space/features/activity_hub/application/providers/cart_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/cart_item_entity.dart';
import 'package:market_space/features/activity_hub/domain/repositories/cart_repository.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';
import 'package:market_space/features/listings/data/dto/listing_dto.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/listings/domain/repositories/listings_repository.dart';
import 'package:market_space/features/listings/presentation/providers/listings_providers.dart';
import 'package:market_space/features/listings/presentation/screens/seller_management_page.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

class _TestSessionNotifier extends SessionNotifier {
  final SessionState initial;
  _TestSessionNotifier(this.initial);

  @override
  SessionState build() => initial;
}

class _EmptyCartRepo implements CartRepository {
  @override
  Future<List<CartItemEntity>> addItem(CartItemEntity item) async => const [];

  @override
  Future<void> clearCart() async {}

  @override
  Future<List<CartItemEntity>> getCartItems() async => const [];

  @override
  Future<List<CartItemEntity>> removeItem(String itemId) async => const [];

  @override
  Future<List<CartItemEntity>> updateQuantity(String itemId, int quantity) async =>
      const [];
}

class _FakeListingsRepo implements ListingsRepository {
  final List<ListingItem> items;
  _FakeListingsRepo(this.items);

  @override
  Future<ListingItem> createListing(CreateListingDto dto) =>
      throw UnimplementedError();

  @override
  Future<void> deleteListing(String id) async {}

  @override
  Future<List<ListingItem>> getFeaturedListings({
    int? governorateId,
    int? cityId,
    String? categorySlug,
    int limit = 10,
  }) async =>
      items;

  @override
  Future<List<HomePromotion>> getHomePromotions() async => const [];

  @override
  Future<ListingItem> getListingDetails(String id) async => items.first;

  @override
  Future<ListingFeed> getListingsFeed(FilterListingsDto filters) async =>
      ListingFeed(items: items, hasMore: false);

  @override
  Future<List<ListingItem>> getRecommendedListings({
    int? governorateId,
    int? cityId,
    String? categorySlug,
    int limit = 10,
  }) async =>
      items;

  @override
  Future<ContactRevealResult> revealContact(String listingId) =>
      throw UnimplementedError();

  @override
  Future<void> submitListingForModeration(String id) async {}

  @override
  Future<void> updateListingAvailability(
    String id,
    String availabilityStatus,
  ) async {}

  @override
  Future<void> updateListingPublicationStatus(String id, String status) async {}
}

UserAccountEntity _account({
  String id = 'acc-1',
  required String type,
  String verification = 'approved',
  bool isActive = true,
  String role = 'owner',
  String name = 'Deal One Partner',
}) {
  return UserAccountEntity(
    id: id,
    accountType: type,
    displayName: name,
    slug: 'partner-$id',
    verificationStatus: verification,
    isActive: isActive,
    role: role,
  );
}

void main() {
  group('AccountCapabilities & SectionNavigationRegistry (6 Categories)', () {
    test('Buyer / unverified / pending / rejected / responder accounts always see Favorites', () {
      final nonActivatedCases = <AccountCapabilities>[
        const AccountCapabilities.guest(),
        AccountCapabilities(
          isAuthenticated: true,
          activeAccount: _account(type: 'individual', verification: 'pending'),
        ),
        AccountCapabilities(
          isAuthenticated: true,
          activeAccount: _account(type: 'company', verification: 'rejected'),
        ),
        AccountCapabilities(
          isAuthenticated: true,
          activeAccount: _account(type: 'company', verification: 'approved', isActive: false),
        ),
        AccountCapabilities(
          isAuthenticated: true,
          activeAccount: _account(type: 'company', verification: 'approved', role: 'responder'),
        ),
      ];

      final expectedBuyerTabs = <String, List<String>>{
        MapCategoryRegistry.realEstateSlug: ['home', 'explore', 'map', 'chat', 'favorites'],
        MapCategoryRegistry.servicesSlug: ['home', 'explore', 'map', 'my_bookings', 'favorites'],
        MapCategoryRegistry.buildingMaterialsSlug: [
          'home',
          'categories',
          'map',
          'price_requests',
          'favorites',
        ],
        MapCategoryRegistry.homeAppliancesSlug: ['home', 'categories', 'map', 'cart', 'favorites'],
        MapCategoryRegistry.carsSlug: ['home', 'explore', 'map', 'maintenance', 'favorites'],
        MapCategoryRegistry.fashionSlug: ['home', 'categories', 'map', 'cart', 'favorites'],
      };

      for (final caps in nonActivatedCases) {
        for (final entry in expectedBuyerTabs.entries) {
          final cfg = SectionNavigationRegistry.resolveConfig(entry.key, caps);
          expect(
            cfg.items.map((e) => e.id).toList(),
            entry.value,
            reason: 'Failed buyer nav for ${entry.key}',
          );
          // Reels must never appear in Real Estate bottom navigation.
          expect(cfg.items.any((e) => e.id == 'reels'), isFalse);
          expect(cfg.floatingAction, isNull);
        }
      }
    });

    test('Activated Company seller receives exact category-specific seller actions across all 6 categories', () {
      final companyCaps = AccountCapabilities(
        isAuthenticated: true,
        activeAccount: _account(type: 'company', verification: 'approved', role: 'owner'),
      );

      expect(
        SectionNavigationRegistry.resolveConfig(MapCategoryRegistry.realEstateSlug, companyCaps)
            .items
            .map((e) => e.id)
            .toList(),
        ['home', 'explore', 'map', 'chat', 'my_listings'],
      );
      expect(
        SectionNavigationRegistry.resolveConfig(MapCategoryRegistry.servicesSlug, companyCaps)
            .items
            .map((e) => e.id)
            .toList(),
        ['home', 'explore', 'map', 'my_bookings', 'my_services'],
      );
      expect(
        SectionNavigationRegistry.resolveConfig(
          MapCategoryRegistry.buildingMaterialsSlug,
          companyCaps,
        ).items.map((e) => e.id).toList(),
        ['home', 'categories', 'map', 'price_requests', 'my_products'],
      );
      expect(
        SectionNavigationRegistry.resolveConfig(MapCategoryRegistry.homeAppliancesSlug, companyCaps)
            .items
            .map((e) => e.id)
            .toList(),
        ['home', 'categories', 'map', 'cart', 'my_listings'],
      );
      expect(
        SectionNavigationRegistry.resolveConfig(MapCategoryRegistry.carsSlug, companyCaps)
            .items
            .map((e) => e.id)
            .toList(),
        ['home', 'explore', 'map', 'maintenance', 'my_services'],
      );
      expect(
        SectionNavigationRegistry.resolveConfig(MapCategoryRegistry.fashionSlug, companyCaps)
            .items
            .map((e) => e.id)
            .toList(),
        ['home', 'categories', 'map', 'cart', 'my_listings'],
      );
    });

    test('Cross-category isolation: Factory & Office accounts only see seller actions in permitted sectors', () {
      final factoryCaps = AccountCapabilities(
        isAuthenticated: true,
        activeAccount: _account(type: 'factory', verification: 'approved', role: 'owner'),
      );
      expect(factoryCaps.canManageBuildingMaterialsProducts, isTrue);
      expect(factoryCaps.canManageAppliancesListings, isTrue);
      expect(factoryCaps.canManageFashionListings, isTrue);
      expect(factoryCaps.canManageRealEstateListings, isFalse);
      expect(factoryCaps.canManageEngineeringServices, isFalse);
      expect(factoryCaps.canManageAutomotiveMaintenanceServices, isFalse);

      // Real Estate must keep Favorites for a factory account.
      expect(
        SectionNavigationRegistry.resolveConfig(MapCategoryRegistry.realEstateSlug, factoryCaps)
            .items
            .last
            .id,
        'favorites',
      );

      final officeCaps = AccountCapabilities(
        isAuthenticated: true,
        activeAccount: _account(type: 'office', verification: 'approved', role: 'manager'),
      );
      expect(officeCaps.canManageRealEstateListings, isTrue);
      expect(officeCaps.canManageEngineeringServices, isTrue);
      expect(officeCaps.canManageAutomotiveMaintenanceServices, isTrue);
      expect(officeCaps.canManageBuildingMaterialsProducts, isFalse);
      expect(officeCaps.canManageFashionListings, isFalse);

      // Building Materials must keep Favorites for an office account.
      expect(
        SectionNavigationRegistry.resolveConfig(
          MapCategoryRegistry.buildingMaterialsSlug,
          officeCaps,
        ).items.last.id,
        'favorites',
      );
    });

    test('Fashion hides Cart tab when backend cart support is disabled', () {
      final noCartCaps = AccountCapabilities(
        isAuthenticated: true,
        activeAccount: _account(type: 'store', verification: 'approved'),
        isCartSupported: false,
      );
      final cfg = SectionNavigationRegistry.resolveConfig(
        MapCategoryRegistry.fashionSlug,
        noCartCaps,
      );
      expect(cfg.items.map((e) => e.id).toList(), [
        'home',
        'categories',
        'map',
        'my_listings',
      ]);
    });
  });

  group('DealOneSectionBottomNav Widget Behavior', () {
    testWidgets('Prevents Favorites flicker while account capabilities are loading', (tester) async {
      final completer = Completer<List<UserAccountEntity>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith(
              () => _TestSessionNotifier(
                const SessionState(status: SessionStatus.authenticated, userId: 'u1'),
              ),
            ),
            myAccountsProvider.overrideWith((ref) => completer.future),
            cartRepositoryProvider.overrideWithValue(_EmptyCartRepo()),
            conversationsListProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                bottomNavigationBar: DealOneSectionBottomNav(
                  sectionId: MapCategoryRegistry.realEstateSlug,
                  activeTabId: 'home',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // While loading: loading slot shown, NEITHER Favorites NOR My Listings flashes!
      expect(find.byKey(const Key('section_nav_role_slot_loading')), findsOneWidget);
      expect(find.byKey(const Key('section_nav_tab_favorites')), findsNothing);
      expect(find.byKey(const Key('section_nav_tab_my_listings')), findsNothing);

      // Complete backend fetch with verified Real Estate office account.
      completer.complete([_account(type: 'office', verification: 'approved')]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('section_nav_role_slot_loading')), findsNothing);
      expect(find.byKey(const Key('section_nav_tab_my_listings')), findsOneWidget);
      expect(find.byKey(const Key('section_nav_tab_chat')), findsOneWidget);
      expect(find.byKey(const Key('section_nav_tab_favorites')), findsNothing);
    });

    testWidgets('Real Estate Chat tab shows unread message badge and updates live on account switch',
        (tester) async {
      final pendingBuyer = _account(
        id: 'acc-buyer',
        type: 'individual',
        verification: 'pending',
      );
      final verifiedOffice = _account(
        id: 'acc-office',
        type: 'office',
        verification: 'approved',
      );

      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(
            () => _TestSessionNotifier(
              const SessionState(status: SessionStatus.authenticated, userId: 'u1'),
            ),
          ),
          myAccountsProvider.overrideWith((ref) async => [pendingBuyer, verifiedOffice]),
          activeAccountProvider.overrideWith((ref) => pendingBuyer),
          cartRepositoryProvider.overrideWithValue(_EmptyCartRepo()),
          conversationsListProvider.overrideWith(
            (ref) async => [
              ConversationEntity(
                id: 'c1',
                listingId: 'l1',
                buyerUserId: 'u1',
                sellerAccountId: 'acc-office',
                counterpartName: 'Ahmed',
                unreadCount: 3,
                lastMessageAt: DateTime(2026, 11, 20),
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                bottomNavigationBar: DealOneSectionBottomNav(
                  sectionId: MapCategoryRegistry.realEstateSlug,
                  activeTabId: 'home',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starts as non-activated buyer -> Favorites visible + unread badge "3" on Chat.
      expect(find.byKey(const Key('section_nav_tab_favorites')), findsOneWidget);
      expect(find.byKey(const Key('section_nav_tab_chat')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Activate/switch to verified office account WITHOUT logging out!
      container.read(activeAccountProvider.notifier).state = verifiedOffice;
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('section_nav_tab_my_listings')), findsOneWidget);
      expect(find.byKey(const Key('section_nav_tab_favorites')), findsNothing);

      // Deactivate/switch back to pending account -> Seller action hidden immediately.
      container.read(activeAccountProvider.notifier).state = pendingBuyer;
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('section_nav_tab_favorites')), findsOneWidget);
      expect(find.byKey(const Key('section_nav_tab_my_listings')), findsNothing);
    });

    testWidgets('Zero overflow across RTL/LTR and 320px/393px/768px with 2.0x text scale',
        (tester) async {
      final sizes = [const Size(320, 568), const Size(393, 873), const Size(768, 1024)];
      final directions = [TextDirection.rtl, TextDirection.ltr];

      for (final size in sizes) {
        for (final dir in directions) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sessionProvider.overrideWith(
                  () => _TestSessionNotifier(
                    const SessionState(status: SessionStatus.authenticated, userId: 'u1'),
                  ),
                ),
                myAccountsProvider.overrideWith(
                  (ref) async => [_account(type: 'company', verification: 'approved')],
                ),
                cartRepositoryProvider.overrideWithValue(_EmptyCartRepo()),
                conversationsListProvider.overrideWith((ref) async => const []),
              ],
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: const TextScaler.linear(2.0),
                  ),
                  child: Directionality(
                    textDirection: dir,
                    child: const Scaffold(
                      bottomNavigationBar: DealOneSectionBottomNav(
                        sectionId: MapCategoryRegistry.buildingMaterialsSlug,
                        activeTabId: 'home',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });

  group('SellerManagementPage Authorization & Mode Separation', () {
    testWidgets('Blocks non-activated user and hides Create button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith(
              () => _TestSessionNotifier(
                const SessionState(status: SessionStatus.authenticated, userId: 'u1'),
              ),
            ),
            myAccountsProvider.overrideWith(
              (ref) async => [_account(type: 'individual', verification: 'pending')],
            ),
            cartRepositoryProvider.overrideWithValue(_EmptyCartRepo()),
            conversationsListProvider.overrideWith((ref) async => const []),
            listingsRepositoryProvider.overrideWithValue(_FakeListingsRepo(const [])),
          ],
          child: const MaterialApp(
            home: SellerManagementPage(
              categorySlug: MapCategoryRegistry.realEstateSlug,
              mode: 'listings',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('seller_create_btn_listings')), findsNothing);
      expect(find.text('Activated Seller Account Required'), findsOneWidget);
    });

    testWidgets('Activated provider in Services sees separated My Services & Incoming Requests tabs',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith(
              () => _TestSessionNotifier(
                const SessionState(status: SessionStatus.authenticated, userId: 'u1'),
              ),
            ),
            myAccountsProvider.overrideWith(
              (ref) async => [_account(type: 'office', verification: 'approved')],
            ),
            cartRepositoryProvider.overrideWithValue(_EmptyCartRepo()),
            conversationsListProvider.overrideWith((ref) async => const []),
            listingsRepositoryProvider.overrideWithValue(_FakeListingsRepo(const [])),
          ],
          child: const MaterialApp(
            home: SellerManagementPage(
              categorySlug: MapCategoryRegistry.servicesSlug,
              mode: 'services',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('seller_create_btn_services')), findsOneWidget);
      expect(find.text('Incoming Requests'), findsOneWidget);
      expect(find.byKey(const Key('seller_owner_endpoint_gap_banner')), findsOneWidget);
    });
  });
}
