import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';

/// Ergonomic Theme and Design System extensions on BuildContext.
/// Allows clean, concise, and reactive access to theme tokens across all widgets.
extension ThemeContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // Background and Surfaces
  Color get scaffoldBackground => theme.scaffoldBackgroundColor;
  Color get surfaceColor => colorScheme.surface;
  Color get surfaceSecondaryColor => isDarkMode
      ? AppColors.darkSurfaceSecondary
      : AppColors.surfaceSecondary;
  Color get surfaceTertiaryColor => isDarkMode
      ? AppColors.darkSurfaceTertiary
      : AppColors.surfaceTertiary;

  // Typography Colors
  Color get textPrimaryColor => isDarkMode
      ? AppColors.darkTextPrimary
      : AppColors.textPrimary;
  Color get textSecondaryColor => isDarkMode
      ? AppColors.darkTextSecondary
      : AppColors.textSecondary;
  Color get textMutedColor => isDarkMode
      ? AppColors.darkTextMuted
      : AppColors.textMuted;

  // Actions and Borders
  Color get primaryColor => colorScheme.primary;
  Color get onPrimaryColor => colorScheme.onPrimary;
  Color get borderColor => isDarkMode ? AppColors.darkBorder : AppColors.border;
  Color get dividerColor => isDarkMode ? AppColors.darkDivider : AppColors.divider;
  Color get iconPrimaryColor => isDarkMode ? AppColors.darkIconPrimary : AppColors.iconPrimary;
  Color get iconSecondaryColor => isDarkMode ? AppColors.darkIconSecondary : AppColors.iconSecondary;
  Color get disabledColor => isDarkMode ? AppColors.darkDisabled : AppColors.disabled;

  // Semantic Status Colors
  Color get semanticSuccess => isDarkMode ? AppColors.darkSuccess : AppColors.success;
  Color get semanticSuccessTint => isDarkMode ? AppColors.darkSuccessTint : AppColors.successTint;
  Color get semanticWarning => isDarkMode ? AppColors.darkWarning : AppColors.warning;
  Color get semanticWarningTint => isDarkMode ? AppColors.darkWarningTint : AppColors.warningTint;
  Color get semanticError => isDarkMode ? AppColors.darkError : AppColors.error;
  Color get semanticErrorTint => isDarkMode ? AppColors.darkErrorTint : AppColors.errorTint;
  Color get semanticInfo => isDarkMode ? AppColors.darkInfo : AppColors.info;
  Color get semanticInfoTint => isDarkMode ? AppColors.darkInfoTint : AppColors.infoTint;
}
