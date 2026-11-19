import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/deal_one_header.dart';
import '../../../../core/design_system/deal_one_promo_banner.dart';
import '../../../../core/design_system/deal_one_search_bar.dart';
import '../../../../core/design_system/deal_one_section_chrome.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../listings/presentation/providers/listings_providers.dart';
import '../../../listings/presentation/widgets/deal_one_listing_card.dart';
import '../../../listings/presentation/widgets/floating_bottom_nav.dart';
import '../../../locations/presentation/providers/locations_providers.dart';
import '../../../search/data/dto/search_dto.dart';
import '../../../search/presentation/providers/search_providers.dart';
import '../providers/main_hub_providers.dart';
import '../widgets/main_hub_categories_grid.dart';
import '../widgets/main_hub_service_card.dart';

/// Home 1 — Main Hub.
/// Entry point of Deal One Marketplace matching `Home 1 - Main Hub.png`.
/// Navigates cleanly into each of the 6 independent Section Homes while
/// preserving Main Hub state and scroll position.
class MainHubPage extends ConsumerStatefulWidget {
  const MainHubPage({super.key});

  @override
  ConsumerState<MainHubPage> createState() => _MainHubPageState();
}

class _MainHubPageState extends ConsumerState<MainHubPage> {
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
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) {
      ref.read(paginatedLatestListingsProvider.notifier).loadMore();
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(mainHubControllerProvider.notifier).loadInitial(
            forceRefresh: true,
          ),
      ref.read(paginatedLatestListingsProvider.notifier).loadInitial(),
    ]);
  }

  void _openSearch({String? categorySlug, bool openFilters = false}) {
    final gov = ref.read(selectedGovernorateProvider);
    final city = ref.read(selectedCityProvider);
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(searchActiveQueryDtoProvider.notifier).state = SearchQueryDto(
      categorySlug: categorySlug,
      governorateId: gov?.id,
      cityId: city?.id,
    );
    context.push(
      openFilters ? '${RouteNames.search}?filters=1' : RouteNames.search,
    );
  }

  void _openSectionHome(String slug) {
    final route = sectionRouteForSlug(slug);
    if (route == RouteNames.search) {
      _openSearch(categorySlug: slug);
    } else {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hubState = ref.watch(mainHubControllerProvider);
    final latestState = ref.watch(paginatedLatestListingsProvider);
    final isOffline = ref.watch(isOfflineProvider).valueOrNull ?? false;

    final feed = hubState.feed;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : DealOneDesignColors.canvasLight,
      extendBody: true,
      bottomNavigationBar: const DealOneFloatingBottomNav(activeIndex: 0),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: DealOneDesignColors.navy,
          onRefresh: _refreshAll,
          child: CustomScrollView(
            key: const PageStorageKey<String>('main_hub_scroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Main Header
              const SliverToBoxAdapter(
                child: DealOneHomeHeader(showBackToHub: false),
              ),

              // 2. Offline indicator if disconnected or showing stale fallback
              if (isOffline || hubState.isOfflineFallback)
                SliverToBoxAdapter(
                  child: DealOneOfflineBanner(onRetry: _refreshAll),
                ),

              // 3. Global Search Bar
              SliverToBoxAdapter(
                child: DealOneSearchBar(
                  hintText: isArabic
                      ? 'أبحث عن عقار، خدمة صيانة، أو جهاز...'
                      : 'Search property, service, car, or appliance...',
                  onSearchTap: () => _openSearch(),
                  onFilterTap: () => _openSearch(openFilters: true),
                ),
              ),

              // 4. Initial Loading / Fatal Error when no cache exists
              if (hubState.isInitialLoading && feed == null)
                const SliverToBoxAdapter(
                  child: Column(
                    children: [
                      DealOneSectionSkeleton(height: 184),
                      SizedBox(height: 12),
                      DealOneSectionSkeleton(height: 170),
                      SizedBox(height: 12),
                      DealOneSectionSkeleton(height: 220),
                    ],
                  ),
                )
              else if (hubState.error != null && feed == null)
                SliverToBoxAdapter(
                  child: DealOneSectionErrorCard(
                    error: hubState.error!,
                    onRetry: _refreshAll,
                  ),
                )
              else if (feed != null) ...[
                // 5. Promotional Hero Banner Carousel
                if (feed.promotions.isNotEmpty)
                  SliverToBoxAdapter(
                    child: DealOnePromoBannerCarousel(
                      promotions: feed.promotions,
                      onActionTap: (promo) =>
                          _openSectionHome(promo.categorySlug),
                    ),
                  ),

                // 6. Six Main Categories Grid (navigates to 6 independent Section Homes)
                SliverToBoxAdapter(
                  child: DealOneSectionHeader(
                    title: isArabic ? 'الأقسام الرئيسية' : 'Main Categories',
                    actionLabel: isArabic ? 'عرض الكل' : 'View All',
                    onActionTap: () => _openSearch(),
                  ),
                ),
                if (feed.categories.isEmpty)
                  SliverToBoxAdapter(
                    child: DealOneSectionEmptyCard(
                      message: isArabic
                          ? 'لا توجد أقسام متاحة حالياً'
                          : 'No categories available yet',
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: MainHubCategoriesGrid(
                      categories: feed.categories,
                      onCategoryTap: (cat) => _openSectionHome(cat.slug),
                    ),
                  ),

                // 7. Most Requested / Recommended (2-Column Grid matching PNG)
                SliverToBoxAdapter(
                  child: DealOneSectionHeader(
                    title: isArabic
                        ? 'الخدمات الأكثر طلباً'
                        : 'Most Requested & Popular',
                    actionLabel: isArabic ? 'عرض الكل' : 'View All',
                    onActionTap: () => _openSearch(),
                  ),
                ),
                if (feed.recommended.isEmpty)
                  SliverToBoxAdapter(
                    child: DealOneSectionEmptyCard(
                      message: isArabic
                          ? 'لا توجد عروض شائعة حالياً'
                          : 'No popular listings yet',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            MainHubPopularCard(item: feed.recommended[index]),
                        childCount: feed.recommended.take(4).length,
                      ),
                    ),
                  ),

                // 8. Featured Listings Horizontal Carousel
                if (feed.featured.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: DealOneSectionHeader(
                      title: isArabic ? 'العروض المميزة' : 'Featured Listings',
                      actionLabel: isArabic ? 'عرض الكل' : 'View All',
                      onActionTap: () => _openSearch(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 256,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: feed.featured.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => SizedBox(
                          width: 186,
                          child: DealOneListingCard(
                            item: feed.featured[index],
                            compact: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],

              // 9. Latest Listings with Cursor Pagination (Independent Provider)
              SliverToBoxAdapter(
                child: DealOneSectionHeader(
                  title: isArabic ? 'أحدث الإعلانات' : 'Latest Listings',
                  actionLabel: isArabic ? 'تصفية' : 'Filter',
                  onActionTap: () => _openSearch(openFilters: true),
                ),
              ),
              if (latestState.isLoadingInitial)
                const SliverToBoxAdapter(
                  child: DealOneSectionSkeleton(height: 240),
                )
              else if (latestState.error != null && latestState.items.isEmpty)
                SliverToBoxAdapter(
                  child: DealOneSectionErrorCard(
                    error: latestState.error!,
                    onRetry: () => ref
                        .read(paginatedLatestListingsProvider.notifier)
                        .loadInitial(),
                  ),
                )
              else if (latestState.items.isEmpty)
                SliverToBoxAdapter(
                  child: DealOneSectionEmptyCard(
                    message: isArabic
                        ? 'لا توجد إعلانات في هذا الموقع حالياً'
                        : 'No listings available in this location',
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          DealOneListingCard(item: latestState.items[index]),
                      childCount: latestState.items.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: latestState.isLoadingMore
                          ? const CircularProgressIndicator.adaptive()
                          : latestState.hasMore
                              ? OutlinedButton.icon(
                                  onPressed: () => ref
                                      .read(paginatedLatestListingsProvider
                                          .notifier)
                                      .loadMore(),
                                  icon: const Icon(Icons.expand_more_rounded),
                                  label: Text(
                                    isArabic ? 'عرض المزيد' : 'Load More',
                                  ),
                                )
                              : Text(
                                  isArabic
                                      ? 'تم عرض جميع الإعلانات المتاحة'
                                      : 'You have reached the end',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMutedOf(context),
                                  ),
                                ),
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
