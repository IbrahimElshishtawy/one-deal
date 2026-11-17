import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_utils.dart';

class ContractorPromoBanner extends StatelessWidget {
  final VoidCallback? onOrderTap;

  const ContractorPromoBanner({super.key, this.onOrderTap});

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
        decoration: BoxDecoration(
          color: AppColors.isDark(context)
              ? AppColors.darkSurface
              : AppColors.neutral,
          borderRadius: AppRadii.lg,
          border: AppColors.isDark(context)
              ? Border.all(color: AppColors.darkBorder)
              : null,
          boxShadow: AppColors.isDark(context)
              ? const []
              : [
                  BoxShadow(
                    color: AppColors.neutral.withValues(alpha: 0.15),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Truck icon container on the left
            Container(
              width: isCompact ? 54.0 : 64.0,
              height: isCompact ? 54.0 : 64.0,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: AppRadii.md,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Icon(
                Icons.local_shipping_rounded,
                size: isCompact ? 28.0 : 34.0,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Content column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Promo tag pill
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadii.full,
                      ),
                      child: Text(
                        'عروض الجملة للمقاولين • خصم حتى 30%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 9.5 : 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6.0),

                  // Headline
                  Text(
                    'طلب مواد البناء والمُوَن والتوريد المباشر إلى موقع مشروعك',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact ? 12.5 : 14.0,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 4.0),

                  // Subtitle
                  Text(
                    'ضمان معتمد وأسعار مصنع مباشرة',
                    style: TextStyle(
                      color: const Color(0xFF94A3B8),
                      fontSize: isCompact ? 10.0 : 11.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 10.0),

                  // Action Button
                  InkWell(
                    onTap: onOrderTap,
                    borderRadius: AppRadii.full,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 10.0 : 14.0,
                        vertical: isCompact ? 5.5 : 6.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadii.full,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'طلب توريد فوري',
                            style: TextStyle(
                              color: AppColors.neutral,
                              fontSize: isCompact ? 11.0 : 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: isCompact ? 14.0 : 15.0,
                            color: AppColors.neutral,
                          ),
                        ],
                      ),
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
