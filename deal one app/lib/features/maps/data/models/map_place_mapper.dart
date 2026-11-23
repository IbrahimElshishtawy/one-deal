import 'package:market_space/features/listings/data/dto/listing_dto.dart';
import 'package:market_space/features/listings/data/mappers/listing_mapper.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/maps/domain/entities/map_place_entity.dart';

/// Maps real backend listing payloads into [MapPlaceEntity] without ever
/// fabricating or mocking coordinates.
class MapPlaceMapper {
  const MapPlaceMapper._();

  static MapPlaceEntity fromListingDto(
    ListingItemDto dto, {
    String? rawAddress,
  }) {
    final entity = ListingMapper.toItemEntity(dto);
    return fromListingEntity(entity, rawAddress: rawAddress);
  }

  static MapPlaceEntity fromListingEntity(
    ListingItem item, {
    String? rawAddress,
  }) {
    final attrAddress =
        item.attributes['address']?.toString() ??
        item.attributes['street_address']?.toString() ??
        item.attributes['location_address']?.toString() ??
        '';
    final resolvedAddress = (rawAddress != null && rawAddress.trim().isNotEmpty)
        ? rawAddress.trim()
        : attrAddress.trim();

    return MapPlaceEntity(
      id: item.id,
      title: item.title,
      description: item.description,
      categoryId: item.categoryId,
      categorySlug: item.categorySlug,
      categoryNameAr: item.categoryNameAr,
      categoryNameEn: item.categoryNameEn,
      price: item.price,
      currency: item.currency,
      listingKind: item.listingKind,
      condition: item.condition,
      latitude: item.latitude,
      longitude: item.longitude,
      address: resolvedAddress,
      areaName: item.areaNameAr,
      cityName: item.cityNameAr,
      governorateName: item.governorateNameAr,
      imageUrl: item.primaryImageUrl,
      merchantName: item.sellerName,
      merchantAvatarUrl: item.sellerAvatarUrl,
      merchantType: item.sellerType,
      isVerified: item.isVerified,
      isFeatured: item.isFeatured,
      attributes: item.attributes,
      sourceListing: item,
    );
  }
}
