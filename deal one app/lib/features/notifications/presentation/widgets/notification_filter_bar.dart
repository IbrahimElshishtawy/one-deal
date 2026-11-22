import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/notifications/presentation/providers/user_notifications_providers.dart';

/// Horizontal notification filter bar matching `Notification.png` and `Non Notification.png`.
class NotificationFilterBar extends StatelessWidget {
  final NotificationCategoryFilter activeFilter;
  final int unreadCount;
  final ValueChanged<NotificationCategoryFilter> onFilterChanged;

  const NotificationFilterBar({
    super.key,
    required this.activeFilter,
    required this.unreadCount,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _NotifChip(
            label: isArabic ? 'الكل' : 'All',
            selected: activeFilter == NotificationCategoryFilter.all,
            countBadge: unreadCount,
            onTap: () => onFilterChanged(NotificationCategoryFilter.all),
          ),
          const SizedBox(width: AppSpacing.sm),
          _NotifChip(
            label: isArabic ? 'العقارات والمعاينات' : 'Properties & Viewings',
            icon: Icons.apartment_rounded,
            selected: activeFilter ==
                NotificationCategoryFilter.propertiesAndViewings,
            onTap: () => onFilterChanged(
              NotificationCategoryFilter.propertiesAndViewings,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _NotifChip(
            label: isArabic ? 'المحادثات' : 'Chats',
            icon: Icons.chat_bubble_outline_rounded,
            selected: activeFilter == NotificationCategoryFilter.chats,
            onTap: () => onFilterChanged(NotificationCategoryFilter.chats),
          ),
        ],
      ),
    );
  }
}

class _NotifChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final int? countBadge;
  final bool selected;
  final VoidCallback onTap;

  const _NotifChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.countBadge,
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
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? Colors.white
                      : DealOneTokens.textPrimaryOf(context),
                ),
                const SizedBox(width: 6),
              ],
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
              if (countBadge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: DealOneTokens.amber,
                    borderRadius: AppRadii.full,
                  ),
                  child: Text(
                    '$countBadge',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
