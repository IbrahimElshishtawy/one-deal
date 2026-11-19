import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';

/// Theme-aware atmospheric gradient overlays for the cinematic onboarding
/// backdrop:
/// - Subtle top vignette protecting status bar & Skip action contrast.
/// - Smooth bottom scrim creating a legible text-safe area without harshly
///   cutting off the illustrated subjects.
/// - Gentle dark-mode brightness moderation preserving artwork detail.
class OnboardingBackground extends StatelessWidget {
  final Widget child;

  const OnboardingBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = AuthDesignTokens.isDark(context);
    final scrimBase = isDark
        ? AuthDesignTokens.darkBackground
        : AuthDesignTokens.onboardingScrimBottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: scrimBase, child: child),
        // Gentle dark-mode dim layer to reduce sky glare while keeping subjects vivid
        if (isDark)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.20),
              ),
            ),
          ),
        // Subtle top gradient for Skip button & status bar legibility
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.16, 0.28],
                colors: [
                  (isDark ? Colors.black : const Color(0xFF0E1521)).withValues(
                    alpha: isDark ? 0.42 : 0.14,
                  ),
                  (isDark ? Colors.black : const Color(0xFF0E1521)).withValues(
                    alpha: isDark ? 0.14 : 0.04,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Bottom text-safe gradient scrim with smooth edge blending
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.54, 0.72, 0.86, 1.0],
                colors: [
                  Colors.transparent,
                  scrimBase.withValues(alpha: 0.06),
                  scrimBase.withValues(alpha: 0.74),
                  scrimBase.withValues(alpha: 0.94),
                  scrimBase,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
