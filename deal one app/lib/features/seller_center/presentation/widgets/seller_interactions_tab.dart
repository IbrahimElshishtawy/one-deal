import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_center/application/providers/seller_center_providers.dart';
import 'package:market_space/shared/widgets/app_loading_indicator.dart';

class SellerInteractionsTab extends ConsumerWidget {
  const SellerInteractionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final selectedType = ref.watch(sellerInteractionsTypeFilterProvider);
    final interactionsAsync = ref.watch(sellerInteractionsProvider);

    final types = [
      ('all', isArabic ? 'الكل' : 'All'),
      ('inquiry', isArabic ? 'الاستفسارات' : 'Inquiries'),
      ('booking', isArabic ? 'طلبات المعاينة' : 'Bookings'),
      ('favorite', isArabic ? 'المفضلة' : 'Favorites'),
    ];

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 6,
            ),
            itemCount: types.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, idx) {
              final (val, label) = types[idx];
              return ChoiceChip(
                label: Text(label),
                selected: selectedType == val,
                onSelected: (_) => ref
                    .read(sellerInteractionsTypeFilterProvider.notifier)
                    .state = val,
              );
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: DealOneTokens.navy,
            onRefresh: () async => ref.invalidate(sellerInteractionsProvider),
            child: interactionsAsync.when(
              loading: () => const Center(child: DealOneDotLoader(dotSize: 9)),
              error: (err, _) => DealOneErrorStateView(
                error: err,
                onRetry: () => ref.invalidate(sellerInteractionsProvider),
              ),
              data: (data) => ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // Summary Metrics Row
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: DealOneTokens.cardDecoration(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MiniMetric(
                          label: isArabic ? 'المشاهدات' : 'Views',
                          value: '${data.views}',
                        ),
                        _MiniMetric(
                          label: isArabic ? 'المفضلة' : 'Favs',
                          value: '${data.favorites}',
                        ),
                        _MiniMetric(
                          label: isArabic ? 'الاستفسارات' : 'Inquiries',
                          value: '${data.inquiries}',
                        ),
                        _MiniMetric(
                          label: isArabic ? 'طلبات تواصل' : 'Contacts',
                          value: '${data.contactRequests}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (data.items.isEmpty)
                    DealOneEmptyStateView(
                      icon: Icons.insights_outlined,
                      title: isArabic
                          ? 'لا توجد تفاعلات مسجلة بعد'
                          : 'No Interactions Yet',
                      description: isArabic
                          ? 'ستظهر هنا استفسارات العملاء وطلبات المعاينة والمفضلة.'
                          : 'Customer inquiries, booking requests, and saves will appear here.',
                    )
                  else
                    ...data.items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: DealOneTokens.cardDecoration(context),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: DealOneTokens.navy.withValues(alpha: 0.1),
                                borderRadius: AppRadii.md,
                              ),
                              child: Icon(
                                item.type == 'favorite'
                                    ? Icons.favorite_rounded
                                    : item.type == 'booking'
                                        ? Icons.event_available_outlined
                                        : Icons.chat_bubble_outline_rounded,
                                size: 18,
                                color: DealOneTokens.navy,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.actorName} • ${item.listingTitle}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color:
                                          DealOneTokens.textPrimaryOf(context),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.summary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: DealOneTokens.textSecondaryOf(
                                        context,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: DealOneTokens.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }
}
