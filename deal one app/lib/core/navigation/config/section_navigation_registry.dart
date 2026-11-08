import 'package:flutter/material.dart';
import 'floating_action_config.dart';
import 'navigation_item_config.dart';
import 'section_navigation_config.dart';

class SectionNavigationRegistry {
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

  static final Map<String, SectionNavigationConfig> _registry = {
    'deal_one': defaultConfig,
  };

  static SectionNavigationConfig getConfig(String sectionId) {
    return _registry[sectionId] ?? defaultConfig;
  }

  static List<SectionNavigationConfig> get allConfigs =>
      _registry.values.toList();
}
