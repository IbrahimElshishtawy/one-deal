import 'package:market_space/features/locations/domain/entities/location_entity.dart';

abstract class LocationsRepository {
  /// Fetches all governorates with embedded cities
  Future<List<GovernorateEntity>> getGovernorates({bool forceRefresh = false});

  /// Fetches areas for a specific city
  Future<List<AreaEntity>> getAreasForCity(int cityId, {bool forceRefresh = false});
}
