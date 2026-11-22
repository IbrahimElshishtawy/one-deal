import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/marketplace/section_home_controller.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/security/session_state.dart';
import 'package:market_space/features/accounts/domain/entities/account_entity.dart';
import 'package:market_space/features/accounts/domain/entities/user_profile_entity.dart';
import 'package:market_space/features/accounts/domain/repositories/user_profile_repository.dart';
import 'package:market_space/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:market_space/features/accounts/presentation/providers/user_profile_providers.dart';
import 'package:market_space/features/accounts/presentation/screens/edit_account_page.dart';
import 'package:market_space/features/accounts/presentation/screens/profile_screen.dart';
import 'package:market_space/features/activity_hub/application/providers/bookings_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/domain/repositories/bookings_repository.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';
import 'package:market_space/features/conversations/presentation/pages/conversations_page.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/locations/domain/entities/location_entity.dart';
import 'package:market_space/features/locations/presentation/providers/locations_providers.dart';
import 'package:market_space/features/notifications/domain/entities/user_notification_entity.dart';
import 'package:market_space/features/notifications/domain/repositories/user_notifications_repository.dart';
import 'package:market_space/features/notifications/presentation/pages/notifications_page.dart';
import 'package:market_space/features/notifications/presentation/providers/user_notifications_providers.dart';
import 'package:market_space/features/real_estate/domain/entities/reel_item_entity.dart';
import 'package:market_space/features/real_estate/presentation/pages/photo_gallery_page.dart';
import 'package:market_space/features/real_estate/presentation/pages/real_estate_details_page.dart';
import 'package:market_space/features/real_estate/presentation/pages/real_estate_map_page.dart';
import 'package:market_space/features/real_estate/presentation/pages/real_estate_reels_page.dart';
import 'package:market_space/l10n/generated/app_localizations.dart';

class _FakeSessionNotifier extends SessionNotifier {
  final SessionState initial;
  _FakeSessionNotifier(this.initial);

  @override
  SessionState build() => initial;
}

class _FakeUserProfileRepo implements UserProfileRepository {
  UserProfileEntity profile;
  int updateCalls = 0;

  _FakeUserProfileRepo(this.profile);

  @override
  Future<UserProfileEntity> getMyProfile() async => profile;

  @override
  Future<UserProfileEntity> updateMyProfile(UpdateUserProfileInput input) async {
    updateCalls++;
    profile = profile.copyWith(
      fullName: input.fullName ?? profile.fullName,
      avatarUrl: input.avatarUrl ?? profile.avatarUrl,
    );
    return profile;
  }

  @override
  Future<void> createBusinessAccount({
    required String displayName,
    required String accountType,
    String? bio,
  }) async {}
}

class _FakeNotificationsRepo implements UserNotificationsRepository {
  List<UserNotificationEntity> items;
  int markAllCalled = 0;

  _FakeNotificationsRepo(this.items);

  @override
  Future<NotificationsPageResult> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    final unread = items.where((n) => !n.isRead).length;
    return NotificationsPageResult(
      items: items,
      unreadCount: unread,
      total: items.length,
      page: page,
      totalPages: 1,
    );
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    items = items
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
  }

  @override
  Future<void> markAllAsRead() async {
    markAllCalled++;
    items = items.map((n) => n.copyWith(isRead: true)).toList();
  }
}

class _NoopApiClient implements ApiClient {
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async =>
      Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: <String, dynamic>{} as T,
      );

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async =>
      Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: <String, dynamic>{} as T,
      );

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async =>
      Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: <String, dynamic>{} as T,
      );

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async =>
      Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: <String, dynamic>{} as T,
      );

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async =>
      Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: <String, dynamic>{} as T,
      );
}

