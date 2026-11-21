import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/presentation/utils/activity_hub_l10n.dart';

class BookingStatusBadge extends StatelessWidget {
  final BookingStatus status;

  const BookingStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final (Color fg, Color bg, IconData icon) = switch (status) {
      BookingStatus.pending => (
        AppColors.warningOf(context),
        isDark ? AppColors.darkWarningTint : AppColors.warningTint,
        Icons.schedule_rounded,
      ),
      BookingStatus.confirmed => (
        AppColors.infoOf(context),
        AppColors.infoTintOf(context),
        Icons.check_circle_outline_rounded,
      ),
      BookingStatus.completed => (
        AppColors.successOf(context),
        isDark ? AppColors.darkSuccessTint : AppColors.successTint,
        Icons.verified_rounded,
      ),
      BookingStatus.rejected => (
        AppColors.errorOf(context),
        isDark ? AppColors.darkErrorTint : AppColors.errorTint,
        Icons.cancel_outlined,
      ),
      BookingStatus.cancelled => (
        AppColors.textMutedOf(context),
        AppColors.surfaceSecondaryOf(context),
        Icons.block_rounded,
      ),
      BookingStatus.unknown => (
        AppColors.textSecondaryOf(context),
        AppColors.surfaceSecondaryOf(context),
        Icons.help_outline_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.full,
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            ActivityHubL10n.bookingStatusLabel(context, status),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
