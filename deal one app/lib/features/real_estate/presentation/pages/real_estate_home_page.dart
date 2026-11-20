import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/deal_one_header.dart';
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
import '../widgets/property_card.dart';

/// Home 2 — Real Estate & Land.
/// Independent section home matching `Home 2 - Real Estate and Land.png`.
class RealEstateHomePage extends ConsumerStatefulWidget {
  static const String sectionSlug = 'real-estate';

  const RealEstateHomePage({super.key});

  @override
  ConsumerState<RealEstateHomePage> createState() => _RealEstateHomePageState();
}

class _RealEstateHomePageState extends ConsumerState<RealEstateHomePage> {
  final ScrollController _scrollController = ScrollController();

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
          .read(sectionHomeControllerProvider(RealEstateHomePage.sectionSlug)
              .notifier)
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
          .read(sectionHomeControllerProvider(RealEstateHomePage.sectionSlug)
              .notifier)
          .applyFilters(updated);
    }
  }

  void _openSearch() {
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(searchActiveQueryDtoProvider.notifier).state =
        const SearchQueryDto(categorySlug: RealEstateHomePage.sectionSlug);
    context.push(RouteNames.search);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = context.horizontalScreenPadding;
    final chipRowHeight =
        44.0 + ((context.effectiveTextScale - 1.0).clamp(0.0, 1.2) * 20.0);
    final state = ref.watch(
      sectionHomeControllerProvider(RealEstateHomePage.sectionSlug),
    );
    final controller = ref.read(
      sectionHomeControllerProvider(RealEstateHomePage.sectionSlug).notifier,
    );
    final isOffline = ref.watch(isOfflineProvider).valueOrNull ?? false;

    final feed = state.feed;
    final subcategories = feed?.section.subcategories ?? const [];

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
            key: const PageStorageKey<String>('real_estate_home_scroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Header with back to Main Hub
              SliverToBoxAdapter(
                child: DealOneHomeHeader(
                  showBackToHub: true,
                  sectionBadge: isArabic ? 'عقارات وأراضٍ' : 'Real Estate',
                ),
              ),

              if (isOffline || state.isOfflineFallback)
                SliverToBoxAdapter(
                  child: DealOneOfflineBanner(
                    onRetry: () => controller.loadInitial(forceRefresh: true),
                  ),
                ),

              // 2. Real Estate Search Bar
              SliverToBoxAdapter(
                child: DealOneSearchBar(
                  hintText: isArabic
                      ? 'أبحث عن عقار للبيع أو الإيجار...'
                      : 'Search properties for sale or rent...',
                  activeFilterCount: state.filters.activeFilterCount,
                  onSearchTap: _openSearch,
                  onFilterTap: () => _openFilterSheet(state),
                ),
              ),

              // 3. Property Category Filter Chips + Sort Button (matching PNG)
              if (feed != null)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: chipRowHeight,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      children: [
                        _RealEstateChip(
                          label: isArabic ? 'الكل' : 'All',
                          selected: state.filters.subcategorySlug == null,
                          onTap: () => controller.applyFilters(
                            state.filters.copyWith(clearSubcategory: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...subcategories.map((sub) {
                          final selected =
                              state.filters.subcategorySlug == sub.slug;
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: _RealEstateChip(
                              label: isArabic ? sub.nameAr : sub.nameEn,
                              selected: selected,
                              onTap: () => controller.applyFilters(
                                selected
                                    ? state.filters
                                        .copyWith(clearSubcategory: true)
                                    : state.filters.copyWith(
                                        subcategorySlug: sub.slug,
                                      ),
                              ),
                            ),
                          );
                        }),
                        InkWell(
                          onTap: () => _openFilterSheet(state),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 40,
                            height: chipRowHeight,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : Colors.black.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Icon(
                              Icons.swap_vert_rounded,
                              size: 20,
                              color: isDark
                                  ? Colors.white
                                  : DealOneDesignColors.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 4. Initial Loading / Error
              if (state.isInitialLoading && feed == null)
                const SliverToBoxAdapter(
                  child: Column(
                    children: [
                      DealOneSectionSkeleton(height: 220),
                      DealOneSectionSkeleton(height: 300),
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
                // 5. Live Previews (`معاينات حية`) matching PNG
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

                // 6. Property Feed Cards
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
                          ? 'لا توجد عقارات مطابقة للفلاتر المختارة'
                          : 'No properties match the selected filters',
                      actionLabel: state.filters.hasActiveFilters
                          ? (isArabic ? 'مسح الفلاتر' : 'Clear Filters')
                          : null,
                      onAction: state.filters.hasActiveFilters
                          ? () => controller.clearFilters()
                          : null,
                    ),
                  )
                else ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          RealEstatePropertyCard(item: state.listings[index]),
                      childCount: state.listings.length,
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

class _RealEstateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RealEstateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? DealOneDesignColors.navy
          : (isDark ? AppColors.darkSurface : Colors.white),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? DealOneDesignColors.navy
                  : (isDark
                        ? AppColors.darkBorder
                        : Colors.black.withValues(alpha: 0.08)),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white70 : DealOneDesignColors.navy),
            ),
          ),
        ),
      ),
    );
  }
}
