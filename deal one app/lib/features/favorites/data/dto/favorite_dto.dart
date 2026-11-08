import 'package:market_space/features/listings/data/dto/listing_dto.dart';

class FavoriteItemDto {
  final String favoriteId;
  final String savedAt;
  final ListingItemDto listing;

  const FavoriteItemDto({
    required this.favoriteId,
    required this.savedAt,
    required this.listing,
  });

  factory FavoriteItemDto.fromJson(Map<String, dynamic> json) {
    final listingJson = json['listing'] is Map ? Map<String, dynamic>.from(json['listing'] as Map) : <String, dynamic>{};
    return FavoriteItemDto(
      favoriteId: json['favoriteId']?.toString() ?? json['favorite_id']?.toString() ?? '',
      savedAt: json['savedAt']?.toString() ?? json['saved_at']?.toString() ?? '',
      listing: ListingItemDto.fromJson(listingJson),
    );
  }
}

class FavoriteToggleResultDto {
  final bool success;
  final bool isFavorite;
  final String? favoriteId;

  const FavoriteToggleResultDto({
    required this.success,
    required this.isFavorite,
    this.favoriteId,
  });

  factory FavoriteToggleResultDto.fromJson(Map<String, dynamic> json) {
    return FavoriteToggleResultDto(
      success: json['success'] == true,
      isFavorite: json['isFavorite'] == true || json['is_favorite'] == true,
      favoriteId: json['favoriteId']?.toString() ?? json['favorite_id']?.toString(),
    );
  }
}
