import 'package:flutter/material.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Telegram-style floating action button to start a new marketplace conversation.
class InboxNewChatFab extends StatelessWidget {
  final ChatColorTheme colorTheme;
  final VoidCallback onPressed;

  const InboxNewChatFab({
    super.key,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);

    return FloatingActionButton.extended(
      key: const Key('inbox_new_chat_fab'),
      onPressed: onPressed,
      backgroundColor: accent,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.full),
      icon: const Icon(Icons.edit_rounded, size: 19),
      label: Text(
        isArabic ? 'محادثة جديدة' : 'New Chat',
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}
