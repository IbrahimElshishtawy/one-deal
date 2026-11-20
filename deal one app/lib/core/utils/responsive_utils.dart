import 'package:flutter/material.dart';

/// Viewport breakpoint constants across small phones, standard/large phones, and tablets.
class AppBreakpoints {
  /// Ultra-compact phones (e.g. 320x568).
  static const double smallPhone = 340.0;

  /// Compact Android phones (e.g. 360x640 / 360x800).
  static const double compact = 360.0;

  /// Standard modern phones (393..412dp).
  static const double standard = 410.0;

  /// Phablet / Small Tablet boundary (600dp).
  static const double large = 600.0;

  /// Tablet portrait boundary (768dp).
  static const double tablet = 768.0;

  /// Large tablet / desktop boundary (960..1024dp).
  static const double largeTablet = 960.0;
}

/// Extension providing responsive layout dimensions, grid delegates, and text-scale helpers.
extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  bool get isLandscape => screenWidth > screenHeight;

  bool get isSmallPhone => screenWidth < AppBreakpoints.smallPhone;
  bool get isCompactPhone => screenWidth < AppBreakpoints.compact;
  bool get isStandardPhone =>
      screenWidth >= AppBreakpoints.compact &&
      screenWidth < AppBreakpoints.standard;
  bool get isLargePhone =>
      screenWidth >= AppBreakpoints.standard &&
      screenWidth < AppBreakpoints.large;
  bool get isTablet => screenWidth >= AppBreakpoints.large;
  bool get isLargeTablet => screenWidth >= AppBreakpoints.largeTablet;

  /// Effective text scale multiplier relative to 1.0x baseline (clamped 1.0..2.2).
  double get effectiveTextScale {
    final scaled = MediaQuery.textScalerOf(this).scale(14.0) / 14.0;
    return scaled.clamp(1.0, 2.2);
  }

  /// Responsive horizontal screen margin: 12dp on small/compact, 16dp on standard, 24dp on tablets.
  double get horizontalScreenPadding {
    if (screenWidth < AppBreakpoints.compact) return 12.0;
    if (screenWidth >= AppBreakpoints.tablet) return 24.0;
    return 16.0;
  }

  /// Calculates adaptive product grid column count based on available width and text scale.
  int productGridColumnsForWidth([double? availableWidth]) {
    final width = availableWidth ?? screenWidth;
    if (width < AppBreakpoints.smallPhone && effectiveTextScale >= 1.65) {
      return 1;
    }
    if (width >= AppBreakpoints.largeTablet) return 4;
    if (width >= AppBreakpoints.large) return 3;
    return 2;
  }

  /// Calculates adaptive category grid column count based on available width and text scale.
  int categoryGridColumnsForWidth([double? availableWidth]) {
    final width = availableWidth ?? screenWidth;
    if (width < AppBreakpoints.smallPhone && effectiveTextScale >= 1.65) {
      return 1;
    }
    if (width >= AppBreakpoints.largeTablet) return 4;
    if (width >= AppBreakpoints.large) return 3;
    return 2;
  }

  /// Text-scale-aware SliverGridDelegate for product cards so cards never overflow
  /// on 320dp small phones or 2.0x accessibility font scaling, and never stretch on tablets.
  SliverGridDelegateWithFixedCrossAxisCount responsiveProductGridDelegate({
    double baseMainAxisExtent = 252.0,
    double extraExtentPerTextScaleUnit = 92.0,
    double crossAxisSpacing = 12.0,
    double mainAxisSpacing = 12.0,
    double? availableWidth,
  }) {
    final cols = productGridColumnsForWidth(availableWidth);
    final scaleDelta = (effectiveTextScale - 1.0).clamp(0.0, 1.2);
    final extent = baseMainAxisExtent + (scaleDelta * extraExtentPerTextScaleUnit);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cols,
      mainAxisExtent: extent,
      crossAxisSpacing: isSmallPhone ? 8.0 : crossAxisSpacing,
      mainAxisSpacing: isSmallPhone ? 10.0 : mainAxisSpacing,
    );
  }

  /// Text-scale-aware SliverGridDelegate for category / subcategory tiles.
  SliverGridDelegateWithFixedCrossAxisCount responsiveCategoryGridDelegate({
    double baseMainAxisExtent = 54.0,
    double extraExtentPerTextScaleUnit = 38.0,
    double crossAxisSpacing = 10.0,
    double mainAxisSpacing = 10.0,
    double? availableWidth,
  }) {
    final cols = categoryGridColumnsForWidth(availableWidth);
    final scaleDelta = (effectiveTextScale - 1.0).clamp(0.0, 1.2);
    final extent = baseMainAxisExtent + (scaleDelta * extraExtentPerTextScaleUnit);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cols,
      mainAxisExtent: extent,
      crossAxisSpacing: isSmallPhone ? 8.0 : crossAxisSpacing,
      mainAxisSpacing: isSmallPhone ? 8.0 : mainAxisSpacing,
    );
  }

  /// Responsive height for hero promotional banner carousels.
  double get responsivePromoBannerHeight {
    final scaleDelta = (effectiveTextScale - 1.0).clamp(0.0, 1.2);
    return 184.0 + (scaleDelta * 64.0);
  }

  /// Responsive height for horizontal live preview carousels (`معاينات حية`).
  double get responsiveLivePreviewHeight {
    final scaleDelta = (effectiveTextScale - 1.0).clamp(0.0, 1.2);
    return 224.0 + (scaleDelta * 56.0);
  }

  /// Responsive height for horizontal featured product carousels.
  double get responsiveFeaturedCarouselHeight {
    final scaleDelta = (effectiveTextScale - 1.0).clamp(0.0, 1.2);
    return 256.0 + (scaleDelta * 76.0);
  }

  /// Returns a responsive value tailored to mobile/tablet sizes.
  T responsiveValue<T>({required T compact, T? standard, T? large}) {
    if (isCompactPhone) {
      return compact;
    }
    if ((isLargePhone || isTablet) && large != null) {
      return large;
    }
    return standard ?? compact;
  }
}
