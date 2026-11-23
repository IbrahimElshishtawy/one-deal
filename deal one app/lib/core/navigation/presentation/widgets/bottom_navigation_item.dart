import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/config/deal_one_navigation_tokens.dart';
import 'package:market_space/core/navigation/models/navigation_item.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

/// Single tab button inside [DealOneBottomNavigation].
///
/// Renders a vertically stacked icon + label with smooth color and icon
/// transitions while keeping identical bounds in both active and inactive states.
class BottomNavigationItem extends StatelessWidget {
  final DealOneNavigationItem item;
  final bool isActive;
  final VoidCallback onTap;

  const BottomNavigationItem({
    super.key,
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = context.isSmallPhone;
    final label = item.labelFor(context);
    final targetColor = isActive
        ? DealOneBottomNavTokens.activeForegroundOf(context)
        : DealOneBottomNavTokens.inactiveForegroundOf(context);
    final fontSize = isSmall
        ? DealOneBottomNavTokens.compactLabelFontSize
        : DealOneBottomNavTokens.labelFontSize;
    final iconSize = isSmall
        ? DealOneBottomNavTokens.compactIconSize
        : DealOneBottomNavTokens.iconSize;

    return Semantics(
      selected: isActive,
      button: true,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('deal_one_nav_item_${item.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            DealOneBottomNavTokens.activePillRadius,
          ),
          splashColor: DealOneBottomNavTokens.activeBackground.withValues(
            alpha: 0.08,
          ),
          highlightColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: DealOneBottomNavTokens.itemMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DealOneBottomNavTokens.pillHorizontalInset + 2,
                vertical: DealOneBottomNavTokens.pillVerticalPadding,
              ),
              child: TweenAnimationBuilder<Color?>(
                duration: DealOneBottomNavTokens.transitionDuration,
                curve: DealOneBottomNavTokens.transitionCurve,
                tween: ColorTween(end: targetColor),
                builder: (context, animatedColor, _) {
                  final color = animatedColor ?? targetColor;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: DealOneBottomNavTokens.iconSwitchDuration,
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          key: ValueKey<bool>(isActive),
                          size: iconSize,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: DealOneBottomNavTokens.iconLabelGap),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: DealOneBottomNavTokens.fontFamily,
                          fontSize: fontSize,
                          height: 1.2,
                          fontWeight: isActive
                              ? DealOneBottomNavTokens.activeFontWeight
                              : DealOneBottomNavTokens.inactiveFontWeight,
                          color: color,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
