import 'package:flutter/material.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/activity_hub/domain/entities/cart_item_entity.dart';
import 'package:market_space/features/activity_hub/presentation/utils/activity_hub_l10n.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_action_button.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_backend_notice_banner.dart';

class CartPriceSummary extends StatelessWidget {
  final CartSummary summary;
  final VoidCallback onCheckoutPressed;

  const CartPriceSummary({
    super.key,
    required this.summary,
    required this.onCheckoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.borderOf(context))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActivityBackendNoticeBanner(
              message: l10n.cartV1CommerceNotice,
              icon: Icons.storefront_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.cartSubtotalLabel} (${l10n.cartItemsCountLabel(summary.totalQuantity)})',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondaryOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ActivityHubL10n.formatPrice(
                    summary.subtotal,
                    currency: summary.currency,
                    isArabic: isArabic,
                  ),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
            if (summary.total != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.cartTotalLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  Text(
                    ActivityHubL10n.formatPrice(
                      summary.total!,
                      currency: summary.currency,
                      isArabic: isArabic,
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: DealOneDesignColors.amberPrice,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ActivityActionButton(
                label: l10n.cartCheckoutAction,
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: onCheckoutPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
