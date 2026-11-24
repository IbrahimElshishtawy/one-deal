import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/notifications/domain/entities/user_notification_entity.dart';
import 'package:market_space/features/notifications/presentation/providers/user_notifications_providers.dart';
import 'package:market_space/features/notifications/presentation/widgets/non_notification_empty_state.dart';
import 'package:market_space/features/notifications/presentation/widgets/notification_filter_bar.dart';
import 'package:market_space/features/notifications/presentation/widgets/notification_item_card.dart';

/// Notifications Screen matching `Notification.png` and `Non Notification.png`.
/// Backed by `GET /notifications`, `PATCH /notifications/:id/read`, `PATCH /notifications/read-all`.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    UserNotificationEntity item,
  ) {
    ref.read(userNotificationsProvider.notifier).markAsRead(item.id);
    if (item.conversationId != null && item.conversationId!.isNotEmpty) {
      context.push('/conversations/${item.conversationId}');
      return;
    }
    if (item.listingId != null && item.listingId!.isNotEmpty) {
      context.push('/listings/${item.listingId}');
      return;
    }
    if (item.bookingId != null && item.bookingId!.isNotEmpty) {
      context.go('${RouteNames.activityHub}?tab=bookings');
      return;
    }
    if (item.targetRoute != null && item.targetRoute!.startsWith('/')) {
      if (RouteNames.isShellBranchLocation(item.targetRoute!)) {
        context.go(item.targetRoute!);
      } else {
        context.push(item.targetRoute!);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;
    final session = ref.watch(sessionProvider);

    if (!session.isAuthenticated) {
      return Scaffold(
        backgroundColor: DealOneTokens.pageBgOf(context),
        body: SafeArea(
          child: Column(
            children: [
              DealOneSubPageHeader(
                title: isArabic ? 'الإشعارات' : 'Notifications',
              ),
              Expanded(
                child: DealOneEmptyStateView(
                  icon: Icons.notifications_none_rounded,
                  title: isArabic
                      ? 'سجّل الدخول لعرض إشعاراتك'
                      : 'Sign in to view notifications',
                  description: isArabic
                      ? 'تابع تنبيهات المعاينات والرسائل وتحديثات الأسعار فور تسجيل الدخول.'
                      : 'Sign in to receive viewing confirmations, messages, and price drop alerts.',
                  actionLabel: isArabic ? 'تسجيل الدخول' : 'Sign In',
                  actionIcon: Icons.login_rounded,
                  onAction: () => context.push(RouteNames.login),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final state = ref.watch(userNotificationsProvider);
    final controller = ref.read(userNotificationsProvider.notifier);
    final filtered = state.filteredItems;

    final now = DateTime.now();
    final todayItems = <UserNotificationEntity>[];
    final earlierItems = <UserNotificationEntity>[];
    for (final n in filtered) {
      final isToday = n.createdAt.year == now.year &&
          n.createdAt.month == now.month &&
          n.createdAt.day == now.day;
      if (isToday) {
        todayItems.add(n);
      } else {
        earlierItems.add(n);
      }
    }

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      body: SafeArea(
        child: Column(
          children: [
            DealOneSubPageHeader(
              title: isArabic ? 'الإشعارات' : 'Notifications',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: DealOneTokens.softTileBgOf(context),
                    borderRadius: AppRadii.full,
                    child: InkWell(
                      key: const Key('notifications_mark_all_read_button'),
                      onTap: state.unreadCount > 0 && !state.isMarkingAll
                          ? controller.markAllAsRead
                          : null,
                      borderRadius: AppRadii.full,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.done_all_rounded,
                              size: 16,
                              color: state.unreadCount > 0
                                  ? DealOneTokens.textPrimaryOf(context)
                                  : DealOneTokens.textSecondaryOf(context),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isArabic
                                  ? 'تحديد الكل كمقروء'
                                  : 'Mark all read',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: state.unreadCount > 0
                                    ? DealOneTokens.textPrimaryOf(context)
                                    : DealOneTokens.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                hPad,
                AppSpacing.xs,
                hPad,
                AppSpacing.md,
              ),
              child: NotificationFilterBar(
                activeFilter: state.filter,
                unreadCount: state.unreadCount,
                onFilterChanged: controller.setFilter,
              ),
            ),
            Expanded(
              child: state.isLoading && state.items.isEmpty
                  ? const DealOneLoadingList(itemCount: 4, itemHeight: 118)
                  : state.error != null && state.items.isEmpty
                      ? DealOneErrorStateView(
                          error: state.error!,
                          onRetry: controller.loadInitial,
                        )
                      : filtered.isEmpty
                          ? NonNotificationEmptyState(
                              onBrowseProperties: () =>
                                  context.go(RouteNames.realEstate),
                            )
                          : RefreshIndicator(
                              color: DealOneTokens.navy,
                              onRefresh: controller.loadInitial,
                              child: ListView(
                                padding: EdgeInsets.fromLTRB(
                                  hPad,
                                  AppSpacing.xs,
                                  hPad,
                                  AppSpacing.xxl,
                                ),
                                children: [
                                  if (todayItems.isNotEmpty) ...[
                                    _DateGroupHeader(
                                      title: isArabic ? 'اليوم' : 'Today',
                                      trailingText: isArabic
                                          ? '${todayItems.where((n) => !n.isRead).length} إشعارات جديدة'
                                          : '${todayItems.where((n) => !n.isRead).length} new',
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    for (final item in todayItems) ...[
                                      NotificationItemCard(
                                        notification: item,
                                        onTap: () => _handleNotificationTap(
                                          context,
                                          ref,
                                          item,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                    ],
                                  ],
                                  if (earlierItems.isNotEmpty) ...[
                                    _DateGroupHeader(
                                      title: isArabic ? 'سابقاً' : 'Earlier',
                                      trailingText: isArabic
                                          ? 'تمت المراجعة'
                                          : 'Reviewed',
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    for (final item in earlierItems) ...[
                                      NotificationItemCard(
                                        notification: item,
                                        onTap: () => _handleNotificationTap(
                                          context,
                                          ref,
                                          item,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                    ],
                                  ],
                                  if (state.hasMore)
                                    Center(
                                      child: OutlinedButton(
                                        onPressed: state.isLoadingMore
                                            ? null
                                            : controller.loadMore,
                                        child: state.isLoadingMore
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                isArabic
                                                    ? 'عرض المزيد'
                                                    : 'Load More',
                                              ),
                                      ),
                                    ),
                                  DealOnePrivacyFooter(
                                    title: isArabic
                                        ? 'جميع التنبيهات مشفرة وتخضع لسياسة الخصوصية'
                                        : 'All notifications are encrypted under Deal One privacy policy',
                                  ),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateGroupHeader extends StatelessWidget {
  final String title;
  final String trailingText;

  const _DateGroupHeader({
    required this.title,
    required this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: DealOneTokens.textSecondaryOf(context),
          ),
        ),
        Text(
          trailingText,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }
}
