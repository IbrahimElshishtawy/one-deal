import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/navigation/drawer/config/categories/appliances_drawer.dart';
import 'package:market_space/core/navigation/drawer/config/categories/automotive_drawer.dart';
import 'package:market_space/core/navigation/drawer/config/categories/building_materials_drawer.dart';
import 'package:market_space/core/navigation/drawer/config/categories/fashion_drawer.dart';
import 'package:market_space/core/navigation/drawer/config/categories/real_estate_drawer.dart';
import 'package:market_space/core/navigation/drawer/config/categories/services_drawer.dart';
import 'package:market_space/core/navigation/drawer/config/category_drawer_registry.dart';
import 'package:market_space/core/navigation/drawer/models/drawer_item_config.dart';
import 'package:market_space/core/navigation/drawer/widgets/category_switcher_widget.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_footer_widget.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_header_widget.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_item_widget.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/security/session_state.dart';
import 'package:market_space/features/accounts/domain/entities/account_entity.dart';
import 'package:market_space/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';
import 'package:market_space/features/listings/presentation/providers/seller_management_providers.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

class _TestSessionNotifier extends SessionNotifier {
  final SessionState initial;
  _TestSessionNotifier(this.initial);

  @override
  SessionState build() => initial;
}

UserAccountEntity _acc({
  required String id,
  required String type,
  String verification = 'approved',
  String role = 'owner',
  String name = 'Partner',
}) {
  return UserAccountEntity(
    id: id,
    accountType: type,
    displayName: name,
    slug: 'slug-$id',
    verificationStatus: verification,
    isActive: true,
    role: role,
  );
}

