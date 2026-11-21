import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:market_space/features/activity_hub/application/providers/activity_hub_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';
import 'package:market_space/features/favorites/domain/entities/favorite_entity.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';

final favoritesFilterCategoryProvider =
    StateProvider<MarketplaceSectorCategory>((ref) {
      return MarketplaceSectorCategory.all;
    });

final filteredFavoritesProvider = Provider<AsyncValue<List<FavoriteItem>>>((
  ref,
) {
  final favoritesAsync = ref.watch(favoritesProvider);
  final selectedCategory = ref.watch(favoritesFilterCategoryProvider);
  final query = ref
      .watch(activityHubControllerProvider.select((s) => s.searchQuery))
      .trim()
      .toLowerCase();

  return favoritesAsync.whenData((items) {
    return items.where((fav) {
      final sector = MarketplaceSectorCategory.fromCategorySlug(
        fav.listing.categorySlug,
      );
      if (selectedCategory != MarketplaceSectorCategory.all &&
          sector != selectedCategory) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesTitle = fav.listing.title.toLowerCase().contains(query);
        final matchesSeller = fav.listing.sellerName.toLowerCase().contains(
          query,
        );
        final matchesCat =
            fav.listing.categoryNameAr.toLowerCase().contains(query) ||
            fav.listing.categoryNameEn.toLowerCase().contains(query);
        return matchesTitle || matchesSeller || matchesCat;
      }
      return true;
    }).toList();
  });
});
