class ConversationListingPreview {
  final String id;
  final String title;
  final double price;
  final String? imageUrl;

  const ConversationListingPreview({
    required this.id,
    required this.title,
    required this.price,
    this.imageUrl,
  });
}

class ConversationEntity {
  final String id;
  final String listingId;
  final String buyerUserId;
  final String sellerAccountId;
  final String counterpartName;
  final String? counterpartAvatarUrl;
  final String? counterpartSubtitle;
  final bool isVerified;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final ConversationListingPreview? listing;

  const ConversationEntity({
    required this.id,
    required this.listingId,
    required this.buyerUserId,
    required this.sellerAccountId,
    required this.counterpartName,
    this.counterpartAvatarUrl,
    this.counterpartSubtitle,
    this.isVerified = false,
    this.lastMessageText,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.listing,
  });

  bool get hasUnread => unreadCount > 0;
}

class ChatMessageEntity {
  final String id;
  final String conversationId;
  final String senderUserId;
  final String senderName;
  final String? senderAvatarUrl;
  final String body;
  final String status;
  final DateTime sentAt;

  const ChatMessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.body,
    required this.status,
    required this.sentAt,
  });
}
