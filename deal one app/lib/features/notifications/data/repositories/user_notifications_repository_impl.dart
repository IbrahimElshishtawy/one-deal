import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/notifications/domain/entities/user_notification_entity.dart';
import 'package:market_space/features/notifications/domain/repositories/user_notifications_repository.dart';

class UserNotificationsRepositoryImpl implements UserNotificationsRepository {
  final ApiClient apiClient;

  const UserNotificationsRepositoryImpl({required this.apiClient});

  @override
  Future<NotificationsPageResult> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (unreadOnly != null) 'unread': unreadOnly,
      },
    );

    final raw = response.data;
    final map = raw is Map
        ? Map<String, dynamic>.from(
            raw['data'] is Map ? raw['data'] as Map : raw,
          )
        : <String, dynamic>{};

    final rawItems = map['items'] is List ? map['items'] as List : const [];
    final items = rawItems
        .whereType<Map>()
        .map((e) => _parseItem(Map<String, dynamic>.from(e)))
        .toList();

    final meta = map['meta'] is Map
        ? Map<String, dynamic>.from(map['meta'] as Map)
        : const <String, dynamic>{};

    return NotificationsPageResult(
      items: items,
      unreadCount: (map['unreadCount'] as num?)?.toInt() ??
          items.where((n) => !n.isRead).length,
      total: (meta['total'] as num?)?.toInt() ?? items.length,
      page: (meta['page'] as num?)?.toInt() ?? page,
      totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await apiClient.patch(ApiEndpoints.markNotificationRead(notificationId));
  }

  @override
  Future<void> markAllAsRead() async {
    await apiClient.patch(ApiEndpoints.markAllNotificationsRead);
  }

  UserNotificationEntity _parseItem(Map<String, dynamic> json) {
    final payload = json['payload'] is Map
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : const <String, dynamic>{};
    return UserNotificationEntity(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'GENERAL',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      isRead: json['isRead'] == true || json['is_read'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      payload: payload,
    );
  }
}
