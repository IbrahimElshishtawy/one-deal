import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/config/floating_action_config.dart';
import 'package:market_space/core/navigation/config/navigation_item_config.dart';
import 'package:market_space/core/navigation/config/section_navigation_config.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

/// Authoritative dynamic navigation configuration registry for Deal One.
///
/// Builds independent, category-isolated navigation configurations for all 6
/// marketplace sections based on verified backend [AccountCapabilities]:
/// - Buyer / non-activated accounts see `Favorites` in slot 5.
/// - Activated sellers/providers see their category-specific seller action
///   (`My Listings`, `My Services`, or `My Products`) in slot 5.
/// - Real Estate removes `Reels` from Bottom Navigation and places `Chat` in slot 4.
class SectionNavigationRegistry {
  static const String homeTabId = 'home';
  static const String exploreTabId = 'explore';
  static const String categoriesTabId = 'categories';
  static const String mapTabId = 'map';
  static const String chatTabId = 'chat';
  static const String myBookingsTabId = 'my_bookings';
  static const String priceRequestsTabId = 'price_requests';
  static const String cartTabId = 'cart';
  static const String maintenanceTabId = 'maintenance';
  static const String favoritesTabId = 'favorites';
  static const String myListingsTabId = 'my_listings';
  static const String myServicesTabId = 'my_services';
  static const String myProductsTabId = 'my_products';

  static const SectionNavigationConfig defaultConfig = SectionNavigationConfig(
    sectionId: 'deal_one',
    sectionName: 'DealOne',
    items: [
      NavigationItemConfig(
        id: homeTabId,
        label: 'الرئيسية',
        labelEn: 'Home',
        activeIcon: Icons.home_rounded,
        inactiveIcon: Icons.home_outlined,
        destination: RouteNames.root,
      ),
      NavigationItemConfig(
        id: categoriesTabId,
        label: 'الأقسام',
        labelEn: 'Categories',
        activeIcon: Icons.grid_view_rounded,
        inactiveIcon: Icons.grid_view_outlined,
        destination: RouteNames.root,
      ),
      NavigationItemConfig(
        id: favoritesTabId,
        label: 'المفضلة',
        labelEn: 'Favorites',
        activeIcon: Icons.favorite_rounded,
        inactiveIcon: Icons.favorite_border_rounded,
        destination: RouteNames.favorites,
      ),
      NavigationItemConfig(
        id: 'profile',
        label: 'حسابي',
        labelEn: 'Profile',
        activeIcon: Icons.person_rounded,
        inactiveIcon: Icons.person_outline_rounded,
        destination: RouteNames.profile,
      ),
    ],
    floatingAction: FloatingActionConfig(
      id: 'add_listing',
      label: 'أضف إعلانك',
      icon: Icons.add,
      onPressedRoute: RouteNames.createListing,
    ),
  );

  static NavigationItemConfig _favoritesItem(String sectionId) {
    return NavigationItemConfig(
      id: favoritesTabId,
      label: 'المفضلة',
      labelEn: 'Favorites',
      activeIcon: Icons.favorite_rounded,
      inactiveIcon: Icons.favorite_border_rounded,
      destination: RouteNames.favorites,
      requiredCapability: NavigationCapability.none,
      visibilityRule: NavigationVisibilityRule.buyerOnly,
      categoryContext: sectionId,
    );
  }

  /// Resolves the dynamic navigation configuration for [sectionId] using
  /// verified backend [capabilities].
  static SectionNavigationConfig resolveConfig(
    String sectionId,
    AccountCapabilities capabilities,
  ) {
    final normalized = MapCategoryRegistry.normalizeSlug(sectionId);
    if (sectionId == 'deal_one') return defaultConfig;

    switch (normalized) {
      case MapCategoryRegistry.realEstateSlug:
        return _buildRealEstateConfig(capabilities);
      case MapCategoryRegistry.servicesSlug:
        return _buildServicesConfig(capabilities);
      case MapCategoryRegistry.buildingMaterialsSlug:
        return _buildBuildingMaterialsConfig(capabilities);
      case MapCategoryRegistry.homeAppliancesSlug:
        return _buildHomeAppliancesConfig(capabilities);
      case MapCategoryRegistry.carsSlug:
        return _buildCarsConfig(capabilities);
      case MapCategoryRegistry.fashionSlug:
        return _buildFashionConfig(capabilities);
      default:
        return defaultConfig;
    }
  }

