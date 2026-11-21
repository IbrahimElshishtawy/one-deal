import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/activity_hub/application/providers/activity_hub_provider.dart';
import 'package:market_space/features/activity_hub/application/providers/favorites_hub_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/favorites/favorite_listing_card.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/favorites/favorites_category_filter.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/favorites/favorites_empty_state.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_error_widget.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_loading_widget.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';

class FavoritesTabView extends ConsumerWidget {
  const FavoritesTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalization.of(context);
    final selectedCategory = ref.watch(favoritesFilterCategoryProvider);
    final filteredAsync = ref.watch(filteredFavoritesProvider);
    final query = ref.watch(
      activityHubControllerProvider.select((s) => s.searchQuery),
    );
    final hPad = context.horizontalScreenPadding;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        FavoritesCategoryFilter(
          selectedCategory: selectedCategory,
          onSelected: (cat) =>
              ref.read(favoritesFilterCategoryProvider.notifier).state = cat,
        ),
        Expanded(
          child: filteredAsync.when(
            loading: () => const ActivityLoadingWidget(),
            error: (err, _) => ActivityErrorWidget(
              error: err,
              onRetry: () =>
                  ref.read(favoritesProvider.notifier).loadFavorites(),
            ),
            data: (items) {
              if (items.isEmpty) {
                final isFiltered =
                    selectedCategory != MarketplaceSectorCategory.all ||
                    query.trim().isNotEmpty;
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(favoritesProvider.notifier).loadFavorites(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 40),
                      FavoritesEmptyState(
                        isFiltered: isFiltered,
                        onResetFilters: () {
                          ref
                                  .read(
                                    favoritesFilterCategoryProvider.notifier,
                                  )
                                  .state =
                              MarketplaceSectorCategory.all;
                          ref
                              .read(activityHubControllerProvider.notifier)
                              .clearSearch();
                        },
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(favoritesProvider.notifier).loadFavorites(),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    AppSpacing.md,
                    hPad,
                    AppSpacing.xxl,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final fav = items[index];
                    final sector = MarketplaceSectorCategory.fromCategorySlug(
                      fav.listing.categorySlug,
                    );
                    return FavoriteListingCard(
                      favorite: fav,
                      onOpenListing: () =>
                          context.push('/listings/${fav.listing.id}'),
                      onOpenSection: () => context.push(sector.sectionRoute),
                      onRemoveFavorite: () async {
                        await ref
                            .read(favoritesProvider.notifier)
                            .toggleFavorite(fav.listing.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.favoritesRemovedSuccess)),
                          );
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
