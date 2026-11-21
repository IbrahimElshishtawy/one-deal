import 'dart:convert';

import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';
import 'package:market_space/features/activity_hub/domain/entities/cart_item_entity.dart';

class CartItemModel {
  static Map<String, dynamic> toJson(CartItemEntity entity) {
    return {
      'id': entity.id,
      'listingId': entity.listingId,
      'title': entity.title,
      'imageUrl': entity.imageUrl,
      'sellerName': entity.sellerName,
      'sellerType': entity.sellerType,
      'unitPrice': entity.unitPrice,
      'currency': entity.currency,
      'quantity': entity.quantity,
      'selectedSize': entity.selectedSize,
      'selectedColor': entity.selectedColor,
      'categorySlug': entity.categorySlug,
      'sector': entity.sector.name,
      'addedAt': entity.addedAt.toIso8601String(),
    };
  }

  static CartItemEntity fromJson(Map<String, dynamic> json) {
    final sectorName = json['sector']?.toString();
    final sector = MarketplaceSectorCategory.values.firstWhere(
      (s) => s.name == sectorName,
      orElse: () => MarketplaceSectorCategory.fromCategorySlug(
        json['categorySlug']?.toString(),
      ),
    );
    return CartItemEntity(
      id: json['id']?.toString() ?? '',
      listingId: json['listingId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      sellerName: json['sellerName']?.toString() ?? '',
      sellerType: json['sellerType']?.toString() ?? 'individual',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'EGP',
      quantity: ((json['quantity'] as num?)?.toInt() ?? 1).clamp(1, 999),
      selectedSize: json['selectedSize']?.toString(),
      selectedColor: json['selectedColor']?.toString(),
      categorySlug: json['categorySlug']?.toString() ?? '',
      sector: sector,
      addedAt:
          DateTime.tryParse(json['addedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static String encodeList(List<CartItemEntity> items) {
    return jsonEncode(items.map(toJson).toList());
  }

  static List<CartItemEntity> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((m) => fromJson(Map<String, dynamic>.from(m)))
        .where((item) => item.id.isNotEmpty && item.listingId.isNotEmpty)
        .toList();
  }
}
