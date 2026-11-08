import 'package:market_space/features/favorites/domain/entities/favorite_entity.dart';

abstract class FavoritesRepository {
  Future<List<FavoriteItem>> getMyFavorites();
  Future<FavoriteToggleResult> toggleFavorite(String listingId);
  Future<void> addFavorite(String listingId);
  Future<void> removeFavorite(String listingId);
}
