import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/deal_one_header.dart';
import '../../../../core/design_system/deal_one_promo_banner.dart';
import '../../../../core/design_system/deal_one_search_bar.dart';
import '../../../../core/design_system/deal_one_section_chrome.dart';
import '../../../../core/design_system/server_driven_filter_sheet.dart';
import '../../../../core/marketplace/section_home_controller.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../listings/presentation/widgets/floating_bottom_nav.dart';
import '../../../search/data/dto/search_dto.dart';
import '../../../search/presentation/providers/search_providers.dart';
import '../widgets/appliance_product_card.dart';

/// Home 3 — Electrical Appliances & Decor.
/// Independent section home matching `Home 3 - Electrical appliances and decor.png`.
class AppliancesDecorHomePage extends ConsumerStatefulWidget {
  static const String sectionSlug = 'home-appliances';

  const AppliancesDecorHomePage({super.key});

  @override
  ConsumerState<AppliancesDecorHomePage> createState() =>
      _AppliancesDecorHomePageState();
}

class _AppliancesDecorHomePageState
    extends ConsumerState<AppliancesDecorHomePage> {
  final ScrollController _scrollController = ScrollController();
  int _activeSegment = 0; // 0 = Electrical Appliances, 1 = Decor & Furniture

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 340) {
      ref
          .read(sectionHomeControllerProvider(
            AppliancesDecorHomePage.sectionSlug,
          ).notifier)
          .loadMore();
    }
  }

  Future<void> _openFilterSheet(SectionHomeState state) async {
    final feed = state.feed;
    if (feed == null) return;
    final updated = await showServerDrivenFilterSheet(
      context: context,
      filterConfig: feed.filterConfig,
      currentFilters: state.filters,
    );
    if (updated != null && mounted) {
      await ref
          .read(sectionHomeControllerProvider(
            AppliancesDecorHomePage.sectionSlug,
          ).notifier)
          .applyFilters(updated);
    }
  }

  void _openSearch() {
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(searchActiveQueryDtoProvider.notifier).state =
        const SearchQueryDto(
          categorySlug: AppliancesDecorHomePage.sectionSlug,
        );
    context.push(RouteNames.search);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = context.horizontalScreenPadding;
    final state = ref.watch(
      sectionHomeControllerProvider(AppliancesDecorHomePage.sectionSlug),
    );
    final controller = ref.read(
      sectionHomeControllerProvider(AppliancesDecorHomePage.sectionSlug)
          .notifier,
    );
    final isOffline = ref.watch(isOfflineProvider).valueOrNull ?? false;
    final feed = state.feed;

    final allSubs = feed?.section.subcategories ?? const [];
    final segmentSubs = _activeSegment == 0
        ? allSubs
            .where(
              (c) =>
                  !c.slug.contains('decor') && !c.slug.contains('furniture'),
            )
            .toList()
        : allSubs
            .where(
              (c) => c.slug.contains('decor') || c.slug.contains('furniture'),
            )
            .toList();
    final visibleSubs = segmentSubs.isNotEmpty ? segmentSubs : allSubs;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : DealOneDesignColors.canvasLight,
      extendBody: true,
      bottomNavigationBar: const DealOneFloatingBottomNav(activeIndex: 0),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: DealOneDesignColors.navy,
          onRefresh: () => controller.loadInitial(forceRefresh: true),
          child: CustomScrollView(
            key: const PageStorageKey<String>('appliances_decor_home_scroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: DealOneHomeHeader(
                  showBackToHub: true,
                  sectionBadge: isArabic ? 'أجهزة وديكور' : 'Appliances',
                ),
              ),
              if (isOffline || state.isOfflineFallback)
                SliverToBoxAdapter(
                  child: DealOneOfflineBanner(
                    onRetry: () => controller.loadInitial(forceRefresh: true),
                  ),
                ),
              SliverToBoxAdapter(
                child: DealOneSearchBar(
                  hintText: isArabic
                      ? 'أبحث عن جهاز، ماركة، أو ديكور...'
                      : 'Search appliance, brand, or decor...',
                  activeFilterCount: state.filters.activeFilterCount,
                  onSearchTap: _openSearch,
                  onFilterTap: () => _openFilterSheet(state),
                ),
              ),
              if (state.isInitialLoading && feed == null)
                const SliverToBoxAdapter(
                  child: Column(
                    children: [
                      DealOneSectionSkeleton(height: 184),
                      DealOneSectionSkeleton(height: 160),
                      DealOneSectionSkeleton(height: 240),
                    ],
                  ),
                )
              else if (state.error != null && feed == null)
                SliverToBoxAdapter(
                  child: DealOneSectionErrorCard(
                    error: state.error!,
                    onRetry: () => controller.loadInitial(forceRefresh: true),
                  ),
                )
              else if (feed != null) ...[
                // 1. Deal of the Day Hero Banner
                SliverToBoxAdapter(
                  child: DealOnePromoBannerCarousel(
                    promotions: feed.promotions,
                    countdownText: isArabic
                        ? 'ينتهي خلال 02 س : 14 د'
                        : 'Ends in 02h : 14m',
                    onActionTap: (_) => _openSearch(),
                  ),
                ),

                // 2. Segmented Toggle (`الأجهزة الكهربائية` | `الديكور والأثاث`)
                SliverToBoxAdapter(
                  child: DealOneSegmentedToggle(
                    firstLabel: isArabic
                        ? 'الأجهزة الكهربائية'
                        : 'Electrical Appliances',
                    secondLabel:
                        isArabic ? 'الديكور والأثاث' : 'Decor & Furniture',
                    selectedIndex: _activeSegment,
                    onChanged: (idx) {
                      setState(() => _activeSegment = idx);
                      if (idx == 1) {
                        final decorSub = allSubs
                            .where(
                              (s) =>
                                  s.slug.contains('decor') ||
                                  s.slug.contains('furniture'),
                            )
                            .firstOrNull;
                        if (decorSub != null) {
                          controller.applyFilters(
                            state.filters.copyWith(
                              subcategorySlug: decorSub.slug,
                            ),
                          );
                        }
                      } else {
                        controller.applyFilters(
                          state.filters.copyWith(clearSubcategory: true),
                        );
                      }
                    },
                  ),
                ),

                // 3. Responsive Subcategories Grid from Backend
                if (visibleSubs.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    sliver: SliverGrid(
                      gridDelegate: context.responsiveCategoryGridDelegate(
                        baseMainAxisExtent: 48,
                        extraExtentPerTextScaleUnit: 28,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final sub = visibleSubs[index];
                        final selected =
                            state.filters.subcategorySlug == sub.slug;
                        return Material(
                          color: selected
                              ? DealOneDesignColors.navy
                              : (isDark ? AppColors.darkSurface : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => controller.applyFilters(
                              selected
                                  ? state.filters
                                      .copyWith(clearSubcategory: true)
                                  : state.filters.copyWith(
                                      subcategorySlug: sub.slug,
                                    ),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? DealOneDesignColors.navy
                                      : (isDark
                                            ? AppColors.darkBorder
                                            : Colors.black.withValues(
                                                alpha: 0.06,
                                              )),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.devices_other_rounded,
                                    size: 18,
                                    color: selected
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white70
                                              : DealOneDesignColors.navy),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isArabic ? sub.nameAr : sub.nameEn,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: selected
                                            ? Colors.white
                                            : (isDark
                                                  ? AppColors.darkTextPrimary
                                                  : DealOneDesignColors.navy),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }, childCount: visibleSubs.length),
                    ),
                  ),

                // 4. Installment Promo Card (matching PNG)
                SliverToBoxAdapter(
                  child: _InstallmentPromoCard(
                    isArabic: isArabic,
                    onTap: () => _openFilterSheet(state),
                  ),
                ),

                // 5. Most Requested Products Responsive Grid
                SliverToBoxAdapter(
                  child: DealOneSectionHeader(
                    title: isArabic
                        ? 'المنتجات الأكثر طلباً'
                        : 'Most Requested Products',
                    actionLabel: isArabic ? 'عرض الكل' : 'View All',
                    onActionTap: _openSearch,
                  ),
                ),
                if (state.isFiltering)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator.adaptive()),
                    ),
                  )
                else if (state.listingsError != null && state.listings.isEmpty)
                  SliverToBoxAdapter(
                    child: DealOneSectionErrorCard(
                      error: state.listingsError!,
                      onRetry: () => controller.applyFilters(state.filters),
                    ),
                  )
                else if (state.listings.isEmpty)
                  SliverToBoxAdapter(
                    child: DealOneSectionEmptyCard(
                      message: isArabic
                          ? 'لا توجد أجهزة أو منتجات ديكور مطابقة حالياً'
                          : 'No matching appliances or decor found',
                      actionLabel: state.filters.hasActiveFilters
                          ? (isArabic ? 'مسح الفلاتر' : 'Clear Filters')
                          : null,
                      onAction: state.filters.hasActiveFilters
                          ? () => controller.clearFilters()
                          : null,
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    sliver: SliverGrid(
                      gridDelegate: context.responsiveProductGridDelegate(
                        baseMainAxisExtent: 266,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            ApplianceProductCard(item: state.listings[index]),
                        childCount: state.listings.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: state.isLoadingMore
                            ? const CircularProgressIndicator.adaptive()
                            : state.hasMore
                                ? OutlinedButton.icon(
                                    onPressed: controller.loadMore,
                                    icon: const Icon(Icons.expand_more_rounded),
                                    label: Text(
                                      isArabic ? 'عرض المزيد' : 'Load More',
                                    ),
                                  )
                                : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstallmentPromoCard extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onTap;

  const _InstallmentPromoCard({required this.isArabic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = context.horizontalScreenPadding;
    return Container(
      margin: EdgeInsetsDirectional.fromSTEB(hPad, 14, hPad, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DealOneDesignColors.navy,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isArabic ? 'تقسيط بدون فوائد' : '0% Installments',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: DealOneDesignColors.amberPrice,
                  ),
                  Flexible(
                    child: Text(
                      isArabic ? 'موافقة خلال دقائق' : 'Instant approval',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isArabic
                ? 'قسط أجهزتك على 12 أو 24 شهر'
                : 'Pay over 12 or 24 months',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : DealOneDesignColors.navy,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isArabic
                ? 'أسهل إجراءات تقسيط مع شركاء التمويل المعتمدين'
                : 'Easy installment plans with certified partners',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMutedOf(context),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DealOneDesignColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  isArabic ? 'تصفية حسب السعر والتقسيط' : 'Filter by Price',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
