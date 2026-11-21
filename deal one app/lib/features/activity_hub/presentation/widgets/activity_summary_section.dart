import 'package:flutter/material.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/activity_hub/application/providers/activity_hub_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';

class ActivitySummarySection extends StatelessWidget {
  final ActivityHubSummaryCounts counts;
  final ValueChanged<ActivityHubTab> onQuickTap;

  const ActivitySummarySection({
    super.key,
    required this.counts,
    required this.onQuickTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final hPad = context.horizontalScreenPadding;

    final items = [
      (
        tab: ActivityHubTab.cart,
        label: l10n.activitySummaryCartItems(counts.cartCount),
        icon: Icons.shopping_basket_outlined,
        color: DealOneDesignColors.amberPrice,
      ),
      (
        tab: ActivityHubTab.bookings,
        label: l10n.activitySummaryBookings(counts.bookingsCount),
        icon: Icons.event_available_outlined,
        color: AppColors.infoOf(context),
      ),
      (
        tab: ActivityHubTab.rfq,
        label: l10n.activitySummaryRfqs(counts.rfqCount),
        icon: Icons.request_quote_outlined,
        color: AppColors.successOf(context),
      ),
      (
        tab: ActivityHubTab.favorites,
        label: l10n.activitySummaryFavorites(counts.favoritesCount),
        icon: Icons.favorite_outline_rounded,
        color: AppColors.errorOf(context),
      ),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = items[index];
          return Material(
            color: AppColors.surfaceOf(context),
            borderRadius: AppRadii.full,
            child: InkWell(
              onTap: () => onQuickTap(item.tab),
              borderRadius: AppRadii.full,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadii.full,
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 15, color: item.color),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
