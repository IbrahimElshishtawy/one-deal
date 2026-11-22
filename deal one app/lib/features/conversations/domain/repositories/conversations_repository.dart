import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';

abstract class ConversationsRepository {
  Future<List<ConversationEntity>> getMyConversations({
    String? currentUserId,
  });

  Future<ConversationEntity> startOrGetConversation(
    String listingId, {
    String? currentUserId,
  });

  Future<List<ChatMessageEntity>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 30,
  });

  Future<ChatMessageEntity> sendMessage(String conversationId, String text);
}
