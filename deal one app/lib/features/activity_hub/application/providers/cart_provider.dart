import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/activity_hub/data/repositories/local_cart_repository.dart';
import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';
import 'package:market_space/features/activity_hub/domain/entities/cart_item_entity.dart';
import 'package:market_space/features/activity_hub/domain/repositories/cart_repository.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return LocalCartRepository(preferencesService: prefs);
});

class CartState {
  final AsyncValue<List<CartItemEntity>> items;
  final bool isMutating;
  final bool isRefreshing;
  final Object? mutationError;

  const CartState({
    this.items = const AsyncValue.loading(),
    this.isMutating = false,
    this.isRefreshing = false,
    this.mutationError,
  });

  CartState copyWith({
    AsyncValue<List<CartItemEntity>>? items,
    bool? isMutating,
    bool? isRefreshing,
    Object? mutationError,
    bool clearMutationError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      isMutating: isMutating ?? this.isMutating,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      mutationError: clearMutationError
          ? null
          : (mutationError ?? this.mutationError),
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final CartRepository _repository;

  CartNotifier(this._repository) : super(const CartState()) {
    loadCart();
  }

  Future<void> loadCart({bool refresh = false}) async {
    if (refresh && state.items.hasValue) {
      state = state.copyWith(isRefreshing: true, clearMutationError: true);
    } else {
      state = state.copyWith(
        items: const AsyncValue.loading(),
        clearMutationError: true,
      );
    }

    try {
      final loaded = await _repository.getCartItems();
      state = state.copyWith(
        items: AsyncValue.data(loaded),
        isRefreshing: false,
      );
    } catch (e, st) {
      state = state.copyWith(
        items: AsyncValue.error(e, st),
        isRefreshing: false,
      );
    }
  }

  Future<bool> addListingToCart(
    ListingItem listing, {
    int quantity = 1,
    String? selectedSize,
    String? selectedColor,
  }) async {
    if (quantity < 1) {
      state = state.copyWith(
        mutationError: ArgumentError.value(quantity, 'quantity', 'Must be >= 1'),
      );
      return false;
    }

    final sector = MarketplaceSectorCategory.fromCategorySlug(
      listing.categorySlug,
    );
    final itemId =
        '${listing.id}_${selectedSize ?? ''}_${selectedColor ?? ''}';
    final newItem = CartItemEntity(
      id: itemId,
      listingId: listing.id,
      title: listing.title,
      imageUrl: listing.primaryImageUrl,
      sellerName: listing.sellerName,
      sellerType: listing.sellerType,
      unitPrice: listing.price,
      currency: listing.currency,
      quantity: quantity,
      selectedSize: selectedSize,
      selectedColor: selectedColor,
      categorySlug: listing.categorySlug,
      sector: sector,
      addedAt: DateTime.now(),
    );

    return addItem(newItem);
  }

  Future<bool> addItem(CartItemEntity item) async {
    if (state.isMutating) return false;
    state = state.copyWith(isMutating: true, clearMutationError: true);
    try {
      final updated = await _repository.addItem(item);
      state = state.copyWith(
        items: AsyncValue.data(updated),
        isMutating: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isMutating: false, mutationError: e);
      return false;
    }
  }

  Future<bool> updateQuantity(String itemId, int quantity) async {
    if (quantity < 1) {
      state = state.copyWith(
        mutationError: ArgumentError.value(quantity, 'quantity', 'Must be >= 1'),
      );
      return false;
    }
    final previous = state.items;
    final currentList = previous.valueOrNull;
    if (currentList != null) {
      final optimistic = currentList
          .map((e) => e.id == itemId ? e.copyWith(quantity: quantity) : e)
          .toList();
      state = state.copyWith(
        items: AsyncValue.data(optimistic),
        isMutating: true,
        clearMutationError: true,
      );
    } else {
      state = state.copyWith(isMutating: true, clearMutationError: true);
    }

    try {
      final updated = await _repository.updateQuantity(itemId, quantity);
      state = state.copyWith(
        items: AsyncValue.data(updated),
        isMutating: false,
      );
      return true;
    } catch (e) {
      // Rollback optimistic update on failure
      state = state.copyWith(
        items: previous,
        isMutating: false,
        mutationError: e,
      );
      return false;
    }
  }

  Future<bool> removeItem(String itemId) async {
    final previous = state.items;
    final currentList = previous.valueOrNull;
    if (currentList != null) {
      final optimistic = currentList.where((e) => e.id != itemId).toList();
      state = state.copyWith(
        items: AsyncValue.data(optimistic),
        isMutating: true,
        clearMutationError: true,
      );
    } else {
      state = state.copyWith(isMutating: true, clearMutationError: true);
    }

    try {
      final updated = await _repository.removeItem(itemId);
      state = state.copyWith(
        items: AsyncValue.data(updated),
        isMutating: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        items: previous,
        isMutating: false,
        mutationError: e,
      );
      return false;
    }
  }

  Future<void> clearCart() async {
    final previous = state.items;
    state = state.copyWith(
      items: const AsyncValue.data([]),
      isMutating: true,
      clearMutationError: true,
    );
    try {
      await _repository.clearCart();
      state = state.copyWith(isMutating: false);
    } catch (e) {
      state = state.copyWith(
        items: previous,
        isMutating: false,
        mutationError: e,
      );
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  return CartNotifier(repository);
});

final cartSummaryProvider = Provider<CartSummary>((ref) {
  final items = ref.watch(cartProvider).items.valueOrNull ?? const [];
  return CartSummary.fromItems(items);
});
