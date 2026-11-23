import 'package:flutter/material.dart';

import 'package:market_space/core/constants/app_constants.dart';
import 'package:market_space/core/theme/app_colors.dart';

/// Unified brand logo widget for DealOne.
///
/// Always loads [AppConstants.logoAssetPath] (`assets/image/logo.png`) with
/// [BoxFit.contain] so the original aspect ratio is preserved without cropping
/// or distortion.
class DealOneLogo extends StatelessWidget {
  /// Target height for the logo. When [width] is omitted, the image scales
  /// proportionally to preserve its intrinsic aspect ratio.
  final double? height;

  /// Optional maximum width constraint. Combined with [BoxFit.contain], this
  /// never stretches or crops the image.
  final double? width;

  /// Adds a subtle radial backdrop behind the logo in dark mode so metallic
  /// lettering stays legible on dark surfaces.
  final bool showDarkModeGlow;

  /// Optional custom fallback widget if the asset cannot be decoded.
  final Widget? fallback;

  const DealOneLogo({
    super.key,
    this.height,
    this.width,
    this.showDarkModeGlow = false,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveFallbackSize = (height ?? width ?? 48) * 0.55;

    final image = Image.asset(
      AppConstants.logoAssetPath,
      height: height,
      width: width,
      fit: BoxFit.contain,
      semanticLabel: AppConstants.appName,
      errorBuilder: (context, error, stackTrace) {
        if (fallback != null) return fallback!;
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handshake_outlined,
              size: effectiveFallbackSize.clamp(14.0, 64.0),
              color: isDark ? Colors.white : DealOneDesignColors.navy,
            ),
            if ((height ?? 48) >= 48) ...[
              const SizedBox(height: 4),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : DealOneDesignColors.navy,
                ),
              ),
            ],
          ],
        );
      },
    );

    if (!showDarkModeGlow || !isDark) {
      return image;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.06),
            Colors.transparent,
          ],
          stops: const [0.0, 0.58, 1.0],
        ),
      ),
      child: image,
    );
  }
}
