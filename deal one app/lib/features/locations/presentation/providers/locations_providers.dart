import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/locations/data/repositories/locations_repository_impl.dart';
import 'package:market_space/features/locations/domain/entities/location_entity.dart';
import 'package:market_space/features/locations/domain/repositories/locations_repository.dart';

final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LocationsRepositoryImpl(apiClient: apiClient);
});

final governoratesProvider = FutureProvider<List<GovernorateEntity>>((ref) async {
  final repository = ref.watch(locationsRepositoryProvider);
  return repository.getGovernorates();
});

final cityAreasFamily = FutureProvider.family<List<AreaEntity>, int>((ref, cityId) async {
  final repository = ref.watch(locationsRepositoryProvider);
  return repository.getAreasForCity(cityId);
});

final selectedGovernorateProvider = StateProvider<GovernorateEntity?>((ref) => null);
final selectedCityProvider = StateProvider<CityEntity?>((ref) => null);
final selectedAreaProvider = StateProvider<AreaEntity?>((ref) => null);
