import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';

/// Search bar + Filter chips + Live advisors status banner matching `Conversations.png`.
class ConversationFilterHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ConversationFilter activeFilter;
  final ValueChanged<ConversationFilter> onFilterChanged;
  final int totalCount;
  final int unreadCount;
  final int readCount;

  const ConversationFilterHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.totalCount,
    required this.unreadCount,
    required this.readCount,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Input Pill
        Container(
          decoration: DealOneTokens.cardDecoration(
            context,
            borderRadius: AppRadii.lg,
          ),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: isArabic
                  ? 'ابحث في المحادثات أو الإعلانات...'
                  : 'Search conversations or listings...',
              hintStyle: TextStyle(
                fontSize: 13.5,
                color: DealOneTokens.textSecondaryOf(context),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: DealOneTokens.textPrimaryOf(context),
              ),
              suffixIcon: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DealOneTokens.softTileBgOf(context),
                  borderRadius: AppRadii.sm,
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: DealOneTokens.textPrimaryOf(context),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Filter Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ConversationFilterPill(
                label: isArabic ? 'الكل' : 'All',
                count: totalCount,
                selected: activeFilter == ConversationFilter.all,
                badgeColor: activeFilter == ConversationFilter.all
                    ? Colors.white
                    : DealOneTokens.softTileBgOf(context),
                badgeTextColor: DealOneTokens.navy,
                onTap: () => onFilterChanged(ConversationFilter.all),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ConversationFilterPill(
                label: isArabic ? 'غير مقروءة' : 'Unread',
                count: unreadCount,
                selected: activeFilter == ConversationFilter.unread,
                badgeColor: DealOneTokens.amber,
                badgeTextColor: Colors.white,
                onTap: () => onFilterChanged(ConversationFilter.unread),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ConversationFilterPill(
                label: isArabic ? 'مقروءة' : 'Read',
                count: readCount,
                selected: activeFilter == ConversationFilter.read,
                badgeColor: DealOneTokens.navySoft,
                badgeTextColor: Colors.white,
                onTap: () => onFilterChanged(ConversationFilter.read),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Live Advisor Banner matching PNG
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: DealOneTokens.softTileBgOf(context),
            borderRadius: AppRadii.md,
            border: Border.all(color: DealOneTokens.cardBorderOf(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: DealOneTokens.navy,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isArabic
                      ? 'الردود الفورية نشطة الآن من مستشاري Deal One'
                      : 'Instant replies are active from Deal One advisors',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConversationFilterPill extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color badgeColor;
  final Color badgeTextColor;
  final VoidCallback onTap;

  const _ConversationFilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? DealOneTokens.navy
          : DealOneTokens.cardSurfaceOf(context),
      borderRadius: AppRadii.full,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.full,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: AppRadii.full,
            border: Border.all(
              color: selected
                  ? DealOneTokens.navy
                  : DealOneTokens.cardBorderOf(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : DealOneTokens.textPrimaryOf(context),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: AppRadii.full,
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
