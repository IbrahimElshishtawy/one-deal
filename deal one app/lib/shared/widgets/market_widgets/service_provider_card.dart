import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/shared/models/home_feed_models.dart';

class ServiceProviderCard extends StatelessWidget {
  final ServiceProviderItem item;
  final VoidCallback? onActionTap;
  final VoidCallback? onTap;

  const ServiceProviderCard({
    super.key,
    required this.item,
    this.onActionTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompactPhone;
    final horizontalPadding = context.horizontalScreenPadding;

    final (icon, iconColor, bgColor) = _resolveCategoryVisuals(
      context,
      item.categoryKey,
    );

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.xs + 1,
      ),
      padding: EdgeInsets.all(isCompact ? 10.0 : 12.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: AppRadii.lg,
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.isDark(context)
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6.0,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lg,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Action button (Left side in RTL)
            InkWell(
              onTap: onActionTap,
              borderRadius: AppRadii.md,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 10.0 : 14.0,
                  vertical: isCompact ? 7.0 : 8.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryOf(context),
                  borderRadius: AppRadii.md,
                ),
                child: Text(
                  item.actionLabel,
                  style: TextStyle(
                    color: AppColors.onPrimaryOf(context),
                    fontSize: isCompact ? 10.5 : 12.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title + verified check
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isCompact ? 12.0 : 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                      ),
                      if (item.isVerified) ...[
                        const SizedBox(width: 3.0),
                        Icon(
                          Icons.verified_rounded,
                          size: 14.0,
                          color: AppColors.primaryOf(context),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 2.0),

                  // Subtitle
                  Text(
                    item.serviceDesc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 10.0 : 11.0,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),

                  const SizedBox(height: 5.0),

                  // Rating + Perk text
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14.0,
                        color: AppColors.warningOf(context),
                      ),
                      const SizedBox(width: 2.0),
                      Text(
                        '${item.rating} (${item.reviewsCount} تقييم)',
                        style: TextStyle(
                          fontSize: isCompact ? 9.5 : 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '• ${item.perkText}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isCompact ? 9.0 : 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Visual Category Icon on Right
            Container(
              width: isCompact ? 42.0 : 48.0,
              height: isCompact ? 42.0 : 48.0,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: AppRadii.md,
              ),
              child: Icon(
                icon,
                size: isCompact ? 22.0 : 26.0,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, Color) _resolveCategoryVisuals(
    BuildContext context,
    String categoryKey,
  ) {
    switch (categoryKey) {
      case 'finishing':
        return (
          Icons.format_paint_rounded,
          AppColors.primaryOf(context),
          AppColors.primaryTintOf(context),
        );
      case 'plumbing':
        return (
          Icons.plumbing_rounded,
          AppColors.primaryOf(context),
          AppColors.secondaryTintOf(context),
        );
      case 'moving':
        return (
          Icons.local_shipping_rounded,
          AppColors.infoOf(context),
          AppColors.infoTintOf(context),
        );
      default:
        return (
          Icons.handyman_rounded,
          AppColors.primaryOf(context),
          AppColors.tertiaryTintOf(context),
        );
    }
  }
}
