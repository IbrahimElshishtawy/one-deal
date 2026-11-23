import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/app/app_router.dart';
import 'package:market_space/core/cache/hybrid_cache_manager.dart';
import 'package:market_space/core/navigation/config/deal_one_navigation_routes.dart';
import 'package:market_space/core/navigation/models/navigation_item.dart';
import 'package:market_space/core/navigation/presentation/widgets/deal_one_bottom_navigation.dart';
import 'package:market_space/core/navigation/presentation/widgets/deal_one_navigation_shell.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/network_info.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/security/session_state.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/features/accounts/domain/entities/account_entity.dart';
import 'package:market_space/features/accounts/domain/entities/user_profile_entity.dart';
import 'package:market_space/features/accounts/domain/repositories/user_profile_repository.dart';
import 'package:market_space/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:market_space/features/accounts/presentation/providers/user_profile_providers.dart';
import 'package:market_space/features/activity_hub/application/providers/activity_hub_provider.dart';
import 'package:market_space/features/activity_hub/application/providers/bookings_provider.dart';
import 'package:market_space/features/activity_hub/application/providers/rfq_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';
import 'package:market_space/features/activity_hub/domain/repositories/bookings_repository.dart';
import 'package:market_space/features/activity_hub/domain/repositories/rfq_repository.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';
import 'package:market_space/features/favorites/domain/entities/favorite_entity.dart';
import 'package:market_space/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/features/notifications/domain/entities/user_notification_entity.dart';
import 'package:market_space/features/notifications/domain/repositories/user_notifications_repository.dart';
import 'package:market_space/features/notifications/presentation/providers/user_notifications_providers.dart';

class _TestNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(true);
}

class _TestSessionNotifier extends SessionNotifier {
  final SessionState initial;
  _TestSessionNotifier(this.initial);

  @override
  SessionState build() => initial;
}

class _StubApiClient implements ApiClient {
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (path == '/home') {
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'success': true,
          'data': {
            'schemaVersion': '1.0',
            'priceFreshnessTtlSeconds': 60,
            'categories': const [],
            'promotions': const [],
            'featured': const [],
            'latest': const [],
            'recommended': const [],
          },
        } as T,
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'success': true, 'data': const [], 'meta': {'hasMore': false}} as T,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async => Response<T>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'success': true, 'data': {}} as T,
  );

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async => Response<T>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'success': true, 'data': {}} as T,
  );

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async => Response<T>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'success': true, 'data': {}} as T,
  );

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async => Response<T>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'success': true, 'data': {}} as T,
  );
}

class _StubFavoritesRepo implements FavoritesRepository {
  @override
  Future<void> addFavorite(String listingId) async {}

  @override
  Future<List<FavoriteItem>> getMyFavorites() async => const [];

  @override
  Future<void> removeFavorite(String listingId) async {}

  @override
  Future<FavoriteToggleResult> toggleFavorite(String listingId) async =>
      const FavoriteToggleResult(success: true, isFavorite: true);
}

class _StubBookingsRepo implements BookingsRepository {
  @override
  bool get isBackendSupported => true;

  @override
  Future<BookingEntity> cancelBooking(String bookingId) =>
      throw UnimplementedError();

  @override
  Future<BookingEntity> createBooking(CreateBookingPayload payload) =>
      throw UnimplementedError();

  @override
  Future<List<BookingEntity>> getBookings() async => const [];
}

class _StubRfqRepo implements RfqRepository {
  @override
  bool get isBackendSupported => true;

  @override
  Future<void> acceptQuotation(String rfqId, String quotationId) async {}

  @override
  Future<RfqRequestEntity> createRfq(CreateRfqPayload payload) =>
      throw UnimplementedError();

  @override
  Future<List<RfqRequestEntity>> getMyRfqs() async => const [];

  @override
  Future<void> rejectQuotation(String rfqId, String quotationId) async {}
}

class _StubUserProfileRepo implements UserProfileRepository {
  @override
  Future<void> createBusinessAccount({
    required String displayName,
    required String accountType,
    String? bio,
  }) async {}

  @override
  Future<UserProfileEntity> getMyProfile() async => const UserProfileEntity(
    id: 'u1',
    phone: '+201000000000',
    fullName: 'مصطفى هيكل',
    email: 'test@dealone.eg',
    isPhoneVerified: true,
  );

  @override
  Future<UserProfileEntity> updateMyProfile(UpdateUserProfileInput input) =>
      getMyProfile();
}

class _StubNotificationsRepo implements UserNotificationsRepository {
  @override
  Future<NotificationsPageResult> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async => const NotificationsPageResult(
    items: <UserNotificationEntity>[],
    unreadCount: 0,
    total: 0,
    page: 1,
    totalPages: 1,
  );

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> markAsRead(String notificationId) async {}
}

