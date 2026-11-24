import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Reusable Telegram-style switch setting row with icon, title, and subtitle.
class ChatSettingsToggleTile extends StatelessWidget {
  final Key? switchKey;
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ChatColorTheme colorTheme;
  final ValueChanged<bool> onChanged;

  const ChatSettingsToggleTile({
    super.key,
    this.switchKey,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = colorTheme.accent(isDark);

    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: AppRadii.sm,
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: DealOneTokens.textPrimaryOf(context),
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: DealOneTokens.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Switch.adaptive(
              key: switchKey,
              value: value,
              activeTrackColor: accent,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
