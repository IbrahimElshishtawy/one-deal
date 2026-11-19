import 'package:flutter/material.dart';

/// Full-width 3-segment animated progress bar matching the onboarding Figma
/// exports: pure white active segment, translucent inactive segments,
/// automatically respecting RTL/LTR directionality and reduced motion.
class OnboardingPageIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalPages;
  final bool reducedMotion;

  const OnboardingPageIndicator({
    super.key,
    required this.currentIndex,
    required this.totalPages,
    this.reducedMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    final duration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 260);

    return Row(
      children: List.generate(totalPages, (index) {
        final isActive = index == currentIndex;
        final isVisited = index < currentIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              end: index == totalPages - 1 ? 0 : 10,
            ),
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              height: isActive ? 5.0 : 4.0,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: isVisited ? 0.65 : 0.38),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }
}
