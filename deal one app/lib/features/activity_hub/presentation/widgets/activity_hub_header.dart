import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

class ActivityHubHeader extends StatelessWidget {
  final VoidCallback? onClearCartTap;
  final bool showClearCart;

  const ActivityHubHeader({
    super.key,
    this.onClearCartTap,
    this.showClearCart = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDark = AppColors.isDark(context);
    final hPad = context.horizontalScreenPadding;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, AppSpacing.md, hPad, AppSpacing.sm),
      child: Row(
        children: [
          Material(
            color: AppColors.surfaceOf(context),
            borderRadius: AppRadii.md,
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RouteNames.root);
                }
              },
              borderRadius: AppRadii.md,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: AppRadii.md,
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : DealOneDesignColors.navy,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.activityHubTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : DealOneDesignColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.activityHubSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ],
            ),
          ),
          if (showClearCart && onClearCartTap != null) ...[
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              tooltip: l10n.cartClearAction,
              onPressed: onClearCartTap,
              icon: Icon(
                Icons.delete_sweep_outlined,
                color: AppColors.errorOf(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
