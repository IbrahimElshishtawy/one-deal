import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/models/navigation_item.dart';
import 'package:market_space/core/routing/route_names.dart';

/// Single source of truth mapping Deal One's 4 primary bottom navigation items
/// to their real application routes.
class DealOneNavigationRoutes {
  DealOneNavigationRoutes._();

  static const List<DealOneNavigationItem> primaryItems = [
    DealOneNavigationItem(
      tab: DealOneNavTab.home,
      labelAr: 'الرئيسية',
      labelEn: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      route: RouteNames.root,
    ),
    DealOneNavigationItem(
      tab: DealOneNavTab.favorites,
      labelAr: 'المفضلة',
      labelEn: 'Favorites',
      icon: Icons.favorite_border_rounded,
      activeIcon: Icons.favorite_rounded,
      route: RouteNames.favorites,
    ),
    DealOneNavigationItem(
      tab: DealOneNavTab.orders,
      labelAr: 'طلباتي',
      labelEn: 'Orders',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
      route: RouteNames.activityHub,
    ),
    DealOneNavigationItem(
      tab: DealOneNavTab.profile,
      labelAr: 'البروفايل',
      labelEn: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      route: RouteNames.profile,
    ),
  ];

  /// Resolves a route path/URI (including deep links with query params)
  /// to the corresponding [DealOneNavTab], or `null` if the route is a
  /// detail/secondary screen outside the primary 4-tab shell.
  static DealOneNavTab? tabForLocation(String location) {
    final uri = Uri.tryParse(location);
    final path = uri?.path ?? location;

    if (path == RouteNames.root || path.isEmpty) {
      return DealOneNavTab.home;
    }
    if (path == RouteNames.favorites) {
      return DealOneNavTab.favorites;
    }
    if (path == RouteNames.activityHub) {
      final tabParam = uri?.queryParameters['tab']?.toLowerCase().trim();
      if (tabParam == 'favorites') {
        return DealOneNavTab.favorites;
      }
      return DealOneNavTab.orders;
    }
    if (path == RouteNames.profile) {
      return DealOneNavTab.profile;
    }
    return null;
  }

  static String routeForTab(DealOneNavTab tab) {
    return primaryItems[tab.index].route;
  }
}