void main() {
  group('Modular Drawer Widgets — Standalone Unit/Widget Verification', () {
    testWidgets('DrawerHeaderWidget composes Avatar, Info, Verification, and Account Switcher',
        (tester) async {
      UserAccountEntity? switchedTo;
      final accounts = [
        _acc(id: 'a1', type: 'office', name: 'Al-Nour Real Estate'),
        _acc(id: 'a2', type: 'factory', name: 'Delta Steel'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawerHeaderWidget(
              isArabic: false,
              userName: 'Ibrahim',
              capabilities: AccountCapabilities(
                isAuthenticated: true,
                activeAccount: accounts.first,
                accounts: accounts,
              ),
              accountsError: null,
              onRetryAccounts: () {},
              onSwitchAccount: (acc) => switchedTo = acc,
              onSignInTap: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('drawer_account_avatar')), findsOneWidget);
      expect(find.byKey(const Key('drawer_account_info')), findsOneWidget);
      expect(find.byKey(const Key('drawer_account_verification_badge')), findsOneWidget);
      expect(find.text('Al-Nour Real Estate'), findsWidgets);

      await tester.tap(find.byKey(const Key('drawer_switch_account_a2')));
      await tester.pump();
      expect(switchedTo?.id, 'a2');
    });

    testWidgets('CategorySwitcherWidget highlights active category and fires callbacks',
        (tester) async {
      DrawerCategoryEntry? tappedCategory;
      bool mainHubTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategorySwitcherWidget(
                activeCategorySlug: MapCategoryRegistry.carsSlug,
                categories: CategoryDrawerRegistry.sixCategories,
                isArabic: false,
                onCategorySelected: (c) => tappedCategory = c,
                onMainHubSelected: () => mainHubTapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('drawer_category_real-estate')));
      await tester.pump();
      expect(tappedCategory?.routeName, RouteNames.realEstateName);

      await tester.tap(find.byKey(const Key('drawer_switch_main_hub')));
      await tester.pump();
      expect(mainHubTapped, isTrue);
    });

    testWidgets('DrawerItemWidget renders isolated DrawerBadgeWidget from badgeProvider',
        (tester) async {
      final liveCountProvider = StateProvider<int>((ref) => 4);
      bool tapped = false;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: DrawerItemWidget(
                item: DrawerItemConfig(
                  id: 'test_badge_item',
                  labelAr: 'طلبات واردة',
                  labelEn: 'Incoming',
                  icon: Icons.inbox_outlined,
                  routeName: RouteNames.sellerManagementName,
                  badgeProvider: liveCountProvider,
                ),
                isArabic: false,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('drawer_badge_test_badge_item')), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      // Update badge count dynamically.
      container.read(liveCountProvider.notifier).state = 9;
      await tester.pump();
      expect(find.text('9'), findsOneWidget);

      await tester.tap(find.byKey(const Key('drawer_item_test_badge_item')));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('DrawerFooterWidget renders logout only when authenticated', (tester) async {
      bool loggedOut = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawerFooterWidget(
              isAuthenticated: false,
              isArabic: false,
              onLogout: () => loggedOut = true,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('drawer_account_logout')), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawerFooterWidget(
              isAuthenticated: true,
              isArabic: false,
              onLogout: () => loggedOut = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('drawer_account_logout')));
      await tester.pump();
      expect(loggedOut, isTrue);
    });
  });

  group('All 6 Category-Specific Drawer Widgets & Live Permission Changes', () {
    testWidgets('Each of the 6 dedicated category drawer widgets renders with its exact slug key',
        (tester) async {
      final widgets = <(Widget, String)>[
        (const RealEstateDrawer(), MapCategoryRegistry.realEstateSlug),
        (const ServicesDrawer(), MapCategoryRegistry.servicesSlug),
        (const BuildingMaterialsDrawer(), MapCategoryRegistry.buildingMaterialsSlug),
        (const AppliancesDrawer(), MapCategoryRegistry.homeAppliancesSlug),
        (const AutomotiveDrawer(), MapCategoryRegistry.carsSlug),
        (const FashionDrawer(), MapCategoryRegistry.fashionSlug),
      ];

      for (final (drawerWidget, slug) in widgets) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionProvider.overrideWith(
                () => _TestSessionNotifier(
                  const SessionState(status: SessionStatus.authenticated, userId: 'u1'),
                ),
              ),
              myAccountsProvider.overrideWith(
                (ref) async => [_acc(id: 'c1', type: 'company')],
              ),
              conversationsListProvider.overrideWith((ref) async => const []),
              providerIncomingBookingsProvider(MapCategoryRegistry.servicesSlug)
                  .overrideWith((ref) async => const []),
              providerIncomingBookingsProvider(MapCategoryRegistry.carsSlug)
                  .overrideWith((ref) async => const []),
              supplierOpenRfqsProvider(MapCategoryRegistry.buildingMaterialsSlug)
                  .overrideWith((ref) async => const []),
            ],
            child: MaterialApp(home: Scaffold(body: drawerWidget)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(Key('deal_one_navigation_drawer_$slug')), findsOneWidget);
        expect(find.byKey(const Key('drawer_account_header')), findsOneWidget);
        expect(find.byKey(const Key('drawer_category_switcher_section')), findsOneWidget);
        expect(find.byKey(const Key('drawer_account_management_section')), findsOneWidget);
        expect(find.byKey(const Key('drawer_support_legal_section')), findsOneWidget);
        expect(find.byKey(const Key('drawer_footer_widget')), findsOneWidget);
      }
    });

    testWidgets('Live permission change during session updates Drawer tools without logout',
        (tester) async {
      final pendingBuyer = _acc(id: 'b1', type: 'individual', verification: 'pending', name: 'Buyer');
      final verifiedOffice = _acc(id: 'o1', type: 'office', verification: 'approved', name: 'Office');

      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(
            () => _TestSessionNotifier(
              const SessionState(status: SessionStatus.authenticated, userId: 'u1'),
            ),
          ),
          myAccountsProvider.overrideWith((ref) async => [pendingBuyer, verifiedOffice]),
          activeAccountProvider.overrideWith((ref) => pendingBuyer),
          conversationsListProvider.overrideWith((ref) async => const []),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: RealEstateDrawer()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pending buyer: no seller tools.
      expect(find.byKey(const Key('drawer_item_drawer_re_create_listing')), findsNothing);

      // Switch to verified office during active session.
      container.read(activeAccountProvider.notifier).state = verifiedOffice;
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('drawer_item_drawer_re_create_listing')), findsOneWidget);
      expect(find.byKey(const Key('drawer_item_drawer_re_listing_management')), findsOneWidget);
    });
  });
}
