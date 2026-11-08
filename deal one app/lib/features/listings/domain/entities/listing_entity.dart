class ListingMedia {
  final String id;
  final String mediaType;
  final String publicUrl;
  final int sortOrder;

  const ListingMedia({
    required this.id,
    required this.mediaType,
    required this.publicUrl,
    this.sortOrder = 0,
  });
}

class ListingItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String condition;
  final String listingKind;
  final String categoryId;
  final String categoryNameAr;
  final String categoryNameEn;
  final String categorySlug;
  final String areaNameAr;
  final String cityNameAr;
  final String governorateNameAr;
  final List<ListingMedia> media;
  final String sellerName;
  final String? sellerPhone; // Protected by privacy policy; null in public feeds
  final String sellerType;
  final bool isVerified;
  final Map<String, dynamic> attributes;
  final int viewsCount;
  final DateTime? createdAt;

  const ListingItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.currency = 'EGP',
    this.condition = 'USED',
    this.listingKind = 'sale',
    required this.categoryId,
    required this.categoryNameAr,
    required this.categoryNameEn,
    required this.categorySlug,
    required this.areaNameAr,
    required this.cityNameAr,
    required this.governorateNameAr,
    this.media = const [],
    required this.sellerName,
    this.sellerPhone,
    this.sellerType = 'individual',
    this.isVerified = false,
    this.attributes = const {},
    this.viewsCount = 0,
    this.createdAt,
  });

  String? get primaryImageUrl => media.isNotEmpty ? media.first.publicUrl : null;
  
  String localizedLocation(String langCode) {
    if (cityNameAr.isNotEmpty) {
      return areaNameAr.isNotEmpty ? '$cityNameAr - $areaNameAr' : cityNameAr;
    }
    return governorateNameAr;
  }
}

class ListingFeed {
  final List<ListingItem> items;
  final String? nextCursor;
  final bool hasMore;

  const ListingFeed({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });
}

class ContactRevealResult {
  final String phone;
  final String sellerName;
  final String? whatsappUrl;
  final int remainingDailyQuota;
  final int dailyLimit;

  const ContactRevealResult({
    required this.phone,
    required this.sellerName,
    this.whatsappUrl,
    required this.remainingDailyQuota,
    required this.dailyLimit,
  });
}
