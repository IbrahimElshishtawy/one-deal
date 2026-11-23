import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/navigation/drawer/deal_one_navigation_drawer.dart';
import 'package:market_space/core/navigation/drawer/models/drawer_item_config.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

/// Category-specific Navigation Drawer for **Appliances & Decor** (`home-appliances`).
/// Complements Bottom Nav (Home | Categories | Map | Cart | My Listings / Favorites).
class AppliancesDrawer extends StatelessWidget {
  final ValueChanged<String>? onRouteSelected;

  const AppliancesDrawer({super.key, this.onRouteSelected});

  static const String slug = MapCategoryRegistry.homeAppliancesSlug;

  static List<DrawerItemConfig> items() => [
        const DrawerItemConfig(
          id: 'drawer_app_favorites',
          labelAr: 'المفضلة',
          labelEn: 'Favorites',
          icon: Icons.favorite_outline_rounded,
          routeName: RouteNames.favoritesName,
          route: RouteNames.favorites,
          categoryContext: slug,
          requiredCapability: NavigationCapability.manageAppliancesListings,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
        ),
        DrawerItemConfig(
          id: 'drawer_app_create_listing',
          labelAr: 'إضافة إعلان جديد',
          labelEn: 'Create Listing',
          icon: Icons.add_business_outlined,
          routeName: RouteNames.createListingName,
          queryParameters: const {'category': slug},
          route: RouteNames.createListingFor(slug),
          categoryContext: slug,
          requiredCapability: NavigationCapability.manageAppliancesListings,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
        ),
        DrawerItemConfig(
          id: 'drawer_app_listing_management',
          labelAr: 'إدارة الإعلانات',
          labelEn: 'Listing Management',
          icon: Icons.tune_rounded,
          routeName: RouteNames.sellerManagementName,
          pathParameters: const {'categorySlug': slug, 'mode': 'listings'},
          route: RouteNames.sellerManagementFor(slug, 'listings'),
          categoryContext: slug,
          requiredCapability: NavigationCapability.manageAppliancesListings,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
        ),
        const DrawerItemConfig(
          id: 'drawer_app_recently_viewed',
          labelAr: 'شوهد مؤخراً',
          labelEn: 'Recently Viewed',
          icon: Icons.history_rounded,
          categoryContext: slug,
          featureAvailable: false,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return DealOneNavigationDrawer(
      activeCategorySlug: slug,
      onRouteSelected: onRouteSelected,
    );
  }
}
