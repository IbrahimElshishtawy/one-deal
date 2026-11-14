import 'package:flutter/material.dart';

enum OnboardingIllustrationType { marketplaceHub, verifiedTrust, localDeals }

/// Immutable content descriptor for each Deal One onboarding slide.
class OnboardingSlideData {
  final OnboardingIllustrationType illustrationType;
  final String badgeText;
  final String title;
  final String description;
  final String primaryButtonLabel;
  final IconData accentIcon;

  const OnboardingSlideData({
    required this.illustrationType,
    required this.badgeText,
    required this.title,
    required this.description,
    required this.primaryButtonLabel,
    required this.accentIcon,
  });

  static const List<OnboardingSlideData> slides = [
    OnboardingSlideData(
      illustrationType: OnboardingIllustrationType.marketplaceHub,
      badgeText: 'سوق واحد متكامل',
      title: 'كل ما تحتاجه في مكان واحد',
      description:
          'تصفح آلاف الإعلانات الموثوقة في العقارات، السيارات، الإلكترونيات والخدمات في جميع محافظات مصر.',
      primaryButtonLabel: 'التالي',
      accentIcon: Icons.storefront_rounded,
    ),
    OnboardingSlideData(
      illustrationType: OnboardingIllustrationType.verifiedTrust,
      badgeText: 'أمان ومصداقية',
      title: 'تواصل مباشر وصفقات آمنة',
      description:
          'حسابات موثقة برقم الهاتف وتقييمات حقيقية وتفاصيل دقيقة لكل إعلان لتشتري وتبيع بثقة تامة.',
      primaryButtonLabel: 'التالي',
      accentIcon: Icons.verified_user_rounded,
    ),
    OnboardingSlideData(
      illustrationType: OnboardingIllustrationType.localDeals,
      badgeText: 'أقرب لك دائماً',
      title: 'أفضل العروض بالقرب منك',
      description:
          'ابحث بذكاء حسب المحافظة والمنطقة والفئة السعرية وتابع إعلاناتك المفضلة لحظة بلحظة.',
      primaryButtonLabel: 'ابدأ الآن',
      accentIcon: Icons.location_on_rounded,
    ),
  ];
}
