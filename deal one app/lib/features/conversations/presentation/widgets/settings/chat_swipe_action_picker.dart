import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Telegram-style Chat List Swipe Gesture selector (Pin / Mute / Archive).
class ChatSwipeActionPicker extends StatelessWidget {
  final ChatListSwipeAction selectedAction;
  final ChatColorTheme colorTheme;
  final ValueChanged<ChatListSwipeAction> onSelected;

  const ChatSwipeActionPicker({
    super.key,
    required this.selectedAction,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? 'إجراء السحب في قائمة المحادثات'
                : 'Chat list swipe gesture',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: DealOneTokens.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: ChatListSwipeAction.values.map((action) {
              final selected = action == selectedAction;
              final actionColor = action.color(isDark, colorTheme);
              return Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: action == ChatListSwipeAction.values.last ? 0 : 8,
                  ),
                  child: InkWell(
                    key: Key('chat_swipe_option_${action.name}'),
                    borderRadius: AppRadii.md,
                    onTap: () => onSelected(action),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? accent.withValues(alpha: isDark ? 0.18 : 0.1)
                            : DealOneTokens.softTileBgOf(context),
                        borderRadius: AppRadii.md,
                        border: Border.all(
                          color: selected
                              ? accent
                              : DealOneTokens.cardBorderOf(context),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            action.icon,
                            size: 20,
                            color: selected ? accent : actionColor,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            action.label(isArabic),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: selected
                                  ? accent
                                  : DealOneTokens.textPrimaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
