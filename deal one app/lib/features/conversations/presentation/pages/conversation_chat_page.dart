import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';
import 'package:market_space/features/conversations/presentation/providers/chat_settings_provider.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_app_bar.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_attachment_sheet.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_date_separator.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_empty_state.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_input_composer.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_listing_context_banner.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_message_actions_sheet.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_message_bubble.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_quick_replies_bar.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_reply_preview_bar.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_scroll_to_bottom_fab.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_search_bar.dart';
import 'package:market_space/features/conversations/presentation/widgets/chat/chat_wallpaper_background.dart';

/// Complete Telegram-inspired Conversation Chat Thread Screen composed of
/// independent reusable widgets and wired to `chatSettingsProvider`.
class ConversationChatPage extends ConsumerStatefulWidget {
  final String conversationId;
  final ConversationEntity? initialConversation;

  const ConversationChatPage({
    super.key,
    required this.conversationId,
    this.initialConversation,
  });

  @override
  ConsumerState<ConversationChatPage> createState() =>
      _ConversationChatPageState();
}

class _ConversationChatPageState extends ConsumerState<ConversationChatPage> {
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  bool _sending = false;
  bool _isSearching = false;
  bool _bannerDismissed = false;
  bool _showQuickRepliesOverride = false;
  bool _showScrollToBottom = false;
  int _activeSearchMatchIdx = 0;
  ChatMessageEntity? _replyingTo;
  String? _pendingClientMessageId;
  String? _pendingPayload;
  final Map<String, GlobalKey> _messageKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    final awayFromBottom = (maxScroll - current) > 140;
    if (awayFromBottom != _showScrollToBottom) {
      setState(() => _showScrollToBottom = awayFromBottom);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  String _composePayload(String rawText) {
    final trimmed = rawText.trim();
    final reply = _replyingTo;
    if (reply == null) return trimmed;
    final senderLabel = reply.senderName.trim().isNotEmpty
        ? reply.senderName.trim()
        : (widget.initialConversation?.counterpartName ?? 'Deal One');
    final snippet = reply.body.replaceAll('\n', ' ').trim();
    final clipped = snippet.length > 60
        ? '${snippet.substring(0, 60)}...'
        : snippet;
    return '↪ $senderLabel: $clipped\n$trimmed';
  }

  Future<void> _sendMessage({String? overrideText}) async {
    final raw = overrideText ?? _messageController.text;
    final text = raw.trim();
    if (text.isEmpty || _sending) return;

    final settings = ref.read(chatSettingsProvider);
    if (settings.hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    final payload = _composePayload(text);
    // Reuse the exact same clientMessageId when retrying the same unsent payload
    // so transient network failures never create duplicate messages.
    final clientMessageId =
        (_pendingPayload == payload && _pendingClientMessageId != null)
            ? _pendingClientMessageId!
            : 'msg-${DateTime.now().microsecondsSinceEpoch}-${payload.hashCode.abs()}';
    _pendingPayload = payload;
    _pendingClientMessageId = clientMessageId;

    setState(() => _sending = true);

    try {
      await ref.read(conversationsRepositoryProvider).sendMessage(
            widget.conversationId,
            payload,
            clientMessageId: clientMessageId,
          );
      _pendingClientMessageId = null;
      _pendingPayload = null;
      if (overrideText == null) {
        _messageController.clear();
      }
      if (mounted) {
        setState(() => _replyingTo = null);
      }
      ref.invalidate(conversationMessagesFamily(widget.conversationId));
      ref.invalidate(conversationsListProvider);
      if (settings.autoScrollToBottom) {
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final isArabic = Directionality.of(context) == TextDirection.rtl;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            action: SnackBarAction(
              label: isArabic ? 'إعادة المحاولة' : 'Retry',
              onPressed: () => _sendMessage(overrideText: overrideText),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _openMessageActions(
    ChatMessageEntity msg,
    bool isArabic,
    ChatSettingsEntity settings,
  ) {
    if (settings.hapticFeedback) {
      HapticFeedback.selectionClick();
    }
    ChatMessageActionsSheet.show(
      context,
      message: msg,
      colorTheme: settings.colorTheme,
      onReply: () => setState(() => _replyingTo = msg),
      onCopy: () {
        Clipboard.setData(ClipboardData(text: msg.body));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'تم نسخ الرسالة' : 'Message copied',
            ),
          ),
        );
      },
    );
  }

  void _jumpToMatch(List<int> matchIndices, List<ChatMessageEntity> messages) {
    if (matchIndices.isEmpty) return;
    final safeIdx = _activeSearchMatchIdx.clamp(0, matchIndices.length - 1);
    final msg = messages[matchIndices[safeIdx]];
    final key = _messageKeys[msg.id];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 220),
        alignment: 0.45,
      );
    }
  }

