class UserNotificationEntity {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  const UserNotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.payload = const {},
  });

  String? get listingId =>
      payload['listingId']?.toString() ?? payload['listing_id']?.toString();

  String? get conversationId =>
      payload['conversationId']?.toString() ??
      payload['conversation_id']?.toString();

  String? get bookingId =>
      payload['bookingId']?.toString() ?? payload['booking_id']?.toString();

  String? get targetRoute =>
      payload['route']?.toString() ?? payload['targetRoute']?.toString();

  String? get locationLabel => payload['location']?.toString();

  String? get senderLabel => payload['senderName']?.toString();

  String? get discountBadge => payload['discountLabel']?.toString();

  bool get isChatType {
    final t = type.toLowerCase();
    return t.contains('chat') ||
        t.contains('message') ||
        conversationId != null;
  }

  bool get isPropertyOrViewingType {
    final t = type.toLowerCase();
    return t.contains('booking') ||
        t.contains('viewing') ||
        t.contains('listing') ||
        t.contains('property') ||
        t.contains('price') ||
        t.contains('favorite') ||
        listingId != null ||
        bookingId != null;
  }

  UserNotificationEntity copyWith({bool? isRead}) {
    return UserNotificationEntity(
      id: id,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      payload: payload,
    );
  }
}

class NotificationsPageResult {
  final List<UserNotificationEntity> items;
  final int unreadCount;
  final int total;
  final int page;
  final int totalPages;

  const NotificationsPageResult({
    required this.items,
    required this.unreadCount,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}
