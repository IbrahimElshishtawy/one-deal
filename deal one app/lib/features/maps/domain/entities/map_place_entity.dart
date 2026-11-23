import 'package:latlong2/latlong.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/maps/domain/entities/map_bounds.dart';

/// Unified domain entity representing a real listing, store, or service provider
/// displayed on the universal Deal One category map.
class MapPlaceEntity {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String categorySlug;
  final String categoryNameAr;
  final String categoryNameEn;
  final double price;
  final String currency;
  final String listingKind;
  final String condition;
  final double? latitude;
  final double? longitude;
  final String address;
  final String areaName;
  final String cityName;
  final String governorateName;
  final String? imageUrl;
  final String merchantName;
  final String? merchantAvatarUrl;
  final String merchantType;
  final bool isVerified;
  final bool isFeatured;
  final Map<String, dynamic> attributes;
  final ListingItem? sourceListing;

  const MapPlaceEntity({
    required this.id,
    required this.title,
    this.description = '',
    required this.categoryId,
    required this.categorySlug,
    this.categoryNameAr = '',
    this.categoryNameEn = '',
    required this.price,
    this.currency = 'EGP',
    this.listingKind = 'sale',
    this.condition = 'USED',
    this.latitude,
    this.longitude,
    this.address = '',
    this.areaName = '',
    this.cityName = '',
    this.governorateName = '',
    this.imageUrl,
    this.merchantName = '',
    this.merchantAvatarUrl,
    this.merchantType = 'individual',
    this.isVerified = false,
    this.isFeatured = false,
    this.attributes = const {},
    this.sourceListing,
  });

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      latitude! >= -90 &&
      latitude! <= 90 &&
      longitude! >= -180 &&
      longitude! <= 180;

  LatLng? get point => hasCoordinates ? LatLng(latitude!, longitude!) : null;

  bool get isStoreOrBusiness =>
      merchantType.toLowerCase() != 'individual' && merchantName.isNotEmpty;

  String formattedAddress(bool isArabic) {
    if (address.trim().isNotEmpty) return address.trim();
    final parts = <String>[
      if (areaName.trim().isNotEmpty) areaName.trim(),
      if (cityName.trim().isNotEmpty) cityName.trim(),
      if (governorateName.trim().isNotEmpty) governorateName.trim(),
    ];
    if (parts.isNotEmpty) {
      return parts.join(isArabic ? '، ' : ', ');
    }
    return isArabic ? 'الموقع غير محدد بالتفصيل' : 'Address not specified';
  }

  /// Distance in km from [reference], or `null` if coordinates are unavailable.
  double? distanceKmFrom(LatLng? reference) {
    if (reference == null || !hasCoordinates) return null;
    return haversineDistanceKm(reference, LatLng(latitude!, longitude!));
  }

  /// Google Maps web directions URI when coordinates are available.
  String? get directionsUrl {
    if (!hasCoordinates) return null;
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }
}

/// Paginated search result returned by [CategoryMapRepository].
class MapPlacesPage {
  final List<MapPlaceEntity> items;
  final int totalCount;
  final int page;
  final int totalPages;

  const MapPlacesPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}
