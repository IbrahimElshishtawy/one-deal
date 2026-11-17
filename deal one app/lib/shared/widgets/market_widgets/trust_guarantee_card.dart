import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_utils.dart';

class TrustGuaranteeCard extends StatelessWidget {
  const TrustGuaranteeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = context.horizontalScreenPadding;
    final isCompact = context.isCompactPhone;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12.0 : 14.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: AppRadii.lg,
          border: Border.all(color: AppColors.borderOf(context)),
          boxShadow: AppColors.isDark(context)
              ? const []
              : [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.04),
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Shield icon container
            Container(
              width: isCompact ? 44.0 : 48.0,
              height: isCompact ? 44.0 : 48.0,
              decoration: BoxDecoration(
                color: AppColors.secondaryTintOf(context),
                borderRadius: AppRadii.md,
              ),
              child: Icon(
                Icons.verified_user_rounded,
                size: 26.0,
                color: AppColors.primaryOf(context),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'حماية المعاملات 100% عبر بازار جو',
                    style: TextStyle(
                      fontSize: isCompact ? 12.5 : 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    'توثيق عقود الإيجار، فحص هندسي للعقارات، وحساب وسيط آمن لحماية دفعات المواد والتشطيب.',
                    style: TextStyle(
                      fontSize: isCompact ? 10.0 : 11.0,
                      height: 1.35,
                      color: AppColors.textSecondaryOf(context),
                    ),
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
