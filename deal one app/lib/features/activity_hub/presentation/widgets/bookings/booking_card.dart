import 'package:flutter/material.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/presentation/utils/activity_hub_l10n.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/bookings/booking_details_section.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/bookings/booking_status_badge.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_action_button.dart';
import 'package:market_space/shared/widgets/market_widgets/safe_network_image.dart';

class BookingCard extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback? onCancelTap;
  final VoidCallback? onContactTap;
  final VoidCallback? onViewListingTap;

  const BookingCard({
    super.key,
    required this.booking,
    this.onCancelTap,
    this.onContactTap,
    this.onViewListingTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: AppRadii.lg,
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppRadii.md,
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: booking.imageUrl != null && booking.imageUrl!.isNotEmpty
                      ? SafeNetworkImage(
                          imageUrl: booking.imageUrl!,
                          fit: BoxFit.cover,
                          fallbackIcon: Icons.event_note_outlined,
                        )
                      : Container(
                          color: AppColors.surfaceSecondaryOf(context),
                          child: Icon(
                            Icons.event_note_outlined,
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ActivityHubL10n.bookingTypeLabel(
                              context,
                              booking.type,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.infoOf(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        BookingStatusBadge(status: booking.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.bookingsProviderLabel}: ${booking.providerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          BookingDetailsSection(booking: booking),
          if (booking.canCancel ||
              booking.canContactProvider ||
              booking.listingId != null) ...[
            const Divider(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (booking.listingId != null && onViewListingTap != null)
                  ActivityActionButton(
                    label: l10n.bookingsViewListingAction,
                    icon: Icons.open_in_new_rounded,
                    isOutlined: true,
                    onPressed: onViewListingTap,
                  ),
                if (booking.canContactProvider && onContactTap != null)
                  ActivityActionButton(
                    label: l10n.bookingsContactProviderAction,
                    icon: Icons.phone_in_talk_rounded,
                    onPressed: onContactTap,
                  ),
                if (booking.canCancel && onCancelTap != null)
                  ActivityActionButton(
                    label: l10n.bookingsCancelAction,
                    icon: Icons.cancel_outlined,
                    isOutlined: true,
                    isDestructive: true,
                    onPressed: onCancelTap,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
