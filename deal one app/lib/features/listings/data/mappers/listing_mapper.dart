import 'package:market_space/features/listings/data/dto/listing_dto.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';

class ListingMapper {
  static ListingMedia toMediaEntity(ListingMediaDto dto) {
    return ListingMedia(
      id: dto.id,
      mediaType: dto.mediaType,
      publicUrl: dto.publicUrl,
      sortOrder: dto.sortOrder,
    );
  }

  static ListingItem toItemEntity(ListingItemDto dto) {
    DateTime? parsedDate;
    if (dto.createdAt.isNotEmpty) {
      parsedDate = DateTime.tryParse(dto.createdAt);
    }

    return ListingItem(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      price: dto.price,
      currency: dto.currency,
      condition: dto.condition,
      listingKind: dto.listingKind,
      categoryId: dto.categoryId,
      categoryNameAr: dto.categoryNameAr,
      categoryNameEn: dto.categoryNameEn,
      categorySlug: dto.categorySlug,
      areaNameAr: dto.areaNameAr,
      cityNameAr: dto.cityNameAr,
      governorateNameAr: dto.governorateNameAr,
      media: dto.media.map(toMediaEntity).toList(),
      sellerName: dto.sellerName,
      sellerPhone: dto.sellerPhone,
      sellerType: dto.sellerType,
      isVerified: dto.isVerified,
      attributes: dto.attributes,
      viewsCount: dto.viewsCount,
      createdAt: parsedDate,
    );
  }

  static ListingFeed toFeedEntity(ListingFeedResponseDto dto) {
    return ListingFeed(
      items: dto.items.map(toItemEntity).toList(),
      nextCursor: dto.nextCursor,
      hasMore: dto.hasMore,
    );
  }

  static ContactRevealResult toContactRevealResult(ContactRevealDto dto) {
    return ContactRevealResult(
      phone: dto.phone,
      sellerName: dto.sellerName,
      whatsappUrl: dto.whatsappUrl,
      remainingDailyQuota: dto.remainingDailyQuota,
      dailyLimit: dto.dailyLimit,
    );
  }
}