  /// A. Real Estate & Lands:
  /// 1. Home | 2. Explore | 3. Map | 4. Chat | 5. My Listings (activated) / Favorites (buyer)
  /// Reels is explicitly removed from bottom navigation.
  static SectionNavigationConfig _buildRealEstateConfig(
    AccountCapabilities capabilities,
  ) {
    const slug = MapCategoryRegistry.realEstateSlug;
    final isActivated = capabilities.canManageRealEstateListings;

    return SectionNavigationConfig(
      sectionId: slug,
      sectionName: 'العقارات والأراضي',
      items: [
        const NavigationItemConfig(
          id: homeTabId,
          label: 'الرئيسية',
          labelEn: 'Home',
          activeIcon: Icons.home_rounded,
          inactiveIcon: Icons.home_outlined,
          destination: RouteNames.realEstate,
          categoryContext: slug,
        ),
        const NavigationItemConfig(
          id: exploreTabId,
          label: 'استكشف',
          labelEn: 'Explore',
          activeIcon: Icons.explore_rounded,
          inactiveIcon: Icons.explore_outlined,
          destination: RouteNames.search,
          categoryContext: slug,
        ),
        NavigationItemConfig(
          id: mapTabId,
          label: 'الخريطة',
          labelEn: 'Map',
          activeIcon: Icons.map_rounded,
          inactiveIcon: Icons.map_outlined,
          destination: RouteNames.categoryMapFor(slug),
          categoryContext: slug,
        ),
        const NavigationItemConfig(
          id: chatTabId,
          label: 'المحادثات',
          labelEn: 'Chat',
          activeIcon: Icons.chat_bubble_rounded,
          inactiveIcon: Icons.chat_bubble_outline_rounded,
          destination: RouteNames.conversations,
          badgeKey: 'chat_unread',
          categoryContext: slug,
        ),
        if (isActivated)
          NavigationItemConfig(
            id: myListingsTabId,
            label: 'إعلاناتي',
            labelEn: 'My Listings',
            activeIcon: Icons.real_estate_agent_rounded,
            inactiveIcon: Icons.real_estate_agent_outlined,
            destination: RouteNames.sellerManagementFor(slug, 'listings'),
            requiredCapability: NavigationCapability.manageRealEstateListings,
            visibilityRule: NavigationVisibilityRule.sellerOnly,
            categoryContext: slug,
            requiresPermission: true,
          )
        else
          _favoritesItem(slug),
      ],
      floatingAction: isActivated
          ? FloatingActionConfig(
              id: 'create_real_estate_listing',
              label: 'أضف عقارك',
              icon: Icons.add,
              onPressedRoute: RouteNames.createListingFor(slug),
            )
          : null,
    );
  }

  /// B. Services & Engineering:
  /// 1. Home | 2. Explore | 3. Map | 4. My Bookings | 5. My Services (activated) / Favorites (buyer)
  static SectionNavigationConfig _buildServicesConfig(
    AccountCapabilities capabilities,
  ) {
    const slug = MapCategoryRegistry.servicesSlug;
    final isActivated = capabilities.canManageEngineeringServices;

    return SectionNavigationConfig(
      sectionId: slug,
      sectionName: 'الخدمات والهندسة',
      items: [
        const NavigationItemConfig(
          id: homeTabId,
          label: 'الرئيسية',
          labelEn: 'Home',
          activeIcon: Icons.home_rounded,
          inactiveIcon: Icons.home_outlined,
          destination: RouteNames.homeServices,
          categoryContext: slug,
        ),
        const NavigationItemConfig(
          id: exploreTabId,
          label: 'استكشف',
          labelEn: 'Explore',
          activeIcon: Icons.explore_rounded,
          inactiveIcon: Icons.explore_outlined,
          destination: RouteNames.search,
          categoryContext: slug,
        ),
        NavigationItemConfig(
          id: mapTabId,
          label: 'الخريطة',
          labelEn: 'Map',
          activeIcon: Icons.map_rounded,
          inactiveIcon: Icons.map_outlined,
          destination: RouteNames.categoryMapFor(slug),
          categoryContext: slug,
        ),
        NavigationItemConfig(
          id: myBookingsTabId,
          label: 'حجوزاتي',
          labelEn: 'My Bookings',
          activeIcon: Icons.calendar_month_rounded,
          inactiveIcon: Icons.calendar_month_outlined,
          destination: RouteNames.activityHubFor(
            tab: 'bookings',
            categorySlug: slug,
          ),
          categoryContext: slug,
        ),
        if (isActivated)
          NavigationItemConfig(
            id: myServicesTabId,
            label: 'خدماتي',
            labelEn: 'My Services',
            activeIcon: Icons.engineering_rounded,
            inactiveIcon: Icons.engineering_outlined,
            destination: RouteNames.sellerManagementFor(slug, 'services'),
            requiredCapability: NavigationCapability.manageEngineeringServices,
            visibilityRule: NavigationVisibilityRule.sellerOnly,
            categoryContext: slug,
            requiresPermission: true,
          )
        else
          _favoritesItem(slug),
      ],
      floatingAction: isActivated
          ? FloatingActionConfig(
              id: 'create_service',
              label: 'أضف خدمة',
              icon: Icons.add,
              onPressedRoute: RouteNames.createListingFor(
                slug,
                listingKind: 'service',
              ),
            )
          : null,
    );
  }

