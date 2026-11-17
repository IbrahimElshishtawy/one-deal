import 'package:flutter/material.dart';

/// Centralized Monochrome Design System Color Tokens.
/// Exclusively Black, White, and Grayscale shades for the core identity,
/// with clear semantic colors for states (Success, Warning, Error, Info).
class AppColors {
  // ==========================================
  // --- 2.1 Light Theme Palette ---
  // ==========================================
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF5F5F5);
  static const Color surfaceTertiary = Color(0xFFEEEEEE);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF404040);
  static const Color textMuted = Color(0xFF666666);
  static const Color primary = Color(0xFF111111);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFE5E5E5);
  static const Color iconPrimary = Color(0xFF222222);
  static const Color iconSecondary = Color(0xFF555555);
  static const Color disabled = Color(0xFFBDBDBD);

  // ==========================================
  // --- 2.2 Dark Theme Palette ---
  // ==========================================
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1C1C1C);
  static const Color darkSurfaceSecondary = Color(0xFF262626);
  static const Color darkSurfaceTertiary = Color(0xFF303030);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFD0D0D0);
  static const Color darkTextMuted = Color(0xFFA0A0A0);
  static const Color darkPrimary = Color(0xFFFFFFFF);
  static const Color darkOnPrimary = Color(0xFF111111);
  static const Color darkBorder = Color(0xFF383838);
  static const Color darkDivider = Color(0xFF303030);
  static const Color darkIconPrimary = Color(0xFFFFFFFF);
  static const Color darkIconSecondary = Color(0xFFC0C0C0);
  static const Color darkDisabled = Color(0xFF707070);

  // ==========================================
  // --- 2.3 Semantic Colors (WCAG 2.2 AA) ---
  // ==========================================
  // Success
  static const Color success = Color(0xFF16A34A);
  static const Color successTint = Color(0xFFF0FDF4);
  static const Color darkSuccess = Color(0xFF22C55E);
  static const Color darkSuccessTint = Color(0xFF052E16);

  // Warning
  static const Color warning = Color(0xFFD97706);
  static const Color warningTint = Color(0xFFFFFBEB);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkWarningTint = Color(0xFF451A03);

  // Error
  static const Color error = Color(0xFFDC2626);
  static const Color errorTint = Color(0xFFFEF2F2);
  static const Color darkError = Color(0xFFEF4444);
  static const Color darkErrorTint = Color(0xFF450A0A);

  // Information
  static const Color info = Color(0xFF2563EB);
  static const Color infoTint = Color(0xFFEFF6FF);
  static const Color darkInfo = Color(0xFF3B82F6);
  static const Color darkInfoTint = Color(0xFF172554);

  // ==========================================
  // --- Dynamic Theme Helpers ---
  // ==========================================
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? darkBackground : background;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  static Color surfaceSecondaryOf(BuildContext context) =>
      isDark(context) ? darkSurfaceSecondary : surfaceSecondary;

  static Color surfaceTertiaryOf(BuildContext context) =>
      isDark(context) ? darkSurfaceTertiary : surfaceTertiary;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color textMutedOf(BuildContext context) =>
      isDark(context) ? darkTextMuted : textMuted;

  static Color borderOf(BuildContext context) =>
      isDark(context) ? darkBorder : border;

  static Color dividerOf(BuildContext context) =>
      isDark(context) ? darkDivider : divider;

  static Color iconOf(BuildContext context) =>
      isDark(context) ? darkIconPrimary : iconPrimary;

  static Color iconSecondaryOf(BuildContext context) =>
      isDark(context) ? darkIconSecondary : iconSecondary;

  static Color primaryOf(BuildContext context) =>
      isDark(context) ? darkPrimary : primary;

  static Color onPrimaryOf(BuildContext context) =>
      isDark(context) ? darkOnPrimary : onPrimary;

  static Color disabledOf(BuildContext context) =>
      isDark(context) ? darkDisabled : disabled;

  static Color successOf(BuildContext context) =>
      isDark(context) ? darkSuccess : success;

  static Color warningOf(BuildContext context) =>
      isDark(context) ? darkWarning : warning;

  static Color errorOf(BuildContext context) =>
      isDark(context) ? darkError : error;

  static Color infoOf(BuildContext context) =>
      isDark(context) ? darkInfo : info;

  static Color primaryTintOf(BuildContext context) =>
      isDark(context) ? darkSurfaceSecondary : primaryTint;

  static Color secondaryTintOf(BuildContext context) =>
      isDark(context) ? darkSurfaceSecondary : secondaryTint;

  static Color tertiaryTintOf(BuildContext context) =>
      isDark(context) ? darkSurfaceSecondary : tertiaryTint;

  static Color infoTintOf(BuildContext context) =>
      isDark(context) ? darkInfoTint : infoTint;

  static Color errorTintOf(BuildContext context) =>
      isDark(context) ? darkErrorTint : errorTint;

  static Color neutralOf(BuildContext context) =>
      isDark(context) ? darkSurfaceSecondary : neutral;

  static Color onNeutralOf(BuildContext context) => Colors.white;

  static Color badgeBgOf(BuildContext context, Color tint) =>
      isDark(context) ? darkSurfaceSecondary : tint;

  // ==========================================
  // --- Legacy Compatibility Tokens ---
  // ==========================================
  static const Color lightBackground = background;
  static const Color lightSurface = surface;
  static const Color lightBorder = border;
  static const Color lightTextPrimary = textPrimary;
  static const Color lightTextSecondary = textSecondary;
  static const Color lightTextMuted = textMuted;

  static const Color primaryDark = Color(0xFF000000);
  static const Color primaryLight = Color(0xFF333333);
  static const Color primaryTint = Color(0xFFF5F5F5);

  static const Color secondary = Color(0xFF262626);
  static const Color secondaryDark = Color(0xFF111111);
  static const Color secondaryLight = Color(0xFF555555);
  static const Color secondaryTint = Color(0xFFF5F5F5);

  static const Color tertiary = Color(0xFF404040);
  static const Color tertiaryDark = Color(0xFF111111);
  static const Color tertiaryLight = Color(0xFF757575);
  static const Color tertiaryTint = Color(0xFFF5F5F5);

  static const Color neutral = Color(0xFF111111);
  static const Color neutralLight = Color(0xFF262626);

  // Grayscale Palette tokens
  static const Color slate50 = Color(0xFFFAFAFA);
  static const Color slate100 = Color(0xFFF5F5F5);
  static const Color slate200 = Color(0xFFEEEEEE);
  static const Color slate300 = Color(0xFFE0E0E0);
  static const Color slate400 = Color(0xFFBDBDBD);
  static const Color slate500 = Color(0xFF757575);
  static const Color slate600 = Color(0xFF616161);
  static const Color slate700 = Color(0xFF424242);
  static const Color slate800 = Color(0xFF212121);
  static const Color slate900 = Color(0xFF111111);

  // Emerald tokens mapped to elegant high-contrast monochrome
  static const Color emerald50 = Color(0xFFFAFAFA);
  static const Color emerald100 = Color(0xFFF0F0F0);
  static const Color emerald200 = Color(0xFFE0E0E0);
  static const Color emerald300 = Color(0xFFBDBDBD);
  static const Color emerald400 = Color(0xFF9E9E9E);
  static const Color emerald500 = Color(0xFF757575);
  static const Color emerald600 = Color(0xFF424242);
  static const Color emerald700 = Color(0xFF212121);
  static const Color emerald800 = Color(0xFF111111);
  static const Color emerald900 = Color(0xFF000000);

  static const Color rose600 = error;
  static const Color accent = Color(0xFF111111);
  static const Color accentDark = Color(0xFF000000);
}
