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
import '../../../main_hub/presentation/widgets/main_hub_service_card.dart';
import '../../../search/data/dto/search_dto.dart';
import '../../../search/presentation/providers/search_providers.dart';
import '../widgets/service_provider_tile.dart';

/// Home 4 — Services & Engineering.
/// Independent section home matching `Home 4 - Services and Engineering.png`.
class ServicesEngineeringHomePage extends ConsumerStatefulWidget {
  static const String sectionSlug = 'services';

  const ServicesEngineeringHomePage({super.key});

  @override
  ConsumerState<ServicesEngineeringHomePage> createState() =>
      _ServicesEngineeringHomePageState();
}

class _ServicesEngineeringHomePageState
    extends ConsumerState<ServicesEngineeringHomePage> {
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
          .read(sectionHomeControllerProvider(
            ServicesEngineeringHomePage.sectionSlug,
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
            ServicesEngineeringHomePage.sectionSlug,
          ).notifier)
          .applyFilters(updated);
    }
  }

  void _openSearch({String? query}) {
    ref.read(searchQueryProvider.notifier).state = query ?? '';
    ref.read(searchActiveQueryDtoProvider.notifier).state = SearchQueryDto(
      query: query ?? '',
      categorySlug: ServicesEngineeringHomePage.sectionSlug,
    );
    context.push(RouteNames.search);
  }

  IconData _iconForServiceSlug(String slug) {
    final s = slug.toLowerCase();
    if (s.contains('ac')) return Icons.ac_unit_rounded;
    if (s.contains('plumb')) return Icons.plumbing_rounded;
    if (s.contains('electr')) return Icons.electrical_services_rounded;
    if (s.contains('paint') || s.contains('interior')) {
      return Icons.format_paint_rounded;
    }
    if (s.contains('carpent') || s.contains('furn')) {
      return Icons.carpenter_rounded;
    }
    if (s.contains('mov') || s.contains('transport')) {
      return Icons.local_shipping_outlined;
    }
    return Icons.handyman_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = context.horizontalScreenPadding;
    final state = ref.watch(
      sectionHomeControllerProvider(ServicesEngineeringHomePage.sectionSlug),
    );
    final controller = ref.read(
      sectionHomeControllerProvider(ServicesEngineeringHomePage.sectionSlug)
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
            key: const PageStorageKey<String>('services_engineering_scroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: DealOneHomeHeader(
                  showBackToHub: true,
                  sectionBadge: isArabic ? 'خدمات وهندسة' : 'Services',
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
                      ? 'أبحث عن خدمة، كهربائي، أو فني تكييفات...'
                      : 'Search service, electrician, or AC technician...',
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
                      DealOneSectionSkeleton(height: 180),
                      DealOneSectionSkeleton(height: 220),
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
                // 1. Instant Service Hero Banner
                SliverToBoxAdapter(
                  child: DealOnePromoBannerCarousel(
                    promotions: feed.promotions,
                    onActionTap: (_) => _openSearch(),
                  ),
                ),

                // 2. Service Categories Responsive Rich Grid (`الأقسام والخدمات`)
                SliverToBoxAdapter(
                  child: DealOneSectionHeader(
                    title: isArabic
                        ? 'الأقسام والخدمات'
                        : 'Service Categories',
                    actionLabel: isArabic ? 'عرض الكل' : 'View All',
                    onActionTap: () => controller.clearFilters(),
                  ),
                ),
                if (subs.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    sliver: SliverGrid(
                      gridDelegate: context.responsiveCategoryGridDelegate(
                        baseMainAxisExtent: 64,
                        extraExtentPerTextScaleUnit: 46,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final sub = subs[index];
                        final selected =
                            state.filters.subcategorySlug == sub.slug;
                        return Material(
                          color: selected
                              ? DealOneDesignColors.navy
                              : (isDark ? AppColors.darkSurface : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => controller.applyFilters(
                              selected
                                  ? state.filters
                                      .copyWith(clearSubcategory: true)
                                  : state.filters.copyWith(
                                      subcategorySlug: sub.slug,
                                    ),
                            ),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
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
                                    _iconForServiceSlug(sub.slug),
                                    size: 20,
                                    color: selected
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white70
                                              : DealOneDesignColors.navy),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            isArabic ? sub.nameAr : sub.nameEn,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: selected
                                                  ? Colors.white
                                                  : (isDark
                                                        ? AppColors
                                                            .darkTextPrimary
                                                        : DealOneDesignColors
                                                            .navy),
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            isArabic
                                                ? '${sub.listingsCount} خدمة متاحة'
                                                : '${sub.listingsCount} available',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: selected
                                                  ? Colors.white70
                                                  : AppColors.textMutedOf(
                                                      context,
                                                    ),
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
                        );
                      }, childCount: subs.length),
                    ),
                  ),

                // 3. Most Requested Services Responsive Grid
                SliverToBoxAdapter(
                  child: DealOneSectionHeader(
                    title: isArabic
                        ? 'الخدمات الأكثر طلباً'
                        : 'Most Requested Services',
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
                          ? 'لا توجد خدمات مطابقة للفلاتر المختارة'
                          : 'No matching services found',
                      actionLabel: state.filters.hasActiveFilters
                          ? (isArabic ? 'مسح الفلاتر' : 'Clear Filters')
                          : null,
                      onAction: state.filters.hasActiveFilters
                          ? () => controller.clearFilters()
                          : null,
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    sliver: SliverGrid(
                      gridDelegate: context.responsiveProductGridDelegate(
                        baseMainAxisExtent: 238,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            MainHubPopularCard(item: state.listings[index]),
                        childCount: state.listings.length,
                      ),
                    ),
                  ),

                // 4. Certified Partners & Service Providers (`الشركاء والتوكيلات المعتمدة`)
                if (feed.providers.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: DealOneSectionHeader(
                      title: isArabic
                          ? 'الشركاء والتوكيلات المعتمدة'
                          : 'Certified Partners & Providers',
                      actionLabel: isArabic ? 'عرض الكل' : 'View All',
                      onActionTap: _openSearch,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final provider = feed.providers[index];
                        return ServicesProviderTile(
                          provider: provider,
                          onBookTap: () =>
                              _openSearch(query: provider.displayName),
                        );
                      },
                      childCount: feed.providers.length,
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
