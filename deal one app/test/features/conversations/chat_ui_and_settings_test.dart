import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/security/session_state.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/core/theme/app_theme_data.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';
import 'package:market_space/features/conversations/domain/repositories/conversations_repository.dart';
import 'package:market_space/features/conversations/presentation/pages/chat_settings_page.dart';
import 'package:market_space/features/conversations/presentation/pages/conversation_chat_page.dart';
import 'package:market_space/features/conversations/presentation/providers/chat_settings_provider.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';

class _FakeConversationsRepository implements ConversationsRepository {
  final List<ChatMessageEntity> messages;
  final List<String> sentTexts = [];

  _FakeConversationsRepository(this.messages);

  @override
  Future<List<ConversationEntity>> getMyConversations({
    String? currentUserId,
  }) async =>
      const [];

  @override
  Future<ConversationEntity> startOrGetConversation(
    String listingId, {
    String? currentUserId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 30,
  }) async =>
      List.unmodifiable(messages);

  @override
  Future<ChatMessageEntity> sendMessage(
    String conversationId,
    String text,
  ) async {
    sentTexts.add(text);
    final created = ChatMessageEntity(
      id: 'msg-${messages.length + 1}',
      conversationId: conversationId,
      senderUserId: 'user-me',
      senderName: 'أنا',
      body: text,
      status: 'sent',
      sentAt: DateTime.now(),
    );
    messages.add(created);
    return created;
  }
}

