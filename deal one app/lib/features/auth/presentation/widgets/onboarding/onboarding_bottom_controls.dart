import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';
import 'onboarding_page_indicator.dart';

/// Bottom onboarding controls matching the 3 Figma exports:
/// 3-segment progress bar + full-width bright blue CTA with 1px white border.
class OnboardingBottomControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final String primaryLabel;
  final bool isSubmitting;
  final VoidCallback onPrimaryPressed;

  const OnboardingBottomControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.primaryLabel,
    required this.isSubmitting,
    required this.onPrimaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OnboardingPageIndicator(
          currentIndex: currentPage,
          totalPages: totalPages,
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            key: const Key('onboarding_primary_button'),
            onPressed: isSubmitting ? null : onPrimaryPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AuthDesignTokens.onboardingCtaBlue,
              disabledBackgroundColor: AuthDesignTokens.onboardingCtaBlue
                  .withValues(alpha: 0.65),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AuthDesignTokens.buttonRadius,
                ),
                side: const BorderSide(color: Colors.white, width: 1.2),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    primaryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
