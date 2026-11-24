import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_date_separator.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_message_bubble.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_wallpaper_background.dart';

/// Live Telegram-style preview card that renders real chat bubbles, wallpaper,
/// date separator, timestamps, and read receipts according to [settings].
class ChatSettingsPreviewCard extends StatelessWidget {
  final ChatSettingsEntity settings;

  const ChatSettingsPreviewCard({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final now = DateTime.now();

    final incomingSample = ChatMessageEntity(
      id: 'preview-in',
      conversationId: 'preview',
      senderUserId: 'seller',
      senderName: isArabic ? 'زايد هايتس' : 'Zayed Heights',
      body: isArabic
          ? 'أهلاً بك! العقار ما زال متاحاً، هل يناسبك موعد للمعاينة غداً؟'
          : 'Welcome! The property is available. Would tomorrow work for a viewing?',
      status: 'read',
      sentAt: now.subtract(const Duration(minutes: 4)),
    );

    final outgoingSample = ChatMessageEntity(
      id: 'preview-out',
      conversationId: 'preview',
      senderUserId: 'me',
      senderName: isArabic ? 'أنت' : 'You',
      body: isArabic
          ? 'ممتاز، الساعة 4 عصراً مناسبة جداً 👍'
          : 'Great, 4:00 PM works nicely 👍',
      status: 'read',
      sentAt: now.subtract(const Duration(minutes: 1)),
    );

    return ClipRRect(
      key: const Key('chat_settings_preview_card'),
      borderRadius: AppRadii.xl,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadii.xl,
          border: Border.all(color: DealOneTokens.cardBorderOf(context)),
          boxShadow: DealOneTokens.cardShadow(context),
        ),
        child: ChatWallpaperBackground(
          wallpaper: settings.wallpaper,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChatDateSeparator(date: now),
                ChatMessageBubble(
                  message: incomingSample,
                  isMine: false,
                  settings: settings,
                ),
                ChatMessageBubble(
                  message: outgoingSample,
                  isMine: true,
                  settings: settings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
