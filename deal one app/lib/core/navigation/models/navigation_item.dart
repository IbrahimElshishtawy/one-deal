import 'package:flutter/material.dart';

/// Canonical tabs for the Deal One primary bottom navigation bar.
///
/// Ordered from start to end (right-to-left in RTL Arabic):
/// 1. Home (الرئيسية)
/// 2. Favorites (المفضلة)
/// 3. Orders (طلباتي)
/// 4. Profile (البروفايل)
enum DealOneNavTab {
  home('home'),
  favorites('favorites'),
  orders('orders'),
  profile('profile');

  final String id;

  const DealOneNavTab(this.id);

  static DealOneNavTab fromIndex(int index) {
    if (index < 0 || index >= DealOneNavTab.values.length) {
      return DealOneNavTab.home;
    }
    return DealOneNavTab.values[index];
  }
}

/// Visual presentation style for [DealOneBottomNavigation].
enum DealOneBottomNavStyle {
  /// Floating white card with 16px radius, 1px border, subtle shadow, and screen margins.
  floating,

  /// Docked bar with 8px top radius and full-width bottom anchoring.
  docked,
}

/// Immutable data model representing a single destination in the Deal One
/// bottom navigation bar.
@immutable
class DealOneNavigationItem {
  final DealOneNavTab tab;
  final String labelAr;
  final String labelEn;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const DealOneNavigationItem({
    required this.tab,
    required this.labelAr,
    required this.labelEn,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });

  String get id => tab.id;

  String labelFor(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    return isArabic ? labelAr : labelEn;
  }
}
