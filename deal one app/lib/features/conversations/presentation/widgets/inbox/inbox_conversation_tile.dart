import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';
import 'package:market_space/features/conversations/presentation/widgets/inbox/inbox_conversation_avatar.dart';
import 'package:market_space/features/conversations/presentation/widgets/inbox/inbox_conversation_meta.dart';
import 'package:market_space/features/conversations/presentation/widgets/inbox/inbox_listing_chip.dart';

/// Telegram-inspired inbox conversation tile composing independent avatar,
/// metadata, listing chip, 2-line/3-line layout, long-press actions, and
/// configurable swipe gesture (`pin`, `mute`, or `archive`).
class InboxConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
  final ChatSettingsEntity settings;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSwipeAction;

  const InboxConversationTile({
    super.key,
    required this.conversation,
    required this.settings,
    required this.onTap,
    required this.onLongPress,
    required this.onSwipeAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = settings.colorTheme.accent(isDark);
    final isPinned = settings.isPinned(conversation.id);
    final isMuted = settings.isMuted(conversation.id);
    final isArchived = settings.isArchived(conversation.id);
    final swipeAction = settings.swipeAction;
    final swipeColor = swipeAction.color(isDark, settings.colorTheme);

    String swipeText;
    switch (swipeAction) {
      case ChatListSwipeAction.pin:
        swipeText = isPinned
            ? (isArabic ? 'إلغاء التثبيت' : 'Unpin')
            : swipeAction.label(isArabic);
      case ChatListSwipeAction.mute:
        swipeText = isMuted
            ? (isArabic ? 'إلغاء الكتم' : 'Unmute')
            : swipeAction.label(isArabic);
      case ChatListSwipeAction.archive:
        swipeText = isArchived
            ? (isArabic ? 'إلغاء الأرشفة' : 'Unarchive')
            : swipeAction.label(isArabic);
    }

    final showListing =
        settings.showListingTagInInbox &&
        !settings.chatListTwoLines &&
        conversation.listing != null &&
        conversation.listing!.title.isNotEmpty;

    final lastMsg = (conversation.lastMessageText != null &&
            conversation.lastMessageText!.isNotEmpty)
        ? conversation.lastMessageText!
        : (isArabic ? 'ابدأ المحادثة الآن...' : 'Start the conversation...');

    return Dismissible(
      key: ValueKey('inbox_tile_dismissible_${conversation.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onSwipeAction();
        return false;
      },
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(
          color: swipeColor,
          borderRadius: AppRadii.lg,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(swipeAction.icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              swipeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      child: Material(
        key: Key('inbox_conversation_tile_${conversation.id}'),
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: AppRadii.lg,
          child: Ink(
            padding: EdgeInsets.all(
              settings.chatListTwoLines ? AppSpacing.md : AppSpacing.lg,
            ),
            decoration: DealOneTokens.cardDecoration(
              context,
              borderColor: isPinned ? accent.withValues(alpha: 0.45) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InboxConversationAvatar(
                      imageUrl: conversation.counterpartAvatarUrl,
                      displayName: conversation.counterpartName,
                      isVerified: conversation.isVerified,
                      size: settings.chatListTwoLines ? 44 : 50,
                      colorTheme: settings.colorTheme,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  conversation.counterpartName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: DealOneTokens.textPrimaryOf(context),
                                  ),
                                ),
                              ),
                              if (isMuted) ...[
                                const SizedBox(width: 5),
                                Icon(
                                  Icons.notifications_off_rounded,
                                  size: 14,
                                  color: DealOneTokens.textSecondaryOf(context),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          if (settings.chatListTwoLines)
                            Text(
                              lastMsg,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: (settings.fontSize - 1.5).clamp(
                                  12.0,
                                  16.0,
                                ),
                                fontWeight: conversation.hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: DealOneTokens.textSecondaryOf(context),
                              ),
                            )
                          else if (conversation.counterpartSubtitle != null &&
                              conversation.counterpartSubtitle!.isNotEmpty)
                            Text(
                              conversation.counterpartSubtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: DealOneTokens.textSecondaryOf(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    InboxConversationMeta(
                      lastMessageAt: conversation.lastMessageAt,
                      unreadCount: conversation.unreadCount,
                      isPinned: isPinned,
                      isMuted: isMuted,
                      showReadReceipts: settings.showReadReceipts,
                      colorTheme: settings.colorTheme,
                    ),
                  ],
                ),
                if (showListing) ...[
                  const SizedBox(height: AppSpacing.md),
                  InboxListingChip(
                    listing: conversation.listing!,
                    colorTheme: settings.colorTheme,
                  ),
                ],
                if (!settings.chatListTwoLines) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: (settings.fontSize - 1.0).clamp(
                              12.5,
                              17.0,
                            ),
                            fontWeight: conversation.hasUnread
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: DealOneTokens.textPrimaryOf(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: DealOneTokens.textSecondaryOf(context),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
