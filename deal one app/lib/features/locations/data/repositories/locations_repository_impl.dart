import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/locations/data/dto/location_dto.dart';
import 'package:market_space/features/locations/data/mappers/location_mapper.dart';
import 'package:market_space/features/locations/domain/entities/location_entity.dart';
import 'package:market_space/features/locations/domain/repositories/locations_repository.dart';

class LocationsRepositoryImpl implements LocationsRepository {
  final ApiClient apiClient;
  
  List<GovernorateEntity>? _cachedGovernorates;
  DateTime? _govCacheTime;
  final Map<int, List<AreaEntity>> _cachedAreas = {};
  final Duration _ttl = const Duration(hours: 1);

  LocationsRepositoryImpl({required this.apiClient});

  @override
  Future<List<GovernorateEntity>> getGovernorates({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedGovernorates != null &&
        _govCacheTime != null &&
        now.difference(_govCacheTime!) < _ttl) {
      return _cachedGovernorates!;
    }

    final response = await apiClient.get(ApiEndpoints.governorates);
    final data = response.data;
    
    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    }

    final dtos = items
        .map((e) => GovernorateDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final entities = dtos.map(LocationMapper.toGovernorateEntity).toList();
    _cachedGovernorates = entities;
    _govCacheTime = now;
    return entities;
  }

  @override
  Future<List<AreaEntity>> getAreasForCity(int cityId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedAreas.containsKey(cityId)) {
      return _cachedAreas[cityId]!;
    }

    final response = await apiClient.get(ApiEndpoints.cityAreas(cityId));
    final data = response.data;

    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    }

    final dtos = items
        .map((e) => AreaDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final entities = dtos.map(LocationMapper.toAreaEntity).toList();
    _cachedAreas[cityId] = entities;
    return entities;
  }
}
