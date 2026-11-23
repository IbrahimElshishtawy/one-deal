import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/config/floating_action_config.dart';
import 'package:market_space/core/navigation/config/navigation_item_config.dart';
import 'package:market_space/core/navigation/config/section_navigation_config.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

/// Authoritative navigation configuration registry for Deal One.
/// Keeps [defaultConfig] for global fallback and defines the 6 canonical
/// category section configurations, each with a permanent Universal Map tab.
class SectionNavigationRegistry {
  static const String mapTabId = 'map';

  static const SectionNavigationConfig defaultConfig = SectionNavigationConfig(
    sectionId: 'deal_one',
    sectionName: 'Deal One',
    items: [
      NavigationItemConfig(
        id: 'home',
        label: 'الرئيسية',
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
        destination: '/',
      ),
      NavigationItemConfig(
        id: 'categories',
        label: 'الأقسام',
        activeIcon: Icons.grid_view,
        inactiveIcon: Icons.grid_view_outlined,
        destination: '/categories',
      ),
      NavigationItemConfig(
        id: 'favorites',
        label: 'المفضلة',
        activeIcon: Icons.favorite,
        inactiveIcon: Icons.favorite_outline,
        destination: '/favorites',
      ),
      NavigationItemConfig(
        id: 'profile',
        label: 'حسابي',
        activeIcon: Icons.person,
        inactiveIcon: Icons.person_outline,
        destination: '/profile',
      ),
    ],
    floatingAction: FloatingActionConfig(
      id: 'add_listing',
      label: 'أضف إعلانك',
      icon: Icons.add,
      onPressedRoute: '/listings/create',
    ),
  );

  static SectionNavigationConfig _buildCategoryConfig({
    required String sectionId,
    required String sectionName,
    required String homeRoute,
  }) {
    return SectionNavigationConfig(
      sectionId: sectionId,
      sectionName: sectionName,
      items: [
        NavigationItemConfig(
          id: 'home',
          label: 'الرئيسية',
          activeIcon: Icons.home_rounded,
          inactiveIcon: Icons.home_outlined,
          destination: homeRoute,
        ),
        NavigationItemConfig(
          id: mapTabId,
          label: 'الخريطة',
          activeIcon: Icons.map_rounded,
          inactiveIcon: Icons.map_outlined,
          destination: RouteNames.categoryMapFor(sectionId),
        ),
        const NavigationItemConfig(
          id: 'explore',
          label: 'استكشف',
          activeIcon: Icons.search_rounded,
          inactiveIcon: Icons.search_outlined,
          destination: RouteNames.search,
        ),
        const NavigationItemConfig(
          id: 'favorites',
          label: 'المفضلة',
          activeIcon: Icons.favorite_rounded,
          inactiveIcon: Icons.favorite_border_rounded,
          destination: RouteNames.favorites,
        ),
        const NavigationItemConfig(
          id: 'profile',
          label: 'حسابي',
          activeIcon: Icons.person_rounded,
          inactiveIcon: Icons.person_outline_rounded,
          destination: RouteNames.profile,
        ),
      ],
      floatingAction: const FloatingActionConfig(
        id: 'add_listing',
        label: 'أضف إعلانك',
        icon: Icons.add,
        onPressedRoute: '/listings/create',
      ),
    );
  }

  static final SectionNavigationConfig realEstateConfig = _buildCategoryConfig(
    sectionId: MapCategoryRegistry.realEstateSlug,
    sectionName: 'العقارات والأراضي',
    homeRoute: RouteNames.realEstate,
  );

  static final SectionNavigationConfig servicesConfig = _buildCategoryConfig(
    sectionId: MapCategoryRegistry.servicesSlug,
    sectionName: 'الخدمات والهندسة',
    homeRoute: RouteNames.homeServices,
  );

  static final SectionNavigationConfig buildingMaterialsConfig =
      _buildCategoryConfig(
        sectionId: MapCategoryRegistry.buildingMaterialsSlug,
        sectionName: 'مواد البناء والكهرباء',
        homeRoute: RouteNames.buildingMaterials,
      );

  static final SectionNavigationConfig homeAppliancesConfig =
      _buildCategoryConfig(
        sectionId: MapCategoryRegistry.homeAppliancesSlug,
        sectionName: 'الأجهزة والديكور',
        homeRoute: RouteNames.homeAppliances,
      );

  static final SectionNavigationConfig carsConfig = _buildCategoryConfig(
    sectionId: MapCategoryRegistry.carsSlug,
    sectionName: 'السيارات والصيانة',
    homeRoute: RouteNames.cars,
  );

  static final SectionNavigationConfig fashionConfig = _buildCategoryConfig(
    sectionId: MapCategoryRegistry.fashionSlug,
    sectionName: 'الأزياء والإكسسوارات',
    homeRoute: RouteNames.fashion,
  );

  static final Map<String, SectionNavigationConfig> _registry = {
    'deal_one': defaultConfig,
    MapCategoryRegistry.realEstateSlug: realEstateConfig,
    MapCategoryRegistry.servicesSlug: servicesConfig,
    MapCategoryRegistry.buildingMaterialsSlug: buildingMaterialsConfig,
    MapCategoryRegistry.homeAppliancesSlug: homeAppliancesConfig,
    MapCategoryRegistry.carsSlug: carsConfig,
    MapCategoryRegistry.fashionSlug: fashionConfig,
  };

  static SectionNavigationConfig getConfig(String sectionId) {
    final direct = _registry[sectionId];
    if (direct != null) return direct;
    final normalized = MapCategoryRegistry.normalizeSlug(sectionId);
    return _registry[normalized] ?? defaultConfig;
  }

  static List<SectionNavigationConfig> get sixCategoryConfigs => [
    realEstateConfig,
    servicesConfig,
    buildingMaterialsConfig,
    homeAppliancesConfig,
    carsConfig,
    fashionConfig,
  ];

  static List<SectionNavigationConfig> get allConfigs =>
      _registry.values.toList();
}