class _StaticSectionHomeController extends StateNotifier<SectionHomeState>
    implements SectionHomeController {
  _StaticSectionHomeController(super.initial);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBookingsRepo implements BookingsRepository {
  @override
  bool get isBackendSupported => true;

  @override
  Future<List<BookingEntity>> getBookings() async => const [];

  @override
  Future<BookingEntity> createBooking(CreateBookingPayload payload) {
    throw UnimplementedError();
  }

  @override
  Future<BookingEntity> cancelBooking(String bookingId) {
    throw UnimplementedError();
  }
}

Widget _wrapApp({
  required Widget child,
  required List<Override> overrides,
  Locale locale = const Locale('ar'),
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

ListingItem _sampleProperty() {
  return ListingItem(
    id: 'dl-8841-abc',
    title: 'شقة مودرن بفيو مفتوح على الشارع الرئيسي',
    description:
        'ريسبشن واسع يتسع لـ 3 قطع كبيرة مع تراس خارجي بفيو مفتوح، 3 غرف نوم مريحة، تشطيب سوبر لوكس بالكامل.',
    price: 14000,
    currency: 'EGP',
    listingKind: 'rent',
    categoryId: 'cat-re',
    categoryNameAr: 'شقة سكنية فاخرة',
    categoryNameEn: 'Luxury Apartment',
    categorySlug: 'real-estate',
    areaNameAr: 'شارع النادي',
    cityNameAr: 'طنطا',
    governorateNameAr: 'الغربية',
    sellerName: 'أ. أحمد سليمان',
    sellerType: 'individual',
    isVerified: true,
    latitude: 30.7865,
    longitude: 31.0004,
    media: const [
      ListingMedia(id: 'm1', mediaType: 'image', publicUrl: ''),
      ListingMedia(id: 'm2', mediaType: 'image', publicUrl: ''),
    ],
    attributes: const {
      'rooms': 3,
      'baths': 2,
      'area_sqm': 175,
      'finishing': 'سوبر لوكس',
      'floor': 5,
    },
  );
}

void main() {
  const authedSession = SessionState(
    status: SessionStatus.authenticated,
    userId: 'user-1',
  );

  final sampleProfile = UserProfileEntity(
    id: 'user-1',
    phone: '+201023456789',
    fullName: 'مصطفى هيكل',
    email: 'mostafa@dealone.eg',
    isPhoneVerified: true,
  );

  group('Profile & Real Estate 9-Screen UI Suite', () {
    testWidgets('1. ProfileScreen renders user data & stats without overflow (RTL 360dp & LTR 320dp)', (
      tester,
    ) async {
      final profileRepo = _FakeUserProfileRepo(sampleProfile);
      final notifRepo = _FakeNotificationsRepo(const []);

      for (final cfg in [
        (const Size(360, 780), const Locale('ar')),
        (const Size(320, 640), const Locale('en')),
      ]) {
        tester.view.physicalSize = cfg.$1;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapApp(
            locale: cfg.$2,
            overrides: [
              sessionProvider.overrideWith(
                () => _FakeSessionNotifier(authedSession),
              ),
              userProfileRepositoryProvider.overrideWithValue(profileRepo),
              myAccountsProvider.overrideWith(
                (ref) async => const <UserAccountEntity>[],
              ),
              favoriteIdsProvider.overrideWith((ref) => {'l1', 'l2'}),
              bookingsRepositoryProvider.overrideWithValue(_FakeBookingsRepo()),
              conversationsListProvider.overrideWith(
                (ref) async => const <ConversationEntity>[],
              ),
              userNotificationsRepositoryProvider.overrideWithValue(notifRepo),
            ],
            child: const ProfileScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('مصطفى هيكل'), findsOneWidget);
        expect(
          find.byKey(const Key('profile_edit_account_button')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('2. EditAccountPage validates required name and submits update', (
      tester,
    ) async {
      final profileRepo = _FakeUserProfileRepo(sampleProfile);

      await tester.pumpWidget(
        _wrapApp(
          overrides: [
            sessionProvider.overrideWith(
              () => _FakeSessionNotifier(authedSession),
            ),
            userProfileRepositoryProvider.overrideWithValue(profileRepo),
            governoratesProvider.overrideWith(
              (ref) async => const [
                GovernorateEntity(
                  id: 1,
                  nameAr: 'الغربية',
                  nameEn: 'Gharbia',
                  slug: 'gharbia',
                  cities: [
                    CityEntity(
                      id: 10,
                      governorateId: 1,
                      nameAr: 'طنطا',
                      nameEn: 'Tanta',
                      slug: 'tanta',
                    ),
                  ],
                ),
              ],
            ),
          ],
          child: const EditAccountPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مصطفى هيكل'), findsOneWidget);

      // Clear name to verify validation error
      await tester.enterText(
        find.byKey(const Key('edit_account_fullname_field')),
        '',
      );
      await tester.ensureVisible(
        find.byKey(const Key('edit_account_save_button')),
      );
      await tester.tap(find.byKey(const Key('edit_account_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('الاسم الكامل مطلوب'), findsOneWidget);
      expect(profileRepo.updateCalls, 0);

      // Enter valid name and submit
      await tester.enterText(
        find.byKey(const Key('edit_account_fullname_field')),
        'أحمد مصطفى',
      );
      await tester.tap(find.byKey(const Key('edit_account_save_button')));
      await tester.pumpAndSettle();

      expect(profileRepo.updateCalls, 1);
    });

    testWidgets('3. ConversationsPage displays real conversations and filters', (
      tester,
    ) async {
      final convs = [
        ConversationEntity(
          id: 'c1',
          listingId: 'l1',
          buyerUserId: 'user-1',
          sellerAccountId: 'acc-1',
          counterpartName: 'م. حسام الدين',
          isVerified: true,
          lastMessageText: 'تم التنسيق مع المالك، هل يناسبك موعد المعاينة غداً؟',
          lastMessageAt: DateTime.now().subtract(const Duration(minutes: 10)),
          unreadCount: 2,
          listing: const ConversationListingPreview(
            id: 'l1',
            title: 'شقة للبيع - الحي المتميز',
            price: 2450000,
          ),
        ),
      ];

      await tester.pumpWidget(
        _wrapApp(
          overrides: [
            sessionProvider.overrideWith(
              () => _FakeSessionNotifier(authedSession),
            ),
            conversationsListProvider.overrideWith((ref) async => convs),
          ],
          child: const ConversationsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('م. حسام الدين'), findsOneWidget);
      expect(find.text('شقة للبيع - الحي المتميز'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4. NotificationsPage renders notifications and Mark All Read', (
      tester,
    ) async {
      final repo = _FakeNotificationsRepo([
        UserNotificationEntity(
          id: 'n1',
          type: 'booking_confirmed',
          title: 'تأكيد موعد المعاينة',
          body: 'تم موافقة أحمد العقارية على معاينة شقة الحي المتميز',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          payload: const {'bookingId': 'b1', 'location': 'الحي المتميز'},
        ),
      ]);

      await tester.pumpWidget(
        _wrapApp(
          overrides: [
            sessionProvider.overrideWith(
              () => _FakeSessionNotifier(authedSession),
            ),
            userNotificationsRepositoryProvider.overrideWithValue(repo),
          ],
          child: const NotificationsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تأكيد موعد المعاينة'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('notifications_mark_all_read_button')),
      );
      await tester.pumpAndSettle();

      expect(repo.markAllCalled, 1);
    });

    testWidgets('5. Non Notification empty state renders cleanly when list is empty', (
      tester,
    ) async {
      final repo = _FakeNotificationsRepo(const []);

      await tester.pumpWidget(
        _wrapApp(
          overrides: [
            sessionProvider.overrideWith(
              () => _FakeSessionNotifier(authedSession),
            ),
            userNotificationsRepositoryProvider.overrideWithValue(repo),
          ],
          child: const NotificationsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('non_notification_empty_state')),
        findsOneWidget,
      );
      expect(find.text('لا توجد إشعارات جديدة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('6. RealEstateMapPage renders property preview card without overflow', (
      tester,
    ) async {
      final property = _sampleProperty();

      await tester.pumpWidget(
        _wrapApp(
          overrides: [
            sessionProvider.overrideWith(
              () => _FakeSessionNotifier(authedSession),
            ),
            sectionHomeControllerProvider('real-estate').overrideWith(
              (ref) => _StaticSectionHomeController(
                SectionHomeState(listings: [property]),
              ),
            ),
          ],
          child: RealEstateMapPage(focusedProperty: property),
        ),
      );
      await tester.pump();

      expect(find.text('الموقع الجغرافي'), findsOneWidget);
      expect(find.text(property.title), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7. PhotoGalleryPage renders hero viewer & thumbnail grid', (
      tester,
    ) async {
      final property = _sampleProperty();

      await tester.pumpWidget(
        _wrapApp(
          overrides: [
            favoriteIdsProvider.overrideWith((ref) => const <String>{}),
          ],
          child: PhotoGalleryPage(
            listingId: property.id,
            initialListing: property,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('جميع صور العقار'), findsOneWidget);
      expect(find.text('معرض الصور'), findsOneWidget);
      expect(find.text('معروضة حالياً'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('8. RealEstateDetailsPage renders specs, description, and seller bar', (
      tester,
    ) async {
      final property = _sampleProperty();

      await tester.pumpWidget(
        _wrapApp(
          overrides: [
            apiClientProvider.overrideWithValue(_NoopApiClient()),
            favoriteIdsProvider.overrideWith((ref) => const <String>{}),
          ],
          child: RealEstateDetailsPage(
            listingId: property.id,
            preloadedItem: property,
          ),
        ),
      );
      await tester.pump();

      expect(find.text(property.title), findsOneWidget);
      expect(find.text('المواصفات الرئيسية'), findsOneWidget);
      expect(find.text('الوصف التفصيلي'), findsOneWidget);
      expect(
        find.byKey(const Key('real_estate_chat_seller_button')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('9. RealEstateReelsPage renders vertical reel overlay and toggles pause', (
      tester,
    ) async {
      final reels = [
        const ReelItemEntity(
          listingId: 'r1',
          title: 'شقة 180م في الحي المتميز',
          price: 4200000,
          cityName: 'طنطا',
          governorateName: 'الغربية',
          sellerName: 'أحمد العقارية',
          favoritesCount: 142,
          attributes: {'rooms': 3, 'baths': 2, 'finishing': 'سوبر لوكس'},
        ),
      ];

      await tester.pumpWidget(
        _wrapApp(
          overrides: [
            favoriteIdsProvider.overrideWith((ref) => const <String>{}),
          ],
          child: RealEstateReelsPage(initialItems: reels),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('شقة 180م في الحي المتميز'), findsOneWidget);
      expect(find.text('أحمد العقارية'), findsOneWidget);
      expect(find.byKey(const Key('reel_open_details_button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
