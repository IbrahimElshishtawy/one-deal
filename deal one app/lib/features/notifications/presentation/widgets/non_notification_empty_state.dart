import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';

/// Empty state widget matching `Non Notification.png`.
class NonNotificationEmptyState extends StatelessWidget {
  final VoidCallback onBrowseProperties;

  const NonNotificationEmptyState({
    super.key,
    required this.onBrowseProperties,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    return DealOneEmptyStateView(
      key: const Key('non_notification_empty_state'),
      icon: Icons.notifications_active_rounded,
      badgeIcon: Icons.done_all_rounded,
      statusPill: isArabic ? 'أنت على اطلاع بكل جديد' : 'You are all caught up',
      title: isArabic ? 'لا توجد إشعارات جديدة' : 'No New Notifications',
      description: isArabic
          ? 'لقد قرأت جميع التنبيهات! سنخطرك فور توفر عروض عقارية جديدة، مواعيد معاينات، أو رسائل من المعلنين.'
          : 'You have read all alerts! We will notify you as soon as new property offers, viewing appointments, or messages arrive.',
      actionLabel: isArabic
          ? 'العودة للرئيسية وتصفح العقارات'
          : 'Back to Home & Browse Properties',
      actionIcon: Icons.explore_outlined,
      onAction: onBrowseProperties,
      footerText: isArabic
          ? 'جميع التنبيهات مشفرة وتخضع لسياسة الخصوصية'
          : 'All notifications are encrypted under Deal One privacy policy',
    );
  }
}
