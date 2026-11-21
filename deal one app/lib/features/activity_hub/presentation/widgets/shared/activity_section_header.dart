import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_spacing.dart';

class ActivitySectionHeader extends StatelessWidget {
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  const ActivitySectionHeader({
    super.key,
    required this.title,
    this.trailingLabel,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
          if (trailingLabel != null && onTrailingTap != null)
            TextButton(
              onPressed: onTrailingTap,
              child: Text(
                trailingLabel!,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.isDark(context)
                      ? AppColors.darkPrimary
                      : DealOneDesignColors.navy,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
