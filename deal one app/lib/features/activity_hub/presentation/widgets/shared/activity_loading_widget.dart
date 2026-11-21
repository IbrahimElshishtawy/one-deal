import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/shared/widgets/app_loading_indicator.dart';

/// Skeleton + adaptive loading placeholder for Activity Hub tabs.
class ActivityLoadingWidget extends StatelessWidget {
  final String? message;
  final int skeletonCount;

  const ActivityLoadingWidget({
    super.key,
    this.message,
    this.skeletonCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final shimmerBase = AppColors.surfaceSecondaryOf(context);
    final shimmerBorder = AppColors.borderOf(context);

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: skeletonCount + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: AppLoadingIndicator(message: message, size: 28),
          );
        }
        return Container(
          height: 104,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: AppRadii.lg,
            border: Border.all(color: shimmerBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: shimmerBase,
                  borderRadius: AppRadii.md,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: shimmerBase,
                        borderRadius: AppRadii.xs,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      height: 12,
                      width: 140,
                      decoration: BoxDecoration(
                        color: shimmerBase,
                        borderRadius: AppRadii.xs,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      height: 12,
                      width: 90,
                      decoration: BoxDecoration(
                        color: shimmerBase,
                        borderRadius: AppRadii.xs,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
