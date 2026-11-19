import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/listings/presentation/widgets/deal_one_listing_card.dart';

/// Floating dark-navy pill navigation bar matching `Home 1 - Main Hub.png`.
class DealOneFloatingBottomNav extends StatelessWidget {
  final int activeIndex;

  const DealOneFloatingBottomNav({
    super.key,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;

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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

              return GestureDetector(
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
                    horizontal: isSelected ? 18 : 14,
                    vertical: 10,
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
                        size: 22,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
