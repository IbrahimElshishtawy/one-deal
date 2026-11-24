import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Grouped Telegram-style settings section card with titled header and items.
class ChatSettingsSectionCard extends StatelessWidget {
  final String title;
  final ChatColorTheme colorTheme;
  final List<Widget> children;

  const ChatSettingsSectionCard({
    super.key,
    required this.title,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = colorTheme.accent(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: DealOneTokens.cardSurfaceOf(context),
            borderRadius: AppRadii.lg,
            border: Border.all(color: DealOneTokens.cardBorderOf(context)),
            boxShadow: DealOneTokens.softShadow(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    indent: 52,
                    color: DealOneTokens.cardBorderOf(context),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
