import 'package:market_space/features/favorites/data/dto/favorite_dto.dart';
import 'package:market_space/features/favorites/domain/entities/favorite_entity.dart';
import 'package:market_space/features/listings/data/mappers/listing_mapper.dart';

class FavoriteMapper {
  static FavoriteItem toEntity(FavoriteItemDto dto) {
    DateTime? parsedDate;
    if (dto.savedAt.isNotEmpty) {
      parsedDate = DateTime.tryParse(dto.savedAt);
    }

    return FavoriteItem(
      favoriteId: dto.favoriteId,
      savedAt: parsedDate,
      listing: ListingMapper.toItemEntity(dto.listing),
    );
  }

  static FavoriteToggleResult toToggleResult(FavoriteToggleResultDto dto) {
    return FavoriteToggleResult(
      success: dto.success,
      isFavorite: dto.isFavorite,
    );
  }
}
