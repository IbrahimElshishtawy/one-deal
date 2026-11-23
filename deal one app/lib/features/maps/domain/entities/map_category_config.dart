import 'package:flutter/material.dart';

/// Filter definition specific to a Deal One category on the map.
class MapCategoryFilterOption {
  final String id;
  final String labelAr;
  final String labelEn;
  final IconData icon;
  final String? listingKind;
  final String? condition;
  final bool? featuredOnly;
  final bool? verifiedOnly;

  const MapCategoryFilterOption({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.icon,
    this.listingKind,
    this.condition,
    this.featuredOnly,
    this.verifiedOnly,
  });

  String localizedLabel(bool isArabic) => isArabic ? labelAr : labelEn;
}

/// Configuration describing how the universal map adapts its context,
/// visual identity, copy, and filters for each of the 6 Deal One categories.
class MapCategoryConfig {
  final String slug;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final String searchHintAr;
  final String searchHintEn;
  final String emptyMessageAr;
  final String emptyMessageEn;
  final String placeTypeLabelAr;
  final String placeTypeLabelEn;
  final IconData markerIcon;
  final Color accentColor;
  final List<MapCategoryFilterOption> quickFilters;

  const MapCategoryConfig({
    required this.slug,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.searchHintAr,
    required this.searchHintEn,
    required this.emptyMessageAr,
    required this.emptyMessageEn,
    required this.placeTypeLabelAr,
    required this.placeTypeLabelEn,
    required this.markerIcon,
    required this.accentColor,
    required this.quickFilters,
  });

  String localizedTitle(bool isArabic) => isArabic ? titleAr : titleEn;
  String localizedSubtitle(bool isArabic) => isArabic ? subtitleAr : subtitleEn;
  String localizedSearchHint(bool isArabic) =>
      isArabic ? searchHintAr : searchHintEn;
  String localizedEmptyMessage(bool isArabic) =>
      isArabic ? emptyMessageAr : emptyMessageEn;
  String localizedPlaceType(bool isArabic) =>
      isArabic ? placeTypeLabelAr : placeTypeLabelEn;
}

/// Canonical registry of all 6 Deal One category map configurations.
class MapCategoryRegistry {
  MapCategoryRegistry._();

  static const String realEstateSlug = 'real-estate';
  static const String servicesSlug = 'services';
  static const String buildingMaterialsSlug = 'building-materials';
  static const String homeAppliancesSlug = 'home-appliances';
  static const String carsSlug = 'cars';
  static const String fashionSlug = 'fashion';

  static const List<String> allSixSlugs = [
    realEstateSlug,
    servicesSlug,
    buildingMaterialsSlug,
    homeAppliancesSlug,
    carsSlug,
    fashionSlug,
  ];

