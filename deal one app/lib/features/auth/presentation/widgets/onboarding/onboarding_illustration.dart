import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';
import 'onboarding_slide_data.dart';

/// Rich layered visual illustration for each Deal One onboarding screen.
class OnboardingIllustration extends StatelessWidget {
  final OnboardingSlideData slide;

  const OnboardingIllustration({
    super.key,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AuthDesignTokens.isDark(context);
    final circleBg = isDark
        ? AuthDesignTokens.darkSurface
        : const Color(0xFFF1F5FB);

    return Container(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 280),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              color: circleBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: AuthDesignTokens.borderOf(context),
                width: 1.2,
              ),
            ),
          ),
          Container(
            width: 176,
            height: 176,
            decoration: BoxDecoration(
              color: AuthDesignTokens.backgroundOf(context),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AuthDesignTokens.navyPrimary.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _buildCenterVisual(context),
          ),
          ..._buildFloatingCards(context),
        ],
      ),
    );
  }

  Widget _buildCenterVisual(BuildContext context) {
    switch (slide.illustrationType) {
      case OnboardingIllustrationType.marketplaceHub:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Image.asset(
            AuthDesignTokens.logoAssetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.storefront_rounded,
              size: 64,
              color: AuthDesignTokens.navyPrimary,
            ),
          ),
        );
      case OnboardingIllustrationType.verifiedTrust:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AuthDesignTokens.actionBlueTint,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 40,
                color: AuthDesignTokens.actionBlue,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AuthDesignTokens.successTintOf(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'حساب موثق',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AuthDesignTokens.successGreen,
                ),
              ),
            ),
          ],
        );
      case OnboardingIllustrationType.localDeals:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AuthDesignTokens.focusOrangeTint,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 42,
                color: AuthDesignTokens.focusOrange,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AuthDesignTokens.navyPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'عروض قريبة منك',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AuthDesignTokens.headingOf(context),
                ),
              ),
            ),
          ],
        );
    }
  }

  List<Widget> _buildFloatingCards(BuildContext context) {
    switch (slide.illustrationType) {
      case OnboardingIllustrationType.marketplaceHub:
        return [
          const Positioned(
            top: 22,
            right: 18,
            child: _FloatingBadge(
              icon: Icons.directions_car_filled_rounded,
              label: 'سيارات',
              accent: AuthDesignTokens.actionBlue,
            ),
          ),
          const Positioned(
            bottom: 24,
            left: 16,
            child: _FloatingBadge(
              icon: Icons.apartment_rounded,
              label: 'عقارات',
              accent: AuthDesignTokens.focusOrange,
            ),
          ),
        ];
      case OnboardingIllustrationType.verifiedTrust:
        return [
          const Positioned(
            top: 22,
            left: 14,
            child: _FloatingBadge(
              icon: Icons.lock_outline_rounded,
              label: 'تحقق فوري',
              accent: AuthDesignTokens.navyPrimary,
            ),
          ),
          const Positioned(
            bottom: 22,
            right: 18,
            child: _FloatingBadge(
              icon: Icons.handshake_rounded,
              label: 'تواصل مباشر',
              accent: AuthDesignTokens.successGreen,
            ),
          ),
        ];
      case OnboardingIllustrationType.localDeals:
        return [
          const Positioned(
            top: 22,
            right: 16,
            child: _FloatingBadge(
              icon: Icons.tune_rounded,
              label: 'بحث ذكي',
              accent: AuthDesignTokens.actionBlue,
            ),
          ),
          const Positioned(
            bottom: 22,
            left: 18,
            child: _FloatingBadge(
              icon: Icons.favorite_rounded,
              label: 'المفضلة',
              accent: AuthDesignTokens.errorRed,
            ),
          ),
        ];
    }
  }
}

class _FloatingBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _FloatingBadge({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AuthDesignTokens.backgroundOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuthDesignTokens.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AuthDesignTokens.headingOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
