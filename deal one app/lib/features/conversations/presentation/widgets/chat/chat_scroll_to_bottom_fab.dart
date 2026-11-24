import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Floating Telegram-style button to jump down to the latest messages.
class ChatScrollToBottomFab extends StatelessWidget {
  final bool visible;
  final ChatColorTheme colorTheme;
  final VoidCallback onPressed;

  const ChatScrollToBottomFab({
    super.key,
    required this.visible,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);

    return AnimatedScale(
      scale: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 180),
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 180),
        child: Material(
          color: DealOneTokens.cardSurfaceOf(context),
          elevation: 4,
          shape: CircleBorder(
            side: BorderSide(color: DealOneTokens.cardBorderOf(context)),
          ),
          child: InkWell(
            key: const Key('chat_scroll_to_bottom_fab'),
            onTap: visible ? onPressed : null,
            customBorder: const CircleBorder(),
            child: Tooltip(
              message: isArabic ? 'النزول لآخر الرسائل' : 'Scroll to bottom',
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 24,
                  color: accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
