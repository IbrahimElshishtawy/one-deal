import 'package:market_space/features/listings/data/dto/listing_dto.dart';

class SearchQueryDto {
  final String query;
  final String? categorySlug;
  final String? categoryId;
  final int? governorateId;
  final int? cityId;
  final double? minPrice;
  final double? maxPrice;
  final String? condition;
  final String? listingKind;
  final int? rooms;
  final int? baths;
  final String? finishing;
  final String? brand;
  final String? transmission;
  final int? year;
  final String? size;
  final String? color;
  final String sort;
  final int page;
  final int limit;

  const SearchQueryDto({
    this.query = '',
    this.categorySlug,
    this.categoryId,
    this.governorateId,
    this.cityId,
    this.minPrice,
    this.maxPrice,
    this.condition,
    this.listingKind,
    this.rooms,
    this.baths,
    this.finishing,
    this.brand,
    this.transmission,
    this.year,
    this.size,
    this.color,
    this.sort = 'newest',
    this.page = 1,
    this.limit = 20,
  });

  SearchQueryDto copyWith({
    String? query,
    String? categorySlug,
    bool clearCategorySlug = false,
    String? categoryId,
    bool clearCategoryId = false,
    int? governorateId,
    bool clearGovernorateId = false,
    int? cityId,
    bool clearCityId = false,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    String? condition,
    bool clearCondition = false,
    String? listingKind,
    bool clearListingKind = false,
    int? rooms,
    bool clearRooms = false,
    int? baths,
    bool clearBaths = false,
    String? finishing,
    bool clearFinishing = false,
    String? brand,
    bool clearBrand = false,
    String? transmission,
    bool clearTransmission = false,
    int? year,
    bool clearYear = false,
    String? size,
    bool clearSize = false,
    String? color,
    bool clearColor = false,
    String? sort,
    int? page,
    int? limit,
  }) {
    return SearchQueryDto(
      query: query ?? this.query,
      categorySlug: clearCategorySlug ? null : (categorySlug ?? this.categorySlug),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      governorateId: clearGovernorateId ? null : (governorateId ?? this.governorateId),
      cityId: clearCityId ? null : (cityId ?? this.cityId),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      condition: clearCondition ? null : (condition ?? this.condition),
      listingKind: clearListingKind ? null : (listingKind ?? this.listingKind),
      rooms: clearRooms ? null : (rooms ?? this.rooms),
      baths: clearBaths ? null : (baths ?? this.baths),
      finishing: clearFinishing ? null : (finishing ?? this.finishing),
      brand: clearBrand ? null : (brand ?? this.brand),
      transmission: clearTransmission ? null : (transmission ?? this.transmission),
      year: clearYear ? null : (year ?? this.year),
      size: clearSize ? null : (size ?? this.size),
      color: clearColor ? null : (color ?? this.color),
      sort: sort ?? this.sort,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  bool get hasAnyFilter =>
      query.trim().isNotEmpty ||
      (categorySlug != null && categorySlug!.isNotEmpty) ||
      (categoryId != null && categoryId!.isNotEmpty) ||
      governorateId != null ||
      cityId != null ||
      minPrice != null ||
      maxPrice != null ||
      condition != null ||
      listingKind != null ||
      rooms != null ||
      baths != null ||
      finishing != null ||
      brand != null ||
      transmission != null ||
      year != null ||
      size != null ||
      color != null;

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort': sort,
    };
    if (query.trim().isNotEmpty) params['q'] = query.trim();
    if (categorySlug != null && categorySlug!.isNotEmpty) params['categorySlug'] = categorySlug;
    if (categoryId != null && categoryId!.isNotEmpty) params['categoryId'] = categoryId;
    if (governorateId != null) params['governorateId'] = governorateId;
    if (cityId != null) params['cityId'] = cityId;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (condition != null && condition!.isNotEmpty) params['condition'] = condition;
    if (listingKind != null && listingKind!.isNotEmpty) params['listingKind'] = listingKind;
    if (rooms != null) params['rooms'] = rooms;
    if (baths != null) params['baths'] = baths;
    if (finishing != null && finishing!.isNotEmpty) params['finishing'] = finishing;
    if (brand != null && brand!.isNotEmpty) params['brand'] = brand;
    if (transmission != null && transmission!.isNotEmpty) params['transmission'] = transmission;
    if (year != null) params['year'] = year;
    if (size != null && size!.isNotEmpty) params['size'] = size;
    if (color != null && color!.isNotEmpty) params['color'] = color;
    return params;
  }
}

class SearchMetaDto {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final String query;

  const SearchMetaDto({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.query,
  });

  factory SearchMetaDto.fromJson(Map<String, dynamic> json) {
    return SearchMetaDto(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] ?? json['total_pages'] as num?)?.toInt() ?? 1,
      query: json['query']?.toString() ?? '',
    );
  }
}

class SearchResponseDto {
  final List<ListingItemDto> items;
  final SearchMetaDto meta;

  const SearchResponseDto({
    required this.items,
    required this.meta,
  });

  factory SearchResponseDto.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] is List ? json['data'] as List : (json['items'] as List? ?? []);
    final items = rawList
        .map((item) => ListingItemDto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    final meta = json['meta'] is Map
        ? SearchMetaDto.fromJson(Map<String, dynamic>.from(json['meta'] as Map))
        : const SearchMetaDto(total: 0, page: 1, limit: 20, totalPages: 1, query: '');

    return SearchResponseDto(items: items, meta: meta);
  }
}
