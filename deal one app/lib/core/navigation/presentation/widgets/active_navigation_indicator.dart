import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/config/deal_one_navigation_tokens.dart';

/// Sliding `#1B2A4A` pill indicator that moves smoothly behind the active tab
/// without altering the bar's height or horizontal layout.
///
/// Uses [AlignmentDirectional] so RTL (Arabic) and LTR (English) directions
/// are handled natively without manual coordinate flipping.
class ActiveNavigationIndicator extends StatelessWidget {
  final int activeIndex;
  final int itemCount;

  const ActiveNavigationIndicator({
    super.key,
    required this.activeIndex,
    required this.itemCount,
  });

  double _directionalAlignmentX() {
    if (itemCount <= 1) return 0.0;
    final clamped = activeIndex.clamp(0, itemCount - 1);
    return -1.0 + (2.0 * clamped / (itemCount - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedAlign(
          duration: DealOneBottomNavTokens.transitionDuration,
          curve: DealOneBottomNavTokens.transitionCurve,
          alignment: AlignmentDirectional(_directionalAlignmentX(), 0.0),
          child: FractionallySizedBox(
            widthFactor: 1.0 / itemCount,
            heightFactor: 1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DealOneBottomNavTokens.pillHorizontalInset,
              ),
              child: DecoratedBox(
                key: const Key('deal_one_nav_active_pill'),
                decoration: BoxDecoration(
                  color: DealOneBottomNavTokens.activeBackgroundOf(context),
                  borderRadius: BorderRadius.circular(
                    DealOneBottomNavTokens.activePillRadius,
                  ),
                  boxShadow: DealOneBottomNavTokens.activePillShadowOf(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
