import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';
import 'package:market_space/features/conversations/presentation/providers/chat_settings_provider.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';
import 'package:market_space/features/conversations/presentation/widgets/inbox/inbox_app_bar.dart';
import 'package:market_space/features/conversations/presentation/widgets/inbox/inbox_archived_folder_tile.dart';
import 'package:market_space/features/conversations/presentation/widgets/inbox/inbox_conversation_actions_sheet.dart';
import 'package:market_space/features/conversations/presentation/widgets/inbox/inbox_conversation_tile.dart';
import 'package:market_space/features/conversations/presentation/widgets/inbox/inbox_folder_tabs.dart';
import 'package:market_space/features/conversations/presentation/widgets/inbox/inbox_guest_gate.dart';
import 'package:market_space/features/conversations/presentation/widgets/inbox/inbox_new_chat_fab.dart';
import 'package:market_space/features/conversations/presentation/widgets/inbox/inbox_privacy_footer.dart';
import 'package:market_space/features/conversations/presentation/widgets/inbox/inbox_search_bar.dart';
import 'package:market_space/features/conversations/presentation/widgets/inbox/inbox_status_banner.dart';

/// Telegram-inspired Conversations Inbox Screen composed exclusively of
/// independent reusable widgets and synchronized with `chatSettingsProvider`.
class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  final _searchController = TextEditingController();
  bool _viewingArchived = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _executeSwipeAction(
    ConversationEntity conv,
    ChatSettingsEntity settings,
    bool isArabic,
  ) {
    if (settings.hapticFeedback) {
      HapticFeedback.selectionClick();
    }
    final notifier = ref.read(chatSettingsProvider.notifier);
    String message;

    switch (settings.swipeAction) {
      case ChatListSwipeAction.pin:
        final wasPinned = settings.isPinned(conv.id);
        notifier.togglePinConversation(conv.id);
        message = wasPinned
            ? (isArabic ? 'تم إلغاء تثبيت المحادثة' : 'Conversation unpinned')
            : (isArabic ? 'تم تثبيت المحادثة' : 'Conversation pinned');
      case ChatListSwipeAction.mute:
        final wasMuted = settings.isMuted(conv.id);
        notifier.toggleMuteConversation(conv.id);
        message = wasMuted
            ? (isArabic ? 'تم تفعيل الإشعارات' : 'Notifications unmuted')
            : (isArabic ? 'تم كتم الإشعارات' : 'Notifications muted');
      case ChatListSwipeAction.archive:
        final wasArchived = settings.isArchived(conv.id);
        notifier.toggleArchiveConversation(conv.id);
        message = wasArchived
            ? (isArabic ? 'تمت استعادة المحادثة من الأرشيف' : 'Unarchived')
            : (isArabic ? 'تم نقل المحادثة إلى الأرشيف' : 'Chat archived');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openConversationActions(
    ConversationEntity conv,
    ChatSettingsEntity settings,
    bool isArabic,
  ) {
    if (settings.hapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    final notifier = ref.read(chatSettingsProvider.notifier);
    final listingId = conv.listingId.isNotEmpty
        ? conv.listingId
        : (conv.listing?.id ?? '');

    InboxConversationActionsSheet.show(
      context,
      conversation: conv,
      isPinned: settings.isPinned(conv.id),
      isMuted: settings.isMuted(conv.id),
      isArchived: settings.isArchived(conv.id),
      colorTheme: settings.colorTheme,
      onTogglePin: () => notifier.togglePinConversation(conv.id),
      onToggleMute: () => notifier.toggleMuteConversation(conv.id),
      onToggleArchive: () => notifier.toggleArchiveConversation(conv.id),
      onViewListing: listingId.isNotEmpty
          ? () => context.push('/listings/$listingId')
          : null,
      onOpenSettings: () => context.push(RouteNames.chatSettings),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;
    final session = ref.watch(sessionProvider);

    if (!session.isAuthenticated) {
      return InboxGuestGate(onSignIn: () => context.push(RouteNames.login));
    }

    final conversationsAsync = ref.watch(conversationsListProvider);
    final filter = ref.watch(conversationsFilterProvider);
    final query = ref.watch(conversationsSearchQueryProvider).trim().toLowerCase();
    final settings = ref.watch(chatSettingsProvider);
    final accent = settings.colorTheme.accent(isDark);

    final allItems =
        conversationsAsync.valueOrNull ?? const <ConversationEntity>[];
    final activeItems =
        allItems.where((c) => !settings.isArchived(c.id)).toList();
    final archivedItems =
        allItems.where((c) => settings.isArchived(c.id)).toList();

    final totalUnreadCount = activeItems.where((c) => c.hasUnread).length;
    final totalPinnedCount =
        activeItems.where((c) => settings.isPinned(c.id)).length;

    final canPopRoute =
        GoRouter.maybeOf(context)?.canPop() ?? Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      floatingActionButton: _viewingArchived
          ? null
          : InboxNewChatFab(
              colorTheme: settings.colorTheme,
              onPressed: () => context.push(RouteNames.realEstate),
            ),
      body: SafeArea(
        child: Column(
          children: [
            InboxAppBar(
              unreadCount: totalUnreadCount,
              pinnedCount: totalPinnedCount,
              viewingArchived: _viewingArchived,
              showBackButton: canPopRoute,
              colorTheme: settings.colorTheme,
              onBack: () {
                if (_viewingArchived) {
                  setState(() => _viewingArchived = false);
                } else if (canPopRoute) {
                  Navigator.of(context).maybePop();
                }
              },
              onSettingsTap: () => context.push(RouteNames.chatSettings),
            ),
            Expanded(
              child: conversationsAsync.when(
                loading: () => const DealOneLoadingList(
                  itemCount: 4,
                  itemHeight: 120,
                ),
                error: (err, _) => DealOneErrorStateView(
                  error: err,
                  onRetry: () => ref.invalidate(conversationsListProvider),
                ),
                data: (_) {
                  final sourceList =
                      _viewingArchived ? archivedItems : activeItems;
                  final unreadCount =
                      sourceList.where((c) => c.hasUnread).length;
                  final pinnedCount =
                      sourceList.where((c) => settings.isPinned(c.id)).length;
                  final readCount = sourceList.length - unreadCount;

                  final filtered = sourceList.where((c) {
                    if (!_viewingArchived) {
                      if (filter == ConversationFilter.unread && !c.hasUnread) {
                        return false;
                      }
                      if (filter == ConversationFilter.pinned &&
                          !settings.isPinned(c.id)) {
                        return false;
                      }
                      if (filter == ConversationFilter.read && c.hasUnread) {
                        return false;
                      }
                    }
                    if (query.isNotEmpty) {
                      final haystack =
                          '${c.counterpartName} ${c.listing?.title ?? ''} ${c.lastMessageText ?? ''}'
                              .toLowerCase();
                      if (!haystack.contains(query)) return false;
                    }
                    return true;
                  }).toList();

                  // Telegram sorting: pinned chats first, then latest activity
                  filtered.sort((a, b) {
                    final aPinned = settings.isPinned(a.id);
                    final bPinned = settings.isPinned(b.id);
                    if (aPinned != bPinned) return aPinned ? -1 : 1;
                    final aTime =
                        a.lastMessageAt ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final bTime =
                        b.lastMessageAt ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return bTime.compareTo(aTime);
                  });

                  return RefreshIndicator(
                    color: accent,
                    onRefresh: () async {
                      ref.invalidate(conversationsListProvider);
                      await ref.read(conversationsListProvider.future);
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            hPad,
                            AppSpacing.md,
                            hPad,
                            AppSpacing.sm,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                InboxSearchBar(
                                  controller: _searchController,
                                  colorTheme: settings.colorTheme,
                                  onChanged: (val) => ref
                                      .read(
                                        conversationsSearchQueryProvider
                                            .notifier,
                                      )
                                      .state = val,
                                  onClear: () {
                                    _searchController.clear();
                                    ref
                                        .read(
                                          conversationsSearchQueryProvider
                                              .notifier,
                                        )
                                        .state = '';
                                  },
                                ),
                                if (!_viewingArchived) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  InboxFolderTabs(
                                    activeFilter: filter,
                                    onFilterChanged: (f) => ref
                                        .read(
                                          conversationsFilterProvider.notifier,
                                        )
                                        .state = f,
                                    totalCount: activeItems.length,
                                    unreadCount: unreadCount,
                                    pinnedCount: pinnedCount,
                                    readCount: readCount,
                                    colorTheme: settings.colorTheme,
                                  ),
                                  if (settings.showAdvisorBanner) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    InboxStatusBanner(
                                      colorTheme: settings.colorTheme,
                                      onDismiss: () => ref
                                          .read(chatSettingsProvider.notifier)
                                          .setShowAdvisorBanner(false),
                                    ),
                                  ],
                                  if (archivedItems.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    InboxArchivedFolderTile(
                                      archivedCount: archivedItems.length,
                                      previewNames: archivedItems
                                          .map((e) => e.counterpartName)
                                          .take(3)
                                          .join('، '),
                                      colorTheme: settings.colorTheme,
                                      onTap: () => setState(
                                        () => _viewingArchived = true,
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: DealOneEmptyStateView(
                              icon: _viewingArchived
                                  ? Icons.archive_outlined
                                  : Icons.chat_bubble_outline_rounded,
                              title: _viewingArchived
                                  ? (isArabic
                                        ? 'لا توجد محادثات مؤرشفة'
                                        : 'No archived chats')
                                  : (isArabic
                                        ? 'لا توجد محادثات مطابقة'
                                        : 'No matching conversations'),
                              description: _viewingArchived
                                  ? (isArabic
                                        ? 'المحادثات التي تقوم بأرشفتها ستظهر هنا.'
                                        : 'Chats you archive will appear here.')
                                  : (isArabic
                                        ? 'تصفح العقارات واضغط "تحدث مع المعلن" لبدء محادثة جديدة.'
                                        : 'Browse properties and tap "Chat with Seller" to start a conversation.'),
                              actionLabel: _viewingArchived
                                  ? (isArabic
                                        ? 'العودة للمحادثات'
                                        : 'Back to Inbox')
                                  : (isArabic
                                        ? 'تصفح العقارات'
                                        : 'Browse Properties'),
                              actionIcon: _viewingArchived
                                  ? Icons.arrow_back_rounded
                                  : Icons.home_work_outlined,
                              onAction: _viewingArchived
                                  ? () => setState(() => _viewingArchived = false)
                                  : () => context.push(RouteNames.realEstate),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              hPad,
                              AppSpacing.xs,
                              hPad,
                              0,
                            ),
                            sliver: SliverList.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => SizedBox(
                                height: settings.chatListTwoLines
                                    ? AppSpacing.sm
                                    : AppSpacing.md,
                              ),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return InboxConversationTile(
                                  conversation: item,
                                  settings: settings,
                                  onTap: () => context.push(
                                    '/conversations/${item.id}',
                                    extra: item,
                                  ),
                                  onLongPress: () => _openConversationActions(
                                    item,
                                    settings,
                                    isArabic,
                                  ),
                                  onSwipeAction: () => _executeSwipeAction(
                                    item,
                                    settings,
                                    isArabic,
                                  ),
                                );
                              },
                            ),
                          ),
                        const SliverToBoxAdapter(child: InboxPrivacyFooter()),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
