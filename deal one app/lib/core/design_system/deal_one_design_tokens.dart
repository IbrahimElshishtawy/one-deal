import 'package:flutter/material.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';

/// Unified visual tokens extracted directly from the Deal One Profile & Real Estate
/// reference designs (`Profile.png`, `Edit account details.png`, `Conversations.png`,
/// `Notification.png`, `Non Notification.png`, `Map View.png`, `Photo Gallery.png`,
/// `Real Estate Details.png`, `Real Estate Reels Viewer.png`).
class DealOneTokens {
  DealOneTokens._();

  // Brand & Surface Colors
  static const Color navy = DealOneDesignColors.navy; // #1B2B48
  static const Color navyDeep = Color(0xFF132038);
  static const Color navySoft = DealOneDesignColors.navySoft;
  static const Color amber = Color(0xFFD97706);
  static const Color amberWarm = Color(0xFFE08B20);
  static const Color amberSoftBg = Color(0xFFFFF4E5);
  static const Color amberBorder = Color(0xFFF6D9B1);

  static const Color pageBg = Color(0xFFF6F8FC);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color softTileBg = Color(0xFFEEF2F8);
  static const Color inputFill = Color(0xFFF1F4FA);
  static const Color cardBorder = Color(0xFFE6ECF5);
  static const Color mutedText = Color(0xFF64748B);
  static const Color dangerRed = Color(0xFFE53935);
  static const Color dangerSoftBg = Color(0xFFFFF1F1);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color successSoftBg = Color(0xFFECFDF3);

  // Adaptive Theme Helpers
  static Color pageBgOf(BuildContext context) =>
      AppColors.isDark(context) ? AppColors.darkBackground : pageBg;

  static Color cardSurfaceOf(BuildContext context) =>
      AppColors.isDark(context) ? AppColors.darkSurface : cardSurface;

  static Color softTileBgOf(BuildContext context) =>
      AppColors.isDark(context) ? AppColors.darkSurfaceElevated : softTileBg;

  static Color inputFillOf(BuildContext context) =>
      AppColors.isDark(context) ? AppColors.darkSurfaceElevated : inputFill;

  static Color cardBorderOf(BuildContext context) =>
      AppColors.isDark(context) ? AppColors.darkBorder : cardBorder;

  static Color textPrimaryOf(BuildContext context) =>
      AppColors.isDark(context) ? AppColors.darkTextPrimary : navy;

  static Color textSecondaryOf(BuildContext context) =>
      AppColors.isDark(context) ? AppColors.darkTextSecondary : mutedText;

  static Color amberTintOf(BuildContext context) => AppColors.isDark(context)
      ? const Color(0xFF3A2810)
      : amberSoftBg;

  // Elevation / Shadows
  static List<BoxShadow> cardShadow(BuildContext context) {
    if (AppColors.isDark(context)) return const [];
    return [
      BoxShadow(
        color: navy.withValues(alpha: 0.05),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static List<BoxShadow> softShadow(BuildContext context) {
    if (AppColors.isDark(context)) return const [];
    return [
      BoxShadow(
        color: navy.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ];
  }

  // Standard Card Decoration
  static BoxDecoration cardDecoration(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? color,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? cardSurfaceOf(context),
      borderRadius: borderRadius ?? AppRadii.lg,
      border: Border.all(color: borderColor ?? cardBorderOf(context)),
      boxShadow: cardShadow(context),
    );
  }

  // Icon Sizes
  static const double iconXs = 14.0;
  static const double iconSm = 18.0;
  static const double iconMd = 22.0;
  static const double iconLg = 26.0;

  // Button & Input Metrics
  static const double buttonMinHeight = 50.0;
  static const double compactButtonMinHeight = 42.0;
  static const EdgeInsets cardPadding = EdgeInsets.all(AppSpacing.lg);
}
