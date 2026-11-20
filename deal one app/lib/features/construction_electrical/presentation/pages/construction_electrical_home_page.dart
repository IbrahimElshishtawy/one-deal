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
import '../widgets/construction_material_card.dart';

/// Home 5 — Construction & Electrical Materials.
/// Independent section home matching `Home 5 - Construction and Electrical Materials.png`.
class ConstructionElectricalHomePage extends ConsumerStatefulWidget {
  static const String sectionSlug = 'building-materials';

  const ConstructionElectricalHomePage({super.key});

  @override
  ConsumerState<ConstructionElectricalHomePage> createState() =>
      _ConstructionElectricalHomePageState();
}

class _ConstructionElectricalHomePageState
    extends ConsumerState<ConstructionElectricalHomePage> {
  final ScrollController _scrollController = ScrollController();
  int _activeSegment = 0; // 0 = Building Materials, 1 = Electrical & Plumbing

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
            ConstructionElectricalHomePage.sectionSlug,
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
            ConstructionElectricalHomePage.sectionSlug,
          ).notifier)
          .applyFilters(updated);
    }
  }

  void _openSearch() {
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(searchActiveQueryDtoProvider.notifier).state =
        const SearchQueryDto(
          categorySlug: ConstructionElectricalHomePage.sectionSlug,
        );
    context.push(RouteNames.search);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = context.horizontalScreenPadding;
    final state = ref.watch(
      sectionHomeControllerProvider(ConstructionElectricalHomePage.sectionSlug),
    );
    final controller = ref.read(
      sectionHomeControllerProvider(ConstructionElectricalHomePage.sectionSlug)
          .notifier,
    );
    final isOffline = ref.watch(isOfflineProvider).valueOrNull ?? false;
    final feed = state.feed;

    final allSubs = feed?.section.subcategories ?? const [];
    final segmentSubs = _activeSegment == 0
        ? allSubs
            .where(
              (c) => !c.slug.contains('electr') && !c.slug.contains('plumb'),
            )
            .toList()
        : allSubs
            .where((c) => c.slug.contains('electr') || c.slug.contains('plumb'))
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
            key: const PageStorageKey<String>('construction_home_scroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: DealOneHomeHeader(
                  showBackToHub: true,
                  sectionBadge: isArabic ? 'مواد بناء وكهرباء' : 'Materials',
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
                      ? 'أبحث عن مواد البناء، أسمنت، حديد، طوب...'
                      : 'Search cement, rebar, bricks, cables...',
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
                      DealOneSectionSkeleton(height: 140),
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
                SliverToBoxAdapter(
                  child: DealOnePromoBannerCarousel(
                    promotions: feed.promotions,
                    onActionTap: (_) => _openSearch(),
                  ),
                ),

                // Segmented Toggle (`مواد البناء` | `الكهرباء والتأسيس`)
                SliverToBoxAdapter(
                  child: DealOneSegmentedToggle(
                    firstLabel: isArabic ? 'مواد البناء' : 'Building Materials',
                    secondLabel:
                        isArabic ? 'الكهرباء والتأسيس' : 'Electrical & MEP',
                    selectedIndex: _activeSegment,
                    onChanged: (idx) {
                      setState(() => _activeSegment = idx);
                      if (idx == 1) {
                        final elecSub = allSubs
                            .where((s) => s.slug.contains('electr'))
                            .firstOrNull;
                        if (elecSub != null) {
                          controller.applyFilters(
                            state.filters.copyWith(
                              subcategorySlug: elecSub.slug,
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

                // Responsive Subcategories Grid
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
                                    Icons.construction_rounded,
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

                // Most Requested Raw Materials Grid
                SliverToBoxAdapter(
                  child: DealOneSectionHeader(
                    title: isArabic
                        ? 'الخامات الأكثر طلباً'
                        : 'Most Requested Materials',
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
                          ? 'لا توجد مواد بناء مطابقة حالياً'
                          : 'No matching building materials found',
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
                        baseMainAxisExtent: 254,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ConstructionMaterialCard(
                          item: state.listings[index],
                        ),
                        childCount: state.listings.length,
                      ),
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

                // Bottom Contractor Bulk Order RFQ Banner (matching PNG)
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsetsDirectional.fromSTEB(hPad, 8, hPad, 8),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: DealOneDesignColors.navy,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isArabic
                              ? 'طلبيات المشاريع والمقاولات الخاصة'
                              : 'Project & Contractor Bulk Orders',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isArabic
                              ? 'احصل على أسعار تنافسية، توريد مباشر للموقع، وجدول دفعات مخصص لمشروعك'
                              : 'Competitive wholesale rates with direct site delivery',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 42),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: DealOneDesignColors.navy,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _openSearch,
                              icon: const Icon(
                                Icons.description_outlined,
                                size: 18,
                              ),
                              label: Text(
                                isArabic
                                    ? 'اطلب مقايسة مخصصة'
                                    : 'Request Custom Quote',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }
}
