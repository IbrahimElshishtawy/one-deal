import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/navigation/drawer/deal_one_navigation_drawer.dart';
import 'package:market_space/core/navigation/drawer/models/drawer_item_config.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

/// Category-specific Navigation Drawer for **Real Estate & Lands** (`real-estate`).
/// Complements Bottom Nav (Home | Explore | Map | Chat | My Listings / Favorites).
class RealEstateDrawer extends StatelessWidget {
  final ValueChanged<String>? onRouteSelected;

  const RealEstateDrawer({super.key, this.onRouteSelected});

  static const String slug = MapCategoryRegistry.realEstateSlug;

  static List<DrawerItemConfig> items() => [
        const DrawerItemConfig(
          id: 'drawer_re_favorites',
          labelAr: 'المفضلة',
          labelEn: 'Favorites',
          icon: Icons.favorite_outline_rounded,
          routeName: RouteNames.favoritesName,
          route: RouteNames.favorites,
          categoryContext: slug,
          requiredCapability: NavigationCapability.manageRealEstateListings,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
        ),
        DrawerItemConfig(
          id: 'drawer_re_create_listing',
          labelAr: 'إضافة عقار جديد',
          labelEn: 'Create Listing',
          icon: Icons.add_home_work_outlined,
          routeName: RouteNames.createListingName,
          queryParameters: const {'category': slug},
          route: RouteNames.createListingFor(slug),
          categoryContext: slug,
          requiredCapability: NavigationCapability.manageRealEstateListings,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
        ),
        DrawerItemConfig(
          id: 'drawer_re_listing_management',
          labelAr: 'إدارة العقارات',
          labelEn: 'Listing Management',
          icon: Icons.tune_rounded,
          routeName: RouteNames.sellerManagementName,
          pathParameters: const {'categorySlug': slug, 'mode': 'listings'},
          route: RouteNames.sellerManagementFor(slug, 'listings'),
          categoryContext: slug,
          requiredCapability: NavigationCapability.manageRealEstateListings,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
        ),
        DrawerItemConfig(
          id: 'drawer_re_viewings',
          labelAr: 'مواعيد المعاينات',
          labelEn: 'Property Viewings',
          icon: Icons.calendar_today_outlined,
          routeName: RouteNames.activityHubName,
          queryParameters: const {'tab': 'bookings', 'category': slug},
          route: RouteNames.activityHubFor(tab: 'bookings', categorySlug: slug),
          categoryContext: slug,
          requiredCapability: NavigationCapability.authenticated,
          visibilityRule: NavigationVisibilityRule.always,
          featureAvailable: true,
        ),
        // Missing Backend/UI Features — explicitly marked unavailable:
        const DrawerItemConfig(
          id: 'drawer_re_contact_requests',
          labelAr: 'طلبات التواصل',
          labelEn: 'Contact Requests',
          icon: Icons.contact_phone_outlined,
          categoryContext: slug,
          requiredCapability: NavigationCapability.manageRealEstateListings,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: false,
        ),
        const DrawerItemConfig(
          id: 'drawer_re_saved_searches',
          labelAr: 'عمليات البحث المحفوظة',
          labelEn: 'Saved Searches',
          icon: Icons.bookmark_border_rounded,
          categoryContext: slug,
          featureAvailable: false,
        ),
        const DrawerItemConfig(
          id: 'drawer_re_recently_viewed',
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
