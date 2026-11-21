import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/features/activity_hub/application/providers/activity_hub_provider.dart';
import 'package:market_space/features/activity_hub/application/providers/cart_provider.dart';
import 'package:market_space/features/activity_hub/application/providers/favorites_hub_provider.dart';
import 'package:market_space/features/activity_hub/data/models/booking_dto.dart';
import 'package:market_space/features/activity_hub/data/models/rfq_dto.dart';
import 'package:market_space/features/activity_hub/data/repositories/local_cart_repository.dart';
import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/domain/entities/cart_item_entity.dart';
import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';
import 'package:market_space/features/favorites/domain/entities/favorite_entity.dart';
import 'package:market_space/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';

class _FakeFavoritesRepository implements FavoritesRepository {
  List<FavoriteItem> items;
  _FakeFavoritesRepository(this.items);

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
    final exists = items.any((e) => e.listing.id == listingId);
    if (exists) {
      items.removeWhere((e) => e.listing.id == listingId);
      return const FavoriteToggleResult(success: true, isFavorite: false);
    }
    return const FavoriteToggleResult(success: true, isFavorite: true);
  }
}

ListingItem _makeListing({
  required String id,
  required String title,
  required String categorySlug,
  double price = 100.0,
}) {
  return ListingItem(
    id: id,
    title: title,
    description: 'Description',
    price: price,
    categoryId: 'cat-$id',
    categoryNameAr: 'قسم',
    categoryNameEn: 'Category',
    categorySlug: categorySlug,
    areaNameAr: 'المعادي',
    cityNameAr: 'القاهرة',
    governorateNameAr: 'القاهرة',
    sellerName: 'Test Seller',
  );
}

