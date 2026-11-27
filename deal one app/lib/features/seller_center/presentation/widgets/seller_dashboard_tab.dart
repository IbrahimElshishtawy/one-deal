import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_center/application/providers/seller_center_providers.dart';
import 'package:market_space/shared/widgets/app_loading_indicator.dart';

class SellerDashboardTab extends ConsumerWidget {
  final ValueChanged<int> onJumpToTab;

  const SellerDashboardTab({super.key, required this.onJumpToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final dashboardAsync = ref.watch(sellerDashboardProvider);

    return RefreshIndicator(
      color: DealOneTokens.navy,
      onRefresh: () async {
        ref.invalidate(sellerDashboardProvider);
      },
      child: dashboardAsync.when(
        loading: () => const Center(child: DealOneDotLoader(dotSize: 9)),
        error: (err, _) => DealOneErrorStateView(
          error: err,
          onRetry: () => ref.invalidate(sellerDashboardProvider),
        ),
        data: (data) {
          final s = data.summary;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DealOneTokens.navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.md,
                        ),
                      ),
                      onPressed: () => context.push(RouteNames.createListing),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(isArabic ? 'إعلان جديد' : 'New Ad'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DealOneTokens.textPrimaryOf(context),
                        side: BorderSide(
                          color: DealOneTokens.cardBorderOf(context),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.md,
                        ),
                      ),
                      onPressed: () => onJumpToTab(5),
                      icon: const Icon(Icons.handshake_outlined, size: 18),
                      label: Text(isArabic ? 'سجل المبيعات' : 'Sales CRM'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // KPI Summary Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.65,
                children: [
                  _KpiCard(
                    title: isArabic ? 'الإعلانات النشطة' : 'Active Ads',
                    value: '${s.activeAds} / ${s.totalAds}',
                    icon: Icons.campaign_outlined,
                    onTap: () => onJumpToTab(1),
                  ),
                  _KpiCard(
                    title: isArabic ? 'إجمالي المشاهدات' : 'Total Views',
                    value: '${s.totalViews}',
                    icon: Icons.visibility_outlined,
                    onTap: () => onJumpToTab(6),
                  ),
                  _KpiCard(
                    title: isArabic ? 'استفسارات معلقة' : 'Pending Inquiries',
                    value: '${s.pendingInquiries}',
                    icon: Icons.mark_chat_unread_outlined,
                    highlight: s.pendingInquiries > 0,
                    onTap: () => onJumpToTab(4),
                  ),
                  _KpiCard(
                    title: isArabic ? 'صفقات مكتملة (CRM)' : 'Completed Deals',
                    value: '${s.completedDealsCount}',
                    icon: Icons.verified_outlined,
                    onTap: () => onJumpToTab(5),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Top Listings Performance
              _SectionHeader(
                title: isArabic ? 'أداء الإعلانات' : 'Top Advertisements',
                actionLabel: isArabic ? 'عرض الكل' : 'View All',
                onAction: () => onJumpToTab(1),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (data.topListings.isEmpty)
                _EmptyCard(
                  text: isArabic
                      ? 'لم تقم بإضافة إعلانات بعد.'
                      : 'No advertisements created yet.',
                )
              else
                ...data.topListings.map(
                  (ad) => Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: DealOneTokens.cardDecoration(context),
                    child: InkWell(
                      onTap: () => context.push('/listings/${ad.id}'),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ad.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: DealOneTokens.textPrimaryOf(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${ad.viewsCount} ${isArabic ? 'مشاهدة' : 'views'} • ${ad.favoritesCount} ${isArabic ? 'مفضلة' : 'favs'} • ${ad.inquiriesCount} ${isArabic ? 'استفسار' : 'inquiries'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        DealOneTokens.textSecondaryOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),

              // Recent Conversations
              _SectionHeader(
                title: isArabic ? 'أحدث المحادثات' : 'Recent Conversations',
                actionLabel: isArabic ? 'صندوق الوارد' : 'Inbox',
                onAction: () => onJumpToTab(4),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (data.recentConversations.isEmpty)
                _EmptyCard(
                  text: isArabic
                      ? 'لا توجد محادثات عملاء حتى الآن.'
                      : 'No customer conversations yet.',
                )
              else
                ...data.recentConversations.map(
                  (conv) => Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: DealOneTokens.cardDecoration(context),
                    child: InkWell(
                      onTap: () => context.push('/conversations/${conv.id}'),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: DealOneTokens.navy,
                            child: Text(
                              conv.customerName.isNotEmpty
                                  ? conv.customerName[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conv.customerName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: DealOneTokens.textPrimaryOf(context),
                                  ),
                                ),
                                Text(
                                  conv.lastMessageText.isNotEmpty
                                      ? conv.lastMessageText
                                      : conv.listingTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color:
                                        DealOneTokens.textSecondaryOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (conv.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD97706),
                                borderRadius: AppRadii.full,
                              ),
                              child: Text(
                                '${conv.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
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
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool highlight;
  final VoidCallback onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    this.highlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Material(
      color: DealOneTokens.cardSurfaceOf(context),
      borderRadius: AppRadii.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lg,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.lg,
            border: Border.all(
              color: highlight
                  ? const Color(0xFFD97706)
                  : DealOneTokens.cardBorderOf(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: DealOneTokens.textSecondaryOf(context),
                      ),
                    ),
                  ),
                  Icon(
                    icon,
                    size: 18,
                    color: highlight
                        ? const Color(0xFFD97706)
                        : (isDark ? Colors.white70 : DealOneTokens.navy),
                  ),
                ],
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: DealOneTokens.textPrimaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: DealOneTokens.cardDecoration(context),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: DealOneTokens.textSecondaryOf(context)),
      ),
    );
  }
}
