import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';
import 'onboarding_slide_data.dart';

/// Full-bleed illustrated backdrop matching the 3 Deal One onboarding Figma
/// exports, with a dark bottom gradient scrim for legible foreground copy.
class OnboardingIllustration extends StatelessWidget {
  final OnboardingSlideData slide;

  const OnboardingIllustration({super.key, required this.slide});

  @override
  Widget build(BuildContext context) {
    final isDark = AuthDesignTokens.isDark(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Top-anchored full-bleed Figma illustration
        Container(
          color: AuthDesignTokens.onboardingScrimBottom,
          child: Image.asset(
            slide.artworkAssetPath,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, _, _) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFBFD7ED),
                    Color(0xFF476985),
                    AuthDesignTokens.onboardingScrimBottom,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  _fallbackIcon,
                  size: 96,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ),
        // Subtle dark tint in Dark Mode to reduce glare on the bright sky
        if (isDark)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
            ),
          ),
        // Bottom dark gradient scrim ensuring crisp white text contrast
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.48, 0.72, 0.88, 1.0],
              colors: [
                Color(0x000E1521),
                Color(0x140E1521),
                Color(0xB80E1521),
                Color(0xEE0E1521),
                AuthDesignTokens.onboardingScrimBottom,
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData get _fallbackIcon {
    switch (slide.illustrationType) {
      case OnboardingIllustrationType.realEstateAndCars:
        return Icons.directions_car_filled_rounded;
      case OnboardingIllustrationType.homeServicesAndMaterials:
        return Icons.home_repair_service_rounded;
      case OnboardingIllustrationType.fashionAndDecor:
        return Icons.checkroom_rounded;
    }
  }
}
