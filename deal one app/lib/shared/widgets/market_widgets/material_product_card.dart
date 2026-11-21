import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/shared/models/home_feed_models.dart';
import 'package:market_space/shared/widgets/market_widgets/safe_network_image.dart';

class MaterialProductCard extends StatelessWidget {
  final BuildingMaterialItem item;
  final VoidCallback? onTap;
  final VoidCallback? onCallTap;
  final VoidCallback? onChatTap;

  const MaterialProductCard({
    super.key,
    required this.item,
    this.onTap,
    this.onCallTap,
    this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompactPhone;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: AppRadii.lg,
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppColors.isDark(context)
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6.0,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with tag
            Stack(
              children: [
                SafeNetworkImage(
                  imageUrl: item.imageUrl,
                  height: isCompact ? 105.0 : 120.0,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16.0),
                  ),
                  fallbackIcon: Icons.handyman_rounded,
                ),
                Positioned(
                  top: 6.0,
                  right: 6.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7.0,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutral.withValues(alpha: 0.85),
                      borderRadius: AppRadii.sm,
                    ),
                    child: Text(
                      item.tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Details
            Padding(
              padding: EdgeInsets.all(isCompact ? 8.0 : 10.0),
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
                          fontSize: isCompact ? 13.5 : 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryOf(context),
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '/ ${item.unit}',
                        style: TextStyle(
                          fontSize: isCompact ? 9.5 : 10.5,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3.0),

                  // Title
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 11.5 : 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),

                  const SizedBox(height: 2.0),

                  // Subtitle
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 9.5 : 10.5,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),

                  const SizedBox(height: 8.0),

                  // Footer with tag and Call/Chat action button
                  Row(
                    children: [
                      // Action icon (Call or Chat)
                      if (item.hasCall)
                        InkWell(
                          onTap: onCallTap,
                          borderRadius: AppRadii.full,
                          child: Container(
                            width: 28.0,
                            height: 28.0,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTintOf(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryOf(context)
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              Icons.phone_rounded,
                              size: 14.0,
                              color: AppColors.primaryOf(context),
                            ),
                          ),
                        )
                      else if (item.hasChat)
                        InkWell(
                          onTap: onChatTap,
                          borderRadius: AppRadii.full,
                          child: Container(
                            width: 28.0,
                            height: 28.0,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTintOf(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryOf(context)
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 14.0,
                              color: AppColors.primaryOf(context),
                            ),
                          ),
                        ),

                      const Spacer(),

                      // Delivery / status footer text
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.footerText.contains('توصيل')
                                ? Icons.local_shipping_outlined
                                : Icons.verified_outlined,
                            size: 13.0,
                            color: AppColors.textSecondaryOf(context),
                          ),
                          const SizedBox(width: 3.0),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isCompact ? 80.0 : 95.0,
                            ),
                            child: Text(
                              item.footerText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isCompact ? 9.5 : 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondaryOf(context),
                              ),
                            ),
                          ),
                        ],
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
}
