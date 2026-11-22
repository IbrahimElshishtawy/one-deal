import 'package:market_space/features/notifications/domain/entities/user_notification_entity.dart';

abstract class UserNotificationsRepository {
  Future<NotificationsPageResult> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  });

  Future<void> markAsRead(String notificationId);

  Future<void> markAllAsRead();
}
