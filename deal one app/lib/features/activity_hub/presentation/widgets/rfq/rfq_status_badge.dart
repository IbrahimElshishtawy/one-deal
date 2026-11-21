import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';
import 'package:market_space/features/activity_hub/presentation/utils/activity_hub_l10n.dart';

class RfqStatusBadge extends StatelessWidget {
  final RfqStatus status;

  const RfqStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final (Color fg, Color bg) = switch (status) {
      RfqStatus.draft => (
        AppColors.textSecondaryOf(context),
        AppColors.surfaceSecondaryOf(context),
      ),
      RfqStatus.submitted || RfqStatus.underReview => (
        AppColors.warningOf(context),
        isDark ? AppColors.darkWarningTint : AppColors.warningTint,
      ),
      RfqStatus.quoted => (
        AppColors.infoOf(context),
        AppColors.infoTintOf(context),
      ),
      RfqStatus.accepted => (
        AppColors.successOf(context),
        isDark ? AppColors.darkSuccessTint : AppColors.successTint,
      ),
      RfqStatus.rejected => (
        AppColors.errorOf(context),
        isDark ? AppColors.darkErrorTint : AppColors.errorTint,
      ),
      RfqStatus.closed || RfqStatus.unknown => (
        AppColors.textMutedOf(context),
        AppColors.surfaceSecondaryOf(context),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.full,
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        ActivityHubL10n.rfqStatusLabel(context, status),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
