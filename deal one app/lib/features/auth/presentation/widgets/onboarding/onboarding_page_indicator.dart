import 'package:flutter/material.dart';

/// Full-width 3-segment horizontal bar indicator matching the onboarding
/// Figma exports (`Onboarding 1–3`): pure white active segment, translucent
/// inactive segments. Respects RTL/LTR directionality automatically.
class OnboardingPageIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalPages;

  const OnboardingPageIndicator({
    super.key,
    required this.currentIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalPages, (index) {
        final isActive = index == currentIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              end: index == totalPages - 1 ? 0 : 10,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              height: 4.5,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }
}
