import 'package:market_space/features/activity_hub/domain/entities/cart_item_entity.dart';

abstract class CartRepository {
  Future<List<CartItemEntity>> getCartItems();
  Future<List<CartItemEntity>> addItem(CartItemEntity item);
  Future<List<CartItemEntity>> updateQuantity(String itemId, int quantity);
  Future<List<CartItemEntity>> removeItem(String itemId);
  Future<void> clearCart();
}
