import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';

/// Telegram-style reply preview strip displayed above the input composer.
class ChatReplyPreviewBar extends StatelessWidget {
  final ChatMessageEntity replyingTo;
  final String senderLabel;
  final ChatColorTheme colorTheme;
  final VoidCallback onCancel;

  const ChatReplyPreviewBar({
    super.key,
    required this.replyingTo,
    required this.senderLabel,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);

    return Container(
      key: const Key('chat_reply_preview_bar'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: DealOneTokens.cardSurfaceOf(context),
        border: Border(
          top: BorderSide(color: DealOneTokens.cardBorderOf(context)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, size: 18, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: AppRadii.full,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                Text(
                  replyingTo.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: DealOneTokens.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('chat_reply_cancel_button'),
            visualDensity: VisualDensity.compact,
            tooltip: isArabic ? 'إلغاء الرد' : 'Cancel reply',
            onPressed: onCancel,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: DealOneTokens.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
