import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/core/theme/app_theme_data.dart';
import 'package:market_space/features/activity_hub/application/providers/bookings_provider.dart';
import 'package:market_space/features/activity_hub/application/providers/cart_provider.dart';
import 'package:market_space/features/activity_hub/application/providers/rfq_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/domain/entities/cart_item_entity.dart';
import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';
import 'package:market_space/features/activity_hub/domain/repositories/bookings_repository.dart';
import 'package:market_space/features/activity_hub/domain/repositories/rfq_repository.dart';
import 'package:market_space/features/activity_hub/presentation/pages/activity_hub_page.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/bookings/booking_card.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/rfq/rfq_request_card.dart';
import 'package:market_space/features/favorites/domain/entities/favorite_entity.dart';
import 'package:market_space/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';

class _TestFavoritesRepo implements FavoritesRepository {
  final List<FavoriteItem> items;
  _TestFavoritesRepo(this.items);

  @override
  Future<void> addFavorite(String listingId) async {}

  @override
  Future<List<FavoriteItem>> getMyFavorites() async => items;

  @override
  Future<void> removeFavorite(String listingId) async {
    items.removeWhere((e) => e.listing.id == listingId);
  }

  @override
  Future<FavoriteToggleResult> toggleFavorite(String listingId) async {
    items.removeWhere((e) => e.listing.id == listingId);
    return const FavoriteToggleResult(success: true, isFavorite: false);
  }
}

class _TestBookingsRepo implements BookingsRepository {
  final List<BookingEntity> items;
  @override
  bool get isBackendSupported => true;

  _TestBookingsRepo(this.items);

  @override
  Future<void> cancelBooking(String bookingId) async {}

  @override
  Future<BookingEntity> createBooking(CreateBookingPayload payload) async {
    throw UnimplementedError();
  }

  @override
  Future<List<BookingEntity>> getBookings() async => items;
}

class _TestRfqRepo implements RfqRepository {
  final List<RfqRequestEntity> items;
  @override
  bool get isBackendSupported => true;

  _TestRfqRepo(this.items);

  @override
  Future<void> acceptQuotation(String rfqId, String quotationId) async {}

  @override
  Future<RfqRequestEntity> createRfq(CreateRfqPayload payload) async {
    throw UnimplementedError();
  }

  @override
  Future<List<RfqRequestEntity>> getMyRfqs() async => items;

  @override
  Future<void> rejectQuotation(String rfqId, String quotationId) async {}
}

