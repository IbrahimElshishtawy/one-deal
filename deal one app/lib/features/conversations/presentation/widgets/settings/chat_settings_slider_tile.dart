import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Telegram-style slider setting tile with live value pill.
class ChatSettingsSliderTile extends StatelessWidget {
  final Key? sliderKey;
  final IconData icon;
  final String title;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ChatColorTheme colorTheme;
  final ValueChanged<double> onChanged;

  const ChatSettingsSliderTile({
    super.key,
    this.sliderKey,
    required this.icon,
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = colorTheme.accent(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadii.full,
                ),
                child: Text(
                  valueLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            key: sliderKey,
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            activeColor: accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
