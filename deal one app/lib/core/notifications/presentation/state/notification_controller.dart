import 'package:flutter/foundation.dart';

import 'package:market_space/core/notifications/data/models/app_notification.dart';
import 'package:market_space/core/notifications/data/repositories/notification_repository.dart';

class NotificationController extends ChangeNotifier {
  final NotificationRepository repository;

  NotificationController({required this.repository}) {
    repository.unreadCountsNotifier.addListener(_onCountsChanged);
  }

  void _onCountsChanged() {
    notifyListeners();
  }

  int getUnreadCount(String sectionId) {
    return repository.getUnreadCountForSection(sectionId);
  }

  List<AppNotification> getNotifications(String sectionId) {
    return repository.getNotificationsForSection(sectionId);
  }

  void markAsRead(String notificationId) {
    repository.markAsRead(notificationId);
  }

  void markAllAsRead(String sectionId) {
    repository.markAllAsReadForSection(sectionId);
  }

  void addNotification(AppNotification notification) {
    repository.addNotification(notification);
  }

  @override
  void dispose() {
    repository.unreadCountsNotifier.removeListener(_onCountsChanged);
    super.dispose();
  }
}
