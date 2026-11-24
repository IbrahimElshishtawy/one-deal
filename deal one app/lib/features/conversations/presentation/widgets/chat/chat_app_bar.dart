import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

enum ChatAppBarMenuAction { search, toggleMute, viewListing, settings }

/// Telegram-inspired chat header bar with counterpart avatar, verified badge,
/// mute indicator, search trigger, settings trigger, and overflow menu.
class ChatAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final bool isVerified;
  final bool isMuted;
  final bool hasListing;
  final ChatColorTheme colorTheme;
  final VoidCallback onBack;
  final VoidCallback onSearchTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onToggleMute;
  final VoidCallback? onViewListing;

  const ChatAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.isVerified = false,
    this.isMuted = false,
    this.hasListing = false,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onBack,
    required this.onSearchTap,
    required this.onSettingsTap,
    required this.onToggleMute,
    this.onViewListing,
  });

  String _initialFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'D';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);
    final hasAvatarUrl = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: DealOneTokens.cardSurfaceOf(context),
        border: Border(
          bottom: BorderSide(color: DealOneTokens.cardBorderOf(context)),
        ),
        boxShadow: DealOneTokens.softShadow(context),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('chat_back_button'),
            tooltip: isArabic ? 'رجوع' : 'Back',
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: DealOneTokens.textPrimaryOf(context),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: accent.withValues(alpha: 0.14),
                backgroundImage: hasAvatarUrl ? NetworkImage(avatarUrl!) : null,
                child: hasAvatarUrl
                    ? null
                    : Text(
                        _initialFor(title),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
              ),
              PositionedDirectional(
                end: -1,
                bottom: -1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: DealOneTokens.successGreen,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DealOneTokens.cardSurfaceOf(context),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: DealOneTokens.textPrimaryOf(context),
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: accent,
                      ),
                    ],
                    if (isMuted) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.notifications_off_rounded,
                        size: 14,
                        color: DealOneTokens.textSecondaryOf(context),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle?.trim().isNotEmpty == true
                      ? subtitle!
                      : (isArabic ? 'متاح عبر ديل ون' : 'Available on Deal One'),
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
          IconButton(
            key: const Key('chat_search_button'),
            tooltip: isArabic ? 'بحث في المحادثة' : 'Search in chat',
            onPressed: onSearchTap,
            icon: Icon(
              Icons.search_rounded,
              size: 22,
              color: DealOneTokens.textPrimaryOf(context),
            ),
          ),
          IconButton(
            key: const Key('chat_settings_button'),
            tooltip: isArabic ? 'إعدادات المحادثة' : 'Chat settings',
            onPressed: onSettingsTap,
            icon: Icon(
              Icons.tune_rounded,
              size: 21,
              color: accent,
            ),
          ),
          PopupMenuButton<ChatAppBarMenuAction>(
            key: const Key('chat_overflow_menu_button'),
            tooltip: isArabic ? 'المزيد' : 'More options',
            icon: Icon(
              Icons.more_vert_rounded,
              size: 21,
              color: DealOneTokens.textPrimaryOf(context),
            ),
            onSelected: (action) {
              switch (action) {
                case ChatAppBarMenuAction.search:
                  onSearchTap();
                case ChatAppBarMenuAction.toggleMute:
                  onToggleMute();
                case ChatAppBarMenuAction.viewListing:
                  onViewListing?.call();
                case ChatAppBarMenuAction.settings:
                  onSettingsTap();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ChatAppBarMenuAction.search,
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text(isArabic ? 'البحث في الرسائل' : 'Search messages'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ChatAppBarMenuAction.toggleMute,
                child: Row(
                  children: [
                    Icon(
                      isMuted
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isMuted
                          ? (isArabic ? 'إلغاء كتم الإشعارات' : 'Unmute chat')
                          : (isArabic ? 'كتم الإشعارات' : 'Mute chat'),
                    ),
                  ],
                ),
              ),
              if (hasListing && onViewListing != null)
                PopupMenuItem(
                  value: ChatAppBarMenuAction.viewListing,
                  child: Row(
                    children: [
                      const Icon(Icons.home_work_outlined, size: 18),
                      const SizedBox(width: 10),
                      Text(isArabic ? 'عرض الإعلان' : 'View listing'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: ChatAppBarMenuAction.settings,
                child: Row(
                  children: [
                    const Icon(Icons.palette_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      isArabic
                          ? 'إعدادات المظهر والدردشة'
                          : 'Chat appearance & settings',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
