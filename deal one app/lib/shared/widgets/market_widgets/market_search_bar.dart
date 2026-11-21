import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

class MarketSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onVoiceSearchTap;
  final String hintText;

  const MarketSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onFilterTap,
    this.onVoiceSearchTap,
    this.hintText = 'ابحث عن شقق، إيجار، أسمنت وحديد، سباك...',
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompactPhone;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalScreenPadding,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          // Filter button
          Container(
            width: isCompact ? 42.0 : 46.0,
            height: isCompact ? 42.0 : 46.0,
            decoration: BoxDecoration(
              color: AppColors.primaryOf(context),
              borderRadius: AppRadii.md,
            ),
            child: IconButton(
              onPressed: onFilterTap,
              icon: Icon(
                Icons.tune_rounded,
                color: AppColors.onPrimaryOf(context),
                size: isCompact ? 20.0 : 22.0,
              ),
              tooltip: 'الفلاتر المتقدمة',
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Search text field container
          Expanded(
            child: Container(
              height: isCompact ? 42.0 : 46.0,
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: AppRadii.full,
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.md),
                  // Mic icon for voice input
                  InkWell(
                    onTap: onVoiceSearchTap,
                    borderRadius: AppRadii.full,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.mic_none_rounded,
                        size: isCompact ? 19.0 : 21.0,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: isCompact ? 12.0 : 13.5,
                        color: AppColors.textPrimaryOf(context),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        hintText: hintText,
                        hintStyle: TextStyle(
                          fontSize: isCompact ? 11.5 : 12.5,
                          color: AppColors.textMutedOf(context),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.search_rounded,
                    size: isCompact ? 20.0 : 22.0,
                    color: AppColors.textSecondaryOf(context),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
