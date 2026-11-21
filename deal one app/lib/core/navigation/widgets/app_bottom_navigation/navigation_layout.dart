import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';

class NavigationLayout {
  static const double borderRadiusValue = 24.0;
  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(borderRadiusValue),
  );

  static const double horizontalMargin = 12.0;
  static const double bottomMargin = 12.0;

  static double getBarHeight(bool isCompact) => isCompact ? 62.0 : 68.0;
  static double getIconSize(bool isCompact) => isCompact ? 22.0 : 25.0;

  static const Color activeColor = AppColors.primary;
  static const Color inactiveColor = AppColors.iconSecondary;
  static const Color backgroundColor = Colors.white;

  static Color activeColorOf(BuildContext context) =>
      AppColors.isDark(context) ? AppColors.darkPrimary : AppColors.primary;
  static Color inactiveColorOf(BuildContext context) =>
      AppColors.isDark(context) ? AppColors.darkIconSecondary : AppColors.iconSecondary;
  static Color backgroundColorOf(BuildContext context) =>
      AppColors.isDark(context) ? AppColors.darkSurface : Colors.white;

  static Border containerBorderOf(BuildContext context) => Border.all(
    color: AppColors.isDark(context) ? AppColors.darkBorder : const Color(0x12000000),
    width: 1.0,
  );

  static List<BoxShadow> containerShadowOf(BuildContext context) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: AppColors.isDark(context) ? 0.35 : 0.1),
      blurRadius: 16.0,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> containerShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16.0,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static const Border containerBorder = Border.fromBorderSide(
    BorderSide(color: Color(0x12000000), width: 1.0),
  );

  static double getFontSize(bool isCompact) => isCompact ? 11.0 : 12.0;

  static const double indicatorHeight = 3.0;
  static const double indicatorWidth = 22.0;
  static const BorderRadius indicatorRadius = AppRadii.full;
}
