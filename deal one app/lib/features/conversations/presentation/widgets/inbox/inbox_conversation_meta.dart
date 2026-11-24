import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Independent trailing metadata column for a conversation row:
/// relative timestamp, unread count pill, pinned/muted indicators, and read ticks.
class InboxConversationMeta extends StatelessWidget {
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final bool showReadReceipts;
  final ChatColorTheme colorTheme;

  const InboxConversationMeta({
    super.key,
    required this.lastMessageAt,
    required this.unreadCount,
    this.isPinned = false,
    this.isMuted = false,
    this.showReadReceipts = true,
    this.colorTheme = ChatColorTheme.dealOneNavy,
  });

  String _formatTime(DateTime? dt, bool isArabic) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return isArabic ? 'الآن' : 'Now';
    if (diff.inMinutes < 60) {
      return isArabic ? 'منذ ${diff.inMinutes} د' : '${diff.inMinutes}m';
    }
    if (diff.inHours < 24) {
      final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final m = local.minute.toString().padLeft(2, '0');
      final period = local.hour >= 12
          ? (isArabic ? 'م' : 'PM')
          : (isArabic ? 'ص' : 'AM');
      return '$h:$m $period';
    }
    if (diff.inDays == 1) return isArabic ? 'أمس' : 'Yesterday';
    return '${local.day}/${local.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);
    final hasUnread = unreadCount > 0;
    final timeStr = _formatTime(lastMessageAt, isArabic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (timeStr.isNotEmpty)
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
              color: hasUnread
                  ? accent
                  : DealOneTokens.textSecondaryOf(context),
            ),
          ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPinned) ...[
              Icon(
                Icons.push_pin_rounded,
                size: 14,
                color: accent,
              ),
              const SizedBox(width: 4),
            ],
            if (hasUnread)
              Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isMuted
                      ? DealOneTokens.textSecondaryOf(context)
                      : accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else if (showReadReceipts)
              Icon(
                Icons.done_all_rounded,
                size: 16,
                color: accent,
              ),
          ],
        ),
      ],
    );
  }
}
