import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_center/presentation/widgets/seller_ads_tab.dart';
import 'package:market_space/features/seller_center/presentation/widgets/seller_analytics_tab.dart';
import 'package:market_space/features/seller_center/presentation/widgets/seller_chat_tab.dart';
import 'package:market_space/features/seller_center/presentation/widgets/seller_crm_tab.dart';
import 'package:market_space/features/seller_center/presentation/widgets/seller_dashboard_tab.dart';
import 'package:market_space/features/seller_center/presentation/widgets/seller_interactions_tab.dart';
import 'package:market_space/features/seller_center/presentation/widgets/seller_posts_tab.dart';
import 'package:market_space/features/seller_verification/application/providers/seller_verification_providers.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/shared/widgets/app_loading_indicator.dart';

/// Unified Deal One Seller Center.
/// Strictly enforces backend-verified `canAccessSellerDashboard` and `APPROVED` status
/// before exposing any seller management tab.
class SellerCenterPage extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const SellerCenterPage({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<SellerCenterPage> createState() => _SellerCenterPageState();
}

class _SellerCenterPageState extends ConsumerState<SellerCenterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 7,
      initialIndex: widget.initialTabIndex.clamp(0, 6),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final verificationAsync = ref.watch(sellerVerificationBadgeProvider);

    return verificationAsync.when(
      loading: () => Scaffold(
        backgroundColor: DealOneTokens.pageBgOf(context),
        appBar: AppBar(
          title: Text(isArabic ? 'مركز البائع' : 'Seller Center'),
        ),
        body: const Center(child: DealOneDotLoader(dotSize: 9)),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: DealOneTokens.pageBgOf(context),
        appBar: AppBar(
          title: Text(isArabic ? 'مركز البائع' : 'Seller Center'),
        ),
        body: DealOneErrorStateView(
          error: err,
          onRetry: () => ref.invalidate(sellerVerificationBadgeProvider),
        ),
      ),
      data: (snapshot) {
        final hasAccess = snapshot != null &&
            snapshot.sellerStatus == VerificationStatus.approved &&
            snapshot.capabilities.canAccessSellerDashboard;

        if (!hasAccess) {
          return _SellerAccessGateView(
            status: snapshot?.sellerStatus ?? VerificationStatus.notSubmitted,
            suspensionReason: snapshot?.sellerSuspensionReason,
            onRefresh: () => ref.invalidate(sellerVerificationBadgeProvider),
          );
        }

        return Scaffold(
          backgroundColor: DealOneTokens.pageBgOf(context),
          appBar: AppBar(
            backgroundColor: DealOneTokens.cardSurfaceOf(context),
            elevation: 0,
            title: Text(
              isArabic ? 'مركز البائع' : 'Seller Center',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            ),
            actions: [
              IconButton(
                tooltip: isArabic ? 'تحديث الصلاحيات' : 'Refresh Permissions',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () =>
                    ref.invalidate(sellerVerificationBadgeProvider),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: DealOneTokens.navy,
              indicatorColor: DealOneTokens.navy,
              tabs: [
                Tab(text: isArabic ? 'لوحة التحكم' : 'Dashboard'),
                Tab(text: isArabic ? 'إعلاناتي' : 'My Ads'),
                Tab(text: isArabic ? 'المنشورات' : 'Posts'),
                Tab(text: isArabic ? 'التفاعلات' : 'Interactions'),
                Tab(text: isArabic ? 'المحادثات' : 'Inbox'),
                Tab(text: isArabic ? 'سجل المبيعات' : 'Sales CRM'),
                Tab(text: isArabic ? 'التحليلات' : 'Analytics'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              SellerDashboardTab(
                onJumpToTab: (idx) => _tabController.animateTo(idx),
              ),
              const SellerAdsTab(),
              SellerPostsTab(
                onOpenAdvertisements: () => _tabController.animateTo(1),
              ),
              const SellerInteractionsTab(),
              const SellerChatTab(),
              const SellerCrmTab(),
              const SellerAnalyticsTab(),
            ],
          ),
        );
      },
    );
  }
}

class _SellerAccessGateView extends StatelessWidget {
  final VerificationStatus status;
  final String? suspensionReason;
  final VoidCallback onRefresh;

  const _SellerAccessGateView({
    required this.status,
    this.suspensionReason,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    final (IconData icon, String title, String desc, String cta, String route) =
        switch (status) {
      VerificationStatus.pending || VerificationStatus.underReview => (
          Icons.hourglass_top_rounded,
          isArabic ? 'طلب التوثيق قيد المراجعة' : 'Verification Under Review',
          isArabic
              ? 'أدوات مركز البائع مغلقة حتى يتم اعتماد طلب التوثيق من الإدارة.'
              : 'Seller Center tools remain locked until your verification is approved.',
          isArabic ? 'متابعة حالة الطلب' : 'Track Application',
          RouteNames.sellerVerificationTracking,
        ),
      VerificationStatus.suspended => (
          Icons.block_rounded,
          isArabic ? 'تم إيقاف صلاحيات البائع' : 'Seller Privileges Suspended',
          suspensionReason?.isNotEmpty == true
              ? suspensionReason!
              : (isArabic
                  ? 'تم تعليق صلاحيات البيع مؤقتاً. يمكنك الاستمرار في التصفح كمشتري.'
                  : 'Your seller privileges are suspended. Buyer features remain active.'),
          isArabic ? 'عرض التفاصيل' : 'View Details',
          RouteNames.sellerVerificationTracking,
        ),
      VerificationStatus.rejected || VerificationStatus.needsChanges => (
          Icons.edit_document,
          isArabic ? 'مطلوب تعديل طلب التوثيق' : 'Action Required on Application',
          isArabic
              ? 'يرجى مراجعة ملاحظات الإدارة وإعادة إرسال المستندات المطلوبة.'
              : 'Please review the admin feedback and resubmit your application.',
          isArabic ? 'مراجعة الطلب' : 'Review Application',
          RouteNames.sellerVerificationTracking,
        ),
      VerificationStatus.expired => (
          Icons.event_busy_rounded,
          isArabic ? 'انتهت صلاحية التوثيق' : 'Verification Expired',
          isArabic
              ? 'يرجى تجديد توثيق حسابك لاستعادة صلاحيات مركز البائع.'
              : 'Please renew your verification to restore Seller Center access.',
          isArabic ? 'تجديد التوثيق' : 'Renew Verification',
          RouteNames.sellerVerificationTracking,
        ),
      _ => (
          Icons.verified_user_outlined,
          isArabic ? 'مركز البائع للحسابات الموثقة فقط' : 'Verified Sellers Only',
          isArabic
              ? 'قدّم طلب توثيق كبائع لتفعيل إدارة الإعلانات والمحادثات وسجل المبيعات.'
              : 'Complete seller verification to unlock advertisements, inbox, CRM, and analytics.',
          isArabic ? 'توثيق حساب البائع' : 'Become a Verified Seller',
          RouteNames.sellerVerification,
        ),
    };

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      appBar: AppBar(
        title: Text(isArabic ? 'مركز البائع' : 'Seller Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: onRefresh,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: DealOneEmptyStateView(
          icon: icon,
          title: title,
          description: desc,
          actionLabel: cta,
          actionIcon: Icons.arrow_forward_rounded,
          onAction: () => context.push(route),
        ),
      ),
    );
  }
}
