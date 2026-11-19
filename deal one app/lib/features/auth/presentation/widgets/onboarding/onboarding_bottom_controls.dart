import 'package:flutter/material.dart';

import 'onboarding_navigation_button.dart';
import 'onboarding_page_indicator.dart';

/// Bottom onboarding control cluster: 3-segment animated progress indicator
/// + directional Previous / Next / Create Account navigation buttons.
class OnboardingBottomControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final String primaryLabel;
  final bool showPrevious;
  final bool isSubmitting;
  final bool reducedMotion;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onPreviousPressed;

  const OnboardingBottomControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.primaryLabel,
    required this.showPrevious,
    required this.isSubmitting,
    this.reducedMotion = false,
    required this.onPrimaryPressed,
    this.onPreviousPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OnboardingPageIndicator(
          currentIndex: currentPage,
          totalPages: totalPages,
          reducedMotion: reducedMotion,
        ),
        const SizedBox(height: 20),
        OnboardingNavigationButtonRow(
          primaryLabel: primaryLabel,
          showPrevious: showPrevious,
          isSubmitting: isSubmitting,
          reducedMotion: reducedMotion,
          onPrimaryPressed: onPrimaryPressed,
          onPreviousPressed: onPreviousPressed,
        ),
      ],
    );
  }
}
