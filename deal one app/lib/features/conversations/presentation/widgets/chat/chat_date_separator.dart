import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';

/// Telegram-style centered translucent date pill separating message days.
class ChatDateSeparator extends StatelessWidget {
  final DateTime date;

  const ChatDateSeparator({super.key, required this.date});

  String _formatDateLabel(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) return isArabic ? 'اليوم' : 'Today';
    if (diff == 1) return isArabic ? 'أمس' : 'Yesterday';
    return intl.DateFormat('d MMM yyyy', isArabic ? 'ar' : 'en').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.42)
                : const Color(0xFF1B2B48).withValues(alpha: 0.14),
            borderRadius: AppRadii.full,
          ),
          child: Text(
            _formatDateLabel(context),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
