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
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/core/navigation/drawer/config/categories/fashion_drawer.dart';
import 'package:market_space/core/navigation/presentation/widgets/deal_one_section_bottom_nav.dart';
import 'package:market_space/features/search/data/dto/search_dto.dart';
import 'package:market_space/features/search/presentation/providers/search_providers.dart';
import 'package:market_space/features/fashion_accessories/presentation/widgets/fashion_brand_card.dart';

/// Home 7 — Fashion & Accessories.
/// Independent section home matching `Home 7 - Fashion and Accessories.png`.
class FashionAccessoriesHomePage extends ConsumerStatefulWidget {
  static const String sectionSlug = 'fashion';

  const FashionAccessoriesHomePage({super.key});

  @override
  ConsumerState<FashionAccessoriesHomePage> createState() =>
      _FashionAccessoriesHomePageState();
}

class _FashionAccessoriesHomePageState
    extends ConsumerState<FashionAccessoriesHomePage> {
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
            FashionAccessoriesHomePage.sectionSlug,
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
            FashionAccessoriesHomePage.sectionSlug,
          ).notifier)
          .applyFilters(updated);
    }
  }

  void _openSearch() {
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(searchActiveQueryDtoProvider.notifier).state =
        const SearchQueryDto(
          categorySlug: FashionAccessoriesHomePage.sectionSlug,
        );
    context.push(RouteNames.search);
  }

  IconData _iconForFashionSlug(String slug) {
    final s = slug.toLowerCase();
    if (s.contains('men')) return Icons.man_rounded;
    if (s.contains('women')) return Icons.woman_rounded;
    if (s.contains('kid')) return Icons.child_care_rounded;
    if (s.contains('shoe') || s.contains('foot')) {
      return Icons.hiking_rounded;
    }
    if (s.contains('watch') || s.contains('access')) {
      return Icons.watch_outlined;
    }
    return Icons.checkroom_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = context.horizontalScreenPadding;
    final state = ref.watch(
      sectionHomeControllerProvider(FashionAccessoriesHomePage.sectionSlug),
    );
    final controller = ref.read(
      sectionHomeControllerProvider(FashionAccessoriesHomePage.sectionSlug)
          .notifier,
    );
    final isOffline = ref.watch(isOfflineProvider).valueOrNull ?? false;
    final feed = state.feed;
    final subs = feed?.section.subcategories ?? const [];
    final featuredLook =
        (feed != null && feed.featured.isNotEmpty) ? feed.featured.first : null;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : DealOneDesignColors.canvasLight,
      extendBody: true,
      drawer: const FashionDrawer(),
      bottomNavigationBar: const DealOneSectionBottomNav(
        sectionId: FashionAccessoriesHomePage.sectionSlug,
        activeTabId: 'home',
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: DealOneDesignColors.navy,
          onRefresh: () => controller.loadInitial(forceRefresh: true),
          child: CustomScrollView(
            key: const PageStorageKey<String>('fashion_home_scroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: DealOneHomeHeader(
                  showBackToHub: true,
                  sectionBadge: isArabic ? 'أزياء وإكسسوارات' : 'Fashion',
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
                      ? 'أبحث عن ملابس، أحذية، ساعات، أو إكسسوارات...'
                      : 'Search clothing, shoes, watches, or accessories...',
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
                // 1. New Season Hero Banner
                SliverToBoxAdapter(
                  child: DealOnePromoBannerCarousel(
                    promotions: feed.promotions,
                    onActionTap: (_) => _openSearch(),
                  ),
                ),

                // 2. Fashion Categories Responsive Rich Grid (`الأقسام والفئات`)
                SliverToBoxAdapter(
                  child: DealOneSectionHeader(
                    title: isArabic ? 'الأقسام والفئات' : 'Categories',
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
                                    _iconForFashionSlug(sub.slug),
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
                                                ? '${sub.listingsCount} منتج'
                                                : '${sub.listingsCount} items',
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

                // 3. Featured Look / Bundle Deal Card (driven by real featured listing)
                if (featuredLook != null)
                  SliverToBoxAdapter(
                    child: _FeaturedLookCard(
                      item: featuredLook,
                      isArabic: isArabic,
                    ),
                  ),

                // 4. Best Sellers from Top Brands (`الأكثر مبيعاً من أشهر الماركات`)
                SliverToBoxAdapter(
                  child: DealOneSectionHeader(
                    title: isArabic
                        ? 'الأكثر مبيعاً من أشهر الماركات'
                        : 'Best Sellers from Top Brands',
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
                          ? 'لا توجد منتجات أزياء مطابقة للفلاتر المختارة'
                          : 'No matching fashion items found',
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
                        (context, index) =>
                            FashionBrandCard(item: state.listings[index]),
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
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedLookCard extends StatelessWidget {
  final ListingItem item;
  final bool isArabic;

  const _FeaturedLookCard({required this.item, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = context.horizontalScreenPadding;
    final brand = item.attributes['brand']?.toString() ??
        (isArabic ? item.categoryNameAr : item.categoryNameEn);

    return Container(
      margin: EdgeInsetsDirectional.fromSTEB(hPad, 16, hPad, 4),
      padding: const EdgeInsets.all(12),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 170,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.primaryImageUrl != null &&
                      item.primaryImageUrl!.isNotEmpty)
                    Image.network(
                      item.primaryImageUrl!,
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                      errorBuilder: (_, _, _) => Container(
                        color: DealOneDesignColors.navy.withValues(alpha: 0.12),
                      ),
                    )
                  else
                    Container(
                      color: DealOneDesignColors.navy.withValues(alpha: 0.12),
                    ),
                  PositionedDirectional(
                    top: 10,
                    end: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        brand,
                        style: const TextStyle(
                          color: DealOneDesignColors.navy,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 10,
                    start: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isArabic ? '03 س : 14 د : 38 ث' : '03h : 14m : 38s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Outfit piece thumbnails strip along bottom of image matching Home 7 PNG
                  PositionedDirectional(
                    bottom: 8,
                    start: 8,
                    end: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final icon in [
                          Icons.checkroom_rounded,
                          Icons.dry_cleaning_rounded,
                          Icons.hiking_rounded,
                          Icons.watch_outlined,
                        ])
                          Container(
                            width: 34,
                            height: 34,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: DealOneDesignColors.navy.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Icon(
                              icon,
                              size: 17,
                              color: DealOneDesignColors.navy,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            item.description.isNotEmpty
                ? item.description
                : item.sellerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMutedOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DealOneLivePriceText(
                listingId: item.id,
                cachedPrice: item.price,
                currency: item.currency,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: DealOneDesignColors.amberPrice,
                ),
              ),
              Text(
                formatDealOnePrice(
                  (item.price * 1.18).roundToDouble(),
                  currency: item.currency,
                  isArabic: isArabic,
                ),
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMutedOf(context),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 42),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DealOneDesignColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.push('/listings/${item.id}'),
                icon: const Icon(Icons.shopping_basket_outlined, size: 17),
                label: Text(
                  isArabic ? 'أضف الطقم للسلة' : 'Add Outfit to Basket',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
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
