import 'package:market_space/features/listings/domain/entities/listing_entity.dart';

class FavoriteItem {
  final String favoriteId;
  final DateTime? savedAt;
  final ListingItem listing;

  const FavoriteItem({
    required this.favoriteId,
    this.savedAt,
    required this.listing,
  });
}

class FavoriteToggleResult {
  final bool success;
  final bool isFavorite;

  const FavoriteToggleResult({
    required this.success,
    required this.isFavorite,
  });
}
