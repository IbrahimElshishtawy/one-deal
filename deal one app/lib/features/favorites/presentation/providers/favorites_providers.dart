import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:market_space/features/favorites/domain/entities/favorite_entity.dart';
import 'package:market_space/features/favorites/domain/repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FavoritesRepositoryImpl(apiClient: apiClient);
});

class FavoritesNotifier extends StateNotifier<AsyncValue<List<FavoriteItem>>> {
  final FavoritesRepository _repository;

  FavoritesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getMyFavorites();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> toggleFavorite(String listingId) async {
    try {
      final result = await _repository.toggleFavorite(listingId);
      // Reload on toggle to maintain consistency with server state
      await loadFavorites();
      return result.isFavorite;
    } catch (_) {
      return false;
    }
  }

  bool isFavorited(String listingId) {
    return state.valueOrNull?.any((f) => f.listing.id == listingId) ?? false;
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<FavoriteItem>>>((ref) {
  final repository = ref.watch(favoritesRepositoryProvider);
  return FavoritesNotifier(repository);
});
