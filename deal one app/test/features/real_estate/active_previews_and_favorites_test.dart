import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/features/activity_hub/application/providers/bookings_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/domain/repositories/bookings_repository.dart';
import 'package:market_space/features/favorites/domain/entities/favorite_entity.dart';
import 'package:market_space/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/real_estate/presentation/pages/active_previews_page.dart';

class _FakeBookingsRepo implements BookingsRepository {
  final List<BookingEntity> items;
  _FakeBookingsRepo(this.items);

  @override
  bool get isBackendSupported => true;

  @override
  Future<List<BookingEntity>> getBookings() async => items;

  @override
  Future<BookingEntity> createBooking(CreateBookingPayload payload) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelBooking(String bookingId) async {}
}

class _FakeFavoritesRepo implements FavoritesRepository {
  final List<FavoriteItem> items;
  _FakeFavoritesRepo(this.items);

  @override
  Future<List<FavoriteItem>> getMyFavorites() async => items;

  @override
  Future<FavoriteToggleResult> toggleFavorite(String listingId) async =>
      const FavoriteToggleResult(success: true, isFavorite: false);

  @override
  Future<void> addFavorite(String listingId) async {}

  @override
  Future<void> removeFavorite(String listingId) async {}
}

void main() {
  testWidgets('ActivePreviewsPage renders Arabic design elements and filters', (
    tester,
  ) async {
    final fakeRepo = _FakeBookingsRepo([
      BookingEntity(
        id: '1094-abcd',
        listingId: 'list-1',
        title: 'شقة فاخرة للبيع - الحي المتميز',
        providerName: 'م. حسام الدين',
        category: BookingCategory.realEstate,
        type: BookingType.propertyViewing,
        bookingDate: DateTime(2026, 10, 24),
        bookingTime: '04:30 م',
        address: 'طنطا - الحي المتميز',
        status: BookingStatus.confirmed,
        rawStatus: 'confirmed',
        referenceCode: '#DL-1094',
      ),
      BookingEntity(
        id: '1082-efgh',
        listingId: 'list-2',
        title: 'فيلا دوبلكس بحديقة خاصة',
        providerName: 'أحمد العقارية',
        category: BookingCategory.realEstate,
        type: BookingType.propertyViewing,
        bookingDate: DateTime(2026, 10, 26),
        bookingTime: '06:00 م',
        address: 'طنطا - كورنيش القاصد',
        status: BookingStatus.pending,
        rawStatus: 'pending',
        referenceCode: '#DL-1082',
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ActivePreviewsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('المعاينات النشطة'), findsOneWidget);
    expect(find.text('حجز معاينة'), findsOneWidget);
    expect(find.text('شقة فاخرة للبيع - الحي المتميز'), findsOneWidget);
    expect(find.text('الموقع والتفاصيل'), findsOneWidget);

    // Filter to confirmed only
    await tester.tap(find.text('مؤكدة (1)'));
    await tester.pumpAndSettle();
    expect(find.text('شقة فاخرة للبيع - الحي المتميز'), findsOneWidget);
    expect(find.text('فيلا دوبلكس بحديقة خاصة'), findsNothing);
    expect(find.text('سياسة مرونة المعاينات'), findsOneWidget);
  });

  testWidgets('FavoritesScreen renders filter pills and property cards', (
    tester,
  ) async {
    final repo = _FakeFavoritesRepo([
      const FavoriteItem(
        favoriteId: 'fav-1',
        listing: ListingItem(
          id: 'l-1',
          title: 'شقة فاخرة للبيع - الحي المتميز',
          description: '',
          price: 2450000,
          currency: 'EGP',
          listingKind: 'sale',
          categoryId: 'cat-1',
          categoryNameAr: 'عقارات للبيع',
          categoryNameEn: 'For Sale',
          categorySlug: 'real-estate-sale',
          areaNameAr: '',
          cityNameAr: 'طنطا',
          governorateNameAr: 'الغربية',
          media: [],
          sellerName: 'أحمد',
          sellerType: 'individual',
          isVerified: true,
        ),
      ),
      const FavoriteItem(
        favoriteId: 'fav-2',
        listing: ListingItem(
          id: 'l-2',
          title: 'استوديو مفروش للإيجار الشهري',
          description: '',
          price: 8500,
          currency: 'EGP',
          listingKind: 'rent',
          categoryId: 'cat-2',
          categoryNameAr: 'عقارات للإيجار',
          categoryNameEn: 'For Rent',
          categorySlug: 'real-estate-rent',
          areaNameAr: '',
          cityNameAr: 'طنطا',
          governorateNameAr: 'الغربية',
          media: [],
          sellerName: 'سارة',
          sellerType: 'individual',
          isVerified: true,
        ),
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoritesRepositoryProvider.overrideWithValue(repo),
          favoritesProvider.overrideWith(
            (ref) => FavoritesNotifier(repo, autoLoad: true),
          ),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: FavoritesScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('المفضلة'), findsAtLeastNWidgets(1));
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('شقة فاخرة للبيع - الحي المتميز'), findsOneWidget);
    expect(find.text('استوديو مفروش للإيجار الشهري'), findsOneWidget);

    // Filter to For Rent only
    await tester.tap(find.text('عقارات للإيجار').first);
    await tester.pumpAndSettle();
    expect(find.text('استوديو مفروش للإيجار الشهري'), findsOneWidget);
    expect(find.text('شقة فاخرة للبيع - الحي المتميز'), findsNothing);
  });
}
