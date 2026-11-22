import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';

/// Conversation Chat Thread Screen connected to:
/// `GET /conversations/:id/messages` and `POST /conversations/:id/messages`.
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
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(conversationsRepositoryProvider)
          .sendMessage(widget.conversationId, text);
      _messageController.clear();
      ref.invalidate(conversationMessagesFamily(widget.conversationId));
      ref.invalidate(conversationsListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final currentUserId = ref.watch(sessionProvider).userId;
    final messagesAsync =
        ref.watch(conversationMessagesFamily(widget.conversationId));
    final title = widget.initialConversation?.counterpartName ??
        (isArabic ? 'المحادثة' : 'Conversation');
    final listingTitle = widget.initialConversation?.listing?.title;

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      body: SafeArea(
        child: Column(
          children: [
            DealOneSubPageHeader(
              title: title,
              subtitle: listingTitle,
              onBack: () {
                if (context.canPop()) context.pop();
              },
              trailing: widget.initialConversation?.listingId.isNotEmpty == true
                  ? IconButton(
                      tooltip: isArabic ? 'عرض العقار' : 'View Property',
                      onPressed: () => context.push(
                        '/listings/${widget.initialConversation!.listingId}',
                      ),
                      icon: Icon(
                        Icons.home_work_outlined,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: messagesAsync.when(
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
                    return DealOneEmptyStateView(
                      icon: Icons.mark_chat_unread_outlined,
                      title: isArabic
                          ? 'ابدأ المحادثة الآن'
                          : 'Start the conversation',
                      description: isArabic
                          ? 'أرسل سؤالك حول العقار أو طلب موعد معاينة.'
                          : 'Send your inquiry about the property or request a viewing.',
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMine = currentUserId != null &&
                          msg.senderUserId == currentUserId;
                      return Align(
                        alignment: isMine
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                          ),
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? DealOneTokens.navy
                                : DealOneTokens.cardSurfaceOf(context),
                            borderRadius: AppRadii.lg,
                            border: isMine
                                ? null
                                : Border.all(
                                    color: DealOneTokens.cardBorderOf(context),
                                  ),
                          ),
                          child: Text(
                            msg.body,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: isMine
                                  ? Colors.white
                                  : DealOneTokens.textPrimaryOf(context),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: DealOneTokens.cardSurfaceOf(context),
                border: Border(
                  top: BorderSide(color: DealOneTokens.cardBorderOf(context)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: isArabic
                            ? 'اكتب رسالتك هنا...'
                            : 'Type your message...',
                        filled: true,
                        fillColor: DealOneTokens.inputFillOf(context),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: AppRadii.full,
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Material(
                    color: DealOneTokens.navy,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _sending ? null : _sendMessage,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
