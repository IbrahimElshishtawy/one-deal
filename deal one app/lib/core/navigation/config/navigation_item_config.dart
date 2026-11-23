import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';

class NavigationItemConfig {
  final String id;
  final String label;
  final String? labelEn;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String destination;
  final NavigationCapability requiredCapability;
  final NavigationVisibilityRule visibilityRule;
  final String? categoryContext;
  final bool requiresPermission;
  final String? badgeKey;

  const NavigationItemConfig({
    required this.id,
    required this.label,
    this.labelEn,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.destination,
    this.requiredCapability = NavigationCapability.none,
    this.visibilityRule = NavigationVisibilityRule.always,
    this.categoryContext,
    this.requiresPermission = false,
    this.badgeKey,
  });

  String localizedLabel(bool isArabic) {
    if (isArabic) return label;
    return labelEn ?? label;
  }
}
