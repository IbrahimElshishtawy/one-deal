import '../../../../../l10n/generated/app_localizations.dart';

enum OnboardingIllustrationType {
  realEstateAndCars,
  homeServicesAndMaterials,
  fashionAndDecor,
}

/// Immutable content descriptor for each Deal One onboarding slide
/// matching the 3 Figma onboarding reference screens.
class OnboardingSlideData {
  final OnboardingIllustrationType illustrationType;
  final String title;
  final String description;
  final String primaryButtonLabel;
  final bool showSkip;

  const OnboardingSlideData({
    required this.illustrationType,
    required this.title,
    required this.description,
    required this.primaryButtonLabel,
    required this.showSkip,
  });

  static List<OnboardingSlideData> localizedSlides(AppLocalizations l10n) => [
    OnboardingSlideData(
      illustrationType: OnboardingIllustrationType.realEstateAndCars,
      title: l10n.onboardingSlide1Title,
      description: l10n.onboardingSlide1Description,
      primaryButtonLabel: l10n.onboardingNext,
      showSkip: true,
    ),
    OnboardingSlideData(
      illustrationType: OnboardingIllustrationType.homeServicesAndMaterials,
      title: l10n.onboardingSlide2Title,
      description: l10n.onboardingSlide2Description,
      primaryButtonLabel: l10n.onboardingNext,
      showSkip: true,
    ),
    OnboardingSlideData(
      illustrationType: OnboardingIllustrationType.fashionAndDecor,
      title: l10n.onboardingSlide3Title,
      description: l10n.onboardingSlide3Description,
      primaryButtonLabel: l10n.onboardingCreateAccount,
      showSkip: false,
    ),
  ];
}