  /// C. Building Materials & Electricity:
  /// 1. Home | 2. Categories | 3. Map | 4. Price Requests | 5. My Products (activated) / Favorites (buyer)
  static SectionNavigationConfig _buildBuildingMaterialsConfig(
    AccountCapabilities capabilities,
  ) {
    const slug = MapCategoryRegistry.buildingMaterialsSlug;
    final isActivated = capabilities.canManageBuildingMaterialsProducts;

    return SectionNavigationConfig(
      sectionId: slug,
      sectionName: 'مواد البناء والكهرباء',
      items: [
        const NavigationItemConfig(
          id: homeTabId,
          label: 'الرئيسية',
          labelEn: 'Home',
          activeIcon: Icons.home_rounded,
          inactiveIcon: Icons.home_outlined,
          destination: RouteNames.buildingMaterials,
          categoryContext: slug,
        ),
        NavigationItemConfig(
          id: categoriesTabId,
          label: 'الأقسام',
          labelEn: 'Categories',
          activeIcon: Icons.grid_view_rounded,
          inactiveIcon: Icons.grid_view_outlined,
          destination: RouteNames.sectionCategoriesFor(slug),
          categoryContext: slug,
        ),
        NavigationItemConfig(
          id: mapTabId,
          label: 'الخريطة',
          labelEn: 'Map',
          activeIcon: Icons.map_rounded,
          inactiveIcon: Icons.map_outlined,
          destination: RouteNames.categoryMapFor(slug),
          categoryContext: slug,
        ),
        NavigationItemConfig(
          id: priceRequestsTabId,
          label: 'طلبات الأسعار',
          labelEn: 'Price Requests',
          activeIcon: Icons.request_quote_rounded,
          inactiveIcon: Icons.request_quote_outlined,
          destination: RouteNames.activityHubFor(
            tab: 'rfq',
            categorySlug: slug,
          ),
          categoryContext: slug,
        ),
        if (isActivated)
          NavigationItemConfig(
            id: myProductsTabId,
            label: 'منتجاتي',
            labelEn: 'My Products',
            activeIcon: Icons.inventory_2_rounded,
            inactiveIcon: Icons.inventory_2_outlined,
            destination: RouteNames.sellerManagementFor(slug, 'products'),
            requiredCapability:
                NavigationCapability.manageBuildingMaterialsProducts,
            visibilityRule: NavigationVisibilityRule.sellerOnly,
            categoryContext: slug,
            requiresPermission: true,
          )
        else
          _favoritesItem(slug),
      ],
      floatingAction: isActivated
          ? FloatingActionConfig(
              id: 'create_material_product',
              label: 'أضف منتج',
              icon: Icons.add,
              onPressedRoute: RouteNames.createListingFor(
                slug,
                listingKind: 'product',
              ),
            )
          : null,
    );
  }

