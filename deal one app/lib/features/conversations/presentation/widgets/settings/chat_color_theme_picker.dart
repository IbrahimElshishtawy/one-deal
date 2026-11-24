import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Telegram-style horizontal color theme picker with miniature bubble previews.
class ChatColorThemePicker extends StatelessWidget {
  final ChatColorTheme selectedTheme;
  final ValueChanged<ChatColorTheme> onSelected;

  const ChatColorThemePicker({
    super.key,
    required this.selectedTheme,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: ChatColorTheme.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final theme = ChatColorTheme.values[index];
          final selected = theme == selectedTheme;
          final accent = theme.accent(isDark);

          return InkWell(
            key: Key('chat_theme_option_${theme.name}'),
            borderRadius: AppRadii.md,
            onTap: () => onSelected(theme),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 84,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DealOneTokens.softTileBgOf(context),
                borderRadius: AppRadii.md,
                border: Border.all(
                  color: selected
                      ? accent
                      : DealOneTokens.cardBorderOf(context),
                  width: selected ? 2.2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Container(
                            width: 42,
                            height: 13,
                            decoration: BoxDecoration(
                              color: DealOneTokens.cardSurfaceOf(context),
                              borderRadius: AppRadii.full,
                              border: Border.all(
                                color: DealOneTokens.cardBorderOf(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Container(
                            width: 46,
                            height: 14,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.outgoingStart(isDark),
                                  theme.outgoingEnd(isDark),
                                ],
                              ),
                              borderRadius: AppRadii.full,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (selected) ...[
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: accent,
                        ),
                        const SizedBox(width: 3),
                      ],
                      Flexible(
                        child: Text(
                          theme.label(isArabic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: selected
                                ? accent
                                : DealOneTokens.textPrimaryOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
