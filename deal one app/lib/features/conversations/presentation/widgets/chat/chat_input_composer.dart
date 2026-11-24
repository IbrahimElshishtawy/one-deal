import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Complete Telegram-style bottom composer with attachment trigger,
/// quick-replies toggle, multiline text field, and themed send button.
class ChatInputComposer extends StatelessWidget {
  final TextEditingController controller;
  final ChatSettingsEntity settings;
  final bool sending;
  final bool showQuickRepliesActive;
  final VoidCallback onSend;
  final VoidCallback onAttachmentTap;
  final VoidCallback onToggleQuickReplies;

  const ChatInputComposer({
    super.key,
    required this.controller,
    required this.settings,
    required this.sending,
    this.showQuickRepliesActive = false,
    required this.onSend,
    required this.onAttachmentTap,
    required this.onToggleQuickReplies,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = settings.colorTheme.accent(isDark);

    return Container(
      key: const Key('chat_input_composer'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: DealOneTokens.cardSurfaceOf(context),
        border: Border(
          top: BorderSide(color: DealOneTokens.cardBorderOf(context)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            key: const Key('chat_attachment_button'),
            tooltip: isArabic ? 'إجراءات سريعة' : 'Quick actions',
            onPressed: onAttachmentTap,
            icon: Icon(
              Icons.attach_file_rounded,
              color: DealOneTokens.textSecondaryOf(context),
            ),
          ),
          IconButton(
            key: const Key('chat_quick_replies_toggle'),
            tooltip: isArabic ? 'ردود سريعة' : 'Quick replies',
            onPressed: onToggleQuickReplies,
            icon: Icon(
              Icons.bolt_rounded,
              color: showQuickRepliesActive
                  ? accent
                  : DealOneTokens.textSecondaryOf(context),
            ),
          ),
          Expanded(
            child: TextField(
              key: const Key('chat_message_input'),
              controller: controller,
              minLines: 1,
              maxLines: 5,
              keyboardType: settings.sendByEnter
                  ? TextInputType.text
                  : TextInputType.multiline,
              textInputAction: settings.sendByEnter
                  ? TextInputAction.send
                  : TextInputAction.newline,
              onSubmitted: settings.sendByEnter ? (_) => onSend() : null,
              style: TextStyle(
                fontSize: settings.fontSize,
                color: DealOneTokens.textPrimaryOf(context),
              ),
              decoration: InputDecoration(
                hintText: isArabic
                    ? 'اكتب رسالتك هنا...'
                    : 'Message...',
                hintStyle: TextStyle(
                  fontSize: settings.fontSize - 0.5,
                  color: DealOneTokens.textSecondaryOf(context),
                ),
                filled: true,
                fillColor: DealOneTokens.inputFillOf(context),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: const OutlineInputBorder(
                  borderRadius: AppRadii.full,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Material(
            color: accent,
            shape: const CircleBorder(),
            child: InkWell(
              key: const Key('chat_send_button'),
              onTap: sending ? null : onSend,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
