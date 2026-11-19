import 'package:flutter/widgets.dart';

import '../../../../../app/app_localization.dart';

enum OnboardingIllustrationType {
  realEstateAndCars,
  homeServicesAndMaterials,
  fashionAndDecor,
}

/// Immutable content descriptor for each Deal One onboarding slide
/// matching the 3 Figma exports in `ui/Authentication & Account Screens/`.
class OnboardingSlideData {
  final OnboardingIllustrationType illustrationType;
  final String artworkAssetPath;
  final String title;
  final String description;
  final String primaryButtonLabel;
  final bool showSkip;

  const OnboardingSlideData({
    required this.illustrationType,
    required this.artworkAssetPath,
    required this.title,
    required this.description,
    required this.primaryButtonLabel,
    required this.showSkip,
  });

  static List<OnboardingSlideData> localizedSlides(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return [
      OnboardingSlideData(
        illustrationType: OnboardingIllustrationType.realEstateAndCars,
        artworkAssetPath: 'assets/image/onboarding_1.png',
        title: l10n.onboarding1Title,
        description: l10n.onboarding1Desc,
        primaryButtonLabel: l10n.authNext,
        showSkip: true,
      ),
      OnboardingSlideData(
        illustrationType: OnboardingIllustrationType.homeServicesAndMaterials,
        artworkAssetPath: 'assets/image/onboarding_2.png',
        title: l10n.onboarding2Title,
        description: l10n.onboarding2Desc,
        primaryButtonLabel: l10n.authNext,
        showSkip: true,
      ),
      OnboardingSlideData(
        illustrationType: OnboardingIllustrationType.fashionAndDecor,
        artworkAssetPath: 'assets/image/onboarding_3.png',
        title: l10n.onboarding3Title,
        description: l10n.onboarding3Desc,
        primaryButtonLabel: l10n.authCreateAccount,
        showSkip: false,
      ),
    ];
  }
}
