import 'package:flutter/material.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

class ActivitySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String? hintText;

  const ActivitySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final hPad = context.horizontalScreenPadding;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText ?? l10n.activitySearchHint,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.iconSecondaryOf(context),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.iconSecondaryOf(context),
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceOf(context),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadii.md,
            borderSide: BorderSide(color: AppColors.borderOf(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.md,
            borderSide: BorderSide(color: AppColors.borderOf(context)),
          ),
        ),
      ),
    );
  }
}
