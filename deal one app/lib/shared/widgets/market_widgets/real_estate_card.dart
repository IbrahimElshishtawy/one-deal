import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/shared/models/home_feed_models.dart';
import 'package:market_space/shared/widgets/market_widgets/safe_network_image.dart';

class RealEstateCard extends StatelessWidget {
  final RealEstateItem item;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const RealEstateCard({
    super.key,
    required this.item,
    this.onTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompactPhone;
    final cardWidth = isCompact ? 275.0 : 310.0;
    final isForSale = item.type == 'للبيع';

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(left: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: AppRadii.lg,
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.isDark(context)
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8.0,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with overlays
            _buildImage(context, isCompact, isForSale),

            // Content
            Padding(
              padding: EdgeInsets.all(isCompact ? 10.0 : 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price row
                  Row(
                    children: [
                      Text(
                        item.price,
                        style: TextStyle(
                          fontSize: isCompact ? 14.0 : 16.0,
                          fontWeight: FontWeight.w800,
                          color: isForSale
                              ? AppColors.primaryOf(context)
                              : AppColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          '/ ${item.priceSuffix}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isCompact ? 10.0 : 11.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4.0),

                  // Title
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 12.5 : 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),

                  const SizedBox(height: 8.0),

                  // Specs Row (Rooms, Baths, Area)
                  _buildSpecsRow(context, isCompact),

                  const SizedBox(height: 8.0),

                  // Location and Time
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13.0,
                        color: AppColors.textMutedOf(context),
                      ),
                      const SizedBox(width: 3.0),
                      Expanded(
                        child: Text(
                          item.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isCompact ? 10.5 : 11.5,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        item.timeAgo,
                        style: TextStyle(
                          fontSize: isCompact ? 10.0 : 11.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, bool isCompact, bool isForSale) {
    return Stack(
      children: [
        SafeNetworkImage(
          imageUrl: item.imageUrl,
          height: isCompact ? 125.0 : 140.0,
          width: double.infinity,
          fit: BoxFit.cover,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
          fallbackIcon: Icons.home_work_rounded,
        ),

        // Type Tag (للبيع / للإيجار)
        Positioned(
          top: 8.0,
          right: 8.0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 3.5,
            ),
            decoration: BoxDecoration(
              color: isForSale ? AppColors.secondary : AppColors.primary,
              borderRadius: AppRadii.sm,
            ),
            child: Text(
              item.type,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        // Favorite Button
        Positioned(
          top: 8.0,
          left: 8.0,
          child: InkWell(
            onTap: onFavoriteTap,
            borderRadius: AppRadii.full,
            child: Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4.0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 18.0,
                color: AppColors.neutral,
              ),
            ),
          ),
        ),

        // Verified advertiser badge
        if (item.isVerified)
          Positioned(
            bottom: 8.0,
            right: 8.0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7.0,
                vertical: 2.5,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: AppRadii.full,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 13.0,
                    color: AppColors.secondaryLight,
                  ),
                  SizedBox(width: 4.0),
                  Text(
                    'معلن معتمد',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Optional badge overlay on bottom left (e.g. مفروشة بالكامل)
        if (item.badge != null)
          Positioned(
            bottom: 8.0,
            left: 8.0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7.0,
                vertical: 2.5,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: AppRadii.full,
              ),
              child: Text(
                item.badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSpecsRow(BuildContext context, bool isCompact) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryOf(context),
        borderRadius: AppRadii.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            child: _buildSpecItem(
              context,
              Icons.bed_rounded,
              '${item.beds} غرف',
              isCompact,
            ),
          ),
          Container(
            height: 12.0,
            width: 1.0,
            color: AppColors.borderOf(context),
          ),
          Flexible(
            child: _buildSpecItem(
              context,
              Icons.bathtub_outlined,
              '${item.baths} حمام',
              isCompact,
            ),
          ),
          if (item.areaM2 != null) ...[
            Container(
              height: 12.0,
              width: 1.0,
              color: AppColors.borderOf(context),
            ),
            Flexible(
              child: _buildSpecItem(
                context,
                Icons.square_foot_rounded,
                '${item.areaM2!.toInt()} م²',
                isCompact,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isCompact,
  ) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isCompact ? 13.0 : 15.0,
            color: AppColors.textSecondaryOf(context),
          ),
          const SizedBox(width: 4.0),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 10.0 : 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
