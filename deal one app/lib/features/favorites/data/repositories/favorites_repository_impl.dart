import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/favorites/data/dto/favorite_dto.dart';
import 'package:market_space/features/favorites/data/mappers/favorite_mapper.dart';
import 'package:market_space/features/favorites/domain/entities/favorite_entity.dart';
import 'package:market_space/features/favorites/domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final ApiClient apiClient;

  FavoritesRepositoryImpl({required this.apiClient});

  @override
  Future<List<FavoriteItem>> getMyFavorites() async {
    final response = await apiClient.get(ApiEndpoints.favorites);
    final data = response.data;

    List rawList = [];
    if (data is List) {
      rawList = data;
    } else if (data is Map && data['data'] is List) {
      rawList = data['data'] as List;
    }

    final dtos = rawList
        .map((e) => FavoriteItemDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return dtos.map(FavoriteMapper.toEntity).toList();
  }

  @override
  Future<FavoriteToggleResult> toggleFavorite(String listingId) async {
    // Uses the atomic toggle endpoint supported by the backend
    final response = await apiClient.post(ApiEndpoints.favoriteItem(listingId));
    final data = response.data;
    final dto = FavoriteToggleResultDto.fromJson(Map<String, dynamic>.from(data as Map));
    return FavoriteMapper.toToggleResult(dto);
  }

  @override
  Future<void> addFavorite(String listingId) async {
    await apiClient.post(ApiEndpoints.favoriteItem(listingId));
  }

  @override
  Future<void> removeFavorite(String listingId) async {
    await apiClient.delete(ApiEndpoints.favoriteItem(listingId));
  }
}
