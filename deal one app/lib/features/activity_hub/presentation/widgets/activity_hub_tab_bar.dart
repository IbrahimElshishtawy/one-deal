import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';
import 'package:market_space/features/activity_hub/presentation/utils/activity_hub_l10n.dart';

class ActivityHubTabBar extends StatelessWidget {
  final ActivityHubTab selectedTab;
  final ValueChanged<ActivityHubTab> onTabSelected;
  final Map<ActivityHubTab, int> badgeCounts;

  const ActivityHubTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.badgeCounts = const {},
  });

  IconData _iconFor(ActivityHubTab tab) {
    switch (tab) {
      case ActivityHubTab.cart:
        return Icons.shopping_basket_rounded;
      case ActivityHubTab.bookings:
        return Icons.calendar_month_rounded;
      case ActivityHubTab.rfq:
        return Icons.request_quote_rounded;
      case ActivityHubTab.favorites:
        return Icons.favorite_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final hPad = context.horizontalScreenPadding;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hPad),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryOf(context),
        borderRadius: AppRadii.lg,
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ActivityHubTab.values.map((tab) {
            final isSelected = tab == selectedTab;
            final count = badgeCounts[tab] ?? 0;
            final selectedBg = isDark
                ? AppColors.darkPrimary
                : DealOneDesignColors.navy;
            final selectedFg = isDark ? AppColors.darkOnPrimary : Colors.white;
            final unselectedFg = AppColors.textSecondaryOf(context);

            return Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: Material(
                color: isSelected ? selectedBg : Colors.transparent,
                borderRadius: AppRadii.md,
                child: InkWell(
                  onTap: () => onTabSelected(tab),
                  borderRadius: AppRadii.md,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 42),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _iconFor(tab),
                            size: 17,
                            color: isSelected ? selectedFg : unselectedFg,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ActivityHubL10n.tabLabel(context, tab),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected ? selectedFg : unselectedFg,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? selectedFg.withValues(alpha: 0.2)
                                    : DealOneDesignColors.amberPrice
                                          .withValues(alpha: 0.16),
                                borderRadius: AppRadii.full,
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? selectedFg
                                      : DealOneDesignColors.amberPrice,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
