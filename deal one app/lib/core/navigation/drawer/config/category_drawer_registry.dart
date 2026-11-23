import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/navigation/drawer/config/categories/appliances_drawer.dart';
import 'package:market_space/core/navigation/drawer/config/categories/automotive_drawer.dart';
import 'package:market_space/core/navigation/drawer/config/categories/building_materials_drawer.dart';
import 'package:market_space/core/navigation/drawer/config/categories/fashion_drawer.dart';
import 'package:market_space/core/navigation/drawer/config/categories/real_estate_drawer.dart';
import 'package:market_space/core/navigation/drawer/config/categories/services_drawer.dart';
import 'package:market_space/core/navigation/drawer/models/drawer_item_config.dart';
import 'package:market_space/core/navigation/drawer/providers/drawer_badge_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

/// Authoritative registry assembling all 6 category Drawer definitions,
/// Category Switcher entries, Account Management items, and Help & Legal items.
class CategoryDrawerRegistry {
  CategoryDrawerRegistry._();

  static const List<DrawerCategoryEntry> sixCategories = [
    DrawerCategoryEntry(
      slug: MapCategoryRegistry.realEstateSlug,
      labelAr: 'العقارات والأراضي',
      labelEn: 'Real Estate & Lands',
      icon: Icons.apartment_rounded,
      routeName: RouteNames.realEstateName,
      route: RouteNames.realEstate,
    ),
    DrawerCategoryEntry(
      slug: MapCategoryRegistry.servicesSlug,
      labelAr: 'الخدمات والهندسة',
      labelEn: 'Services & Engineering',
      icon: Icons.engineering_rounded,
      routeName: RouteNames.homeServicesName,
      route: RouteNames.homeServices,
    ),
    DrawerCategoryEntry(
      slug: MapCategoryRegistry.buildingMaterialsSlug,
      labelAr: 'مواد البناء والكهرباء',
      labelEn: 'Building Materials',
      icon: Icons.construction_rounded,
      routeName: RouteNames.buildingMaterialsName,
      route: RouteNames.buildingMaterials,
    ),
    DrawerCategoryEntry(
      slug: MapCategoryRegistry.homeAppliancesSlug,
      labelAr: 'الأجهزة والديكور',
      labelEn: 'Appliances & Decor',
      icon: Icons.chair_rounded,
      routeName: RouteNames.homeAppliancesName,
      route: RouteNames.homeAppliances,
    ),
    DrawerCategoryEntry(
      slug: MapCategoryRegistry.carsSlug,
      labelAr: 'السيارات والصيانة',
      labelEn: 'Cars & Maintenance',
      icon: Icons.directions_car_rounded,
      routeName: RouteNames.carsName,
      route: RouteNames.cars,
    ),
    DrawerCategoryEntry(
      slug: MapCategoryRegistry.fashionSlug,
      labelAr: 'الأزياء والإكسسوارات',
      labelEn: 'Fashion & Accessories',
      icon: Icons.checkroom_rounded,
      routeName: RouteNames.fashionName,
      route: RouteNames.fashion,
    ),
  ];

  /// Returns all declared items for [categorySlug] from its dedicated category file.
  static List<DrawerItemConfig> declaredItemsForCategory(String categorySlug) {
    final normalized = MapCategoryRegistry.normalizeSlug(categorySlug);
    switch (normalized) {
      case MapCategoryRegistry.realEstateSlug:
        return RealEstateDrawer.items();
      case MapCategoryRegistry.servicesSlug:
        return ServicesDrawer.items();
      case MapCategoryRegistry.buildingMaterialsSlug:
        return BuildingMaterialsDrawer.items();
      case MapCategoryRegistry.homeAppliancesSlug:
        return AppliancesDrawer.items();
      case MapCategoryRegistry.carsSlug:
        return AutomotiveDrawer.items();
      case MapCategoryRegistry.fashionSlug:
        return FashionDrawer.items();
      default:
        return const [];
    }
  }

  /// Resolves the complete, capability-filtered [ResolvedDrawerConfig].
  static ResolvedDrawerConfig resolve(
    String categorySlug,
    AccountCapabilities capabilities,
  ) {
    final normalized = MapCategoryRegistry.normalizeSlug(categorySlug);
    final declared = declaredItemsForCategory(normalized);
    final visibleCategoryActions =
        declared.where((item) => item.isVisibleFor(capabilities)).toList();

    final accountItems = _accountManagementItems(normalized)
        .where((item) => item.isVisibleFor(capabilities))
        .toList();

    final legalItems = _helpAndLegalItems()
        .where((item) => item.isVisibleFor(capabilities))
        .toList();

    return ResolvedDrawerConfig(
      activeCategorySlug: normalized,
      categories: sixCategories,
      categoryActions: visibleCategoryActions,
      accountManagementItems: accountItems,
      helpAndLegalItems: legalItems,
      declaredCategoryItems: declared,
    );
  }

  static List<DrawerItemConfig> _accountManagementItems(String activeSlug) {
    return [
      const DrawerItemConfig(
        id: 'drawer_account_profile',
        labelAr: 'الملف الشخصي والتحقق',
        labelEn: 'Profile & Verification',
        icon: Icons.person_outline_rounded,
        routeName: RouteNames.profileName,
        route: RouteNames.profile,
      ),
      const DrawerItemConfig(
        id: 'drawer_account_edit',
        labelAr: 'تعديل بيانات الحساب',
        labelEn: 'Edit Account Details',
        icon: Icons.manage_accounts_outlined,
        routeName: RouteNames.editAccountName,
        route: RouteNames.editAccount,
        requiredCapability: NavigationCapability.authenticated,
      ),
      DrawerItemConfig(
        id: 'drawer_account_notifications',
        labelAr: 'الإشعارات',
        labelEn: 'Notifications',
        icon: Icons.notifications_none_rounded,
        routeName: RouteNames.globalNotificationsName,
        route: RouteNames.globalNotifications,
        requiredCapability: NavigationCapability.authenticated,
        badgeProvider: drawerNotificationsUnreadProvider,
        badgeKey: 'notifications_unread',
      ),
      if (activeSlug != MapCategoryRegistry.realEstateSlug)
        DrawerItemConfig(
          id: 'drawer_account_conversations',
          labelAr: 'المحادثات',
          labelEn: 'Messages',
          icon: Icons.chat_bubble_outline_rounded,
          routeName: RouteNames.conversationsName,
          route: RouteNames.conversations,
          requiredCapability: NavigationCapability.authenticated,
          badgeProvider: drawerChatUnreadProvider,
          badgeKey: 'chat_unread',
        ),
      const DrawerItemConfig(
        id: 'drawer_account_settings',
        labelAr: 'الإعدادات واللغة والمظهر',
        labelEn: 'Settings, Language & Theme',
        icon: Icons.settings_outlined,
        action: DrawerItemAction.openSettingsSheet,
      ),
    ];
  }

  static List<DrawerItemConfig> _helpAndLegalItems() {
    return const [
      DrawerItemConfig(
        id: 'drawer_legal_terms',
        labelAr: 'الشروط والأحكام',
        labelEn: 'Terms of Service',
        icon: Icons.description_outlined,
        routeName: RouteNames.termsName,
        route: RouteNames.terms,
      ),
      DrawerItemConfig(
        id: 'drawer_legal_privacy',
        labelAr: 'سياسة الخصوصية',
        labelEn: 'Privacy Policy',
        icon: Icons.privacy_tip_outlined,
        routeName: RouteNames.privacyName,
        route: RouteNames.privacy,
      ),
    ];
  }
}
