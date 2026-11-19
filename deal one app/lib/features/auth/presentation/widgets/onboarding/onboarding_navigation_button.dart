import 'package:flutter/material.dart';

import '../../../../../app/app_localization.dart';
import '../../theme/auth_design_tokens.dart';

/// Navigation button row for onboarding:
/// - Slide 1: Full-width primary CTA (`Next`).
/// - Slide 2: Directional `Previous` button + primary CTA (`Next`).
/// - Slide 3: Directional `Previous` button + primary CTA (`Create Account`).
class OnboardingNavigationButtonRow extends StatelessWidget {
  final String primaryLabel;
  final bool showPrevious;
  final bool isSubmitting;
  final bool reducedMotion;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onPreviousPressed;

  const OnboardingNavigationButtonRow({
    super.key,
    required this.primaryLabel,
    required this.showPrevious,
    required this.isSubmitting,
    required this.reducedMotion,
    required this.onPrimaryPressed,
    this.onPreviousPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final animDuration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 240);

    final previousSlot = showPrevious
        ? Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: SizedBox(
              height: 52,
              width: 56,
              child: Tooltip(
                message: l10n.authPrevious,
                child: OutlinedButton(
                  key: const Key('onboarding_previous_button'),
                  onPressed: isSubmitting ? null : onPreviousPressed,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AuthDesignTokens.buttonRadius,
                      ),
                    ),
                  ),
                  child: Semantics(
                    label: l10n.authPrevious,
                    button: true,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    return Row(
      children: [
        if (reducedMotion)
          previousSlot
        else
          AnimatedSize(
            duration: animDuration,
            curve: Curves.easeOutCubic,
            child: previousSlot,
          ),
        Expanded(
          child: SizedBox(
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
                  : AnimatedSwitcher(
                      duration: animDuration,
                      child: Text(
                        primaryLabel,
                        key: ValueKey<String>(primaryLabel),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
