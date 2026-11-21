import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';

/// Represents a product item in the user's Shopping Cart.
class CartItemEntity {
  final String id;
  final String listingId;
  final String title;
  final String? imageUrl;
  final String sellerName;
  final String sellerType;
  final double unitPrice;
  final String currency;
  final int quantity;
  final String? selectedSize;
  final String? selectedColor;
  final String categorySlug;
  final MarketplaceSectorCategory sector;
  final DateTime addedAt;

  const CartItemEntity({
    required this.id,
    required this.listingId,
    required this.title,
    this.imageUrl,
    required this.sellerName,
    this.sellerType = 'individual',
    required this.unitPrice,
    this.currency = 'EGP',
    required this.quantity,
    this.selectedSize,
    this.selectedColor,
    required this.categorySlug,
    required this.sector,
    required this.addedAt,
  });

  double get lineTotal => unitPrice * quantity;

  CartItemEntity copyWith({
    String? id,
    String? listingId,
    String? title,
    String? imageUrl,
    String? sellerName,
    String? sellerType,
    double? unitPrice,
    String? currency,
    int? quantity,
    String? selectedSize,
    String? selectedColor,
    String? categorySlug,
    MarketplaceSectorCategory? sector,
    DateTime? addedAt,
  }) {
    return CartItemEntity(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      sellerName: sellerName ?? this.sellerName,
      sellerType: sellerType ?? this.sellerType,
      unitPrice: unitPrice ?? this.unitPrice,
      currency: currency ?? this.currency,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      categorySlug: categorySlug ?? this.categorySlug,
      sector: sector ?? this.sector,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

/// Aggregated summary of the shopping cart.
class CartSummary {
  final int itemCount;
  final int totalQuantity;
  final double subtotal;
  final double? total;
  final String currency;

  const CartSummary({
    required this.itemCount,
    required this.totalQuantity,
    required this.subtotal,
    this.total,
    this.currency = 'EGP',
  });

  factory CartSummary.fromItems(List<CartItemEntity> items) {
    if (items.isEmpty) {
      return const CartSummary(
        itemCount: 0,
        totalQuantity: 0,
        subtotal: 0,
        total: 0,
      );
    }
    var totalQty = 0;
    var sum = 0.0;
    for (final item in items) {
      totalQty += item.quantity;
      sum += item.lineTotal;
    }
    return CartSummary(
      itemCount: items.length,
      totalQuantity: totalQty,
      subtotal: sum,
      total: sum,
      currency: items.first.currency,
    );
  }
}
