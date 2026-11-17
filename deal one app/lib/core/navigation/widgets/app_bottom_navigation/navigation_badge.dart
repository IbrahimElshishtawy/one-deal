import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class NavigationBadge extends StatelessWidget {
  final int count;

  const NavigationBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final label = count > 99 ? '99+' : '$count';

    return Positioned(
      top: -3,
      right: -6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
        constraints: const BoxConstraints(minWidth: 16.0, minHeight: 16.0),
        decoration: BoxDecoration(
          color: AppColors.errorOf(context),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.surfaceOf(context), width: 1.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
