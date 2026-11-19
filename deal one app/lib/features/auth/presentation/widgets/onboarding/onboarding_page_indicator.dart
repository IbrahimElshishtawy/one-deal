import 'package:flutter/material.dart';

/// 3-segment equal-width horizontal progress bar matching the Deal One
/// onboarding Figma reference screens.
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
                    : Colors.white.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }
}