List<Override> _routerTestOverrides() {
  final prefs = InMemoryPreferencesService();
  final api = _StubApiClient();
  final cache = HybridCacheManager(preferencesService: prefs);
  return [
    preferencesServiceProvider.overrideWithValue(prefs),
    networkInfoProvider.overrideWithValue(_TestNetworkInfo()),
    apiClientProvider.overrideWithValue(api),
    hybridCacheManagerProvider.overrideWithValue(cache),
    sessionProvider.overrideWith(
      () => _TestSessionNotifier(
        const SessionState(status: SessionStatus.authenticated, userId: 'u1'),
      ),
    ),
    favoritesRepositoryProvider.overrideWithValue(_StubFavoritesRepo()),
    bookingsRepositoryProvider.overrideWithValue(_StubBookingsRepo()),
    rfqRepositoryProvider.overrideWithValue(_StubRfqRepo()),
    userProfileRepositoryProvider.overrideWithValue(_StubUserProfileRepo()),
    userNotificationsRepositoryProvider.overrideWithValue(
      _StubNotificationsRepo(),
    ),
    myAccountsProvider.overrideWith((ref) async => const <UserAccountEntity>[]),
    conversationsListProvider.overrideWith(
      (ref) async => const <ConversationEntity>[],
    ),
  ];
}

