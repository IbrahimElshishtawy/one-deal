import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/features/conversations/data/repositories/conversations_repository_impl.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';
import 'package:market_space/features/conversations/domain/repositories/conversations_repository.dart';
import 'package:market_space/features/conversations/presentation/pages/conversation_chat_page.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';

class _RecordingConversationsRepo implements ConversationsRepository {
  final List<String?> sentClientMessageIds = [];
  bool failNextSend = false;

  @override
  Future<List<ConversationEntity>> getMyConversations({
    String? currentUserId,
  }) async =>
      const [];

  @override
  Future<ConversationEntity> startOrGetConversation(
    String listingId, {
    String? currentUserId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 30,
  }) async =>
      const [];

  @override
  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String text, {
    String? clientMessageId,
  }) async {
    sentClientMessageIds.add(clientMessageId);
    if (failNextSend) {
      failNextSend = false;
      throw Exception('Transient network timeout');
    }
    return ChatMessageEntity(
      id: 'msg-server-1',
      conversationId: conversationId,
      senderUserId: 'user-1',
      senderName: 'Test User',
      body: text,
      status: 'sent',
      sentAt: DateTime(2026, 11, 27, 12, 0),
    );
  }
}

class _FakeApiClient implements ApiClient {
  Map<String, dynamic>? lastData;
  Options? lastOptions;
  String? lastPath;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastData = data is Map<String, dynamic> ? data : null;
    lastOptions = options;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 201,
      data: {
        'data': {
          'id': 'msg-1',
          'conversationId': 'conv-1',
          'senderUserId': 'user-1',
          'body': lastData?['text'] ?? '',
          'status': 'sent',
          'sentAt': '2026-11-27T12:00:00.000Z',
        },
      } as T,
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();
}

void main() {
  group('Phase 2 Messaging Idempotency (MSG-001 Flutter)', () {
    test(
      'ConversationsRepositoryImpl sends clientMessageId in body and Idempotency-Key header',
      () async {
        final api = _FakeApiClient();
        final repo = ConversationsRepositoryImpl(apiClient: api);

        final msg = await repo.sendMessage(
          'conv-1',
          'Hello seller',
          clientMessageId: 'idem-fixed-key-42',
        );

        expect(api.lastPath, ApiEndpoints.conversationMessages('conv-1'));
        expect(api.lastData?['clientMessageId'], 'idem-fixed-key-42');
        expect(
          api.lastOptions?.headers?['Idempotency-Key'],
          'idem-fixed-key-42',
        );
        expect(msg.id, 'msg-1');
      },
    );

    testWidgets(
      'ConversationChatPage reuses the exact same clientMessageId on retry and rotates after success',
      (tester) async {
        final repo = _RecordingConversationsRepo()..failNextSend = true;
        final prefs = InMemoryPreferencesService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesServiceProvider.overrideWithValue(prefs),
              conversationsRepositoryProvider.overrideWithValue(repo),
            ],
            child: const MaterialApp(
              home: ConversationChatPage(conversationId: 'conv-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter text and send (1st attempt fails)
        await tester.enterText(
          find.byType(TextField).first,
          'Is this available?',
        );
        await tester.pump();
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        expect(repo.sentClientMessageIds.length, 1);
        final firstKey = repo.sentClientMessageIds.first;
        expect(firstKey, isNotNull);
        expect(firstKey, isNotEmpty);

        // Retry via Retry button on SnackBar -> MUST reuse exact same key
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        expect(repo.sentClientMessageIds.length, 2);
        expect(repo.sentClientMessageIds[1], equals(firstKey));

        // Sending a second distinct message -> MUST use a new key
        await tester.enterText(find.byType(TextField).first, 'Second message');
        await tester.pump();
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        expect(repo.sentClientMessageIds.length, 3);
        expect(repo.sentClientMessageIds[2], isNot(equals(firstKey)));
      },
    );
  });
}
