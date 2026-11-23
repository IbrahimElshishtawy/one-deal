import 'package:market_space/features/maps/data/datasources/category_map_remote_datasource.dart';
import 'package:market_space/features/maps/domain/entities/map_place_entity.dart';
import 'package:market_space/features/maps/domain/repositories/category_map_repository.dart';

class CategoryMapRepositoryImpl implements CategoryMapRepository {
  final CategoryMapRemoteDataSource remoteDataSource;

  CategoryMapRepositoryImpl({required this.remoteDataSource});

  @override
  Future<MapPlacesPage> fetchPlaces({
    required String requestScopeKey,
    required MapPlacesQuery query,
  }) {
    return remoteDataSource.searchMapPlaces(
      requestScopeKey: requestScopeKey,
      query: query,
    );
  }

  @override
  void cancelInFlight(String requestScopeKey) {
    remoteDataSource.cancelInFlight(requestScopeKey);
  }
}
