class ListingMediaDto {
  final String id;
  final String mediaType;
  final String publicUrl;
  final int sortOrder;

  const ListingMediaDto({
    required this.id,
    required this.mediaType,
    required this.publicUrl,
    this.sortOrder = 0,
  });

  factory ListingMediaDto.fromJson(Map<String, dynamic> json) {
    return ListingMediaDto(
      id: json['id']?.toString() ?? '',
      mediaType: json['mediaType']?.toString() ?? json['media_type']?.toString() ?? 'image',
      publicUrl: json['publicUrl']?.toString() ?? json['public_url']?.toString() ?? '',
      sortOrder: (json['sortOrder'] ?? json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class ListingItemDto {
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
  final List<ListingMediaDto> media;
  final String sellerName;
  final String? sellerPhone; // Verified: always null in public feed
  final String sellerType;
  final bool isVerified;
  final Map<String, dynamic> attributes;
  final int viewsCount;
  final String createdAt;

  const ListingItemDto({
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
    required this.createdAt,
  });

  factory ListingItemDto.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>? ?? {};
    final area = json['area'] as Map<String, dynamic>? ?? {};
    final city = area['city'] as Map<String, dynamic>? ?? {};
    final governorate = city['governorate'] as Map<String, dynamic>? ?? {};

    final mediaList = (json['media'] as List?)
            ?.map((m) => ListingMediaDto.fromJson(Map<String, dynamic>.from(m as Map)))
            .toList() ??
        [];

    final rawPrice = json['price'];
    final double parsedPrice = rawPrice is num ? rawPrice.toDouble() : (double.tryParse(rawPrice?.toString() ?? '') ?? 0.0);

    return ListingItemDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: parsedPrice,
      currency: json['currency']?.toString() ?? 'EGP',
      condition: json['condition']?.toString() ?? 'USED',
      listingKind: json['listingKind']?.toString() ?? json['listing_kind']?.toString() ?? 'sale',
      categoryId: category['id']?.toString() ?? json['categoryId']?.toString() ?? '',
      categoryNameAr: category['nameAr']?.toString() ?? category['name_ar']?.toString() ?? '',
      categoryNameEn: category['nameEn']?.toString() ?? category['name_en']?.toString() ?? '',
      categorySlug: category['slug']?.toString() ?? '',
      areaNameAr: area['nameAr']?.toString() ?? area['name_ar']?.toString() ?? '',
      cityNameAr: city['nameAr']?.toString() ?? city['name_ar']?.toString() ?? '',
      governorateNameAr: governorate['nameAr']?.toString() ?? governorate['name_ar']?.toString() ?? '',
      media: mediaList,
      sellerName: json['sellerName']?.toString() ?? json['seller_name']?.toString() ?? '',
      sellerPhone: json['sellerPhone']?.toString() ?? json['seller_phone']?.toString(),
      sellerType: json['sellerType']?.toString() ?? json['seller_type']?.toString() ?? 'individual',
      isVerified: json['isVerified'] == true || json['is_verified'] == true,
      attributes: json['attributes'] is Map ? Map<String, dynamic>.from(json['attributes'] as Map) : {},
      viewsCount: (json['viewsCount'] ?? json['views_count'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
    );
  }
}

class ListingFeedResponseDto {
  final List<ListingItemDto> items;
  final String? nextCursor;
  final bool hasMore;

  const ListingFeedResponseDto({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });

  factory ListingFeedResponseDto.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] is List ? json['data'] as List : (json['items'] as List? ?? []);
    final items = rawList
        .map((item) => ListingItemDto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    final meta = json['meta'] as Map<String, dynamic>?;
    final nextCursor = meta?['nextCursor']?.toString() ??
        meta?['next_cursor']?.toString() ??
        json['nextCursor']?.toString();
    final hasMore = meta?['hasMore'] as bool? ?? (nextCursor != null && nextCursor.isNotEmpty);

    return ListingFeedResponseDto(
      items: items,
      nextCursor: nextCursor,
      hasMore: hasMore,
    );
  }
}

class ContactRevealDto {
  final String phone;
  final String sellerName;
  final String? whatsappUrl;
  final int remainingDailyQuota;
  final int dailyLimit;

  const ContactRevealDto({
    required this.phone,
    required this.sellerName,
    this.whatsappUrl,
    required this.remainingDailyQuota,
    required this.dailyLimit,
  });

  factory ContactRevealDto.fromJson(Map<String, dynamic> json) {
    return ContactRevealDto(
      phone: json['phone']?.toString() ?? '',
      sellerName: json['sellerName']?.toString() ?? json['seller_name']?.toString() ?? '',
      whatsappUrl: json['whatsappUrl']?.toString() ?? json['whatsapp']?.toString(),
      remainingDailyQuota: (json['remainingDailyQuota'] ?? json['remaining_daily_quota'] as num?)?.toInt() ?? 0,
      dailyLimit: (json['dailyLimit'] ?? json['daily_limit'] as num?)?.toInt() ?? 5,
    );
  }
}

class FilterListingsDto {
  final String? categorySlug;
  final String? categoryId;
  final String? q;
  final String? sort; // newest, latest, price_asc, price_desc, nearest
  final int? governorateId;
  final int? cityId;
  final double? minPrice;
  final double? maxPrice;
  final String? condition; // NEW, USED, NOT_APPLICABLE
  final String? cursor;
  final int limit;

  const FilterListingsDto({
    this.categorySlug,
    this.categoryId,
    this.q,
    this.sort = 'newest',
    this.governorateId,
    this.cityId,
    this.minPrice,
    this.maxPrice,
    this.condition,
    this.cursor,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{'limit': limit};
    if (categorySlug != null && categorySlug!.isNotEmpty) params['categorySlug'] = categorySlug;
    if (categoryId != null && categoryId!.isNotEmpty) params['categoryId'] = categoryId;
    if (q != null && q!.isNotEmpty) params['q'] = q;
    if (sort != null && sort!.isNotEmpty) params['sort'] = sort;
    if (governorateId != null) params['governorateId'] = governorateId;
    if (cityId != null) params['cityId'] = cityId;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (condition != null && condition!.isNotEmpty) params['condition'] = condition;
    if (cursor != null && cursor!.isNotEmpty) params['cursor'] = cursor;
    return params;
  }
}

class CreateListingDto {
  final String categoryId;
  final int cityId;
  final String title;
  final String description;
  final double price;
  final String condition;
  final Map<String, dynamic> attributes;
  final List<String> mediaKeys;
  final String? videoStreamUid;

  const CreateListingDto({
    required this.categoryId,
    required this.cityId,
    required this.title,
    required this.description,
    required this.price,
    this.condition = 'USED',
    this.attributes = const {},
    required this.mediaKeys,
    this.videoStreamUid,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'cityId': cityId,
      'title': title,
      'description': description,
      'price': price,
      'condition': condition,
      'attributes': attributes,
      'mediaKeys': mediaKeys,
      if (videoStreamUid != null) 'videoStreamUid': videoStreamUid,
    };
  }
}
