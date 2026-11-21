import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/features/activity_hub/data/models/cart_item_model.dart';
import 'package:market_space/features/activity_hub/domain/entities/cart_item_entity.dart';
import 'package:market_space/features/activity_hub/domain/repositories/cart_repository.dart';

/// Persistent local cart repository backed by [PreferencesService].
/// Preserves user cart items across app restarts while V1 backend operates
/// without server-side cart/order endpoints.
class LocalCartRepository implements CartRepository {
  static const String _storageKey = 'activity_hub_cart_items_v1';

  final PreferencesService preferencesService;

  LocalCartRepository({required this.preferencesService});

  @override
  Future<List<CartItemEntity>> getCartItems() async {
    final raw = await preferencesService.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return CartItemModel.decodeList(raw);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<CartItemEntity>> addItem(CartItemEntity item) async {
    final current = List<CartItemEntity>.from(await getCartItems());
    final existingIdx = current.indexWhere(
      (e) =>
          e.listingId == item.listingId &&
          (e.selectedSize ?? '') == (item.selectedSize ?? '') &&
          (e.selectedColor ?? '') == (item.selectedColor ?? ''),
    );

    if (existingIdx >= 0) {
      final existing = current[existingIdx];
      final newQty = (existing.quantity + item.quantity).clamp(1, 999);
      current[existingIdx] = existing.copyWith(quantity: newQty);
    } else {
      current.insert(0, item);
    }

    await preferencesService.setString(
      _storageKey,
      CartItemModel.encodeList(current),
    );
    return current;
  }

  @override
  Future<List<CartItemEntity>> updateQuantity(
    String itemId,
    int quantity,
  ) async {
    if (quantity < 1) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be >= 1');
    }
    final current = List<CartItemEntity>.from(await getCartItems());
    final idx = current.indexWhere((e) => e.id == itemId);
    if (idx >= 0) {
      current[idx] = current[idx].copyWith(quantity: quantity.clamp(1, 999));
      await preferencesService.setString(
        _storageKey,
        CartItemModel.encodeList(current),
      );
    }
    return current;
  }

  @override
  Future<List<CartItemEntity>> removeItem(String itemId) async {
    final current = List<CartItemEntity>.from(await getCartItems());
    current.removeWhere((e) => e.id == itemId);
    await preferencesService.setString(
      _storageKey,
      CartItemModel.encodeList(current),
    );
    return current;
  }

  @override
  Future<void> clearCart() async {
    await preferencesService.remove(_storageKey);
  }
}