void main() {
  group('DealOneNavigationRoutes Unit Tests', () {
    test('defines exact 4 canonical tabs in RTL order', () {
      final items = DealOneNavigationRoutes.primaryItems;
      expect(items.length, 4);
      expect(items.map((e) => e.tab).toList(), [
        DealOneNavTab.home,
        DealOneNavTab.favorites,
        DealOneNavTab.orders,
        DealOneNavTab.profile,
      ]);
      expect(items.map((e) => e.labelAr).toList(), [
        'الرئيسية',
        'المفضلة',
        'طلباتي',
        'البروفايل',
      ]);
      expect(items.map((e) => e.route).toList(), [
        RouteNames.root,
        RouteNames.favorites,
        RouteNames.activityHub,
        RouteNames.profile,
      ]);
    });

    test('resolves deep links and detail routes accurately', () {
      expect(DealOneNavigationRoutes.tabForLocation('/'), DealOneNavTab.home);
      expect(
        DealOneNavigationRoutes.tabForLocation('/favorites'),
        DealOneNavTab.favorites,
      );
      expect(
        DealOneNavigationRoutes.tabForLocation('/activity-hub'),
        DealOneNavTab.orders,
      );
      expect(
        DealOneNavigationRoutes.tabForLocation('/activity-hub?tab=bookings'),
        DealOneNavTab.orders,
      );
      expect(
        DealOneNavigationRoutes.tabForLocation('/activity-hub?tab=favorites'),
        DealOneNavTab.favorites,
      );
      expect(
        DealOneNavigationRoutes.tabForLocation('/profile'),
        DealOneNavTab.profile,
      );
      expect(DealOneNavigationRoutes.tabForLocation('/profile/edit'), isNull);
      expect(
        DealOneNavigationRoutes.tabForLocation('/real-estate/detail?id=1'),
        isNull,
      );
      expect(
        DealOneNavigationRoutes.tabForLocation('/conversations/c1'),
        isNull,
      );
    });
  });

  group('DealOneBottomNavigation Component & Animation Tests', () {
    testWidgets(
      'renders all 4 states with exact RTL order, design tokens, and constant bar height',
      (tester) async {
        int activeIndex = 0;
        late StateSetter setLocalState;

        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                bottomNavigationBar: StatefulBuilder(
                  builder: (context, setState) {
                    setLocalState = setState;
                    return DealOneBottomNavigation(
                      activeIndex: activeIndex,
                      onTabSelected: (i) => setState(() => activeIndex = i),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify RTL right-to-left horizontal order:
        // الرئيسية (rightmost) > المفضلة > طلباتي > البروفايل (leftmost)
        final homeX = tester.getCenter(find.text('الرئيسية')).dx;
        final favX = tester.getCenter(find.text('المفضلة')).dx;
        final ordersX = tester.getCenter(find.text('طلباتي')).dx;
        final profileX = tester.getCenter(find.text('البروفايل')).dx;
        expect(homeX, greaterThan(favX));
        expect(favX, greaterThan(ordersX));
        expect(ordersX, greaterThan(profileX));

        // Verify active pill token color (#1B2A4A) & radius (12px)
        final pillDecor =
            tester
                    .widget<DecoratedBox>(
                      find.byKey(const Key('deal_one_nav_active_pill')),
                    )
                    .decoration
                as BoxDecoration;
        expect(pillDecor.color, const Color(0xFF1B2A4A));
        expect(pillDecor.borderRadius, BorderRadius.circular(12));

        // Record bar height across all 4 states — must stay strictly constant
        final initialBarSize = tester.getSize(
          find.byKey(const Key('deal_one_bottom_navigation_bar')),
        );
        final pillPositions = <double>[];

        for (var idx = 0; idx < 4; idx++) {
          setLocalState(() => activeIndex = idx);
          await tester.pumpAndSettle();
          final currentSize = tester.getSize(
            find.byKey(const Key('deal_one_bottom_navigation_bar')),
          );
          expect(currentSize.height, equals(initialBarSize.height));
          expect(currentSize.width, equals(initialBarSize.width));
          pillPositions.add(
            tester
                .getCenter(find.byKey(const Key('deal_one_nav_active_pill')))
                .dx,
          );
        }

        // In RTL, pill moves from right to left across indices 0 -> 1 -> 2 -> 3
        expect(pillPositions[0], greaterThan(pillPositions[1]));
        expect(pillPositions[1], greaterThan(pillPositions[2]));
        expect(pillPositions[2], greaterThan(pillPositions[3]));
      },
    );

    testWidgets('reverses order naturally in LTR (English)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              bottomNavigationBar: DealOneBottomNavigation(
                activeIndex: 0,
                onTabSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final homeX = tester.getCenter(find.text('Home')).dx;
      final favX = tester.getCenter(find.text('Favorites')).dx;
      final ordersX = tester.getCenter(find.text('Orders')).dx;
      final profileX = tester.getCenter(find.text('Profile')).dx;
      expect(homeX, lessThan(favX));
      expect(favX, lessThan(ordersX));
      expect(ordersX, lessThan(profileX));
    });

    testWidgets(
      'responsive matrix: zero overflow on 320dp..1024dp, 2.0x text scale, and SafeArea insets',
      (tester) async {
        const viewports = [
          Size(320, 568), // Small Phone
          Size(360, 800), // Medium Phone
          Size(393, 873), // Standard Phone
          Size(440, 956), // Large Phone
          Size(768, 1024), // Tablet
          Size(1024, 1366), // Large Tablet
        ];

        for (final size in viewports) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          for (final dir in [TextDirection.rtl, TextDirection.ltr]) {
            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: const TextScaler.linear(2.0),
                    padding: const EdgeInsets.only(bottom: 34),
                  ),
                  child: Directionality(
                    textDirection: dir,
                    child: Scaffold(
                      bottomNavigationBar: DealOneBottomNavigation(
                        activeIndex: 2,
                        onTabSelected: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            final barRect = tester.getRect(
              find.byKey(const Key('deal_one_bottom_navigation_bar')),
            );
            // Never overflows screen horizontally and stays above SafeArea bottom inset
            expect(barRect.left, greaterThanOrEqualTo(0));
            expect(barRect.right, lessThanOrEqualTo(size.width));
            expect(barRect.bottom, lessThanOrEqualTo(size.height - 34));
          }
        }
      },
    );
  });

  group('AppRouter & DealOneNavigationShell Integration Tests', () {
    testWidgets(
      'switches between Home, Favorites, Orders, Profile; no-ops on active tab; hides on detail screens & keyboard',
      (tester) async {
        tester.view.physicalSize = const Size(393, 873);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final router = AppRouter.createRouter(initialLocation: RouteNames.root);
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: _routerTestOverrides(),
            child: MaterialApp.router(
              locale: const Locale('ar'),
              supportedLocales: AppLocalization.supportedLocales,
              localizationsDelegates: AppLocalization.localizationsDelegates,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Starts on Home with single DealOneBottomNavigation
        expect(find.byType(DealOneBottomNavigation), findsOneWidget);
        expect(
          tester
              .widget<DealOneBottomNavigation>(
                find.byType(DealOneBottomNavigation),
              )
              .activeIndex,
          DealOneNavTab.home.index,
        );

        // 2. Tap Favorites -> navigates to /favorites & updates active index
        await tester.tap(find.byKey(const Key('deal_one_nav_item_favorites')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DealOneBottomNavigation>(
                find.byType(DealOneBottomNavigation),
              )
              .activeIndex,
          DealOneNavTab.favorites.index,
        );

        // 3. Tap Orders -> navigates to /activity-hub & updates active index
        await tester.tap(find.byKey(const Key('deal_one_nav_item_orders')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DealOneBottomNavigation>(
                find.byType(DealOneBottomNavigation),
              )
              .activeIndex,
          DealOneNavTab.orders.index,
        );

        // 4. Tap Profile -> navigates to /profile & updates active index
        await tester.tap(find.byKey(const Key('deal_one_nav_item_profile')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DealOneBottomNavigation>(
                find.byType(DealOneBottomNavigation),
              )
              .activeIndex,
          DealOneNavTab.profile.index,
        );
        expect(find.text('مصطفى هيكل'), findsOneWidget);

        // 5. Tapping already-active Profile tab is a safe no-op
        await tester.tap(find.byKey(const Key('deal_one_nav_item_profile')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DealOneBottomNavigation>(
                find.byType(DealOneBottomNavigation),
              )
              .activeIndex,
          DealOneNavTab.profile.index,
        );

        // 6. Pushing detail screen (Edit Account) hides bottom navigation bar
        router.push(RouteNames.editAccount);
        await tester.pumpAndSettle();
        expect(find.byType(DealOneBottomNavigation), findsNothing);

        // Popping detail screen restores Profile with bottom navigation bar
        router.pop();
        await tester.pumpAndSettle();
        expect(find.byType(DealOneBottomNavigation), findsOneWidget);
        expect(
          tester
              .widget<DealOneBottomNavigation>(
                find.byType(DealOneBottomNavigation),
              )
              .activeIndex,
          DealOneNavTab.profile.index,
        );

        // 7. Deep link to /activity-hub?tab=bookings activates Orders tab & bookings subtab
        router.go('${RouteNames.activityHub}?tab=bookings');
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DealOneBottomNavigation>(
                find.byType(DealOneBottomNavigation),
              )
              .activeIndex,
          DealOneNavTab.orders.index,
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(DealOneNavigationShell)),
        );
        expect(
          container.read(activityHubControllerProvider).selectedTab,
          ActivityHubTab.bookings,
        );

        // 8. Detail screen (Real Estate Details / Notifications / Chat) hides bar
        router.push(RouteNames.globalNotifications);
        await tester.pumpAndSettle();
        expect(find.byType(DealOneBottomNavigation), findsNothing);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.byType(DealOneBottomNavigation), findsOneWidget);

        // 9. Android system Back on non-Home tab returns cleanly to Home tab
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DealOneBottomNavigation>(
                find.byType(DealOneBottomNavigation),
              )
              .activeIndex,
          DealOneNavTab.home.index,
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'preserves scroll position across tab switches and hides bar when keyboard opens',
      (tester) async {
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, shell) =>
                  DealOneNavigationShell(navigationShell: shell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/',
                      builder: (context, state) => ListView.builder(
                        controller: scrollController,
                        itemCount: 50,
                        itemBuilder: (_, i) => ListTile(title: Text('Row $i')),
                      ),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/favorites',
                      builder: (context, state) =>
                          const Center(child: Text('Favs Page')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/activity-hub',
                      builder: (context, state) =>
                          const Center(child: Text('Orders Page')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/profile',
                      builder: (context, state) =>
                          const Center(child: Text('Profile Page')),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);

        double keyboardHeight = 0;
        late StateSetter setKeyboard;

        await tester.pumpWidget(
          ProviderScope(
            overrides: _routerTestOverrides(),
            child: StatefulBuilder(
              builder: (context, setState) {
                setKeyboard = setState;
                return MediaQuery(
                  data: MediaQueryData(
                    size: const Size(393, 873),
                    viewInsets: EdgeInsets.only(bottom: keyboardHeight),
                  ),
                  child: MaterialApp.router(
                    locale: const Locale('ar'),
                    supportedLocales: AppLocalization.supportedLocales,
                    localizationsDelegates:
                        AppLocalization.localizationsDelegates,
                    routerConfig: router,
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll Home down
        scrollController.jumpTo(420);
        await tester.pumpAndSettle();
        expect(scrollController.offset, 420);

        // Switch to Profile and back to Home
        await tester.tap(find.byKey(const Key('deal_one_nav_item_profile')));
        await tester.pumpAndSettle();
        expect(find.text('Profile Page'), findsOneWidget);

        await tester.tap(find.byKey(const Key('deal_one_nav_item_home')));
        await tester.pumpAndSettle();
        expect(scrollController.offset, 420);

        // Open soft keyboard -> bottom bar hides cleanly
        setKeyboard(() => keyboardHeight = 300);
        await tester.pumpAndSettle();
        expect(find.byType(DealOneBottomNavigation), findsNothing);

        // Close soft keyboard -> bottom bar reappears
        setKeyboard(() => keyboardHeight = 0);
        await tester.pumpAndSettle();
        expect(find.byType(DealOneBottomNavigation), findsOneWidget);
      },
    );
  });
}
