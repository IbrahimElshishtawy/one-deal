import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Clean Telegram-style inbox app bar with live unread/pinned/archived subtitle
/// and quick navigation to Telegram Chat Settings.
class InboxAppBar extends StatelessWidget {
  final int unreadCount;
  final int pinnedCount;
  final bool viewingArchived;
  final bool showBackButton;
  final ChatColorTheme colorTheme;
  final VoidCallback onBack;
  final VoidCallback onSettingsTap;

  const InboxAppBar({
    super.key,
    required this.unreadCount,
    required this.pinnedCount,
    this.viewingArchived = false,
    this.showBackButton = true,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onBack,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);

    String subtitleText;
    if (viewingArchived) {
      subtitleText = isArabic
          ? 'المحادثات المؤرشفة'
          : 'Archived conversations';
    } else if (unreadCount > 0) {
      subtitleText = isArabic
          ? '$unreadCount رسائل غير مقروءة'
          : '$unreadCount unread';
    } else if (pinnedCount > 0) {
      subtitleText = isArabic
          ? '$pinnedCount محادثات مثبتة'
          : '$pinnedCount pinned';
    } else {
      subtitleText = isArabic ? 'كل المحادثات محدثة' : 'All caught up';
    }

    return Container(
      key: const Key('inbox_app_bar'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: DealOneTokens.cardSurfaceOf(context),
        border: Border(
          bottom: BorderSide(color: DealOneTokens.cardBorderOf(context)),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton || viewingArchived)
            IconButton(
              key: const Key('inbox_back_button'),
              tooltip: isArabic ? 'رجوع' : 'Back',
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            )
          else
            const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  viewingArchived
                      ? (isArabic ? 'الأرشيف' : 'Archived Chats')
                      : (isArabic ? 'المحادثات' : 'Conversations'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: unreadCount > 0 && !viewingArchived
                        ? accent
                        : DealOneTokens.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('conversations_settings_button'),
            tooltip: isArabic ? 'إعدادات التليجرام والدردشة' : 'Chat settings',
            onPressed: onSettingsTap,
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 19,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
