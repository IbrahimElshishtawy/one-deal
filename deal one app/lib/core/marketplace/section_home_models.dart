import 'package:market_space/features/categories/data/dto/category_dto.dart';
import 'package:market_space/features/categories/data/mappers/category_mapper.dart';
import 'package:market_space/features/categories/domain/entities/category_entity.dart';
import 'package:market_space/features/listings/data/dto/listing_dto.dart';
import 'package:market_space/features/listings/data/mappers/listing_mapper.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';

class SectionFilterOption {
  final String value;
  final String labelAr;
  final String labelEn;

  const SectionFilterOption({
    required this.value,
    required this.labelAr,
    required this.labelEn,
  });

  factory SectionFilterOption.fromJson(Map<String, dynamic> json) {
    return SectionFilterOption(
      value: json['value']?.toString() ?? '',
      labelAr: json['labelAr']?.toString() ?? json['value']?.toString() ?? '',
      labelEn: json['labelEn']?.toString() ?? json['value']?.toString() ?? '',
    );
  }

  String localizedLabel(bool isArabic) => isArabic ? labelAr : labelEn;
}

class SectionFilterField {
  final String key;
  final String labelAr;
  final String labelEn;
  final String type; // text | number | select | multi_select | boolean
  final List<String> options;
  final int sortOrder;

  const SectionFilterField({
    required this.key,
    required this.labelAr,
    required this.labelEn,
    required this.type,
    this.options = const [],
    this.sortOrder = 0,
  });

