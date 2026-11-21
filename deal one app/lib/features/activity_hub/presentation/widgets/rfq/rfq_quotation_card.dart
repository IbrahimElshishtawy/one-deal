import 'package:flutter/material.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';
import 'package:market_space/features/activity_hub/presentation/utils/activity_hub_l10n.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_action_button.dart';

class RfqQuotationCard extends StatelessWidget {
  final RfqQuotationEntity quotation;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const RfqQuotationCard({
    super.key,
    required this.quotation,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryOf(context),
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  quotation.supplierName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ),
              Text(
                ActivityHubL10n.formatPrice(
                  quotation.totalPrice,
                  currency: quotation.currency,
                  isArabic: isArabic,
                ),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: DealOneDesignColors.amberPrice,
                ),
              ),
            ],
          ),
          if (quotation.deliveryEstimate != null &&
              quotation.deliveryEstimate!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              quotation.deliveryEstimate!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ],
          if (quotation.notes != null && quotation.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              quotation.notes!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMutedOf(context),
              ),
            ),
          ],
          if (quotation.canAccept || quotation.canReject) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (quotation.canAccept && onAccept != null)
                  Expanded(
                    child: ActivityActionButton(
                      label: l10n.rfqAcceptQuotationAction,
                      icon: Icons.check_rounded,
                      onPressed: onAccept,
                    ),
                  ),
                if (quotation.canAccept && quotation.canReject)
                  const SizedBox(width: AppSpacing.sm),
                if (quotation.canReject && onReject != null)
                  Expanded(
                    child: ActivityActionButton(
                      label: l10n.rfqRejectQuotationAction,
                      icon: Icons.close_rounded,
                      isOutlined: true,
                      isDestructive: true,
                      onPressed: onReject,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
