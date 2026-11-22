import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';
import 'package:market_space/features/conversations/presentation/widgets/conversation_card.dart';
import 'package:market_space/features/conversations/presentation/widgets/conversation_filter_header.dart';

/// Conversations List Screen matching `Conversations.png`.
/// Backed by `GET /conversations`.
class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;
    final session = ref.watch(sessionProvider);

    if (!session.isAuthenticated) {
      return Scaffold(
        backgroundColor: DealOneTokens.pageBgOf(context),
        body: SafeArea(
          child: Column(
            children: [
              DealOneSubPageHeader(
                title: isArabic ? 'المحادثات' : 'Conversations',
              ),
              Expanded(
                child: DealOneEmptyStateView(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: isArabic
                      ? 'سجّل الدخول لعرض محادثاتك'
                      : 'Sign in to view your chats',
                  description: isArabic
                      ? 'تواصل مباشرة مع المعلنين ومستشاري العقارات بعد تسجيل الدخول.'
                      : 'Sign in to chat directly with property owners and Deal One advisors.',
                  actionLabel: isArabic ? 'تسجيل الدخول' : 'Sign In',
                  actionIcon: Icons.login_rounded,
                  onAction: () => context.push(RouteNames.login),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final conversationsAsync = ref.watch(conversationsListProvider);
    final filter = ref.watch(conversationsFilterProvider);
    final query = ref.watch(conversationsSearchQueryProvider).trim().toLowerCase();

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      body: SafeArea(
        child: Column(
          children: [
            DealOneSubPageHeader(
              title: isArabic ? 'المحادثات' : 'Conversations',
              trailing: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DealOneTokens.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.full,
                  ),
                ),
                onPressed: () => context.push(RouteNames.realEstate),
                icon: const Icon(Icons.edit_square, size: 16),
                label: Text(
                  isArabic ? 'محادثة جديدة' : 'New Chat',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: conversationsAsync.when(
                loading: () => const DealOneLoadingList(
                  itemCount: 4,
                  itemHeight: 132,
                ),
                error: (err, _) => DealOneErrorStateView(
                  error: err,
                  onRetry: () => ref.invalidate(conversationsListProvider),
                ),
                data: (allConversations) {
                  final unreadTotal =
                      allConversations.where((c) => c.hasUnread).length;
                  final readTotal = allConversations.length - unreadTotal;

                  final filtered = allConversations.where((c) {
                    if (filter == ConversationFilter.unread && !c.hasUnread) {
                      return false;
                    }
                    if (filter == ConversationFilter.read && c.hasUnread) {
                      return false;
                    }
                    if (query.isNotEmpty) {
                      final haystack =
                          '${c.counterpartName} ${c.listing?.title ?? ''} ${c.lastMessageText ?? ''}'
                              .toLowerCase();
                      if (!haystack.contains(query)) return false;
                    }
                    return true;
                  }).toList();

                  return RefreshIndicator(
                    color: DealOneTokens.navy,
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
                            AppSpacing.sm,
                            hPad,
                            AppSpacing.md,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: ConversationFilterHeader(
                              searchController: _searchController,
                              onSearchChanged: (val) => ref
                                  .read(
                                    conversationsSearchQueryProvider.notifier,
                                  )
                                  .state = val,
                              activeFilter: filter,
                              onFilterChanged: (f) => ref
                                  .read(conversationsFilterProvider.notifier)
                                  .state = f,
                              totalCount: allConversations.length,
                              unreadCount: unreadTotal,
                              readCount: readTotal,
                            ),
                          ),
                        ),
                        if (filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: DealOneEmptyStateView(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: isArabic
                                  ? 'لا توجد محادثات بعد'
                                  : 'No conversations yet',
                              description: isArabic
                                  ? 'تصفح العقارات واضغط "تحدث مع المعلن" لبدء محادثة مباشرة.'
                                  : 'Browse properties and tap "Chat with Seller" to start a conversation.',
                              actionLabel: isArabic
                                  ? 'تصفح العقارات'
                                  : 'Browse Properties',
                              actionIcon: Icons.home_work_outlined,
                              onAction: () =>
                                  context.push(RouteNames.realEstate),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            sliver: SliverList.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return ConversationCard(
                                  conversation: item,
                                  onTap: () => context.push(
                                    '/conversations/${item.id}',
                                    extra: item,
                                  ),
                                );
                              },
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: DealOnePrivacyFooter(
                            showCircleLock: true,
                            title: isArabic
                                ? 'محادثاتك مشفرة ومحمية بالكامل'
                                : 'Your chats are encrypted and protected',
                            subtitle: isArabic
                                ? 'جميع المعاملات العقارية تتم تحت إشراف مستشارين معتمدين'
                                : 'All real estate conversations are protected by Deal One safety standards',
                          ),
                        ),
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
