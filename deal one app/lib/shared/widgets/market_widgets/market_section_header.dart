import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_utils.dart';

class MarketSectionHeader extends StatelessWidget {
  final String title;
  final Color markerColor;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const MarketSectionHeader({
    super.key,
    required this.title,
    required this.markerColor,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    this.actionLabel = 'عرض الكل',
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = context.horizontalScreenPadding;
    final isCompact = context.isCompactPhone;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Marker vertical bar
          Container(
            width: 4.5,
            height: isCompact ? 18.0 : 21.0,
            decoration: BoxDecoration(
              color: markerColor,
              borderRadius: AppRadii.full,
            ),
          ),

          const SizedBox(width: AppSpacing.xs + 3),

          // Title and optional badge in Expanded
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 14.0 : 16.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
                if (badgeText != null) ...[
                  const SizedBox(width: AppSpacing.xs + 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7.0,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor ?? markerColor.withValues(alpha: 0.14),
                      borderRadius: AppRadii.full,
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        fontSize: isCompact ? 9.5 : 10.5,
                        fontWeight: FontWeight.w700,
                        color: badgeTextColor ?? markerColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Action link with arrow
          if (actionLabel != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: AppRadii.sm,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 2.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: TextStyle(
                        fontSize: isCompact ? 11.5 : 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOf(context),
                      ),
                    ),
                    const SizedBox(width: 2.0),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 15.0,
                      color: AppColors.primaryOf(context),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
