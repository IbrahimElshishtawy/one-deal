import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Horizontal quick-reply suggestion chips tailored for marketplace deals.
class ChatQuickRepliesBar extends StatelessWidget {
  final ChatColorTheme colorTheme;
  final ValueChanged<String> onSelected;

  const ChatQuickRepliesBar({
    super.key,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);

    final suggestions = isArabic
        ? const [
            'هل ما زال متاحاً؟',
            'كم السعر النهائي؟',
            'أريد تحديد موعد معاينة',
            'أين الموقع بالتفصيل؟',
          ]
        : const [
            'Is it still available?',
            'What is the final price?',
            'Can I schedule a viewing?',
            'Could you share the exact location?',
          ];

    return Container(
      key: const Key('chat_quick_replies_bar'),
      height: 44,
      decoration: BoxDecoration(
        color: DealOneTokens.cardSurfaceOf(context).withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(color: DealOneTokens.cardBorderOf(context)),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final text = suggestions[index];
          return ActionChip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            backgroundColor: accent.withValues(alpha: isDark ? 0.16 : 0.08),
            side: BorderSide(color: accent.withValues(alpha: 0.25)),
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.full),
            label: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            ),
            onPressed: () => onSelected(text),
          );
        },
      ),
    );
  }
}
