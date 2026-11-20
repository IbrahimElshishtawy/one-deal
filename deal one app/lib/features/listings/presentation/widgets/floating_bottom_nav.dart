import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

/// Floating dark-navy pill navigation bar matching `Home 1 - Main Hub.png`.
/// Adapts across 320dp small phones, standard phones, tablets (max 560dp centered pill),
/// and up to 2.0x text scaling without overflow.
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
        icon: Icons.favorite_border_rounded,
        label: isArabic ? 'المفضلة' : 'Saved',
        route: RouteNames.favorites,
      ),
      (
        icon: Icons.person_outline_rounded,
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
              minHeight: 60,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 6 : 10,
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
                            ? (isSmall ? 12 : 16)
                            : (isSmall ? 10 : 14),
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.16)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.68),
                            size: isSmall ? 20 : 22,
                          ),
                          if (isSelected) ...[
                            SizedBox(width: isSmall ? 5 : 8),
                            Flexible(
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: isSmall ? 12 : 13,
                                ),
                              ),
                            ),
                          ],
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