  /// D. Appliances & Decor:
  /// 1. Home | 2. Categories | 3. Map | 4. Cart | 5. My Listings (activated) / Favorites (buyer)
  static SectionNavigationConfig _buildHomeAppliancesConfig(
    AccountCapabilities capabilities,
  ) {
    const slug = MapCategoryRegistry.homeAppliancesSlug;
    final isActivated = capabilities.canManageAppliancesListings;

    return SectionNavigationConfig(
      sectionId: slug,
      sectionName: 'الأجهزة والديكور',
      items: [
        const NavigationItemConfig(
          id: homeTabId,
          label: 'الرئيسية',
          labelEn: 'Home',
          activeIcon: Icons.home_rounded,
          inactiveIcon: Icons.home_outlined,
          destination: RouteNames.homeAppliances,
          categoryContext: slug,
        ),
        NavigationItemConfig(
          id: categoriesTabId,
          label: 'الأقسام',
          labelEn: 'Categories',
          activeIcon: Icons.grid_view_rounded,
          inactiveIcon: Icons.grid_view_outlined,
          destination: RouteNames.sectionCategoriesFor(slug),
          categoryContext: slug,
        ),
        NavigationItemConfig(
          id: mapTabId,
          label: 'الخريطة',
          labelEn: 'Map',
          activeIcon: Icons.map_rounded,
          inactiveIcon: Icons.map_outlined,
          destination: RouteNames.categoryMapFor(slug),
          categoryContext: slug,
        ),
        NavigationItemConfig(
          id: cartTabId,
          label: 'السلة',
          labelEn: 'Cart',
          activeIcon: Icons.shopping_bag_rounded,
          inactiveIcon: Icons.shopping_bag_outlined,
          destination: RouteNames.activityHubFor(
            tab: 'cart',
            categorySlug: slug,
          ),
          requiredCapability: NavigationCapability.useSavedCart,
          visibilityRule: NavigationVisibilityRule.whenSupported,
          badgeKey: 'cart_count',
          categoryContext: slug,
        ),
        if (isActivated)
          NavigationItemConfig(
            id: myListingsTabId,
            label: 'إعلاناتي',
            labelEn: 'My Listings',
            activeIcon: Icons.storefront_rounded,
            inactiveIcon: Icons.storefront_outlined,
            destination: RouteNames.sellerManagementFor(slug, 'listings'),
            requiredCapability: NavigationCapability.manageAppliancesListings,
            visibilityRule: NavigationVisibilityRule.sellerOnly,
            categoryContext: slug,
            requiresPermission: true,
          )
        else
          _favoritesItem(slug),
      ],
      floatingAction: isActivated
          ? FloatingActionConfig(
              id: 'create_appliance_listing',
              label: 'أضف إعلانك',
              icon: Icons.add,
              onPressedRoute: RouteNames.createListingFor(slug),
            )
          : null,
    );
  }

  /// E. Cars & Maintenance:
  /// 1. Home | 2. Explore | 3. Map | 4. Maintenance | 5. My Services (activated) / Favorites (buyer)
  static SectionNavigationConfig _buildCarsConfig(
    AccountCapabilities capabilities,
  ) {
    const slug = MapCategoryRegistry.carsSlug;
    final isActivated = capabilities.canManageAutomotiveMaintenanceServices;

    return SectionNavigationConfig(
      sectionId: slug,
      sectionName: 'السيارات والصيانة',
      items: [
        const NavigationItemConfig(
          id: homeTabId,
          label: 'الرئيسية',
          labelEn: 'Home',
          activeIcon: Icons.home_rounded,
          inactiveIcon: Icons.home_outlined,
          destination: RouteNames.cars,
          categoryContext: slug,
        ),
        const NavigationItemConfig(
          id: exploreTabId,
          label: 'استكشف',
          labelEn: 'Explore',
          activeIcon: Icons.explore_rounded,
          inactiveIcon: Icons.explore_outlined,
          destination: RouteNames.search,
          categoryContext: slug,
        ),
        NavigationItemConfig(
          id: mapTabId,
          label: 'الخريطة',
          labelEn: 'Map',
          activeIcon: Icons.map_rounded,
          inactiveIcon: Icons.map_outlined,
          destination: RouteNames.categoryMapFor(slug),
          categoryContext: slug,
        ),
        NavigationItemConfig(
          id: maintenanceTabId,
          label: 'الصيانة',
          labelEn: 'Maintenance',
          activeIcon: Icons.car_repair_rounded,
          inactiveIcon: Icons.car_repair_outlined,
          destination: RouteNames.activityHubFor(
            tab: 'bookings',
            categorySlug: slug,
          ),
          categoryContext: slug,
        ),
        if (isActivated)
          NavigationItemConfig(
            id: myServicesTabId,
            label: 'خدماتي',
            labelEn: 'My Services',
            activeIcon: Icons.build_circle_rounded,
            inactiveIcon: Icons.build_circle_outlined,
            destination: RouteNames.sellerManagementFor(slug, 'services'),
            requiredCapability:
                NavigationCapability.manageAutomotiveMaintenanceServices,
            visibilityRule: NavigationVisibilityRule.sellerOnly,
            categoryContext: slug,
            requiresPermission: true,
          )
        else
          _favoritesItem(slug),
      ],
      floatingAction: isActivated
          ? FloatingActionConfig(
              id: 'create_maintenance_service',
              label: 'أضف خدمة صيانة',
              icon: Icons.add,
              onPressedRoute: RouteNames.createListingFor(
                slug,
                listingKind: 'service',
              ),
            )
          : null,
    );
  }

