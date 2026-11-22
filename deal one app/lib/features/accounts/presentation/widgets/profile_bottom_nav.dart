import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

/// Floating white rounded bottom navigation bar matching `Profile.png`:
/// Home, Favorites, My Orders, Profile (active dark navy pill).
class ProfileBottomNav extends StatelessWidget {
  final int activeIndex;

  const ProfileBottomNav({super.key, this.activeIndex = 3});

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;

    final items = [
      (
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: isArabic ? 'الرئيسية' : 'Home',
        route: RouteNames.root,
      ),
      (
        icon: Icons.favorite_border_rounded,
        activeIcon: Icons.favorite_rounded,
        label: isArabic ? 'المفضلة' : 'Favorites',
        route: RouteNames.favorites,
      ),
      (
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
        label: isArabic ? 'طلباتي' : 'Orders',
        route: RouteNames.activityHub,
      ),
      (
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: isArabic ? 'البروفايل' : 'Profile',
        route: RouteNames.profile,
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(hPad, 0, hPad, AppSpacing.md),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: DealOneTokens.cardDecoration(
                context,
                borderRadius: AppRadii.xl,
              ),
              child: Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final selected = index == activeIndex;
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        if (selected) return;
                        if (item.route == RouteNames.root) {
                          context.go(RouteNames.root);
                        } else {
                          context.push(item.route);
                        }
                      },
                      borderRadius: AppRadii.lg,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? DealOneTokens.navy
                              : Colors.transparent,
                          borderRadius: AppRadii.lg,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selected ? item.activeIcon : item.icon,
                              size: 21,
                              color: selected
                                  ? Colors.white
                                  : DealOneTokens.textPrimaryOf(context),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.isSmallPhone ? 10.5 : 11.5,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : DealOneTokens.textPrimaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
