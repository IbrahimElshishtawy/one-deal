import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/navigation/drawer/deal_one_navigation_drawer.dart';
import 'package:market_space/core/navigation/drawer/models/drawer_item_config.dart';
import 'package:market_space/core/navigation/drawer/providers/drawer_badge_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

/// Category-specific Navigation Drawer for **Cars & Maintenance** (`cars`).
/// Complements Bottom Nav (Home | Explore | Map | Maintenance | My Services / Favorites).
class AutomotiveDrawer extends StatelessWidget {
  final ValueChanged<String>? onRouteSelected;

  const AutomotiveDrawer({super.key, this.onRouteSelected});

  static const String slug = MapCategoryRegistry.carsSlug;

  static List<DrawerItemConfig> items() => [
        const DrawerItemConfig(
          id: 'drawer_cars_favorites',
          labelAr: 'المفضلة',
          labelEn: 'Favorites',
          icon: Icons.favorite_outline_rounded,
          routeName: RouteNames.favoritesName,
          route: RouteNames.favorites,
          categoryContext: slug,
          requiredCapability:
              NavigationCapability.manageAutomotiveMaintenanceServices,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
        ),
        DrawerItemConfig(
          id: 'drawer_cars_service_history',
          labelAr: 'سجل الصيانة والحجوزات',
          labelEn: 'Service History',
          icon: Icons.history_rounded,
          routeName: RouteNames.activityHubName,
          queryParameters: const {'tab': 'bookings', 'category': slug},
          route: RouteNames.activityHubFor(tab: 'bookings', categorySlug: slug),
          categoryContext: slug,
          requiredCapability: NavigationCapability.authenticated,
          visibilityRule: NavigationVisibilityRule.always,
          featureAvailable: true,
        ),
        DrawerItemConfig(
          id: 'drawer_cars_my_listings',
          labelAr: 'سياراتي وإعلاناتي',
          labelEn: 'My Cars & Listings',
          icon: Icons.directions_car_outlined,
          routeName: RouteNames.sellerManagementName,
          pathParameters: const {'categorySlug': slug, 'mode': 'listings'},
          route: RouteNames.sellerManagementFor(slug, 'listings'),
          categoryContext: slug,
          requiredCapability: NavigationCapability.manageAppliancesListings,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
        ),
        DrawerItemConfig(
          id: 'drawer_cars_create_maintenance',
          labelAr: 'إضافة خدمة صيانة',
          labelEn: 'Create Maintenance Service',
          icon: Icons.build_outlined,
          routeName: RouteNames.createListingName,
          queryParameters: const {'category': slug, 'kind': 'service'},
          route: RouteNames.createListingFor(slug, listingKind: 'service'),
          categoryContext: slug,
          requiredCapability:
              NavigationCapability.manageAutomotiveMaintenanceServices,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
        ),
        DrawerItemConfig(
          id: 'drawer_cars_maintenance_requests',
          labelAr: 'طلبات الصيانة الواردة',
          labelEn: 'Maintenance Requests',
          icon: Icons.car_repair_outlined,
          routeName: RouteNames.sellerManagementName,
          pathParameters: const {'categorySlug': slug, 'mode': 'services'},
          queryParameters: const {'tab': 'incoming'},
          route: '${RouteNames.sellerManagementFor(slug, 'services')}?tab=incoming',
          categoryContext: slug,
          requiredCapability:
              NavigationCapability.manageAutomotiveMaintenanceServices,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
          badgeProvider: drawerIncomingMaintenanceRequestsCountProvider,
          badgeKey: 'incoming_bookings_cars',
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
