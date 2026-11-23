import 'package:flutter/material.dart';
import 'package:market_space/core/theme/app_colors.dart';

/// Visual & layout tokens for the Deal One Bottom Navigation Bar,
/// aligned with the approved Figma Variant Matrix reference.
class DealOneBottomNavTokens {
  DealOneBottomNavTokens._();

  // Brand & Surface Colors (Light Mode exact spec)
  static const Color activeBackground = Color(0xFF1B2A4A);
  static const Color activeForeground = Color(0xFFFFFFFF);
  static const Color inactiveForeground = Color(0xFF64748B);
  static const Color barBackground = Color(0xFFFFFFFF);
  static const Color barBorder = Color(0xFFE2E8F0);

  // Dark Mode Adaptive Colors
  static const Color darkActiveBackground = Color(0xFF283E6B);
  static const Color darkInactiveForeground = Color(0xFF94A3B8);

  // Typography
  static const String fontFamily = 'Cairo';
  static const double labelFontSize = 12.0;
  static const double compactLabelFontSize = 11.0;
  static const FontWeight activeFontWeight = FontWeight.w700;
  static const FontWeight inactiveFontWeight = FontWeight.w500;

  // Spacing & Geometry (8pt Grid)
  static const double horizontalPadding = 16.0;
  static const double compactHorizontalPadding = 8.0;
  static const double verticalPadding = 10.0;
  static const double pillVerticalPadding = 8.0;
  static const double pillHorizontalInset = 4.0;
  static const double iconSize = 24.0;
  static const double compactIconSize = 22.0;
  static const double iconLabelGap = 4.0;
  static const double maxBarWidth = 540.0;
  static const double itemMinHeight = 56.0;

  // Corner Radii
  static const double floatingBarRadius = 16.0;
  static const double dockedBarRadius = 8.0;
  static const double activePillRadius = 12.0;

  // Animation
  static const Duration transitionDuration = Duration(milliseconds: 260);
  static const Duration iconSwitchDuration = Duration(milliseconds: 180);
  static const Curve transitionCurve = Curves.easeInOutCubic;

  // Adaptive Color Helpers
  static Color activeBackgroundOf(BuildContext context) =>
      AppColors.isDark(context) ? darkActiveBackground : activeBackground;

  static Color activeForegroundOf(BuildContext context) => activeForeground;

  static Color inactiveForegroundOf(BuildContext context) =>
      AppColors.isDark(context) ? darkInactiveForeground : inactiveForeground;

  static Color barBackgroundOf(BuildContext context) =>
      AppColors.isDark(context) ? AppColors.darkSurface : barBackground;

  static Color barBorderOf(BuildContext context) =>
      AppColors.isDark(context) ? AppColors.darkBorder : barBorder;

  static List<BoxShadow> floatingBarShadowOf(BuildContext context) {
    if (AppColors.isDark(context)) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.32),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
    }
    return [
      BoxShadow(
        color: activeBackground.withValues(alpha: 0.08),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: activeBackground.withValues(alpha: 0.03),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> activePillShadowOf(BuildContext context) {
    if (AppColors.isDark(context)) return const [];
    return [
      BoxShadow(
        color: activeBackground.withValues(alpha: 0.16),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ];
  }
}