  bool _isSameCalendarDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final currentUserId = ref.watch(sessionProvider).userId;
    final settings = ref.watch(chatSettingsProvider);
    final messagesAsync = ref.watch(
      conversationMessagesFamily(widget.conversationId),
    );

    final conv = widget.initialConversation;
    final title =
        conv?.counterpartName ?? (isArabic ? 'المحادثة' : 'Conversation');
    final listing = conv?.listing;
    final listingId = conv?.listingId ?? listing?.id ?? '';
    final isMuted = settings.isMuted(widget.conversationId);
    final showQuickReplies =
        settings.showQuickReplies || _showQuickRepliesOverride;

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      body: SafeArea(
        child: Column(
          children: [
            ChatAppBar(
              title: title,
              subtitle: listing?.title ?? conv?.counterpartSubtitle,
              avatarUrl: conv?.counterpartAvatarUrl,
              isVerified: conv?.isVerified ?? false,
              isMuted: isMuted,
              hasListing: listingId.isNotEmpty,
              colorTheme: settings.colorTheme,
              onBack: () {
                if (context.canPop()) context.pop();
              },
              onSearchTap: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _activeSearchMatchIdx = 0;
                  }
                });
              },
              onSettingsTap: () => context.push(RouteNames.chatSettings),
              onToggleMute: () {
                ref
                    .read(chatSettingsProvider.notifier)
                    .toggleMuteConversation(widget.conversationId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      !isMuted
                          ? (isArabic
                                ? 'تم كتم إشعارات هذه المحادثة'
                                : 'Notifications muted for this chat')
                          : (isArabic
                                ? 'تم تفعيل إشعارات هذه المحادثة'
                                : 'Notifications unmuted'),
                    ),
                  ),
                );
              },
              onViewListing: listingId.isNotEmpty
                  ? () => context.push('/listings/$listingId')
                  : null,
            ),
            if (_isSearching)
              Builder(
                builder: (context) {
                  final list =
                      messagesAsync.valueOrNull ?? const <ChatMessageEntity>[];
                  final q = _searchController.text.trim().toLowerCase();
                  final matchIndices = <int>[];
                  if (q.isNotEmpty) {
                    for (var i = 0; i < list.length; i++) {
                      if (list[i].body.toLowerCase().contains(q)) {
                        matchIndices.add(i);
                      }
                    }
                  }
                  return ChatSearchBar(
                    controller: _searchController,
                    totalMatches: matchIndices.length,
                    currentMatchIndex: matchIndices.isEmpty
                        ? 0
                        : _activeSearchMatchIdx.clamp(
                            0,
                            matchIndices.length - 1,
                          ),
                    colorTheme: settings.colorTheme,
                    onChanged: (_) => setState(() => _activeSearchMatchIdx = 0),
                    onPreviousMatch: () {
                      if (matchIndices.isEmpty) return;
                      setState(() {
                        _activeSearchMatchIdx =
                            (_activeSearchMatchIdx - 1 + matchIndices.length) %
                            matchIndices.length;
                      });
                      _jumpToMatch(matchIndices, list);
                    },
                    onNextMatch: () {
                      if (matchIndices.isEmpty) return;
                      setState(() {
                        _activeSearchMatchIdx =
                            (_activeSearchMatchIdx + 1) % matchIndices.length;
                      });
                      _jumpToMatch(matchIndices, list);
                    },
                    onClose: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        _activeSearchMatchIdx = 0;
                      });
                    },
                  );
                },
              ),
            if (settings.showListingBanner &&
                !_bannerDismissed &&
                listing != null)
              ChatListingContextBanner(
                listing: listing,
                colorTheme: settings.colorTheme,
                onOpenListing: () => context.push('/listings/${listing.id}'),
                onDismiss: () => setState(() => _bannerDismissed = true),
              ),
            Expanded(
              child: ChatWallpaperBackground(
                wallpaper: settings.wallpaper,
                child: Stack(
                  children: [
                    messagesAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                      error: (err, _) => DealOneErrorStateView(
                        error: err,
                        onRetry: () => ref.invalidate(
                          conversationMessagesFamily(widget.conversationId),
                        ),
                      ),
                      data: (messages) {
                        if (messages.isEmpty) {
                          return ChatEmptyState(
                            counterpartName: title,
                            colorTheme: settings.colorTheme,
                            onPromptSelected: (prompt) =>
                                _sendMessage(overrideText: prompt),
                          );
                        }

                        final q = _searchController.text.trim().toLowerCase();
                        final matchIds = <String>[];
                        if (_isSearching && q.isNotEmpty) {
                          for (final m in messages) {
                            if (m.body.toLowerCase().contains(q)) {
                              matchIds.add(m.id);
                            }
                          }
                        }
                        final focusedMatchId = matchIds.isNotEmpty
                            ? matchIds[_activeSearchMatchIdx.clamp(
                                0,
                                matchIds.length - 1,
                              )]
                            : null;

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final msgKey = _messageKeys.putIfAbsent(
                              msg.id,
                              () => GlobalKey(),
                            );
                            final isMine =
                                currentUserId != null &&
                                msg.senderUserId == currentUserId;
                            final showDateHeader =
                                index == 0 ||
                                !_isSameCalendarDay(
                                  messages[index - 1].sentAt,
                                  msg.sentAt,
                                );

                            return Column(
                              key: msgKey,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (showDateHeader)
                                  ChatDateSeparator(date: msg.sentAt),
                                ChatMessageBubble(
                                  message: msg,
                                  isMine: isMine,
                                  settings: settings,
                                  searchQuery: _isSearching
                                      ? _searchController.text
                                      : '',
                                  isHighlightedMatch: focusedMatchId == msg.id,
                                  onLongPress: () => _openMessageActions(
                                    msg,
                                    isArabic,
                                    settings,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    PositionedDirectional(
                      end: AppSpacing.md,
                      bottom: AppSpacing.md,
                      child: ChatScrollToBottomFab(
                        visible: _showScrollToBottom,
                        colorTheme: settings.colorTheme,
                        onPressed: _scrollToBottom,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_replyingTo != null)
              ChatReplyPreviewBar(
                replyingTo: _replyingTo!,
                senderLabel: _replyingTo!.senderUserId == currentUserId
                    ? (isArabic ? 'أنت' : 'You')
                    : (_replyingTo!.senderName.trim().isNotEmpty
                          ? _replyingTo!.senderName
                          : title),
                colorTheme: settings.colorTheme,
                onCancel: () => setState(() => _replyingTo = null),
              ),
            if (showQuickReplies)
              ChatQuickRepliesBar(
                colorTheme: settings.colorTheme,
                onSelected: (text) {
                  _messageController.text = text;
                  _messageController.selection = TextSelection.collapsed(
                    offset: text.length,
                  );
                },
              ),
            ChatInputComposer(
              controller: _messageController,
              settings: settings,
              sending: _sending,
              showQuickRepliesActive: showQuickReplies,
              onSend: () => _sendMessage(),
              onAttachmentTap: () {
                ChatAttachmentSheet.show(
                  context,
                  colorTheme: settings.colorTheme,
                  onTemplateSelected: (template) =>
                      _sendMessage(overrideText: template),
                );
              },
              onToggleQuickReplies: () {
                setState(
                  () => _showQuickRepliesOverride = !_showQuickRepliesOverride,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
