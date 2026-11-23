import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';

/// Action kind for a Drawer item when it triggers a sheet/callback instead of a route.
enum DrawerItemAction {
  navigateRoute,
  openCategorySearch,
  openSettingsSheet,
  logout,
}

/// Authoritative navigation item contract for all Deal One Navigation Drawers.
///
/// Supports GoRouter Named Routes (`routeName`, `pathParameters`, `queryParameters`),
/// Riverpod `badgeProvider`, capability-based visibility, and feature-availability gating.
@immutable
class DrawerItemConfig {
  final String id;
  final String labelAr;
  final String labelEn;
  final IconData icon;

  /// Canonical GoRouter route name (from [RouteNames.*Name]).
  final String? routeName;

  /// GoRouter path parameters for [routeName] (e.g. `{'categorySlug': 'services', 'mode': 'services'}`).
  final Map<String, String> pathParameters;

  /// GoRouter query parameters for [routeName] (e.g. `{'tab': 'incoming'}`).
  final Map<String, String> queryParameters;

  /// Canonical URI path fallback / deep-link representation.
  final String route;

  final String? categoryContext;
  final NavigationCapability requiredCapability;
  final NavigationVisibilityRule visibilityRule;

  /// True only when both Backend API and Flutter screen genuinely exist.
  final bool featureAvailable;

  /// Optional Riverpod provider supplying a real-time badge count for this item.
  final ProviderListenable<int>? badgeProvider;

  /// Optional string key retained for backward compatibility and testing.
  final String? badgeKey;

  final DrawerItemAction action;

  const DrawerItemConfig({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.icon,
    this.routeName,
    this.pathParameters = const {},
    this.queryParameters = const {},
    this.route = '',
    this.categoryContext,
    this.requiredCapability = NavigationCapability.none,
    this.visibilityRule = NavigationVisibilityRule.always,
    this.featureAvailable = true,
    this.badgeProvider,
    this.badgeKey,
    this.action = DrawerItemAction.navigateRoute,
  });

  String localizedLabel(bool isArabic) => isArabic ? labelAr : labelEn;

  /// Evaluates whether this item should be visible for the given [capabilities].
  bool isVisibleFor(AccountCapabilities capabilities) {
    if (!featureAvailable) return false;

    // Never expose protected / seller-only items while account permissions are loading.
    if (capabilities.isLoading &&
        (visibilityRule == NavigationVisibilityRule.sellerOnly ||
            requiredCapability != NavigationCapability.none)) {
      return false;
    }

    switch (visibilityRule) {
      case NavigationVisibilityRule.always:
        return capabilities.hasCapability(requiredCapability);
      case NavigationVisibilityRule.buyerOnly:
        if (categoryContext == null) {
          return !capabilities.hasVerifiedListingManagementRole;
        }
        return !capabilities.isActivatedSellerForSection(categoryContext!);
      case NavigationVisibilityRule.sellerOnly:
        return capabilities.hasCapability(requiredCapability);
      case NavigationVisibilityRule.whenSupported:
        return capabilities.hasCapability(requiredCapability);
    }
  }
}

/// Category entry in the Drawer's Category Switcher section.
@immutable
class DrawerCategoryEntry {
  final String slug;
  final String labelAr;
  final String labelEn;
  final IconData icon;
  final String routeName;
  final String route;

  const DrawerCategoryEntry({
    required this.slug,
    required this.labelAr,
    required this.labelEn,
    required this.icon,
    required this.routeName,
    required this.route,
  });

  String localizedLabel(bool isArabic) => isArabic ? labelAr : labelEn;
}

/// Resolved, capability-filtered Drawer configuration for an active category.
@immutable
class ResolvedDrawerConfig {
  final String activeCategorySlug;
  final List<DrawerCategoryEntry> categories;
  final List<DrawerItemConfig> categoryActions;
  final List<DrawerItemConfig> accountManagementItems;
  final List<DrawerItemConfig> helpAndLegalItems;

  /// All declared items for the active category (including unavailable ones)
  /// for auditability and automated testing.
  final List<DrawerItemConfig> declaredCategoryItems;

  const ResolvedDrawerConfig({
    required this.activeCategorySlug,
    required this.categories,
    required this.categoryActions,
    required this.accountManagementItems,
    required this.helpAndLegalItems,
    this.declaredCategoryItems = const [],
  });
}
