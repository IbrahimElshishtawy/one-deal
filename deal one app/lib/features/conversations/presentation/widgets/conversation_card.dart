import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';

/// Conversation list item card matching `Conversations.png`:
/// Avatar, counterpart name + verified badge, timestamp + unread badge,
/// linked listing pill with price, and last message preview.
class ConversationCard extends StatelessWidget {
  final ConversationEntity conversation;
  final VoidCallback onTap;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  String _formatTime(DateTime? dt, bool isArabic) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return isArabic ? 'الآن' : 'Now';
    if (diff.inMinutes < 60) {
      return isArabic
          ? 'منذ ${diff.inMinutes} دقيقة'
          : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12
          ? (isArabic ? 'م' : 'PM')
          : (isArabic ? 'ص' : 'AM');
      return '$h:$m $period';
    }
    if (diff.inDays == 1) return isArabic ? 'أمس' : 'Yesterday';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final timeStr = _formatTime(conversation.lastMessageAt, isArabic);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lg,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: DealOneTokens.cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar + Name + Timestamp/Unread
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DealOneAvatar(
                    imageUrl: conversation.counterpartAvatarUrl,
                    fallbackText: conversation.counterpartName,
                    size: 50,
                    isVerified: conversation.isVerified,
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
                            if (conversation.isVerified) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: DealOneTokens.softTileBgOf(context),
                                  borderRadius: AppRadii.sm,
                                ),
                                child: Text(
                                  isArabic ? 'معتمد' : 'Verified',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: DealOneTokens.textPrimaryOf(context),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (conversation.counterpartSubtitle != null &&
                            conversation.counterpartSubtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
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
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: conversation.hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: conversation.hasUnread
                                ? DealOneTokens.amber
                                : DealOneTokens.textSecondaryOf(context),
                          ),
                        ),
                      const SizedBox(height: 6),
                      if (conversation.hasUnread)
                        Container(
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 22,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: DealOneTokens.navy,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.done_all_rounded,
                          size: 16,
                          color: DealOneTokens.amber,
                        ),
                    ],
                  ),
                ],
              ),

              // Linked Listing Context Pill
              if (conversation.listing != null &&
                  conversation.listing!.title.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: DealOneTokens.softTileBgOf(context),
                    borderRadius: AppRadii.md,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        size: 16,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          conversation.listing!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: DealOneTokens.textPrimaryOf(context),
                          ),
                        ),
                      ),
                      if (conversation.listing!.price > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          formatDealOnePrice(
                            conversation.listing!.price,
                            isArabic: isArabic,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: DealOneTokens.amber,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Last Message Preview Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (conversation.lastMessageText != null &&
                              conversation.lastMessageText!.isNotEmpty)
                          ? conversation.lastMessageText!
                          : (isArabic
                              ? 'ابدأ المحادثة الآن...'
                              : 'Start the conversation...'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
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
          ),
        ),
      ),
    );
  }
}
