import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_center/application/providers/seller_center_providers.dart';
import 'package:market_space/features/seller_center/domain/entities/seller_center_entities.dart';
import 'package:market_space/shared/widgets/app_loading_indicator.dart';

class SellerAnalyticsTab extends ConsumerWidget {
  const SellerAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final selectedRange = ref.watch(sellerAnalyticsRangeProvider);
    final analyticsAsync = ref.watch(sellerAnalyticsProvider);

    final ranges = [
      ('7d', isArabic ? '7 أيام' : '7 Days'),
      ('30d', isArabic ? '30 يوماً' : '30 Days'),
      ('90d', isArabic ? '90 يوماً' : '90 Days'),
      ('all', isArabic ? 'الكل' : 'All Time'),
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
            itemCount: ranges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, idx) {
              final (val, label) = ranges[idx];
              return ChoiceChip(
                label: Text(label),
                selected: selectedRange == val,
                onSelected: (_) =>
                    ref.read(sellerAnalyticsRangeProvider.notifier).state = val,
              );
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: DealOneTokens.navy,
            onRefresh: () async => ref.invalidate(sellerAnalyticsProvider),
            child: analyticsAsync.when(
              loading: () => const Center(child: DealOneDotLoader(dotSize: 9)),
              error: (err, _) => DealOneErrorStateView(
                error: err,
                onRetry: () => ref.invalidate(sellerAnalyticsProvider),
              ),
              data: (data) => ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.75,
                    children: [
                      _MetricTile(
                        label: isArabic ? 'إجمالي الإعلانات' : 'Total Ads',
                        value: '${data.totalAds} (${data.activeAds})',
                      ),
                      _MetricTile(
                        label: isArabic ? 'المشاهدات' : 'Views',
                        value: '${data.totalViews}',
                      ),
                      _MetricTile(
                        label: isArabic ? 'المفضلة' : 'Favorites',
                        value: '${data.totalFavorites}',
                      ),
                      _MetricTile(
                        label: isArabic ? 'الاستفسارات' : 'Inquiries',
                        value: '${data.customerInquiries}',
                      ),
                      _MetricTile(
                        label: isArabic ? 'صفقات مكتملة (CRM)' : 'Completed Deals',
                        value: '${data.completedSellerReportedDeals}',
                      ),
                      _MetricTile(
                        label: isArabic ? 'معدل الاستجابة' : 'Response Rate',
                        value: '${data.responseRatePercent}%',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Activity Bar Chart (strictly real backend series)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: DealOneTokens.cardDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic
                              ? 'نشاط الاستفسارات والصفقات اليومي'
                              : 'Daily Inquiries & Deals Activity',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: DealOneTokens.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (data.dailySeries.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                isArabic
                                    ? 'لا توجد بيانات نشاط في هذه الفترة.'
                                    : 'No activity recorded in this period.',
                                style: TextStyle(
                                  color: DealOneTokens.textSecondaryOf(context),
                                ),
                              ),
                            ),
                          )
                        else
                          _RealActivityBarChart(points: data.dailySeries),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    isArabic ? 'الأعلى أداءً' : 'Top Performing Advertisements',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: DealOneTokens.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (data.topPerformingAds.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: DealOneTokens.cardDecoration(context),
                      child: Text(
                        isArabic ? 'لا توجد إعلانات بعد.' : 'No ads yet.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...data.topPerformingAds.map(
                      (ad) => Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: DealOneTokens.cardDecoration(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                ad.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${ad.viewsCount} ${isArabic ? 'مشاهدة' : 'views'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD97706),
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

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: DealOneTokens.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: DealOneTokens.textSecondaryOf(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: DealOneTokens.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _RealActivityBarChart extends StatelessWidget {
  final List<SellerDailyPoint> points;

  const _RealActivityBarChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final visible =
        points.length > 10 ? points.sublist(points.length - 10) : points;
    final maxVal = visible.fold<int>(
      1,
      (m, p) => (p.inquiries + p.deals) > m ? (p.inquiries + p.deals) : m,
    );

    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: visible.map((p) {
          final total = p.inquiries + p.deals;
          final ratio = (total / maxVal).clamp(0.08, 1.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: ratio,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: DealOneTokens.navy,
                          borderRadius: AppRadii.sm,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.date.length >= 10 ? p.date.substring(5) : p.date,
                    style: const TextStyle(fontSize: 9.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
