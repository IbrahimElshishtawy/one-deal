import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/navigation/drawer/deal_one_navigation_drawer.dart';
import 'package:market_space/core/navigation/drawer/models/drawer_item_config.dart';
import 'package:market_space/core/navigation/drawer/providers/drawer_badge_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

/// Category-specific Navigation Drawer for **Building Materials & Electricity** (`building-materials`).
/// Complements Bottom Nav (Home | Categories | Map | Price Requests | My Products / Favorites).
class BuildingMaterialsDrawer extends StatelessWidget {
  final ValueChanged<String>? onRouteSelected;

  const BuildingMaterialsDrawer({super.key, this.onRouteSelected});

  static const String slug = MapCategoryRegistry.buildingMaterialsSlug;

  static List<DrawerItemConfig> items() => [
        const DrawerItemConfig(
          id: 'drawer_bm_favorites',
          labelAr: 'المفضلة',
          labelEn: 'Favorites',
          icon: Icons.favorite_outline_rounded,
          routeName: RouteNames.favoritesName,
          route: RouteNames.favorites,
          categoryContext: slug,
          requiredCapability:
              NavigationCapability.manageBuildingMaterialsProducts,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
        ),
        const DrawerItemConfig(
          id: 'drawer_bm_supplier_discovery',
          labelAr: 'استكشاف الموردين',
          labelEn: 'Supplier Discovery',
          icon: Icons.store_mall_directory_outlined,
          routeName: RouteNames.searchName,
          route: RouteNames.search,
          categoryContext: slug,
          action: DrawerItemAction.openCategorySearch,
          featureAvailable: true,
        ),
        DrawerItemConfig(
          id: 'drawer_bm_add_product',
          labelAr: 'إضافة منتج مواد بناء',
          labelEn: 'Add Product',
          icon: Icons.add_box_outlined,
          routeName: RouteNames.createListingName,
          queryParameters: const {'category': slug, 'kind': 'product'},
          route: RouteNames.createListingFor(slug, listingKind: 'product'),
          categoryContext: slug,
          requiredCapability:
              NavigationCapability.manageBuildingMaterialsProducts,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
        ),
        DrawerItemConfig(
          id: 'drawer_bm_incoming_rfqs',
          labelAr: 'طلبات الأسعار الواردة',
          labelEn: 'Incoming RFQs',
          icon: Icons.request_quote_outlined,
          routeName: RouteNames.sellerManagementName,
          pathParameters: const {'categorySlug': slug, 'mode': 'products'},
          queryParameters: const {'tab': 'incoming'},
          route: '${RouteNames.sellerManagementFor(slug, 'products')}?tab=incoming',
          categoryContext: slug,
          requiredCapability:
              NavigationCapability.manageBuildingMaterialsProducts,
          visibilityRule: NavigationVisibilityRule.sellerOnly,
          featureAvailable: true,
          badgeProvider: drawerIncomingRfqsCountProvider,
          badgeKey: 'incoming_rfqs_building_materials',
        ),
        // Missing Backend Endpoint (no GET /quotations/mine for suppliers):
        const DrawerItemConfig(
          id: 'drawer_bm_my_quotations',
          labelAr: 'عروض الأسعار المقدمة',
          labelEn: 'My Quotations',
          icon: Icons.receipt_long_outlined,
          categoryContext: slug,
          requiredCapability:
              NavigationCapability.manageBuildingMaterialsProducts,
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
