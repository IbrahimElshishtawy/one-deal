import 'package:flutter/material.dart';

import 'package:market_space/core/constants/app_constants.dart';
import 'package:market_space/core/design_system/deal_one_logo.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

class MarketHeaderBar extends StatelessWidget {
  final String selectedCity;
  final VoidCallback? onCityTap;
  final VoidCallback? onNotificationsTap;

  const MarketHeaderBar({
    super.key,
    this.selectedCity = 'الرياض / دبي',
    this.onCityTap,
    this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompactPhone;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalScreenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Brand Logo & Name
          Expanded(child: _buildBrand(context, isCompact)),

          const SizedBox(width: AppSpacing.xs),

          // City selector dropdown
          _buildCitySelector(context, isCompact),

          const SizedBox(width: AppSpacing.xs),

          // Notification icon with unread badge
          _buildNotificationButton(context),
        ],
      ),
    );
  }

  Widget _buildBrand(BuildContext context, bool isCompact) {
    final logoSize = isCompact ? 36.0 : 40.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DealOneLogo(
          height: logoSize,
          width: logoSize,
          showDarkModeGlow: true,
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppConstants.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimaryOf(context),
                  fontSize: isCompact ? 16.0 : 18.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 1.0),
              Text(
                'عقارات • تشطيب ومُوَن • خدمات',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondaryOf(context),
                  fontSize: isCompact ? 11.0 : 12.0,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCitySelector(BuildContext context, bool isCompact) {
    return InkWell(
      onTap: onCityTap,
      borderRadius: AppRadii.full,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8.0 : 10.0,
          vertical: 5.0,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondaryOf(context),
          borderRadius: AppRadii.full,
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 15.0,
              color: AppColors.primaryOf(context),
            ),
            const SizedBox(width: 4.0),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isCompact ? 75.0 : 95.0),
              child: Text(
                selectedCity,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimaryOf(context),
                  fontSize: isCompact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 2.0),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16.0,
              color: AppColors.iconSecondaryOf(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onNotificationsTap,
          icon: Icon(
            Icons.notifications_none_rounded,
            color: AppColors.iconOf(context),
            size: 24.0,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 38.0, minHeight: 38.0),
          visualDensity: VisualDensity.compact,
        ),
        Positioned(
          top: 6.0,
          right: 6.0,
          child: Container(
            width: 8.5,
            height: 8.5,
            decoration: BoxDecoration(
              color: AppColors.primaryOf(context),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.backgroundOf(context),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
