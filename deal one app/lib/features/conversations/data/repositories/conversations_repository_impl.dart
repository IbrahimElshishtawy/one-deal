import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';
import 'package:market_space/features/conversations/domain/repositories/conversations_repository.dart';

class ConversationsRepositoryImpl implements ConversationsRepository {
  final ApiClient apiClient;

  const ConversationsRepositoryImpl({required this.apiClient});

  @override
  Future<List<ConversationEntity>> getMyConversations({
    String? currentUserId,
  }) async {
    final response = await apiClient.get(ApiEndpoints.conversations);
    final raw = response.data;

    List<dynamic> list = const [];
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      if (raw['data'] is List) {
        list = raw['data'] as List;
      } else if (raw['items'] is List) {
        list = raw['items'] as List;
      }
    }

    final entities = list
        .whereType<Map>()
        .map(
          (m) => _parseConversation(
            Map<String, dynamic>.from(m),
            currentUserId: currentUserId,
          ),
        )
        .toList();

    entities.sort((a, b) {
      final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return entities;
  }

  @override
  Future<ConversationEntity> startOrGetConversation(
    String listingId, {
    String? currentUserId,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.conversations,
      data: {'listingId': listingId},
    );
    final raw = response.data;
    final map = raw is Map
        ? Map<String, dynamic>.from(
            raw['data'] is Map ? raw['data'] as Map : raw,
          )
        : <String, dynamic>{};
    return _parseConversation(map, currentUserId: currentUserId);
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 30,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.conversationMessages(conversationId),
      queryParameters: {'page': page, 'limit': limit},
    );
    final raw = response.data;
    List<dynamic> list = const [];
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      final inner = raw['data'] is Map ? raw['data'] as Map : raw;
      if (inner['messages'] is List) {
        list = inner['messages'] as List;
      } else if (raw['messages'] is List) {
        list = raw['messages'] as List;
      }
    }

    return list
        .whereType<Map>()
        .map((m) => _parseMessage(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String text,
  ) async {
    final response = await apiClient.post(
      ApiEndpoints.conversationMessages(conversationId),
      data: {'text': text.trim()},
    );
    final raw = response.data;
    final map = raw is Map
        ? Map<String, dynamic>.from(
            raw['data'] is Map ? raw['data'] as Map : raw,
          )
        : <String, dynamic>{};
    return _parseMessage(map);
  }

  ConversationEntity _parseConversation(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final buyer = json['buyer'] is Map
        ? Map<String, dynamic>.from(json['buyer'] as Map)
        : const <String, dynamic>{};
    final sellerAccount = json['sellerAccount'] is Map
        ? Map<String, dynamic>.from(json['sellerAccount'] as Map)
        : const <String, dynamic>{};
    final listingMap = json['listing'] is Map
        ? Map<String, dynamic>.from(json['listing'] as Map)
        : null;

    final buyerUserId = json['buyerUserId']?.toString() ?? '';
    final isCurrentUserBuyer =
        currentUserId != null && currentUserId == buyerUserId;

    final counterpartName = isCurrentUserBuyer
        ? (sellerAccount['displayName']?.toString() ??
            buyer['fullName']?.toString() ??
            'Deal One')
        : (buyer['fullName']?.toString() ??
            sellerAccount['displayName']?.toString() ??
            'Deal One');

    final counterpartAvatar = isCurrentUserBuyer
        ? sellerAccount['logoUrl']?.toString()
        : buyer['avatarUrl']?.toString();

    ConversationListingPreview? listingPreview;
    if (listingMap != null) {
      String? imageUrl;
      if (listingMap['media'] is List &&
          (listingMap['media'] as List).isNotEmpty) {
        final first = (listingMap['media'] as List).first;
        if (first is Map) {
          imageUrl = first['publicUrl']?.toString();
        }
      }
      final rawPrice = listingMap['price'];
      final price = rawPrice is num
          ? rawPrice.toDouble()
          : (double.tryParse(rawPrice?.toString() ?? '') ?? 0.0);

      listingPreview = ConversationListingPreview(
        id: listingMap['id']?.toString() ?? '',
        title: listingMap['title']?.toString() ?? '',
        price: price,
        imageUrl: imageUrl,
      );
    }

    final unreadRaw = json['unreadCount'] ?? json['unread_count'];
    final unreadCount = unreadRaw is num ? unreadRaw.toInt() : 0;

    return ConversationEntity(
      id: json['id']?.toString() ?? '',
      listingId: json['listingId']?.toString() ?? listingPreview?.id ?? '',
      buyerUserId: buyerUserId,
      sellerAccountId: json['sellerAccountId']?.toString() ?? '',
      counterpartName: counterpartName,
      counterpartAvatarUrl: counterpartAvatar,
      counterpartSubtitle: sellerAccount['displayName']?.toString(),
      isVerified: sellerAccount['verificationStatus'] == 'approved',
      lastMessageText: json['lastMessageText']?.toString(),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null),
      unreadCount: unreadCount,
      listing: listingPreview,
    );
  }

  ChatMessageEntity _parseMessage(Map<String, dynamic> json) {
    final sender = json['sender'] is Map
        ? Map<String, dynamic>.from(json['sender'] as Map)
        : const <String, dynamic>{};

    return ChatMessageEntity(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderUserId:
          json['senderUserId']?.toString() ?? sender['id']?.toString() ?? '',
      senderName: sender['fullName']?.toString() ?? '',
      senderAvatarUrl: sender['avatarUrl']?.toString(),
      body: json['body']?.toString() ?? json['text']?.toString() ?? '',
      status: json['status']?.toString() ?? 'sent',
      sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
