import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';

/// Telegram-style long-press action sheet for an inbox conversation
/// (Pin/Unpin, Mute/Unmute, Archive/Unarchive, View Listing, Chat Settings).
class InboxConversationActionsSheet extends StatelessWidget {
  final ConversationEntity conversation;
  final bool isPinned;
  final bool isMuted;
  final bool isArchived;
  final ChatColorTheme colorTheme;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleArchive;
  final VoidCallback? onViewListing;
  final VoidCallback onOpenSettings;

  const InboxConversationActionsSheet({
    super.key,
    required this.conversation,
    required this.isPinned,
    required this.isMuted,
    required this.isArchived,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onTogglePin,
    required this.onToggleMute,
    required this.onToggleArchive,
    this.onViewListing,
    required this.onOpenSettings,
  });

  static Future<void> show(
    BuildContext context, {
    required ConversationEntity conversation,
    required bool isPinned,
    required bool isMuted,
    required bool isArchived,
    required ChatColorTheme colorTheme,
    required VoidCallback onTogglePin,
    required VoidCallback onToggleMute,
    required VoidCallback onToggleArchive,
    VoidCallback? onViewListing,
    required VoidCallback onOpenSettings,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DealOneTokens.cardSurfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => InboxConversationActionsSheet(
        conversation: conversation,
        isPinned: isPinned,
        isMuted: isMuted,
        isArchived: isArchived,
        colorTheme: colorTheme,
        onTogglePin: onTogglePin,
        onToggleMute: onToggleMute,
        onToggleArchive: onToggleArchive,
        onViewListing: onViewListing,
        onOpenSettings: onOpenSettings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);

    return SafeArea(
      child: SingleChildScrollView(
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
            Text(
              conversation.counterpartName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              key: const Key('inbox_action_pin'),
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
              leading: Icon(
                isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                color: accent,
              ),
              title: Text(
                isPinned
                    ? (isArabic ? 'إلغاء تثبيت المحادثة' : 'Unpin conversation')
                    : (isArabic ? 'تثبيت المحادثة في الأعلى' : 'Pin to top'),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onTogglePin();
              },
            ),
            ListTile(
              key: const Key('inbox_action_mute'),
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
              leading: Icon(
                isMuted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                color: DealOneTokens.amber,
              ),
              title: Text(
                isMuted
                    ? (isArabic ? 'تفعيل الإشعارات' : 'Unmute notifications')
                    : (isArabic ? 'كتم الإشعارات' : 'Mute notifications'),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onToggleMute();
              },
            ),
            ListTile(
              key: const Key('inbox_action_archive'),
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
              leading: Icon(
                isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                color: DealOneTokens.textSecondaryOf(context),
              ),
              title: Text(
                isArchived
                    ? (isArabic ? 'إلغاء الأرشفة' : 'Unarchive chat')
                    : (isArabic ? 'أرشفة المحادثة' : 'Archive chat'),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onToggleArchive();
              },
            ),
            if (onViewListing != null)
              ListTile(
                shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
                leading: Icon(Icons.home_work_outlined, color: accent),
                title: Text(isArabic ? 'عرض الإعلان المرتبط' : 'View listing'),
                onTap: () {
                  Navigator.of(context).pop();
                  onViewListing?.call();
                },
              ),
            ListTile(
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
              leading: Icon(Icons.tune_rounded, color: accent),
              title: Text(
                isArabic ? 'إعدادات الدردشة والتليجرام' : 'Chat settings',
              ),
              onTap: () {
                Navigator.of(context).pop();
                onOpenSettings();
              },
            ),
          ],
        ),
      ),
    );
  }
}
