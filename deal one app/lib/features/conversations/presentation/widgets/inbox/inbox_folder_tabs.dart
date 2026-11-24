import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';

/// Telegram-style horizontal folder tabs (All, Unread, Pinned, Read)
/// dynamically colored by [colorTheme].
class InboxFolderTabs extends StatelessWidget {
  final ConversationFilter activeFilter;
  final ValueChanged<ConversationFilter> onFilterChanged;
  final int totalCount;
  final int unreadCount;
  final int pinnedCount;
  final int readCount;
  final ChatColorTheme colorTheme;

  const InboxFolderTabs({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.totalCount,
    required this.unreadCount,
    required this.pinnedCount,
    required this.readCount,
    this.colorTheme = ChatColorTheme.dealOneNavy,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);

    final tabs = [
      (
        filter: ConversationFilter.all,
        label: isArabic ? 'الكل' : 'All',
        count: totalCount,
        badgeColor: activeFilter == ConversationFilter.all
            ? Colors.white.withValues(alpha: 0.22)
            : DealOneTokens.softTileBgOf(context),
        badgeTextColor: activeFilter == ConversationFilter.all
            ? Colors.white
            : DealOneTokens.textPrimaryOf(context),
      ),
      (
        filter: ConversationFilter.unread,
        label: isArabic ? 'غير مقروءة' : 'Unread',
        count: unreadCount,
        badgeColor: DealOneTokens.amber,
        badgeTextColor: Colors.white,
      ),
      (
        filter: ConversationFilter.pinned,
        label: isArabic ? 'مثبتة' : 'Pinned',
        count: pinnedCount,
        badgeColor: activeFilter == ConversationFilter.pinned
            ? Colors.white.withValues(alpha: 0.22)
            : accent.withValues(alpha: 0.14),
        badgeTextColor: activeFilter == ConversationFilter.pinned
            ? Colors.white
            : accent,
      ),
      (
        filter: ConversationFilter.read,
        label: isArabic ? 'مقروءة' : 'Read',
        count: readCount,
        badgeColor: activeFilter == ConversationFilter.read
            ? Colors.white.withValues(alpha: 0.22)
            : DealOneTokens.softTileBgOf(context),
        badgeTextColor: activeFilter == ConversationFilter.read
            ? Colors.white
            : DealOneTokens.textSecondaryOf(context),
      ),
    ];

    return SingleChildScrollView(
      key: const Key('inbox_folder_tabs'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final selected = tab.filter == activeFilter;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
            child: Material(
              color: selected ? accent : DealOneTokens.cardSurfaceOf(context),
              borderRadius: AppRadii.full,
              child: InkWell(
                key: Key('inbox_tab_${tab.filter.name}'),
                onTap: () => onFilterChanged(tab.filter),
                borderRadius: AppRadii.full,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.full,
                    border: Border.all(
                      color: selected
                          ? accent
                          : DealOneTokens.cardBorderOf(context),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : DealOneTokens.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tab.badgeColor,
                          borderRadius: AppRadii.full,
                        ),
                        child: Text(
                          '${tab.count}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: tab.badgeTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
