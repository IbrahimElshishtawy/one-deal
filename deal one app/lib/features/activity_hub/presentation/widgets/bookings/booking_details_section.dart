import 'package:flutter/material.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/bookings/booking_date_widget.dart';

class BookingDetailsSection extends StatelessWidget {
  final BookingEntity booking;

  const BookingDetailsSection({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookingDateWidget(date: booking.bookingDate, time: booking.bookingTime),
        if (booking.address.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 15,
                color: AppColors.iconSecondaryOf(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  booking.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (booking.referenceCode != null &&
            booking.referenceCode!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.bookingsReferenceLabel(booking.referenceCode!),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMutedOf(context),
            ),
          ),
        ],
      ],
    );
  }
}