void main() {
  group('CartSummary & Quantity Validation', () {
    test('calculates subtotal, total, and totalQuantity accurately', () {
      final items = [
        CartItemEntity(
          id: '1',
          listingId: 'l1',
          title: 'Cement Bag',
          sellerName: 'Al-Ahram',
          unitPrice: 250.0,
          quantity: 3,
          categorySlug: 'building-materials',
          sector: MarketplaceSectorCategory.buildingMaterials,
          addedAt: DateTime(2026, 11, 1),
        ),
        CartItemEntity(
          id: '2',
          listingId: 'l2',
          title: 'Cotton Shirt',
          sellerName: 'Cairo Wear',
          unitPrice: 400.0,
          quantity: 2,
          selectedSize: 'L',
          selectedColor: 'Navy',
          categorySlug: 'fashion',
          sector: MarketplaceSectorCategory.fashionAccessories,
          addedAt: DateTime(2026, 11, 2),
        ),
      ];

      final summary = CartSummary.fromItems(items);
      expect(summary.itemCount, 2);
      expect(summary.totalQuantity, 5);
      expect(summary.subtotal, 1550.0);
      expect(summary.total, 1550.0);
      expect(summary.currency, 'EGP');
    });

    test('LocalCartRepository persists, merges variants, and validates qty', () async {
      final prefs = InMemoryPreferencesService();
      final repo = LocalCartRepository(preferencesService: prefs);

      final item1 = CartItemEntity(
        id: 'l1_M_Black',
        listingId: 'l1',
        title: 'Jacket',
        sellerName: 'Store',
        unitPrice: 500,
        quantity: 1,
        selectedSize: 'M',
        selectedColor: 'Black',
        categorySlug: 'fashion',
        sector: MarketplaceSectorCategory.fashionAccessories,
        addedAt: DateTime(2026, 11, 1),
      );

      await repo.addItem(item1);
      await repo.addItem(item1.copyWith(quantity: 2));
      var list = await repo.getCartItems();
      expect(list.length, 1);
      expect(list.first.quantity, 3);

      expect(
        () => repo.updateQuantity(item1.id, 0),
        throwsA(isA<ArgumentError>()),
      );

      list = await repo.removeItem(item1.id);
      expect(list, isEmpty);
    });

    test('CartNotifier rejects quantity < 1 and sets mutationError', () async {
      final prefs = InMemoryPreferencesService();
      final container = ProviderContainer(
        overrides: [preferencesServiceProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      await notifier.loadCart();
      final added = await notifier.addListingToCart(
        _makeListing(id: 'l1', title: 'Fridge', categorySlug: 'appliances'),
      );
      expect(added, isTrue);

      final itemId = container.read(cartProvider).items.value!.first.id;
      final ok = await notifier.updateQuantity(itemId, 0);
      expect(ok, isFalse);
      expect(container.read(cartProvider).mutationError, isA<ArgumentError>());
      expect(container.read(cartProvider).items.value!.first.quantity, 1);
    });
  });

  group('Booking Status & DTO Mapping', () {
    test('maps backend statuses accurately without inventing statuses', () {
      expect(BookingStatus.fromBackend('pending'), BookingStatus.pending);
      expect(BookingStatus.fromBackend('confirmed'), BookingStatus.confirmed);
      expect(BookingStatus.fromBackend('rejected'), BookingStatus.rejected);
      expect(BookingStatus.fromBackend('cancelled'), BookingStatus.cancelled);
      expect(BookingStatus.fromBackend('completed'), BookingStatus.completed);
      expect(BookingStatus.fromBackend('weird_state'), BookingStatus.unknown);
    });

    test('BookingDto parses JSON and maps to BookingEntity', () {
      final dto = BookingDto.fromJson({
        'id': 'b-1',
        'listingId': 'l-99',
        'title': 'Villa Viewing',
        'providerName': 'Nile Realty',
        'category': 'real_estate',
        'type': 'property_viewing',
        'bookingDate': '2026-12-01T10:00:00Z',
        'bookingTime': '10:00 AM',
        'address': 'New Cairo',
        'status': 'confirmed',
        'referenceCode': 'BK-101',
        'canCancel': true,
      });

      final entity = dto.toEntity();
      expect(entity.id, 'b-1');
      expect(entity.category, BookingCategory.realEstate);
      expect(entity.type, BookingType.propertyViewing);
      expect(entity.status, BookingStatus.confirmed);
      expect(entity.referenceCode, 'BK-101');
      expect(entity.canCancel, isTrue);
    });
  });

  group('RFQ Status & DTO Mapping', () {
    test('maps RFQ backend statuses and parses nested quotations', () {
      expect(RfqStatus.fromBackend('submitted'), RfqStatus.submitted);
      expect(RfqStatus.fromBackend('quoted'), RfqStatus.quoted);
      expect(RfqStatus.fromBackend('accepted'), RfqStatus.accepted);
      expect(RfqStatus.fromBackend('rejected'), RfqStatus.rejected);
      expect(RfqStatus.fromBackend('unknown_val'), RfqStatus.unknown);

      final dto = RfqRequestDto.fromJson({
        'id': 'rfq-1',
        'title': 'Steel & Cement',
        'referenceNumber': 'RFQ-2026-01',
        'submittedAt': '2026-11-20T09:00:00Z',
        'requestedItemsCount': 2,
        'materialsSummary': 'Cement, Steel',
        'quantitySummary': '10 Tons',
        'deliveryLocation': '6th October',
        'status': 'quoted',
        'quotations': [
          {
            'id': 'q-1',
            'rfqId': 'rfq-1',
            'supplierName': 'Ezz Partner',
            'totalPrice': 45000,
            'status': 'pending',
            'canAccept': true,
            'canReject': true,
          },
        ],
      });

      final entity = dto.toEntity();
      expect(entity.status, RfqStatus.quoted);
      expect(entity.quotationsCount, 1);
      expect(entity.quotations.first.supplierName, 'Ezz Partner');
      expect(entity.quotations.first.totalPrice, 45000.0);
    });
  });

  group('MarketplaceSectorCategory & Favorites Filtering', () {
    test('maps all 6 sector slugs to canonical enum and route', () {
      expect(
        MarketplaceSectorCategory.fromCategorySlug('real-estate').sectionRoute,
        RouteNames.realEstate,
      );
      expect(
        MarketplaceSectorCategory.fromCategorySlug('cars').sectionRoute,
        RouteNames.cars,
      );
      expect(
        MarketplaceSectorCategory.fromCategorySlug('services').sectionRoute,
        RouteNames.homeServices,
      );
      expect(
        MarketplaceSectorCategory.fromCategorySlug('building-materials')
            .sectionRoute,
        RouteNames.buildingMaterials,
      );
      expect(
        MarketplaceSectorCategory.fromCategorySlug('home-appliances')
            .sectionRoute,
        RouteNames.homeAppliances,
      );
      expect(
        MarketplaceSectorCategory.fromCategorySlug('fashion').sectionRoute,
        RouteNames.fashion,
      );
    });

    test('filteredFavoritesProvider filters by sector and search query', () async {
      final repo = _FakeFavoritesRepository([
        FavoriteItem(
          favoriteId: 'f1',
          listing: _makeListing(
            id: '1',
            title: 'Apartment in Maadi',
            categorySlug: 'real-estate',
          ),
        ),
        FavoriteItem(
          favoriteId: 'f2',
          listing: _makeListing(
            id: '2',
            title: 'Toyota Corolla',
            categorySlug: 'cars',
          ),
        ),
      ]);

      final container = ProviderContainer(
        overrides: [favoritesRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(favoritesProvider.notifier).loadFavorites();

      expect(container.read(filteredFavoritesProvider).value!.length, 2);

      container.read(favoritesFilterCategoryProvider.notifier).state =
          MarketplaceSectorCategory.carsMaintenance;
      expect(container.read(filteredFavoritesProvider).value!.length, 1);
      expect(
        container.read(filteredFavoritesProvider).value!.first.listing.id,
        '2',
      );

      container.read(favoritesFilterCategoryProvider.notifier).state =
          MarketplaceSectorCategory.all;
      container
          .read(activityHubControllerProvider.notifier)
          .setSearchQuery('maadi');
      expect(container.read(filteredFavoritesProvider).value!.length, 1);
      expect(
        container.read(filteredFavoritesProvider).value!.first.listing.id,
        '1',
      );
    });
  });
}
