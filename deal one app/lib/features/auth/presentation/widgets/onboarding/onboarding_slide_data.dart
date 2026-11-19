import 'package:flutter/material.dart';

import '../../../../../app/app_localization.dart';

enum OnboardingIllustrationType {
  realEstateAndCars,
  homeServicesAndMaterials,
  fashionAndDecor,
}

/// Immutable slide descriptor combining localized copy and per-image
/// cinematic Ken Burns framing parameters for Deal One's 3 onboarding assets.
class OnboardingSlideData {
  final OnboardingIllustrationType illustrationType;
  final String artworkAssetPath;
  final String subtitle;
  final String title;
  final String description;
  final String primaryButtonLabel;
  final bool showSkip;
  final bool showPrevious;
  final Alignment focalAlignment;
  final Offset kenBurnsBeginOffset;
  final Offset kenBurnsEndOffset;

  const OnboardingSlideData({
    required this.illustrationType,
    required this.artworkAssetPath,
    required this.subtitle,
    required this.title,
    required this.description,
    required this.primaryButtonLabel,
    required this.showSkip,
    required this.showPrevious,
    required this.focalAlignment,
    required this.kenBurnsBeginOffset,
    required this.kenBurnsEndOffset,
  });

  /// Canonical list of onboarding image asset paths for one-time precaching.
  static const List<String> artworkAssetPaths = [
    'assets/image/onboarding_1.png',
    'assets/image/onboarding_2.png',
    'assets/image/onboarding_3.png',
  ];

  static List<OnboardingSlideData> localizedSlides(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return [
      OnboardingSlideData(
        illustrationType: OnboardingIllustrationType.realEstateAndCars,
        artworkAssetPath: artworkAssetPaths[0],
        subtitle: l10n.onboarding1Subtitle,
        title: l10n.onboarding1Title,
        description: l10n.onboarding1Desc,
        primaryButtonLabel: l10n.authNext,
        showSkip: true,
        showPrevious: false,
        focalAlignment: const Alignment(0.0, 0.15),
        kenBurnsBeginOffset: const Offset(-5, -8),
        kenBurnsEndOffset: const Offset(5, 6),
      ),
      OnboardingSlideData(
        illustrationType: OnboardingIllustrationType.homeServicesAndMaterials,
        artworkAssetPath: artworkAssetPaths[1],
        subtitle: l10n.onboarding2Subtitle,
        title: l10n.onboarding2Title,
        description: l10n.onboarding2Desc,
        primaryButtonLabel: l10n.authNext,
        showSkip: true,
        showPrevious: true,
        focalAlignment: const Alignment(0.0, 0.18),
        kenBurnsBeginOffset: const Offset(6, -6),
        kenBurnsEndOffset: const Offset(-6, 8),
      ),
      OnboardingSlideData(
        illustrationType: OnboardingIllustrationType.fashionAndDecor,
        artworkAssetPath: artworkAssetPaths[2],
        subtitle: l10n.onboarding3Subtitle,
        title: l10n.onboarding3Title,
        description: l10n.onboarding3Desc,
        primaryButtonLabel: l10n.authCreateAccount,
        showSkip: false,
        showPrevious: true,
        focalAlignment: const Alignment(0.0, 0.15),
        kenBurnsBeginOffset: const Offset(-5, -6),
        kenBurnsEndOffset: const Offset(5, 6),
      ),
    ];
  }
}