void main() {
  group('ChatSettingsNotifier persistence & defaults', () {
    test('updates, persists across containers, toggles mute, and resets', () async {
      final prefs = InMemoryPreferencesService();
      final container1 = ProviderContainer(
        overrides: [preferencesServiceProvider.overrideWithValue(prefs)],
      );
      addTearDown(container1.dispose);

      await Future<void>.delayed(Duration.zero);
      final notifier = container1.read(chatSettingsProvider.notifier);

      notifier.setFontSize(19.0);
      notifier.setBubbleRadius(10.0);
      notifier.setColorTheme(ChatColorTheme.telegramBlue);
      notifier.setWallpaper(ChatWallpaperPreset.midnightAurora);
      notifier.setSendByEnter(false);
      notifier.setCompactMode(true);
      notifier.toggleMuteConversation('conv-1');

      await Future<void>.delayed(Duration.zero);

      final container2 = ProviderContainer(
        overrides: [preferencesServiceProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);
      container2.read(chatSettingsProvider);
      await Future<void>.delayed(Duration.zero);

      final loaded = container2.read(chatSettingsProvider);
      expect(loaded.fontSize, 19.0);
      expect(loaded.bubbleRadius, 10.0);
      expect(loaded.colorTheme, ChatColorTheme.telegramBlue);
      expect(loaded.wallpaper, ChatWallpaperPreset.midnightAurora);
      expect(loaded.sendByEnter, isFalse);
      expect(loaded.compactMode, isTrue);
      expect(loaded.isMuted('conv-1'), isTrue);

      container2.read(chatSettingsProvider.notifier).resetToDefaults();
      expect(container2.read(chatSettingsProvider), ChatSettingsEntity.defaults);
    });
  });

  group('ConversationChatPage & ChatSettingsPage Widgets', () {
    late InMemoryPreferencesService prefs;
    late _FakeConversationsRepository fakeRepo;
    late ConversationEntity sampleConv;

    setUp(() {
      prefs = InMemoryPreferencesService();
      final now = DateTime.now();
      sampleConv = const ConversationEntity(
        id: 'conv-100',
        listingId: 'listing-1',
        buyerUserId: 'user-me',
        sellerAccountId: 'seller-acc-1',
        counterpartName: 'زايد هايتس للتسويق العقاري',
        isVerified: true,
        listing: ConversationListingPreview(
          id: 'listing-1',
          title: 'أرض 600م بطنطا متفرع من شارع الجيش',
          price: 4500000,
        ),
      );
      fakeRepo = _FakeConversationsRepository([
        ChatMessageEntity(
          id: 'm1',
          conversationId: 'conv-100',
          senderUserId: 'seller-1',
          senderName: 'زايد هايتس',
          body: 'مرحباً بك في إعلان زايد هايتس',
          status: 'read',
          sentAt: now.subtract(const Duration(minutes: 5)),
        ),
        ChatMessageEntity(
          id: 'm2',
          conversationId: 'conv-100',
          senderUserId: 'user-me',
          senderName: 'أنا',
          body: 'هل السعر قابل للتفاوض؟',
          status: 'read',
          sentAt: now.subtract(const Duration(minutes: 2)),
        ),
      ]);
    });

    Widget buildHarness({
      required Widget child,
      ThemeMode themeMode = ThemeMode.dark,
    }) {
      return ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefs),
          conversationsRepositoryProvider.overrideWithValue(fakeRepo),
          sessionProvider.overrideWith(
            () => _AuthenticatedTestSessionNotifier('user-me'),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          themeMode: themeMode,
          theme: AppThemeData.lightTheme,
          darkTheme: AppThemeData.darkTheme,
          localizationsDelegates: AppLocalization.localizationsDelegates,
          supportedLocales: AppLocalization.supportedLocales,
          home: child,
        ),
      );
    }

    testWidgets(
      'ConversationChatPage renders independent widgets, search, reply & sends message',
      (tester) async {
        await tester.pumpWidget(
          buildHarness(
            child: ConversationChatPage(
              conversationId: 'conv-100',
              initialConversation: sampleConv,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('chat_listing_context_banner')), findsOneWidget);
        expect(find.byKey(const Key('chat_quick_replies_bar')), findsOneWidget);
        expect(find.byKey(const Key('chat_input_composer')), findsOneWidget);
        expect(find.text('مرحباً بك في إعلان زايد هايتس'), findsOneWidget);
        expect(find.text('هل السعر قابل للتفاوض؟'), findsOneWidget);

        // Toggle search bar
        await tester.tap(find.byKey(const Key('chat_search_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('chat_search_bar')), findsOneWidget);
        await tester.enterText(find.byKey(const Key('chat_search_input')), 'تفاوض');
        await tester.pumpAndSettle();
        expect(find.text('1/1'), findsOneWidget);
        await tester.tap(find.byKey(const Key('chat_search_close_button')));
        await tester.pumpAndSettle();

        // Long-press incoming message to reply
        await tester.longPress(find.text('مرحباً بك في إعلان زايد هايتس'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('رد على الرسالة'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('chat_reply_preview_bar')), findsOneWidget);

        // Send reply message
        await tester.enterText(
          find.byKey(const Key('chat_message_input')),
          'تمام شكراً لحضرتك',
        );
        await tester.tap(find.byKey(const Key('chat_send_button')));
        await tester.pumpAndSettle();

        expect(fakeRepo.sentTexts.length, 1);
        expect(fakeRepo.sentTexts.first, contains('↪ زايد هايتس:'));
        expect(fakeRepo.sentTexts.first, contains('تمام شكراً لحضرتك'));
        expect(find.byKey(const Key('chat_reply_preview_bar')), findsNothing);
      },
    );

    testWidgets(
      'ChatSettingsPage updates theme, wallpaper, switches and resets cleanly',
      (tester) async {
        await tester.pumpWidget(
          buildHarness(
            themeMode: ThemeMode.light,
            child: const ChatSettingsPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('chat_settings_preview_card')), findsOneWidget);

        // Tap Telegram blue theme option
        await tester.tap(find.byKey(const Key('chat_theme_option_telegramBlue')));
        await tester.pumpAndSettle();

        // Tap Aurora wallpaper option
        await tester.tap(
          find.byKey(const Key('chat_wallpaper_option_midnightAurora')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('chat_wallpaper_midnightAurora')),
          findsOneWidget,
        );

        // Scroll down and toggle compact mode
        await tester.scrollUntilVisible(
          find.byKey(const Key('chat_compact_mode_switch')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(
          find.byKey(const Key('chat_compact_mode_switch')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('chat_compact_mode_switch')));
        await tester.pumpAndSettle();

        // Tap reset
        await tester.tap(find.byKey(const Key('chat_settings_reset_button')));
        await tester.pumpAndSettle();

        // Scroll back to top preview card
        await tester.scrollUntilVisible(
          find.byKey(const Key('chat_settings_preview_card')),
          -300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('chat_wallpaper_geometricDoodle')),
          findsOneWidget,
        );
      },
    );
  });
}

class _AuthenticatedTestSessionNotifier extends SessionNotifier {
  final String _userId;

  _AuthenticatedTestSessionNotifier(this._userId);

  @override
  SessionState build() =>
      SessionState(status: SessionStatus.authenticated, userId: _userId);
}
