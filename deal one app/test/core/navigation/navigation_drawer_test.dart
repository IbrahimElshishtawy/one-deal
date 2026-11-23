import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/navigation/drawer/category_drawer_registry.dart';
import 'package:market_space/core/navigation/drawer/deal_one_navigation_drawer.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/security/session_state.dart';
import 'package:market_space/features/accounts/domain/entities/account_entity.dart';
import 'package:market_space/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';
import 'package:market_space/features/listings/presentation/providers/seller_management_providers.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

class _TestSessionNotifier extends SessionNotifier {
  final SessionState initial;
  _TestSessionNotifier(this.initial);

  @override
  SessionState build() => initial;
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
  group('CategoryDrawerRegistry — Permission & Feature Availability Matrix', () {
    test('Never exposes unsupported backend features in any category for any role', () {
      final superCaps = AccountCapabilities(
        isAuthenticated: true,
        activeAccount: _account(type: 'company', verification: 'approved', role: 'owner'),
      );

      final unsupportedIds = {
        'drawer_re_contact_requests',
        'drawer_re_saved_searches',
        'drawer_re_recently_viewed',
        'drawer_srv_schedule_management',
        'drawer_srv_service_areas',
        'drawer_bm_my_quotations',
        'drawer_app_recently_viewed',
        'drawer_fash_recently_viewed',
      };

      for (final cat in CategoryDrawerRegistry.sixCategories) {
        final resolved = CategoryDrawerRegistry.resolve(cat.slug, superCaps);
        for (final item in resolved.categoryActions) {
          expect(item.featureAvailable, isTrue);
          expect(unsupportedIds.contains(item.id), isFalse);
        }
      }
    });

    test('Buyer / Non-Activated / Responder accounts never see seller or provider tools across all 6 categories',
        () {
      final nonSellerCases = [
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

      for (final caps in nonSellerCases) {
        for (final cat in CategoryDrawerRegistry.sixCategories) {
          final resolved = CategoryDrawerRegistry.resolve(cat.slug, caps);
          expect(
            resolved.categoryActions.any((i) => i.id.contains('create') || i.id.contains('add_product') || i.id.contains('incoming') || i.id.contains('management') || i.id.contains('maintenance_requests')),
            isFalse,
            reason: 'Unauthorized seller item leaked in ${cat.slug}',
          );
        }
      }
    });

    test('Activated Real Estate Office sees Real Estate & Services tools, NOT Building Materials or Fashion tools',
        () {
      final officeCaps = AccountCapabilities(
        isAuthenticated: true,
        activeAccount: _account(type: 'office', verification: 'approved', role: 'owner'),
      );

      final re = CategoryDrawerRegistry.resolve(MapCategoryRegistry.realEstateSlug, officeCaps);
      expect(
        re.categoryActions.map((i) => i.id),
        containsAll(['drawer_re_favorites', 'drawer_re_create_listing', 'drawer_re_listing_management']),
      );
      // Real Estate has Chat in Bottom Nav, so Drawer omits duplicate Conversations link.
      expect(
        re.accountManagementItems.any((i) => i.id == 'drawer_account_conversations'),
        isFalse,
      );

      final srv = CategoryDrawerRegistry.resolve(MapCategoryRegistry.servicesSlug, officeCaps);
      expect(
        srv.categoryActions.map((i) => i.id),
        containsAll(['drawer_srv_create_service', 'drawer_srv_incoming_requests']),
      );

      final bm = CategoryDrawerRegistry.resolve(
        MapCategoryRegistry.buildingMaterialsSlug,
        officeCaps,
      );
      expect(bm.categoryActions.any((i) => i.id == 'drawer_bm_add_product'), isFalse);
      expect(bm.categoryActions.any((i) => i.id == 'drawer_bm_incoming_rfqs'), isFalse);

      final fash = CategoryDrawerRegistry.resolve(MapCategoryRegistry.fashionSlug, officeCaps);
      expect(fash.categoryActions.any((i) => i.id == 'drawer_fash_create_listing'), isFalse);
    });

    test('Multi-Capability Company account resolves category-appropriate tools for all 6 sections', () {
      final companyCaps = AccountCapabilities(
        isAuthenticated: true,
        activeAccount: _account(type: 'company', verification: 'approved', role: 'owner'),
      );

      expect(
        CategoryDrawerRegistry.resolve(MapCategoryRegistry.realEstateSlug, companyCaps)
            .categoryActions
            .map((i) => i.id),
        contains('drawer_re_create_listing'),
      );
      expect(
        CategoryDrawerRegistry.resolve(MapCategoryRegistry.servicesSlug, companyCaps)
            .categoryActions
            .map((i) => i.id),
        contains('drawer_srv_incoming_requests'),
      );
      expect(
        CategoryDrawerRegistry.resolve(MapCategoryRegistry.buildingMaterialsSlug, companyCaps)
            .categoryActions
            .map((i) => i.id),
        containsAll(['drawer_bm_add_product', 'drawer_bm_incoming_rfqs']),
      );
      expect(
        CategoryDrawerRegistry.resolve(MapCategoryRegistry.homeAppliancesSlug, companyCaps)
            .categoryActions
            .map((i) => i.id),
        contains('drawer_app_create_listing'),
      );
      expect(
        CategoryDrawerRegistry.resolve(MapCategoryRegistry.carsSlug, companyCaps)
            .categoryActions
            .map((i) => i.id),
        containsAll([
          'drawer_cars_my_listings',
          'drawer_cars_create_maintenance',
          'drawer_cars_maintenance_requests',
        ]),
      );
      expect(
        CategoryDrawerRegistry.resolve(MapCategoryRegistry.fashionSlug, companyCaps)
            .categoryActions
            .map((i) => i.id),
        contains('drawer_fash_create_listing'),
      );
    });
  });

  group('DealOneNavigationDrawer Widget Tests', () {
    testWidgets('Loading state hides unauthorized seller items and renders loading skeleton',
        (tester) async {
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
            conversationsListProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DealOneNavigationDrawer(
                activeCategorySlug: MapCategoryRegistry.servicesSlug,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('drawer_actions_loading')), findsOneWidget);
      expect(find.byKey(const Key('drawer_item_drawer_srv_create_service')), findsNothing);

      completer.complete([_account(type: 'office', verification: 'approved')]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('drawer_actions_loading')), findsNothing);
      expect(find.byKey(const Key('drawer_item_drawer_srv_create_service')), findsOneWidget);
    });

    testWidgets('Error state displays retry banner when account permissions fail to load',
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
              (ref) => Future<List<UserAccountEntity>>.error(Exception('Network down')),
            ),
            conversationsListProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DealOneNavigationDrawer(
                activeCategorySlug: MapCategoryRegistry.realEstateSlug,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('drawer_accounts_error_banner')), findsOneWidget);
      expect(find.byKey(const Key('drawer_accounts_retry_btn')), findsOneWidget);
      expect(find.byKey(const Key('drawer_item_drawer_re_create_listing')), findsNothing);
    });

    testWidgets('Displays real live badges for incoming service requests and resolves routes',
        (tester) async {
      final selectedRoutes = <String>[];

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
            conversationsListProvider.overrideWith((ref) async => const []),
            providerIncomingBookingsProvider(MapCategoryRegistry.servicesSlug).overrideWith(
              (ref) async => [
                BookingEntity(
                  id: 'b1',
                  title: 'AC Repair',
                  providerName: 'Office',
                  category: BookingCategory.servicesEngineering,
                  type: BookingType.airConditioning,
                  address: 'Cairo',
                  status: BookingStatus.pending,
                  rawStatus: 'PENDING',
                ),
                BookingEntity(
                  id: 'b2',
                  title: 'Plumbing',
                  providerName: 'Office',
                  category: BookingCategory.servicesEngineering,
                  type: BookingType.plumbing,
                  address: 'Giza',
                  status: BookingStatus.pending,
                  rawStatus: 'PENDING',
                ),
              ],
            ),
            supplierOpenRfqsProvider(MapCategoryRegistry.buildingMaterialsSlug).overrideWith(
              (ref) async => const <RfqRequestEntity>[],
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DealOneNavigationDrawer(
                activeCategorySlug: MapCategoryRegistry.servicesSlug,
                onRouteSelected: selectedRoutes.add,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final incomingTile = find.byKey(const Key('drawer_item_drawer_srv_incoming_requests'));
      await tester.ensureVisible(incomingTile);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('drawer_badge_drawer_srv_incoming_requests')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(incomingTile);
      await tester.pumpAndSettle();
      expect(
        selectedRoutes.single,
        '${RouteNames.sellerManagementFor(MapCategoryRegistry.servicesSlug, 'services')}?tab=incoming',
      );
    });

    testWidgets('Renders cleanly in RTL (Arabic) and LTR (English) across phone & tablet widths',
        (tester) async {
      for (final dir in [TextDirection.rtl, TextDirection.ltr]) {
        for (final size in [const Size(320, 640), const Size(768, 1024)]) {
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
                  (ref) async => [
                    _account(id: 'a1', type: 'company', name: 'Deal One Corp'),
                    _account(id: 'a2', type: 'individual', verification: 'pending', name: 'Personal'),
                  ],
                ),
                conversationsListProvider.overrideWith((ref) async => const []),
                supplierOpenRfqsProvider(MapCategoryRegistry.buildingMaterialsSlug).overrideWith(
                  (ref) async => const [],
                ),
              ],
              child: MaterialApp(
                home: Directionality(
                  textDirection: dir,
                  child: const Scaffold(
                    body: DealOneNavigationDrawer(
                      activeCategorySlug: MapCategoryRegistry.buildingMaterialsSlug,
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
}