  /// F. Fashion & Accessories:
  /// 1. Home | 2. Categories | 3. Map | 4. Cart (only if supported) | 5. My Listings (activated) / Favorites (buyer)
  static SectionNavigationConfig _buildFashionConfig(
    AccountCapabilities capabilities,
  ) {
    const slug = MapCategoryRegistry.fashionSlug;
    final isActivated = capabilities.canManageFashionListings;
    final showCart = capabilities.hasCapability(
      NavigationCapability.useSavedCart,
    );

    return SectionNavigationConfig(
      sectionId: slug,
      sectionName: 'الأزياء والإكسسوارات',
      items: [
        const NavigationItemConfig(
          id: homeTabId,
          label: 'الرئيسية',
          labelEn: 'Home',
          activeIcon: Icons.home_rounded,
          inactiveIcon: Icons.home_outlined,
          destination: RouteNames.fashion,
          categoryContext: slug,
        ),
        NavigationItemConfig(
          id: categoriesTabId,
          label: 'الأقسام',
          labelEn: 'Categories',
          activeIcon: Icons.grid_view_rounded,
          inactiveIcon: Icons.grid_view_outlined,
          destination: RouteNames.sectionCategoriesFor(slug),
          categoryContext: slug,
        ),
        NavigationItemConfig(
          id: mapTabId,
          label: 'الخريطة',
          labelEn: 'Map',
          activeIcon: Icons.map_rounded,
          inactiveIcon: Icons.map_outlined,
          destination: RouteNames.categoryMapFor(slug),
          categoryContext: slug,
        ),
        if (showCart)
          NavigationItemConfig(
            id: cartTabId,
            label: 'السلة',
            labelEn: 'Cart',
            activeIcon: Icons.shopping_bag_rounded,
            inactiveIcon: Icons.shopping_bag_outlined,
            destination: RouteNames.activityHubFor(
              tab: 'cart',
              categorySlug: slug,
            ),
            requiredCapability: NavigationCapability.useSavedCart,
            visibilityRule: NavigationVisibilityRule.whenSupported,
            badgeKey: 'cart_count',
            categoryContext: slug,
          ),
        if (isActivated)
          NavigationItemConfig(
            id: myListingsTabId,
            label: 'إعلاناتي',
            labelEn: 'My Listings',
            activeIcon: Icons.checkroom_rounded,
            inactiveIcon: Icons.checkroom_outlined,
            destination: RouteNames.sellerManagementFor(slug, 'listings'),
            requiredCapability: NavigationCapability.manageFashionListings,
            visibilityRule: NavigationVisibilityRule.sellerOnly,
            categoryContext: slug,
            requiresPermission: true,
          )
        else
          _favoritesItem(slug),
      ],
      floatingAction: isActivated
          ? FloatingActionConfig(
              id: 'create_fashion_listing',
              label: 'أضف إعلانك',
              icon: Icons.add,
              onPressedRoute: RouteNames.createListingFor(slug),
            )
          : null,
    );
  }

  /// Default (buyer-safe) static getters preserved for backward compatibility.
  static SectionNavigationConfig get realEstateConfig =>
      resolveConfig(MapCategoryRegistry.realEstateSlug, const AccountCapabilities.guest());

  static SectionNavigationConfig get servicesConfig =>
      resolveConfig(MapCategoryRegistry.servicesSlug, const AccountCapabilities.guest());

  static SectionNavigationConfig get buildingMaterialsConfig =>
      resolveConfig(MapCategoryRegistry.buildingMaterialsSlug, const AccountCapabilities.guest());

  static SectionNavigationConfig get homeAppliancesConfig =>
      resolveConfig(MapCategoryRegistry.homeAppliancesSlug, const AccountCapabilities.guest());

  static SectionNavigationConfig get carsConfig =>
      resolveConfig(MapCategoryRegistry.carsSlug, const AccountCapabilities.guest());

  static SectionNavigationConfig get fashionConfig =>
      resolveConfig(MapCategoryRegistry.fashionSlug, const AccountCapabilities.guest());

  static SectionNavigationConfig getConfig(
    String sectionId, {
    AccountCapabilities capabilities = const AccountCapabilities.guest(),
  }) {
    return resolveConfig(sectionId, capabilities);
  }

  static List<SectionNavigationConfig> get sixCategoryConfigs => [
        realEstateConfig,
        servicesConfig,
        buildingMaterialsConfig,
        homeAppliancesConfig,
        carsConfig,
        fashionConfig,
      ];

  static List<SectionNavigationConfig> get allConfigs => [
        defaultConfig,
        ...sixCategoryConfigs,
      ];
}
