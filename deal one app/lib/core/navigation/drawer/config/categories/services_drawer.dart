import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/navigation/drawer/deal_one_navigation_drawer.dart';
import 'package:market_space/core/navigation/drawer/models/drawer_item_config.dart';
import 'package:market_space/core/navigation/drawer/providers/drawer_badge_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

/// Category-specific Navigation Drawer for **Services & Engineering** (`services`).
/// Complements Bottom Nav (Home | Explore | Map | My Bookings | My Services / Favorites).
class ServicesDrawer extends StatelessWidget {
  final ValueChanged<String>? onRouteSelected;

  const ServicesDrawer({super.key, this.onRouteSelected});

  static const String slug = MapCategoryRegistry.servicesSlug;

  static List<DrawerItemConfig> items() => [
        const DrawerItemConfig(
          id: 'drawer_srv_favorites',
          labelAr: 'المفضلة',
          labelEn: 'Favorites',
          icon: Icons.favorite_outline_rounded,
          routeName: RouteNames.favoritesName,
          route: RouteNames.favorites,
          categoryContext: slug,
          requiredCapability: NavigationCapability.manageEngineeringServices,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
        ),
        DrawerItemConfig(
          id: 'drawer_srv_booking_history',
          labelAr: 'سجل الحجوزات',
          labelEn: 'Booking History',
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
          id: 'drawer_srv_create_service',
          labelAr: 'إضافة خدمة جديدة',
          labelEn: 'Create Service',
          icon: Icons.add_circle_outline_rounded,
          routeName: RouteNames.createListingName,
          queryParameters: const {'category': slug, 'kind': 'service'},
          route: RouteNames.createListingFor(slug, listingKind: 'service'),
          categoryContext: slug,
          requiredCapability: NavigationCapability.manageEngineeringServices,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
        ),
        DrawerItemConfig(
          id: 'drawer_srv_incoming_requests',
          labelAr: 'طلبات الخدمة الواردة',
          labelEn: 'Incoming Service Requests',
          icon: Icons.inbox_outlined,
          routeName: RouteNames.sellerManagementName,
          pathParameters: const {'categorySlug': slug, 'mode': 'services'},
          queryParameters: const {'tab': 'incoming'},
          route: '${RouteNames.sellerManagementFor(slug, 'services')}?tab=incoming',
          categoryContext: slug,
          requiredCapability: NavigationCapability.manageEngineeringServices,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
          badgeProvider: drawerIncomingServiceRequestsCountProvider,
          badgeKey: 'incoming_bookings_services',
        ),
        // Missing Backend/UI Features:
        const DrawerItemConfig(
          id: 'drawer_srv_schedule_management',
          labelAr: 'إدارة المواعيد',
          labelEn: 'Schedule Management',
          icon: Icons.schedule_rounded,
          categoryContext: slug,
          requiredCapability: NavigationCapability.manageEngineeringServices,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: false,
        ),
        const DrawerItemConfig(
          id: 'drawer_srv_service_areas',
          labelAr: 'نطاقات الخدمة',
          labelEn: 'Service Areas',
          icon: Icons.location_searching_rounded,
          categoryContext: slug,
          requiredCapability: NavigationCapability.manageEngineeringServices,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
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