  factory SectionFilterField.fromJson(Map<String, dynamic> json) {
    final rawOpts = json['options'] as List? ?? const [];
    return SectionFilterField(
      key: json['key']?.toString() ?? json['fieldKey']?.toString() ?? '',
      labelAr: json['labelAr']?.toString() ?? '',
      labelEn: json['labelEn']?.toString() ?? '',
      type: json['type']?.toString() ?? json['fieldType']?.toString() ?? 'text',
      options: rawOpts.map((e) => e.toString()).toList(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  String localizedLabel(bool isArabic) =>
      isArabic && labelAr.isNotEmpty ? labelAr : labelEn;
}

class SectionFilterConfig {
  final String sectionSlug;
  final bool supportsPriceRange;
  final bool supportsLocation;
  final bool supportsCondition;
  final bool supportsListingKind;
  final List<SectionFilterOption> listingKindOptions;
  final List<SectionFilterOption> sortOptions;
  final List<SectionFilterField> fields;

  const SectionFilterConfig({
    required this.sectionSlug,
    this.supportsPriceRange = true,
    this.supportsLocation = true,
    this.supportsCondition = false,
    this.supportsListingKind = false,
    this.listingKindOptions = const [],
    this.sortOptions = const [],
    this.fields = const [],
  });

  factory SectionFilterConfig.fromJson(Map<String, dynamic> json) {
    return SectionFilterConfig(
      sectionSlug: json['sectionSlug']?.toString() ?? '',
      supportsPriceRange: json['supportsPriceRange'] as bool? ?? true,
      supportsLocation: json['supportsLocation'] as bool? ?? true,
      supportsCondition: json['supportsCondition'] as bool? ?? false,
      supportsListingKind: json['supportsListingKind'] as bool? ?? false,
      listingKindOptions: (json['listingKindOptions'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SectionFilterOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      sortOptions: (json['sortOptions'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SectionFilterOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      fields: (json['fields'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SectionFilterField.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class LivePreviewItem {
  final String listingId;
  final String title;
  final double price;
  final String currency;
  final String? imageUrl;
  final int mediaCount;
  final String sellerName;
  final bool isVerified;
  final DateTime? createdAt;

  const LivePreviewItem({
    required this.listingId,
    required this.title,
    required this.price,
    this.currency = 'EGP',
    this.imageUrl,
    this.mediaCount = 1,
    required this.sellerName,
    this.isVerified = false,
    this.createdAt,
  });

  factory LivePreviewItem.fromJson(Map<String, dynamic> json) {
    return LivePreviewItem(
      listingId: json['listingId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'EGP',
      imageUrl: json['imageUrl']?.toString(),
      mediaCount: (json['mediaCount'] as num?)?.toInt() ?? 1,
      sellerName: json['sellerName']?.toString() ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class SectionProviderItem {
  final String id;
  final String displayName;
  final String slug;
  final String accountType;
  final String? logoUrl;
  final bool isVerified;
  final String specialtyAr;
  final String specialtyEn;
  final int listingsCount;

  const SectionProviderItem({
    required this.id,
    required this.displayName,
    required this.slug,
    required this.accountType,
    this.logoUrl,
    this.isVerified = false,
    required this.specialtyAr,
    required this.specialtyEn,
    this.listingsCount = 0,
  });

  factory SectionProviderItem.fromJson(Map<String, dynamic> json) {
    return SectionProviderItem(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      accountType: json['accountType']?.toString() ?? 'individual',
      logoUrl: json['logoUrl']?.toString(),
      isVerified: json['isVerified'] as bool? ?? false,
      specialtyAr: json['specialtyAr']?.toString() ?? '',
      specialtyEn: json['specialtyEn']?.toString() ?? '',
      listingsCount: (json['listingsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class SectionInfo {
  final String id;
  final String slug;
  final String canonicalSlug;
  final String nameAr;
  final String nameEn;
  final String? iconUrl;
  final int sortOrder;
  final int listingsCount;
  final List<CategoryItem> subcategories;

  const SectionInfo({
    required this.id,
    required this.slug,
    required this.canonicalSlug,
    required this.nameAr,
    required this.nameEn,
    this.iconUrl,
    this.sortOrder = 0,
    this.listingsCount = 0,
    this.subcategories = const [],
  });

  factory SectionInfo.fromJson(Map<String, dynamic> json) {
    final rawSubs = json['subcategories'] as List? ?? const [];
    return SectionInfo(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      canonicalSlug:
          json['canonicalSlug']?.toString() ?? json['slug']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      listingsCount: (json['listingsCount'] as num?)?.toInt() ?? 0,
      subcategories: rawSubs
          .whereType<Map>()
          .map(
            (e) => CategoryMapper.toEntity(
              CategoryDto.fromJson(Map<String, dynamic>.from(e)),
            ),
          )
          .toList(),
    );
  }
}

class SectionHomeFeed {
  final String schemaVersion;
  final DateTime? generatedAt;
  final int priceFreshnessTtlSeconds;
  final SectionInfo section;
  final List<HomePromotion> promotions;
  final List<LivePreviewItem> livePreviews;
  final List<ListingItem> featured;
  final List<ListingItem> latest;
  final List<ListingItem> recommended;
  final List<SectionProviderItem> providers;
  final SectionFilterConfig filterConfig;
  final bool isFromCache;

  const SectionHomeFeed({
    this.schemaVersion = '1.0',
    this.generatedAt,
    this.priceFreshnessTtlSeconds = 60,
    required this.section,
    this.promotions = const [],
    this.livePreviews = const [],
    this.featured = const [],
    this.latest = const [],
    this.recommended = const [],
    this.providers = const [],
    required this.filterConfig,
    this.isFromCache = false,
  });

  factory SectionHomeFeed.fromJson(
    Map<String, dynamic> json, {
    bool isFromCache = false,
  }) {
    List<ListingItem> parseListings(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (e) => ListingMapper.toItemEntity(
              ListingItemDto.fromJson(Map<String, dynamic>.from(e)),
            ),
          )
          .toList();
    }

    List<HomePromotion> parsePromos(dynamic raw) {
      if (raw is! List) return const [];
      return raw.whereType<Map>().map((e) {
        final m = Map<String, dynamic>.from(e);
        return HomePromotion(
          id: m['id']?.toString() ?? '',
          badgeAr: m['badgeAr']?.toString() ?? '',
          badgeEn: m['badgeEn']?.toString() ?? '',
          titleAr: m['titleAr']?.toString() ?? '',
          titleEn: m['titleEn']?.toString() ?? '',
          subtitleAr: m['subtitleAr']?.toString() ?? '',
          subtitleEn: m['subtitleEn']?.toString() ?? '',
          ctaAr: m['ctaAr']?.toString() ?? '',
          ctaEn: m['ctaEn']?.toString() ?? '',
          categorySlug: m['categorySlug']?.toString() ?? '',
          imageUrl: m['imageUrl']?.toString() ?? '',
        );
      }).toList();
    }

    final sectionMap = json['section'] is Map
        ? Map<String, dynamic>.from(json['section'] as Map)
        : const <String, dynamic>{};
    final filterMap = json['filterConfig'] is Map
        ? Map<String, dynamic>.from(json['filterConfig'] as Map)
        : const <String, dynamic>{};

    return SectionHomeFeed(
      schemaVersion: json['schemaVersion']?.toString() ?? '1.0',
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString())
          : null,
      priceFreshnessTtlSeconds:
          (json['priceFreshnessTtlSeconds'] as num?)?.toInt() ?? 60,
      section: SectionInfo.fromJson(sectionMap),
      promotions: parsePromos(json['promotions']),
      livePreviews: (json['livePreviews'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => LivePreviewItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      featured: parseListings(json['featured']),
      latest: parseListings(json['latest']),
      recommended: parseListings(json['recommended']),
      providers: (json['providers'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SectionProviderItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      filterConfig: SectionFilterConfig.fromJson(filterMap),
      isFromCache: isFromCache,
    );
  }

  List<String> get allListingIds {
    final ids = <String>{};
    for (final l in featured) {
      ids.add(l.id);
    }
    for (final l in latest) {
      ids.add(l.id);
    }
    for (final l in recommended) {
      ids.add(l.id);
    }
    return ids.toList();
  }
}

class MainHubFeed {
  final String schemaVersion;
  final DateTime? generatedAt;
  final int priceFreshnessTtlSeconds;
  final List<CategoryItem> categories;
  final List<HomePromotion> promotions;
  final List<ListingItem> featured;
  final List<ListingItem> latest;
  final List<ListingItem> recommended;
  final bool isFromCache;

  const MainHubFeed({
    this.schemaVersion = '1.0',
    this.generatedAt,
    this.priceFreshnessTtlSeconds = 60,
    this.categories = const [],
    this.promotions = const [],
    this.featured = const [],
    this.latest = const [],
    this.recommended = const [],
    this.isFromCache = false,
  });

  factory MainHubFeed.fromJson(
    Map<String, dynamic> json, {
    bool isFromCache = false,
  }) {
    List<ListingItem> parseListings(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (e) => ListingMapper.toItemEntity(
              ListingItemDto.fromJson(Map<String, dynamic>.from(e)),
            ),
          )
          .toList();
    }

    final rawCategories = json['categories'] as List? ?? const [];
    final rawPromos = json['promotions'] as List? ?? const [];

    return MainHubFeed(
      schemaVersion: json['schemaVersion']?.toString() ?? '1.0',
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString())
          : null,
      priceFreshnessTtlSeconds:
          (json['priceFreshnessTtlSeconds'] as num?)?.toInt() ?? 60,
      categories: rawCategories
          .whereType<Map>()
          .map(
            (e) => CategoryMapper.toEntity(
              CategoryDto.fromJson(Map<String, dynamic>.from(e)),
            ),
          )
          .toList(),
      promotions: rawPromos.whereType<Map>().map((e) {
        final m = Map<String, dynamic>.from(e);
        return HomePromotion(
          id: m['id']?.toString() ?? '',
          badgeAr: m['badgeAr']?.toString() ?? '',
          badgeEn: m['badgeEn']?.toString() ?? '',
          titleAr: m['titleAr']?.toString() ?? '',
          titleEn: m['titleEn']?.toString() ?? '',
          subtitleAr: m['subtitleAr']?.toString() ?? '',
          subtitleEn: m['subtitleEn']?.toString() ?? '',
          ctaAr: m['ctaAr']?.toString() ?? '',
          ctaEn: m['ctaEn']?.toString() ?? '',
          categorySlug: m['categorySlug']?.toString() ?? '',
          imageUrl: m['imageUrl']?.toString() ?? '',
        );
      }).toList(),
      featured: parseListings(json['featured']),
      latest: parseListings(json['latest']),
      recommended: parseListings(json['recommended']),
      isFromCache: isFromCache,
    );
  }

  List<String> get allListingIds {
    final ids = <String>{};
    for (final l in featured) {
      ids.add(l.id);
    }
    for (final l in latest) {
      ids.add(l.id);
    }
    for (final l in recommended) {
      ids.add(l.id);
    }
    return ids.toList();
  }
}
