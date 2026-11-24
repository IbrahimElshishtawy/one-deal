import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';

/// Telegram-style bottom sheet shown on message long-press (Reply / Copy).
class ChatMessageActionsSheet extends StatelessWidget {
  final ChatMessageEntity message;
  final ChatColorTheme colorTheme;
  final VoidCallback onReply;
  final VoidCallback onCopy;

  const ChatMessageActionsSheet({
    super.key,
    required this.message,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onReply,
    required this.onCopy,
  });

  static Future<void> show(
    BuildContext context, {
    required ChatMessageEntity message,
    required ChatColorTheme colorTheme,
    required VoidCallback onReply,
    required VoidCallback onCopy,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: DealOneTokens.cardSurfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChatMessageActionsSheet(
        message: message,
        colorTheme: colorTheme,
        onReply: onReply,
        onCopy: onCopy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: DealOneTokens.cardBorderOf(context),
                  borderRadius: AppRadii.full,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: DealOneTokens.softTileBgOf(context),
                borderRadius: AppRadii.md,
              ),
              child: Text(
                message.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  color: DealOneTokens.textPrimaryOf(context),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
              leading: Icon(Icons.reply_rounded, color: accent),
              title: Text(isArabic ? 'رد على الرسالة' : 'Reply'),
              onTap: () {
                Navigator.of(context).pop();
                onReply();
              },
            ),
            ListTile(
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
              leading: Icon(Icons.copy_rounded, color: accent),
              title: Text(isArabic ? 'نسخ النص' : 'Copy text'),
              onTap: () {
                Navigator.of(context).pop();
                onCopy();
              },
            ),
          ],
        ),
      ),
    );
  }
}
