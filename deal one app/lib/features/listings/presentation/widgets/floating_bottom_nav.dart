import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

/// Floating dark-navy pill navigation bar matching all 7 Home reference PNGs:
/// - Active pill on start (right in RTL) with home icon + `الرئيسية`.
/// - Three icons on end (left in RTL): Sparkles, 3D Package Cube, and User-Gear.
class DealOneFloatingBottomNav extends StatelessWidget {
  final int activeIndex;

  const DealOneFloatingBottomNav({
    super.key,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isSmall = context.isSmallPhone;
    final hPad = context.horizontalScreenPadding;

    final items = [
      (
        icon: Icons.home_rounded,
        label: isArabic ? 'الرئيسية' : 'Home',
        route: RouteNames.root,
      ),
      (
        icon: Icons.auto_awesome_outlined,
        label: isArabic ? 'استكشف' : 'Explore',
        route: RouteNames.search,
      ),
      (
        icon: Icons.view_in_ar_outlined,
        label: isArabic ? 'المفضلة' : 'Saved',
        route: RouteNames.favorites,
      ),
      (
        icon: Icons.manage_accounts_outlined,
        label: isArabic ? 'حسابي' : 'Profile',
        route: RouteNames.profile,
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(hPad, 0, hPad, 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 560,
              minHeight: 62,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 8 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: DealOneDesignColors.navy,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: DealOneDesignColors.navy.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == activeIndex;

                  final pill = GestureDetector(
                    onTap: () {
                      if (isSelected) return;
                      if (item.route == RouteNames.root) {
                        context.go(RouteNames.root);
                      } else {
                        context.push(item.route);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected
                            ? (isSmall ? 14 : 20)
                            : (isSmall ? 10 : 14),
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.17)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Flexible(
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: isSmall ? 12.5 : 13.5,
                                ),
                              ),
                            ),
                            SizedBox(width: isSmall ? 6 : 8),
                          ],
                          Icon(
                            item.icon,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.72),
                            size: isSmall ? 20 : 22,
                          ),
                        ],
                      ),
                    ),
                  );

                  return isSelected ? Flexible(child: pill) : pill;
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
