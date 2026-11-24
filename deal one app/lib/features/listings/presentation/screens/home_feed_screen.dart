import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/providers/app_settings_providers.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/features/categories/domain/entities/category_entity.dart';
import 'package:market_space/features/categories/presentation/providers/categories_providers.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/listings/presentation/providers/listings_providers.dart';
import 'package:market_space/features/listings/presentation/widgets/deal_one_listing_card.dart';
import 'package:market_space/features/listings/presentation/widgets/floating_bottom_nav.dart';
import 'package:market_space/features/listings/presentation/widgets/location_selector_sheet.dart';
import 'package:market_space/features/locations/presentation/providers/locations_providers.dart';
import 'package:market_space/features/search/data/dto/search_dto.dart';
import 'package:market_space/features/search/presentation/providers/search_providers.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final PageController _promoController = PageController();
  int _promoIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _promoController.dispose();
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
    ref.invalidate(categoryTreeProvider);
    ref.invalidate(homePromotionsProvider);
    ref.invalidate(featuredListingsProvider);
    ref.invalidate(recommendedListingsProvider);
    await ref.read(paginatedLatestListingsProvider.notifier).loadInitial();
  }

  void _openCategoryBrowse(String categorySlug) {
    final gov = ref.read(selectedGovernorateProvider);
    final city = ref.read(selectedCityProvider);
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(searchActiveQueryDtoProvider.notifier).state = SearchQueryDto(
      categorySlug: categorySlug,
      governorateId: gov?.id,
      cityId: city?.id,
    );
    context.push(RouteNames.search);
  }

  void _openSearch({bool openFilters = false}) {
    final gov = ref.read(selectedGovernorateProvider);
    final city = ref.read(selectedCityProvider);
    ref.read(searchActiveQueryDtoProvider.notifier).state = SearchQueryDto(
      governorateId: gov?.id,
      cityId: city?.id,
    );
    context.push(
      openFilters ? '${RouteNames.search}?filters=1' : RouteNames.search,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = ref.watch(activeUserDisplayNameProvider) ??
        (isArabic ? 'مصطفى هيكل' : 'Deal One Guest');
    final selectedGov = ref.watch(selectedGovernorateProvider);
    final selectedCity = ref.watch(selectedCityProvider);
    final categoriesAsync = ref.watch(categoryTreeProvider);
    final promotionsAsync = ref.watch(homePromotionsProvider);
    final featuredAsync = ref.watch(featuredListingsProvider);
    final recommendedAsync = ref.watch(recommendedListingsProvider);
    final latestState = ref.watch(paginatedLatestListingsProvider);

    final locationDisplay = selectedCity != null
        ? '${isArabic ? selectedGov?.nameAr ?? '' : selectedGov?.nameEn ?? ''} - ${isArabic ? selectedCity.nameAr : selectedCity.nameEn}'
        : selectedGov != null
            ? (isArabic ? selectedGov.nameAr : selectedGov.nameEn)
            : (isArabic ? 'كل محافظات مصر' : 'All Egypt');

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
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. App Header (User + Location Selector + Quick Actions)
              SliverToBoxAdapter(
                child: _HomeHeader(
                  userName: userName,
                  locationDisplay: locationDisplay,
                  isArabic: isArabic,
                  onLocationTap: () => showLocationSelectorSheet(context, ref),
                  onFavoritesTap: () => context.go(RouteNames.favorites),
                  onToggleLanguage: () {
                    final current = ref.read(appLocaleProvider);
                    ref.read(appLocaleProvider.notifier).setLocale(
                          current.languageCode == 'ar'
                              ? const Locale('en')
                              : const Locale('ar'),
                        );
                  },
                ),
              ),

              // 2. Pill Search Bar with Filter trigger
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: _HomeSearchBar(
                    isArabic: isArabic,
                    onSearchTap: () => _openSearch(),
                    onFilterTap: () => _openSearch(openFilters: true),
                  ),
                ),
              ),

              // 3. Promotional Hero Banner Carousel (Independent Async)
              SliverToBoxAdapter(
                child: promotionsAsync.when(
                  data: (promotions) {
                    if (promotions.isEmpty) return const SizedBox.shrink();
                    return _PromoCarousel(
                      promotions: promotions,
                      controller: _promoController,
                      currentIndex: _promoIndex,
                      isArabic: isArabic,
                      onPageChanged: (idx) => setState(() => _promoIndex = idx),
                      onActionTap: (slug) => _openCategoryBrowse(slug),
                    );
                  },
                  loading: () => const _SectionSkeleton(height: 176),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),

              // 4. Main Categories Grid (2-Column Pill Cards from Backend)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: _SectionHeader(
                    title: isArabic ? 'الأقسام الرئيسية' : 'Main Categories',
                    actionLabel: isArabic ? 'عرض الكل' : 'View All',
                    onActionTap: () => _openSearch(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: categoriesAsync.when(
                  data: (categories) {
                    if (categories.isEmpty) {
                      return _SectionEmptyCard(
                        message: isArabic
                            ? 'لا توجد أقسام متاحة حالياً'
                            : 'No categories available',
                      );
                    }
                    return _MainCategoriesGrid(
                      categories: categories,
                      isArabic: isArabic,
                      onCategoryTap: (cat) => _openCategoryBrowse(cat.slug),
                    );
                  },
                  loading: () => const _SectionSkeleton(height: 170),
                  error: (_, _) => _SectionErrorCard(
                    message: isArabic
                        ? 'تعذر تحميل الأقسام'
                        : 'Failed to load categories',
                    retryLabel: isArabic ? 'إعادة المحاولة' : 'Retry',
                    onRetry: () => ref.invalidate(categoryTreeProvider),
                  ),
                ),
              ),

              // 5. Featured Products Horizontal Carousel (Independent Async)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                  child: _SectionHeader(
                    title: isArabic ? 'العروض المميزة' : 'Featured Deals',
                    actionLabel: isArabic ? 'عرض الكل' : 'View All',
                    onActionTap: () => _openSearch(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: featuredAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return _SectionEmptyCard(
                        message: isArabic
                            ? 'لا توجد عروض مميزة في هذا الموقع حالياً'
                            : 'No featured deals in this area yet',
                      );
                    }
                    return SizedBox(
                      height: 258,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => SizedBox(
                          width: 186,
                          child: DealOneListingCard(
                            item: items[index],
                            compact: true,
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const _SectionSkeleton(height: 240),
                  error: (_, _) => _SectionErrorCard(
                    message: isArabic
                        ? 'تعذر تحميل العروض المميزة'
                        : 'Failed to load featured products',
                    retryLabel: isArabic ? 'إعادة المحاولة' : 'Retry',
                    onRetry: () => ref.invalidate(featuredListingsProvider),
                  ),
                ),
              ),

              // 6. Most Requested / Recommended Section (Independent Async)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                  child: _SectionHeader(
                    title: isArabic
                        ? 'الأكثر طلباً ومقترح لك'
                        : 'Most Requested & Recommended',
                    actionLabel: isArabic ? 'عرض الكل' : 'View All',
                    onActionTap: () => _openSearch(),
                  ),
                ),
              ),
              recommendedAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _SectionEmptyCard(
                        message: isArabic
                            ? 'لا توجد منتجات مقترحة حالياً'
                            : 'No recommendations available yet',
                      ),
                    );
                  }
                  final previewItems = items.take(4).toList();
                  return SliverPadding(
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
                            DealOneListingCard(item: previewItems[index]),
                        childCount: previewItems.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: _SectionSkeleton(height: 240),
                ),
                error: (_, _) => SliverToBoxAdapter(
                  child: _SectionErrorCard(
                    message: isArabic
                        ? 'تعذر تحميل المنتجات المقترحة'
                        : 'Failed to load recommended products',
                    retryLabel: isArabic ? 'إعادة المحاولة' : 'Retry',
                    onRetry: () => ref.invalidate(recommendedListingsProvider),
                  ),
                ),
              ),

              // 7. Latest Products with Cursor Pagination
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                  child: _SectionHeader(
                    title: isArabic ? 'أحدث الإعلانات' : 'Latest Listings',
                    actionLabel: isArabic ? 'تصفية' : 'Filter',
                    onActionTap: () => _openSearch(openFilters: true),
                  ),
                ),
              ),
              if (latestState.isLoadingInitial)
                const SliverToBoxAdapter(
                  child: _SectionSkeleton(height: 260),
                )
              else if (latestState.error != null && latestState.items.isEmpty)
                SliverToBoxAdapter(
                  child: _SectionErrorCard(
                    message: isArabic
                        ? 'تعذر تحميل أحدث الإعلانات'
                        : 'Failed to load latest listings',
                    retryLabel: isArabic ? 'إعادة المحاولة' : 'Retry',
                    onRetry: () => ref
                        .read(paginatedLatestListingsProvider.notifier)
                        .loadInitial(),
                  ),
                )
              else if (latestState.items.isEmpty)
                SliverToBoxAdapter(
                  child: _SectionEmptyCard(
                    message: isArabic
                        ? 'لا توجد إعلانات مطابقة في هذا الموقع حالياً'
                        : 'No listings found for this location',
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
                    padding: const EdgeInsets.symmetric(vertical: 18),
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

              // Bottom clearance for floating navy pill nav
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String userName;
  final String locationDisplay;
  final bool isArabic;
  final VoidCallback onLocationTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onToggleLanguage;

  const _HomeHeader({
    required this.userName,
    required this.locationDisplay,
    required this.isArabic,
    required this.onLocationTap,
    required this.onFavoritesTap,
    required this.onToggleLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // User Avatar + Deal One badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: DealOneDesignColors.navy,
                child: Text(
                  userName.isNotEmpty ? userName.characters.first : 'D',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              PositionedDirectional(
                bottom: -3,
                end: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Text(
                    'D1',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: DealOneDesignColors.navy,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Name + Location Selector
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : DealOneDesignColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: onLocationTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 15,
                        color: DealOneDesignColors.navy,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          locationDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMutedOf(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.textMutedOf(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(
            icon: Icons.favorite_border_rounded,
            tooltip: isArabic ? 'المفضلة' : 'Favorites',
            onTap: onFavoritesTap,
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(
            icon: Icons.translate_rounded,
            tooltip: isArabic ? 'English' : 'العربية',
            onTap: onToggleLanguage,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? Colors.white : DealOneDesignColors.navy,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeSearchBar extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  const _HomeSearchBar({
    required this.isArabic,
    required this.onSearchTap,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onSearchTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : Colors.black.withValues(alpha: 0.07),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: isDark ? Colors.white70 : DealOneDesignColors.navy,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isArabic
                      ? 'أبحث عن عقار، سيارة، خدمة صيانة، أو جهاز...'
                      : 'Search properties, cars, services, appliances...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: isDark ? Colors.white : DealOneDesignColors.navy,
                  size: 20,
                ),
                onPressed: onFilterTap,
                tooltip: isArabic ? 'فلاتر البحث' : 'Filters',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoCarousel extends StatelessWidget {
  final List<HomePromotion> promotions;
  final PageController controller;
  final int currentIndex;
  final bool isArabic;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String> onActionTap;

  const _PromoCarousel({
    required this.promotions,
    required this.controller,
    required this.currentIndex,
    required this.isArabic,
    required this.onPageChanged,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 184,
      child: PageView.builder(
        controller: controller,
        onPageChanged: onPageChanged,
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          final promo = promotions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    promo.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: DealOneDesignColors.navy,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.topEnd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: DealOneDesignColors.navy.withValues(
                                alpha: 0.85,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isArabic ? promo.badgeAr : promo.badgeEn,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isArabic ? promo.titleAr : promo.titleEn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isArabic ? promo.subtitleAr : promo.subtitleEn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: DealOneDesignColors.navy,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => onActionTap(promo.categorySlug),
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                              ),
                              label: Text(
                                isArabic ? promo.ctaAr : promo.ctaEn,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            Row(
                              children: List.generate(promotions.length, (i) {
                                final active = i == currentIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: active ? 20 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MainCategoriesGrid extends StatelessWidget {
  final List<CategoryItem> categories;
  final bool isArabic;
  final ValueChanged<CategoryItem> onCategoryTap;

  const _MainCategoriesGrid({
    required this.categories,
    required this.isArabic,
    required this.onCategoryTap,
  });

  IconData _iconForSlug(String slug) {
    final s = slug.toLowerCase();
    if (s.contains('real') || s.contains('propert')) {
      return Icons.apartment_rounded;
    }
    if (s.contains('building') || s.contains('material')) {
      return Icons.engineering_rounded;
    }
    if (s.contains('service')) return Icons.home_repair_service_rounded;
    if (s.contains('appliance') || s.contains('decor')) {
      return Icons.chair_rounded;
    }
    if (s.contains('car') || s.contains('vehicle')) {
      return Icons.directions_car_rounded;
    }
    if (s.contains('fashion') || s.contains('cloth')) {
      return Icons.shopping_bag_rounded;
    }
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3.1,
        ),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final title = isArabic ? cat.nameAr : cat.nameEn;
          return Material(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => onCategoryTap(cat),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: DealOneDesignColors.navy,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconForSlug(cat.slug),
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : DealOneDesignColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.darkTextPrimary : DealOneDesignColors.navy,
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMutedOf(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  final double height;

  const _SectionSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

class _SectionEmptyCard extends StatelessWidget {
  final String message;

  const _SectionEmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: AppColors.textMutedOf(context)),
        ),
      ),
    );
  }
}

class _SectionErrorCard extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _SectionErrorCard({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