Widget _wrapApp({
  required Widget child,
  required InMemoryPreferencesService prefs,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      preferencesServiceProvider.overrideWithValue(prefs),
      ...overrides,
    ],
    child: MaterialApp(
      locale: locale,
      themeMode: themeMode,
      theme: AppThemeData.lightTheme,
      darkTheme: AppThemeData.darkTheme,
      localizationsDelegates: AppLocalization.localizationsDelegates,
      supportedLocales: AppLocalization.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('ActivityHubPage switches tabs & renders Arabic RTL + Dark Mode', (
    tester,
  ) async {
    final prefs = InMemoryPreferencesService();
    final favRepo = _TestFavoritesRepo([
      FavoriteItem(
        favoriteId: 'f1',
        listing: const ListingItem(
          id: 'l1',
          title: 'شقة بالتجمع الخامس',
          description: 'وصف',
          price: 2500000,
          categoryId: 'c1',
          categoryNameAr: 'عقارات',
          categoryNameEn: 'Real Estate',
          categorySlug: 'real-estate',
          areaNameAr: 'التجمع',
          cityNameAr: 'القاهرة',
          governorateNameAr: 'القاهرة',
          sellerName: 'شركة النيل',
        ),
      ),
    ]);

    await tester.pumpWidget(
      _wrapApp(
        prefs: prefs,
        locale: const Locale('ar'),
        themeMode: ThemeMode.dark,
        overrides: [favoritesRepositoryProvider.overrideWithValue(favRepo)],
        child: const ActivityHubPage(initialTab: ActivityHubTab.cart),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مركز النشاط والتجارة'), findsOneWidget);
    expect(find.text('سلة التسوق فارغة'), findsOneWidget);

    // Switch to Bookings tab
    await tester.tap(find.text('الحجوزات'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد حجوزات أو مواعيد بعد'), findsOneWidget);

    // Switch to RFQ tab
    await tester.tap(find.text('عروض الأسعار'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد طلبات عروض أسعار بعد'), findsOneWidget);

    // Switch to Favorites tab
    await tester.tap(find.text('المفضلة'));
    await tester.pumpAndSettle();
    expect(find.text('شقة بالتجمع الخامس'), findsOneWidget);
  });

  testWidgets('CartTabView renders item, increments qty, and confirms remove', (
    tester,
  ) async {
    final prefs = InMemoryPreferencesService();
    final favRepo = _TestFavoritesRepo([]);

    await tester.pumpWidget(
      _wrapApp(
        prefs: prefs,
        locale: const Locale('en'),
        overrides: [favoritesRepositoryProvider.overrideWithValue(favRepo)],
        child: const ActivityHubPage(initialTab: ActivityHubTab.cart),
      ),
    );
    await tester.pumpAndSettle();

    // Add item via CartNotifier
    final element = tester.element(find.byType(ActivityHubPage));
    final container = ProviderScope.containerOf(element);
    await container.read(cartProvider.notifier).addItem(
      CartItemEntity(
        id: 'c1',
        listingId: 'l-10',
        title: 'Bosch Washing Machine',
        sellerName: 'Cairo Appliances',
        unitPrice: 12000,
        quantity: 1,
        categorySlug: 'home-appliances',
        sector: MarketplaceSectorCategory.homeAppliances,
        addedAt: DateTime(2026, 11, 20),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bosch Washing Machine'), findsOneWidget);
    expect(find.text('Seller: Cairo Appliances'), findsOneWidget);

    // Increment quantity
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(container.read(cartSummaryProvider).totalQuantity, 2);

    // Tap Remove -> confirm dialog
    await tester.ensureVisible(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Remove Item'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Your shopping cart is empty'), findsOneWidget);
  });

  testWidgets('BookingCard renders all status badges cleanly', (tester) async {
    final prefs = InMemoryPreferencesService();
    final booking = BookingEntity(
      id: 'b1',
      listingId: 'l1',
      title: 'AC Maintenance',
      providerName: 'CoolTech',
      category: BookingCategory.servicesEngineering,
      type: BookingType.airConditioning,
      bookingDate: DateTime(2026, 12, 5),
      bookingTime: '02:00 PM',
      address: 'Nasr City, Cairo',
      status: BookingStatus.confirmed,
      rawStatus: 'confirmed',
      referenceCode: 'BK-202',
      canCancel: true,
    );

    await tester.pumpWidget(
      _wrapApp(
        prefs: prefs,
        child: Scaffold(body: BookingCard(booking: booking)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AC Maintenance'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Ref #BK-202'), findsOneWidget);
    expect(find.text('Nasr City, Cairo'), findsOneWidget);
  });

  testWidgets('RfqRequestCard expands to show quotations', (tester) async {
    final prefs = InMemoryPreferencesService();
    final rfq = RfqRequestEntity(
      id: 'r1',
      title: 'Villa Cement Supply',
      referenceNumber: 'RFQ-99',
      submittedAt: DateTime(2026, 11, 15),
      requestedItemsCount: 3,
      materialsSummary: 'Portland Cement',
      quantitySummary: '20 Tons',
      deliveryLocation: 'Sheikh Zayed',
      status: RfqStatus.quoted,
      rawStatus: 'quoted',
      quotations: [
        const RfqQuotationEntity(
          id: 'q1',
          rfqId: 'r1',
          supplierName: 'Delta Materials',
          totalPrice: 68000,
          rawStatus: 'pending',
          canAccept: true,
          canReject: true,
        ),
      ],
    );

    await tester.pumpWidget(
      _wrapApp(
        prefs: prefs,
        child: Scaffold(
          body: RfqRequestCard(
            rfq: rfq,
            onAcceptQuotation: (_) {},
            onRejectQuotation: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Villa Cement Supply'), findsOneWidget);
    expect(find.text('Quoted'), findsOneWidget);

    await tester.tap(find.text('Compare Quotations'));
    await tester.pumpAndSettle();

    expect(find.text('Delta Materials'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });

  testWidgets('Responsive check on 320x568 small phone and 1024x1366 tablet', (
    tester,
  ) async {
    final prefs = InMemoryPreferencesService();
    final favRepo = _TestFavoritesRepo([]);
    final bookingsRepo = _TestBookingsRepo([]);
    final rfqRepo = _TestRfqRepo([]);

    for (final size in [const Size(320, 568), const Size(1024, 1366)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        _wrapApp(
          prefs: prefs,
          overrides: [
            favoritesRepositoryProvider.overrideWithValue(favRepo),
            bookingsRepositoryProvider.overrideWithValue(bookingsRepo),
            rfqRepositoryProvider.overrideWithValue(rfqRepo),
          ],
          child: const ActivityHubPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
