import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_center/application/providers/seller_center_providers.dart';
import 'package:market_space/shared/widgets/app_loading_indicator.dart';

class SellerChatTab extends ConsumerWidget {
  const SellerChatTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final unreadOnly = ref.watch(sellerInboxUnreadOnlyProvider);
    final inboxAsync = ref.watch(sellerInboxConversationsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: isArabic
                        ? 'ابحث بالعميل أو الإعلان...'
                        : 'Search by customer or ad...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: AppRadii.md),
                  ),
                  onChanged: (v) =>
                      ref.read(sellerInboxSearchProvider.notifier).state = v,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilterChip(
                label: Text(isArabic ? 'غير مقروءة' : 'Unread'),
                selected: unreadOnly,
                onSelected: (v) =>
                    ref.read(sellerInboxUnreadOnlyProvider.notifier).state = v,
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: DealOneTokens.navy,
            onRefresh: () async =>
                ref.invalidate(sellerInboxConversationsProvider),
            child: inboxAsync.when(
              loading: () => const Center(child: DealOneDotLoader(dotSize: 9)),
              error: (err, _) => DealOneErrorStateView(
                error: err,
                onRetry: () => ref.invalidate(sellerInboxConversationsProvider),
              ),
              data: (conversations) {
                if (conversations.isEmpty) {
                  return DealOneEmptyStateView(
                    icon: Icons.forum_outlined,
                    title: isArabic ? 'لا توجد محادثات' : 'No Conversations',
                    description: isArabic
                        ? 'عندما يتواصل معك العملاء بخصوص إعلاناتك ستظهر محادثاتهم هنا.'
                        : 'Customer messages regarding your ads will appear here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    return Container(
                      decoration: DealOneTokens.cardDecoration(context),
                      child: ListTile(
                        onTap: () => context.push('/conversations/${conv.id}'),
                        leading: CircleAvatar(
                          backgroundColor: DealOneTokens.navy,
                          child: Text(
                            conv.customerName.isNotEmpty
                                ? conv.customerName[0].toUpperCase()
                                : 'C',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          conv.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conv.listingTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              conv.lastMessageText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: conv.unreadCount > 0
                            ? CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color(0xFFD97706),
                                child: Text(
                                  '${conv.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )
                            : const Icon(Icons.chevron_right_rounded),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
