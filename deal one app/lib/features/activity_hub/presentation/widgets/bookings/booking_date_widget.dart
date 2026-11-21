import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_spacing.dart';

class BookingDateWidget extends StatelessWidget {
  final DateTime? date;
  final String? time;

  const BookingDateWidget({super.key, this.date, this.time});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final dateText = date != null
        ? DateFormat.yMMMd(locale).format(date!)
        : '--';

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: AppColors.iconSecondaryOf(context),
            ),
            const SizedBox(width: 4),
            Text(
              dateText,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ],
        ),
        if (time != null && time!.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AppColors.iconSecondaryOf(context),
              ),
              const SizedBox(width: 4),
              Text(
                time!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
