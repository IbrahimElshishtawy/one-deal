import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

class ActivityFilterOption<T> {
  final T value;
  final String label;

  const ActivityFilterOption({required this.value, required this.label});
}

class ActivityFilterBar<T> extends StatelessWidget {
  final List<ActivityFilterOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  const ActivityFilterBar({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final hPad = context.horizontalScreenPadding;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.value == selectedValue;
          final bg = isSelected
              ? (isDark ? AppColors.darkPrimary : DealOneDesignColors.navy)
              : AppColors.surfaceOf(context);
          final fg = isSelected
              ? (isDark ? AppColors.darkOnPrimary : Colors.white)
              : AppColors.textSecondaryOf(context);

          return ChoiceChip(
            label: Text(
              option.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: fg,
              ),
            ),
            selected: isSelected,
            showCheckmark: false,
            backgroundColor: bg,
            selectedColor: bg,
            side: BorderSide(
              color: isSelected ? bg : AppColors.borderOf(context),
            ),
            shape: RoundedRectangleBorder(borderRadius: AppRadii.full),
            onSelected: (_) => onSelected(option.value),
          );
        },
      ),
    );
  }
}
