import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/config/deal_one_navigation_routes.dart';
import 'package:market_space/core/navigation/config/deal_one_navigation_tokens.dart';
import 'package:market_space/core/navigation/models/navigation_item.dart';
import 'package:market_space/core/navigation/presentation/widgets/active_navigation_indicator.dart';
import 'package:market_space/core/navigation/presentation/widgets/bottom_navigation_item.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

/// Reusable Deal One Bottom Navigation Bar implementing the approved
/// 4-state Variant Matrix (Home, Favorites, Orders, Profile).
///
/// Pure presentation component: receives [activeIndex] and notifies
/// [onTabSelected] without embedding business or routing logic.
class DealOneBottomNavigation extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabSelected;
  final List<DealOneNavigationItem> items;
  final DealOneBottomNavStyle style;

  const DealOneBottomNavigation({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
    this.items = DealOneNavigationRoutes.primaryItems,
    this.style = DealOneBottomNavStyle.floating,
  });

  @override
  Widget build(BuildContext context) {
    assert(items.isNotEmpty, 'DealOneBottomNavigation requires at least 1 item');
    final safeIndex = activeIndex.clamp(0, items.length - 1);
    final isSmall = context.isSmallPhone;
    final screenHPad = context.horizontalScreenPadding;
    final isFloating = style == DealOneBottomNavStyle.floating;

    final barPadding = EdgeInsets.symmetric(
      horizontal: isSmall
          ? DealOneBottomNavTokens.compactHorizontalPadding
          : DealOneBottomNavTokens.horizontalPadding,
      vertical: DealOneBottomNavTokens.verticalPadding,
    );

    final borderRadius = isFloating
        ? BorderRadius.circular(DealOneBottomNavTokens.floatingBarRadius)
        : const BorderRadius.vertical(
            top: Radius.circular(DealOneBottomNavTokens.dockedBarRadius),
          );

    final barContent = MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.28,
      child: Container(
        key: const Key('deal_one_bottom_navigation_bar'),
        padding: barPadding,
        decoration: BoxDecoration(
          color: DealOneBottomNavTokens.barBackgroundOf(context),
          borderRadius: borderRadius,
          border: Border.all(
            color: DealOneBottomNavTokens.barBorderOf(context),
            width: 1.0,
          ),
          boxShadow: isFloating
              ? DealOneBottomNavTokens.floatingBarShadowOf(context)
              : const [],
        ),
        child: IntrinsicHeight(
          child: Stack(
            children: [
              ActiveNavigationIndicator(
                activeIndex: safeIndex,
                itemCount: items.length,
              ),
              Row(
                children: List.generate(items.length, (index) {
                  return Expanded(
                    child: BottomNavigationItem(
                      item: items[index],
                      isActive: index == safeIndex,
                      onTap: () => onTabSelected(index),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );

    if (!isFloating) {
      return SafeArea(
        top: false,
        child: barContent,
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          screenHPad,
          8.0,
          screenHPad,
          12.0,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DealOneBottomNavTokens.maxBarWidth,
            ),
            child: barContent,
          ),
        ),
      ),
    );
  }
}
