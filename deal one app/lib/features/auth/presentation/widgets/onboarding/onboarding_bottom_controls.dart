import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';
import 'onboarding_page_indicator.dart';

/// Bottom navigation overlay for the Deal One onboarding screens:
/// 3-bar progress indicator + Figma-faithful blue bordered CTA button.
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingPageIndicator(
          currentIndex: currentPage,
          totalPages: totalPages,
        ),
        const SizedBox(height: AuthDesignTokens.spaceLg),
        SizedBox(
          height: AuthDesignTokens.buttonHeight,
          child: ElevatedButton(
            key: const Key('onboarding_primary_button'),
            onPressed: isSubmitting ? null : onPrimaryPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AuthDesignTokens.onboardingCtaBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AuthDesignTokens.onboardingCtaBlue
                  .withValues(alpha: 0.55),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.white, width: 1.4),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    primaryLabel,
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
