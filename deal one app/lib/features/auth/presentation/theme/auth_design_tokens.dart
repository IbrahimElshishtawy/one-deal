import 'package:flutter/material.dart';

/// Visual & spacing tokens extracted from the 7 Deal One authentication
/// design PNGs on a standardized 4/8pt layout rhythm, with dark-mode support.
class AuthDesignTokens {
  AuthDesignTokens._();

  static const String logoAssetPath = 'assets/image/logo.png';

  // Brand & Semantic Accents from Design Reference
  static const Color navyPrimary = Color(0xFF1D2B44);
  static const Color navyPrimaryDarkMode = Color(0xFF3A7AFE);
  static const Color navySurface = Color(0xFF1E3258);
  static const Color actionBlue = Color(0xFF3A7AFE);
  static const Color actionBlueTint = Color(0xFFEEF4FF);
  static const Color focusOrange = Color(0xFFE68A2E);
  static const Color focusOrangeTint = Color(0xFFFFF7ED);

  // Error / Expired / Destructive States
  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorDeepRed = Color(0xFFB91C1C);
  static const Color errorBorder = Color(0xFFFCA5A5);
  static const Color errorTint = Color(0xFFFDECEC);
  static const Color expiredCardTint = Color(0xFFFADBD8);
  static const Color darkErrorTint = Color(0xFF3F1518);

  // Pill & Badge Surfaces
  static const Color softBluePill = Color(0xFFEBF0F7);
  static const Color darkSoftBluePill = Color(0xFF1E293B);

  // Success States
  static const Color successGreen = Color(0xFF16A34A);
  static const Color successTealDot = Color(0xFF0F766E);
  static const Color successTint = Color(0xFFECFDF5);
  static const Color darkSuccessTint = Color(0xFF0B321C);

  // Light Neutrals (matching supplied PNGs)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightInputFill = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Dark Neutrals
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkInputFill = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Standardized 4/8pt Spacing Scale
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceBase = 16;
  static const double spaceLg = 20;
  static const double spaceXl = 24;
  static const double space2xl = 32;
  static const double space3xl = 40;

  // Dimensions & Radii
  static const double maxContentWidth = 440;
  static const double horizontalPadding = spaceXl;
  static const double verticalPadding = spaceBase;
  static const double topBarHeight = 44;
  static const double logoSize = 92;
  static const double inputHeight = 52;
  static const double buttonHeight = 52;
  static const double socialButtonHeight = 48;
  static const double headerToFormGap = spaceXl;
  static const double sectionGap = spaceLg;
  static const double inputRadius = 12;
  static const double buttonRadius = 12;
  static const double cardRadius = 16;
  static const double otpBoxRadius = 12;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color inputFillOf(BuildContext context) =>
      isDark(context) ? darkInputFill : lightInputFill;

  static Color borderOf(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static Color dividerOf(BuildContext context) =>
      isDark(context) ? darkDivider : lightDivider;

  static Color primaryActionOf(BuildContext context) =>
      isDark(context) ? navyPrimaryDarkMode : navyPrimary;

  static Color headingOf(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color bodyOf(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color mutedOf(BuildContext context) =>
      isDark(context) ? darkTextMuted : lightTextMuted;

  static Color errorTintOf(BuildContext context) =>
      isDark(context) ? darkErrorTint : errorTint;

  static Color expiredCardOf(BuildContext context) =>
      isDark(context) ? darkErrorTint : expiredCardTint;

  static Color softPillOf(BuildContext context) =>
      isDark(context) ? darkSoftBluePill : softBluePill;

  static Color successTintOf(BuildContext context) =>
      isDark(context) ? darkSuccessTint : successTint;

  static List<BoxShadow> cardShadowOf(BuildContext context) {
    if (isDark(context)) {
      return const [];
    }
    return const [
      BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, 4)),
    ];
  }
}
