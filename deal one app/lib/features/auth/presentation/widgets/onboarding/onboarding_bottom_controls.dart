import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';
import '../common/auth_primary_button.dart';
import 'onboarding_page_indicator.dart';

/// Bottom navigation bar for onboarding: indicator + primary CTA + guest browsing option.
class OnboardingBottomControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final String primaryLabel;
  final bool isSubmitting;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onBrowseAsGuest;

  const OnboardingBottomControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.primaryLabel,
    required this.isSubmitting,
    required this.onPrimaryPressed,
    this.onBrowseAsGuest,
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
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: primaryLabel,
          isLoading: isSubmitting,
          onPressed: onPrimaryPressed,
        ),
        if (onBrowseAsGuest != null) ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: isSubmitting ? null : onBrowseAsGuest,
            child: Text(
              'استكشاف الإعلانات أولاً',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AuthDesignTokens.mutedOf(context),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
