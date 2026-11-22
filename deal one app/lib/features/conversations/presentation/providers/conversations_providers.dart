import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/conversations/data/repositories/conversations_repository_impl.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';
import 'package:market_space/features/conversations/domain/repositories/conversations_repository.dart';

enum ConversationFilter { all, unread, read }

final conversationsRepositoryProvider = Provider<ConversationsRepository>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return ConversationsRepositoryImpl(apiClient: apiClient);
});

final conversationsListProvider = FutureProvider<List<ConversationEntity>>((
  ref,
) async {
  final session = ref.watch(sessionProvider);
  if (!session.isAuthenticated) return const [];
  final repo = ref.watch(conversationsRepositoryProvider);
  return repo.getMyConversations(currentUserId: session.userId);
});

final conversationsFilterProvider = StateProvider<ConversationFilter>(
  (ref) => ConversationFilter.all,
);

final conversationsSearchQueryProvider = StateProvider<String>((ref) => '');

final conversationMessagesFamily = FutureProvider.autoDispose
    .family<List<ChatMessageEntity>, String>((ref, conversationId) async {
      final repo = ref.watch(conversationsRepositoryProvider);
      return repo.getMessages(conversationId);
    });
