import 'package:flutter/material.dart';

/// Visual tokens extracted from `docs/design/image.png` for the Deal One
/// authentication & onboarding experience, with clean dark-mode support.
class AuthDesignTokens {
  AuthDesignTokens._();

  static const String logoAssetPath = 'assets/image/logo.png';

  // Brand & Semantic Accents from Design Reference
  static const Color navyPrimary = Color(0xFF182949);
  static const Color navyPrimaryDarkMode = Color(0xFF3A7AFE);
  static const Color navySurface = Color(0xFF1E3258);
  static const Color actionBlue = Color(0xFF3A7AFE);
  static const Color actionBlueTint = Color(0xFFEEF4FF);
  static const Color focusOrange = Color(0xFFE68A2E);
  static const Color focusOrangeTint = Color(0xFFFFF7ED);

  // Error / Expired / Destructive States
  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorBorder = Color(0xFFFCA5A5);
  static const Color errorTint = Color(0xFFFEF2F2);
  static const Color darkErrorTint = Color(0xFF3F1518);

  // Success States
  static const Color successGreen = Color(0xFF16A34A);
  static const Color successTint = Color(0xFFECFDF5);
  static const Color darkSuccessTint = Color(0xFF0B321C);

  // Light Neutrals
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8FAFC);
  static const Color lightInputFill = Color(0xFFF9FAFB);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF182949);
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

  // Dimensions & Radii
  static const double maxContentWidth = 440;
  static const double horizontalPadding = 24;
  static const double buttonHeight = 54;
  static const double inputRadius = 14;
  static const double buttonRadius = 14;
  static const double cardRadius = 20;
  static const double otpBoxRadius = 14;

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

  static Color successTintOf(BuildContext context) =>
      isDark(context) ? darkSuccessTint : successTint;
}