  static const Map<String, MapCategoryConfig> _configs = {
    realEstateSlug: MapCategoryConfig(
      slug: realEstateSlug,
      titleAr: 'خريطة العقارات والأراضي',
      titleEn: 'Real Estate & Lands Map',
      subtitleAr: 'مواقع العقارات والأراضي المعروضة',
      subtitleEn: 'Available properties & lands nearby',
      searchHintAr: 'ابحث عن شقة، فيلا، أو أرض على الخريطة...',
      searchHintEn: 'Search apartments, villas, or lands on map...',
      emptyMessageAr: 'لا توجد عقارات أو أراضٍ في نطاق البحث الحالي',
      emptyMessageEn: 'No properties or lands found in the current area',
      placeTypeLabelAr: 'عقار',
      placeTypeLabelEn: 'Property',
      markerIcon: Icons.apartment_rounded,
      accentColor: Color(0xFF1B2A4A),
      quickFilters: [
        MapCategoryFilterOption(
          id: 'all',
          labelAr: 'الكل',
          labelEn: 'All',
          icon: Icons.apps_rounded,
        ),
        MapCategoryFilterOption(
          id: 'sale',
          labelAr: 'للبيع',
          labelEn: 'For Sale',
          icon: Icons.home_outlined,
          listingKind: 'sale',
        ),
        MapCategoryFilterOption(
          id: 'rent',
          labelAr: 'للإيجار',
          labelEn: 'For Rent',
          icon: Icons.key_outlined,
          listingKind: 'rent',
        ),
        MapCategoryFilterOption(
          id: 'verified',
          labelAr: 'معلن موثق',
          labelEn: 'Verified',
          icon: Icons.verified_outlined,
          verifiedOnly: true,
        ),
      ],
    ),
    servicesSlug: MapCategoryConfig(
      slug: servicesSlug,
      titleAr: 'خريطة الخدمات والهندسة',
      titleEn: 'Services & Engineering Map',
      subtitleAr: 'مواقع مقدمي الخدمات والمهندسين والفنيين',
      subtitleEn: 'Service providers, engineers & technicians',
      searchHintAr: 'ابحث عن مهندس، فني، أو مقدم خدمة...',
      searchHintEn: 'Search engineers, technicians, or providers...',
      emptyMessageAr: 'لا يوجد مقدمو خدمات في نطاق البحث الحالي',
      emptyMessageEn: 'No service providers found in the current area',
      placeTypeLabelAr: 'مقدم خدمة',
      placeTypeLabelEn: 'Provider',
      markerIcon: Icons.engineering_rounded,
      accentColor: Color(0xFF0F766E),
      quickFilters: [
        MapCategoryFilterOption(
          id: 'all',
          labelAr: 'الكل',
          labelEn: 'All',
          icon: Icons.apps_rounded,
        ),
        MapCategoryFilterOption(
          id: 'verified',
          labelAr: 'معتمدون',
          labelEn: 'Verified',
          icon: Icons.verified_user_outlined,
          verifiedOnly: true,
        ),
        MapCategoryFilterOption(
          id: 'featured',
          labelAr: 'مميزون',
          labelEn: 'Featured',
          icon: Icons.star_outline_rounded,
          featuredOnly: true,
        ),
      ],
    ),
    buildingMaterialsSlug: MapCategoryConfig(
      slug: buildingMaterialsSlug,
      titleAr: 'خريطة مواد البناء والكهرباء',
      titleEn: 'Building Materials & Electricity Map',
      subtitleAr: 'مواقع المحلات والموردين والمعارض',
      subtitleEn: 'Suppliers, stores & showrooms',
      searchHintAr: 'ابحث عن مورد، معرض، أو محل مواد بناء...',
      searchHintEn: 'Search suppliers, stores, or electrical shops...',
      emptyMessageAr: 'لا توجد محلات أو موردون في نطاق البحث الحالي',
      emptyMessageEn: 'No stores or suppliers found in the current area',
      placeTypeLabelAr: 'مورد / محل',
      placeTypeLabelEn: 'Supplier',
      markerIcon: Icons.construction_rounded,
      accentColor: Color(0xFFB45309),
      quickFilters: [
        MapCategoryFilterOption(
          id: 'all',
          labelAr: 'الكل',
          labelEn: 'All',
          icon: Icons.apps_rounded,
        ),
        MapCategoryFilterOption(
          id: 'new',
          labelAr: 'جديد',
          labelEn: 'New',
          icon: Icons.new_releases_outlined,
          condition: 'NEW',
        ),
        MapCategoryFilterOption(
          id: 'verified',
          labelAr: 'مورد موثق',
          labelEn: 'Verified',
          icon: Icons.verified_outlined,
          verifiedOnly: true,
        ),
        MapCategoryFilterOption(
          id: 'featured',
          labelAr: 'عروض مميزة',
          labelEn: 'Featured',
          icon: Icons.local_offer_outlined,
          featuredOnly: true,
        ),
      ],
    ),
    homeAppliancesSlug: MapCategoryConfig(
      slug: homeAppliancesSlug,
      titleAr: 'خريطة الأجهزة والديكور',
      titleEn: 'Appliances & Decor Map',
      subtitleAr: 'مواقع متاجر الأجهزة والأثاث والديكور',
      subtitleEn: 'Appliances, furniture & decor stores',
      searchHintAr: 'ابحث عن متجر أجهزة، أثاث، أو ديكور...',
      searchHintEn: 'Search appliance, furniture, or decor stores...',
      emptyMessageAr: 'لا توجد متاجر أجهزة أو ديكور في نطاق البحث الحالي',
      emptyMessageEn: 'No appliance or decor stores found in this area',
      placeTypeLabelAr: 'متجر',
      placeTypeLabelEn: 'Store',
      markerIcon: Icons.chair_rounded,
      accentColor: Color(0xFF4338CA),
      quickFilters: [
        MapCategoryFilterOption(
          id: 'all',
          labelAr: 'الكل',
          labelEn: 'All',
          icon: Icons.apps_rounded,
        ),
        MapCategoryFilterOption(
          id: 'new',
          labelAr: 'جديد',
          labelEn: 'New',
          icon: Icons.fiber_new_outlined,
          condition: 'NEW',
        ),
        MapCategoryFilterOption(
          id: 'used',
          labelAr: 'مستعمل',
          labelEn: 'Used',
          icon: Icons.recycling_outlined,
          condition: 'USED',
        ),
        MapCategoryFilterOption(
          id: 'verified',
          labelAr: 'متجر موثق',
          labelEn: 'Verified',
          icon: Icons.verified_outlined,
          verifiedOnly: true,
        ),
      ],
    ),
    carsSlug: MapCategoryConfig(
      slug: carsSlug,
      titleAr: 'خريطة السيارات والصيانة',
      titleEn: 'Cars & Maintenance Map',
      subtitleAr: 'مواقع معارض السيارات ومراكز الصيانة وقطع الغيار',
      subtitleEn: 'Showrooms, service centers & spare parts',
      searchHintAr: 'ابحث عن معرض سيارات، مركز صيانة، أو قطع غيار...',
      searchHintEn: 'Search showrooms, maintenance, or spare parts...',
      emptyMessageAr: 'لا توجد معارض أو مراكز صيانة في نطاق البحث الحالي',
      emptyMessageEn: 'No showrooms or service centers found in this area',
      placeTypeLabelAr: 'معرض / مركز',
      placeTypeLabelEn: 'Showroom',
      markerIcon: Icons.directions_car_rounded,
      accentColor: Color(0xFF1D4ED8),
      quickFilters: [
        MapCategoryFilterOption(
          id: 'all',
          labelAr: 'الكل',
          labelEn: 'All',
          icon: Icons.apps_rounded,
        ),
        MapCategoryFilterOption(
          id: 'new',
          labelAr: 'زيرو / جديد',
          labelEn: 'New',
          icon: Icons.directions_car_filled_outlined,
          condition: 'NEW',
        ),
        MapCategoryFilterOption(
          id: 'used',
          labelAr: 'مستعمل',
          labelEn: 'Used',
          icon: Icons.car_rental_outlined,
          condition: 'USED',
        ),
        MapCategoryFilterOption(
          id: 'verified',
          labelAr: 'معرض موثق',
          labelEn: 'Verified',
          icon: Icons.verified_outlined,
          verifiedOnly: true,
        ),
      ],
    ),
    fashionSlug: MapCategoryConfig(
      slug: fashionSlug,
      titleAr: 'خريطة الأزياء والإكسسوارات',
      titleEn: 'Fashion & Accessories Map',
      subtitleAr: 'مواقع محلات الملابس والأحذية والإكسسوارات',
      subtitleEn: 'Clothing, footwear & accessories shops',
      searchHintAr: 'ابحث عن محل ملابس، أحذية، أو إكسسوارات...',
      searchHintEn: 'Search clothing, shoes, or accessories shops...',
      emptyMessageAr: 'لا توجد محلات أزياء أو إكسسوارات في نطاق البحث الحالي',
      emptyMessageEn: 'No fashion or accessories shops found in this area',
      placeTypeLabelAr: 'محل أزياء',
      placeTypeLabelEn: 'Boutique',
      markerIcon: Icons.checkroom_rounded,
      accentColor: Color(0xFF9D174D),
      quickFilters: [
        MapCategoryFilterOption(
          id: 'all',
          labelAr: 'الكل',
          labelEn: 'All',
          icon: Icons.apps_rounded,
        ),
        MapCategoryFilterOption(
          id: 'new',
          labelAr: 'جديد',
          labelEn: 'New',
          icon: Icons.checkroom_outlined,
          condition: 'NEW',
        ),
        MapCategoryFilterOption(
          id: 'featured',
          labelAr: 'عروض مميزة',
          labelEn: 'Featured',
          icon: Icons.local_offer_outlined,
          featuredOnly: true,
        ),
        MapCategoryFilterOption(
          id: 'verified',
          labelAr: 'متجر موثق',
          labelEn: 'Verified',
          icon: Icons.verified_outlined,
          verifiedOnly: true,
        ),
      ],
    ),
  };

  /// Normalizes known aliases (e.g. `home-services` -> `services`) to canonical slugs.
  static String normalizeSlug(String rawSlug) {
    final cleaned = rawSlug.trim().toLowerCase().replaceAll('_', '-');
    switch (cleaned) {
      case 'home-services':
      case 'services-engineering':
        return servicesSlug;
      case 'construction-electrical':
        return buildingMaterialsSlug;
      case 'appliances-decor':
        return homeAppliancesSlug;
      case 'cars-maintenance':
        return carsSlug;
      case 'fashion-accessories':
        return fashionSlug;
      default:
        return _configs.containsKey(cleaned) ? cleaned : realEstateSlug;
    }
  }

  static MapCategoryConfig forSlug(String slug) {
    return _configs[normalizeSlug(slug)] ?? _configs[realEstateSlug]!;
  }

  static List<MapCategoryConfig> get allConfigs =>
      allSixSlugs.map((slug) => _configs[slug]!).toList(growable: false);
}
