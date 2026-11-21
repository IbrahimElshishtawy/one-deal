import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';

class ActivityActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isDestructive;
  final bool isLoading;

  const ActivityActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isOutlined = false,
    this.isDestructive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final baseColor = isDestructive
        ? AppColors.errorOf(context)
        : (isDark ? AppColors.darkPrimary : DealOneDesignColors.navy);

    final child = isLoading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isOutlined
                  ? baseColor
                  : (isDark && !isDestructive
                        ? AppColors.darkOnPrimary
                        : Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: baseColor,
          side: BorderSide(color: baseColor.withValues(alpha: 0.45)),
          minimumSize: const Size(44, 42),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.md),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: baseColor,
        foregroundColor: isDark && !isDestructive
            ? AppColors.darkOnPrimary
            : Colors.white,
        elevation: 0,
        minimumSize: const Size(44, 42),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.md),
      ),
      child: child,
    );
  }
}
