import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/core/design_system/deal_one_header.dart';
import 'package:market_space/core/design_system/deal_one_promo_banner.dart';
import 'package:market_space/core/design_system/deal_one_search_bar.dart';
import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/design_system/server_driven_filter_sheet.dart';
import 'package:market_space/core/marketplace/section_home_controller.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/listings/presentation/widgets/floating_bottom_nav.dart';
import 'package:market_space/features/search/data/dto/search_dto.dart';
import 'package:market_space/features/search/presentation/providers/search_providers.dart';
import 'package:market_space/features/cars_maintenance/presentation/widgets/car_showcase_card.dart';

/// Home 6 — Cars & Maintenance.
/// Independent section home matching `Home 6 - Cars and their maintenance.png`.
class CarsMaintenanceHomePage extends ConsumerStatefulWidget {
  static const String sectionSlug = 'cars';

  const CarsMaintenanceHomePage({super.key});

  @override
  ConsumerState<CarsMaintenanceHomePage> createState() =>
      _CarsMaintenanceHomePageState();
}

class _CarsMaintenanceHomePageState
    extends ConsumerState<CarsMaintenanceHomePage> {
  final ScrollController _scrollController = ScrollController();
  int _activeSegment = 0; // 0 = Cars & Spare Parts, 1 = Workshops & Maintenance

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
            CarsMaintenanceHomePage.sectionSlug,
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
            CarsMaintenanceHomePage.sectionSlug,
          ).notifier)
          .applyFilters(updated);
    }
  }

  void _openSearch({String? query}) {
    ref.read(searchQueryProvider.notifier).state = query ?? '';
    ref.read(searchActiveQueryDtoProvider.notifier).state = SearchQueryDto(
      query: query ?? '',
      categorySlug: CarsMaintenanceHomePage.sectionSlug,
    );
    context.push(RouteNames.search);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = context.horizontalScreenPadding;
    final state = ref.watch(
      sectionHomeControllerProvider(CarsMaintenanceHomePage.sectionSlug),
    );
    final controller = ref.read(
      sectionHomeControllerProvider(CarsMaintenanceHomePage.sectionSlug)
          .notifier,
    );
    final isOffline = ref.watch(isOfflineProvider).valueOrNull ?? false;
    final feed = state.feed;
    final subs = feed?.section.subcategories ?? const [];

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
            key: const PageStorageKey<String>('cars_maintenance_home_scroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: DealOneHomeHeader(
                  showBackToHub: true,
                  sectionBadge: isArabic ? 'سيارات وصيانة' : 'Cars',
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
                      ? 'أبحث عن سيارة للبيع، قطعة غيار، أو ورشة صيانة...'
                      : 'Search cars, spare parts, or workshops...',
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
                      DealOneSectionSkeleton(height: 220),
                      DealOneSectionSkeleton(height: 280),
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
                SliverToBoxAdapter(
                  child: DealOnePromoBannerCarousel(
                    promotions: feed.promotions,
                    onActionTap: (_) => _openSearch(),
                  ),
                ),

                // Live Previews (`معاينات حية`) matching PNG
                if (feed.livePreviews.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: DealOneSectionHeader(
                      title: isArabic ? 'معاينات حية' : 'Live Previews',
                      trailingIcon: Icons.videocam_outlined,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: DealOneLivePreviewsStrip(items: feed.livePreviews),
                  ),
                ],

                // Segmented Toggle (`السيارات وقطع الغيار` | `الورش والصيانة`)
                SliverToBoxAdapter(
                  child: DealOneSegmentedToggle(
                    firstLabel: isArabic
                        ? 'السيارات وقطع الغيار'
                        : 'Cars & Spare Parts',
                    secondLabel:
                        isArabic ? 'الورش والصيانة' : 'Workshops & Service',
                    selectedIndex: _activeSegment,
                    onChanged: (idx) {
                      setState(() => _activeSegment = idx);
                      if (idx == 1) {
                        final partsSub = subs
                            .where((s) => s.slug.contains('part'))
                            .firstOrNull;
                        if (partsSub != null) {
                          controller.applyFilters(
                            state.filters.copyWith(
                              subcategorySlug: partsSub.slug,
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

                // Responsive Subcategories Grid from Backend
                if (subs.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    sliver: SliverGrid(
                      gridDelegate: context.responsiveCategoryGridDelegate(
                        baseMainAxisExtent: 48,
                        extraExtentPerTextScaleUnit: 28,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final sub = subs[index];
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
                                    Icons.directions_car_filled_outlined,
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
                      }, childCount: subs.length),
                    ),
                  ),

                // 2-Column Emergency Roadside Cards matching PNG
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      hPad,
                      14,
                      hPad,
                      6,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _RoadsideActionCard(
                            icon: Icons.local_gas_station_rounded,
                            accentColor: const Color(0xFFEA580C),
                            title: isArabic
                                ? 'عطلان من البنزين؟'
                                : 'Out of Fuel?',
                            subtitle: isArabic
                                ? 'وقودك يوصلك لحد عندك فوراً'
                                : 'Emergency fuel delivery',
                            ctaLabel: isArabic ? 'اطلب وقود' : 'Order Fuel',
                            onTap: () => _openSearch(query: 'صيانة'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _RoadsideActionCard(
                            icon: Icons.car_repair_rounded,
                            accentColor: const Color(0xFF2563EB),
                            title: isArabic
                                ? 'عطلان في السكة؟'
                                : 'Stuck on Road?',
                            subtitle: isArabic
                                ? 'ونش إنقاذ يجيلك في ثواني'
                                : 'Fast tow truck dispatch',
                            ctaLabel:
                                isArabic ? 'اطلب ونش إنقاذ' : 'Call Tow Truck',
                            onTap: () => _openSearch(query: 'ونش'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Car Showcase Feed
                SliverToBoxAdapter(
                  child: DealOneSectionHeader(
                    title: isArabic ? 'السيارات المتاحة' : 'Available Cars',
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
                else if (state.listings.isEmpty)
                  SliverToBoxAdapter(
                    child: DealOneSectionEmptyCard(
                      message: isArabic
                          ? 'لا توجد سيارات مطابقة للفلاتر المختارة'
                          : 'No cars match the selected filters',
                      actionLabel: state.filters.hasActiveFilters
                          ? (isArabic ? 'مسح الفلاتر' : 'Clear Filters')
                          : null,
                      onAction: state.filters.hasActiveFilters
                          ? () => controller.clearFilters()
                          : null,
                    ),
                  )
                else ...[
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          CarShowcaseCard(item: state.listings[index]),
                      childCount: state.listings.length,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

class _RoadsideActionCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onTap;

  const _RoadsideActionCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 62,
            width: double.infinity,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: accentColor),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : DealOneDesignColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textMutedOf(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 34),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DealOneDesignColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onTap,
                child: Text(
                  ctaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
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
