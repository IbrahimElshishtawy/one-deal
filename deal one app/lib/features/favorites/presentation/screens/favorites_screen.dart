import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/navigation/presentation/widgets/deal_one_navigation_shell.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/accounts/presentation/widgets/profile_bottom_nav.dart';
import 'package:market_space/features/favorites/domain/entities/favorite_entity.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/shared/widgets/app_loading_indicator.dart';

enum _FavoritesFilter { all, forSale, forRent }

/// Favorites Screen matching `Favorite Items.png`.
/// Connected to `favoritesProvider` (`GET /favorites`, `POST /favorites/:id/toggle`).
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  _FavoritesFilter _selectedFilter = _FavoritesFilter.all;

  bool _isRentListing(FavoriteItem fav) {
    final kind = fav.listing.listingKind.toLowerCase();
    final slug = fav.listing.categorySlug.toLowerCase();
    final title = fav.listing.title.toLowerCase();
    return kind == 'rent' ||
        slug.contains('rent') ||
        title.contains('إيجار') ||
        title.contains('ايجار');
  }

  List<FavoriteItem> _applyFilter(List<FavoriteItem> all) {
    return switch (_selectedFilter) {
      _FavoritesFilter.all => all,
      _FavoritesFilter.forSale => all.where((f) => !_isRentListing(f)).toList(),
      _FavoritesFilter.forRent => all.where(_isRentListing).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final insideShell = DealOneNavigationShellScope.isInsideShell(context);
    final favoritesState = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      bottomNavigationBar: insideShell
          ? null
          : const ProfileBottomNav(activeIndex: 1),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: DealOneTokens.navy,
          onRefresh: () async {
            await ref.read(favoritesProvider.notifier).loadFavorites();
          },
          child: favoritesState.when(
            loading: () => const Center(child: DealOneDotLoader(dotSize: 9)),
            error: (err, _) => DealOneErrorStateView(
              error: err,
              onRetry: () =>
                  ref.read(favoritesProvider.notifier).loadFavorites(),
            ),
            data: (favorites) {
              final filtered = _applyFilter(favorites);
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: DealOneSubPageHeader(
                      title: isArabic ? 'المفضلة' : 'Favorites',
                      showBackButton: Navigator.of(context).canPop(),
                    ),
                  ),

                  // Filter Chips Row ("الكل (N)", "عقارات للبيع", "عقارات للإيجار")
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          _FavoritesFilterChip(
                            label: isArabic ? 'الكل' : 'All',
                            badgeCount: favorites.length,
                            isSelected: _selectedFilter == _FavoritesFilter.all,
                            onTap: () => setState(
                              () => _selectedFilter = _FavoritesFilter.all,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _FavoritesFilterChip(
                            label: isArabic ? 'عقارات للبيع' : 'For Sale',
                            isSelected:
                                _selectedFilter == _FavoritesFilter.forSale,
                            onTap: () => setState(
                              () => _selectedFilter = _FavoritesFilter.forSale,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _FavoritesFilterChip(
                            label: isArabic ? 'عقارات للإيجار' : 'For Rent',
                            isSelected:
                                _selectedFilter == _FavoritesFilter.forRent,
                            onTap: () => setState(
                              () => _selectedFilter = _FavoritesFilter.forRent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: DealOneEmptyStateView(
                        icon: Icons.favorite_border_rounded,
                        title: isArabic
                            ? 'لا توجد إعلانات مفضلة بعد'
                            : 'No Saved Listings Yet',
                        description: isArabic
                            ? 'احفظ العقارات والمنتجات التي تعجبك للرجوع إليها بسهولة في أي وقت.'
                            : 'Tap the heart icon on any listing to save it here.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xxxl,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final fav = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: _FavoritePropertyCard(
                                favorite: fav,
                                isRent: _isRentListing(fav),
                                isArabic: isArabic,
                                onTap: () =>
                                    context.push('/listings/${fav.listing.id}'),
                                onToggleFavorite: () => ref
                                    .read(favoritesProvider.notifier)
                                    .toggleFavorite(fav.listing.id),
                              ),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FavoritesFilterChip extends StatelessWidget {
  final String label;
  final int? badgeCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _FavoritesFilterChip({
    required this.label,
    this.badgeCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Material(
      color: isSelected
          ? DealOneTokens.navy
          : (isDark ? AppColors.darkSurface : Colors.white),
      borderRadius: AppRadii.full,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.full,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadii.full,
            border: Border.all(
              color: isSelected
                  ? DealOneTokens.navy
                  : DealOneTokens.cardBorderOf(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : DealOneTokens.textPrimaryOf(context),
                ),
              ),
              if (badgeCount != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB45309),
                    borderRadius: AppRadii.full,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritePropertyCard extends StatelessWidget {
  final FavoriteItem favorite;
  final bool isRent;
  final bool isArabic;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _FavoritePropertyCard({
    required this.favorite,
    required this.isRent,
    required this.isArabic,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final item = favorite.listing;
    final isDark = AppColors.isDark(context);
    final formattedPrice = intl.NumberFormat('#,##0').format(item.price);
    final currencyLabel = item.currency.toUpperCase() == 'EGP'
        ? (isArabic ? 'ج.م' : 'EGP')
        : item.currency;
    final priceLine = isRent
        ? '$formattedPrice $currencyLabel / ${isArabic ? 'شهر' : 'mo'}'
        : '$formattedPrice $currencyLabel';
    final categoryTag = isRent
        ? (isArabic ? 'عقارات للإيجار' : 'For Rent')
        : (isArabic ? 'عقارات للبيع' : 'For Sale');
    final locationText = [
      if (item.cityNameAr.isNotEmpty) item.cityNameAr,
      if (item.governorateNameAr.isNotEmpty &&
          item.governorateNameAr != item.cityNameAr)
        item.governorateNameAr,
    ].join(' - ');

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
            border: Border.all(color: DealOneTokens.cardBorderOf(context)),
            boxShadow: DealOneTokens.cardShadow(context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Thumbnail
              ClipRRect(
                borderRadius: AppRadii.md,
                child: item.primaryImageUrl != null &&
                        item.primaryImageUrl!.isNotEmpty
                    ? Image.network(
                        item.primaryImageUrl!,
                        width: 102,
                        height: 98,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _FallbackThumb(),
                      )
                    : _FallbackThumb(),
              ),
              const SizedBox(width: AppSpacing.md),

              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceElevated
                                : const Color(0xFFEFF4FF),
                            borderRadius: AppRadii.full,
                          ),
                          child: Text(
                            categoryTag,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: DealOneTokens.textPrimaryOf(context),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onToggleFavorite,
                          borderRadius: AppRadii.full,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFF92400E),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                    if (locationText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: DealOneTokens.textSecondaryOf(context),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              locationText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: DealOneTokens.textSecondaryOf(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      priceLine,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD97706),
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
  }
}

class _FallbackThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 102,
      height: 98,
      color: AppColors.surfaceSecondaryOf(context),
      child: Icon(
        Icons.home_work_outlined,
        color: AppColors.textMutedOf(context),
        size: 32,
      ),
    );
  }
}
