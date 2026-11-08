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
    this.sort = 'newest',
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'q': query,
      'page': page,
      'limit': limit,
      'sort': sort,
    };
    if (categorySlug != null && categorySlug!.isNotEmpty) params['categorySlug'] = categorySlug;
    if (categoryId != null && categoryId!.isNotEmpty) params['categoryId'] = categoryId;
    if (governorateId != null) params['governorateId'] = governorateId;
    if (cityId != null) params['cityId'] = cityId;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (condition != null && condition!.isNotEmpty) params['condition'] = condition;
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
