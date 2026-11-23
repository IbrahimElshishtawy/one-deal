import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/maps/data/datasources/category_map_remote_datasource.dart';
import 'package:market_space/features/maps/data/repositories/category_map_repository_impl.dart';
import 'package:market_space/features/maps/domain/entities/location_permission_state.dart';
import 'package:market_space/features/maps/domain/entities/map_bounds.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';
import 'package:market_space/features/maps/domain/entities/map_cluster.dart';
import 'package:market_space/features/maps/domain/entities/map_place_entity.dart';
import 'package:market_space/features/maps/domain/repositories/category_map_repository.dart';
import 'package:market_space/features/maps/presentation/providers/map_location_service.dart';

/// Default map center in Egypt (Cairo/Delta corridor) when no coordinates are yet available.
const LatLng kDefaultEgyptMapCenter = LatLng(30.0444, 31.2357);
const double kDefaultMapZoom = 11.5;

final categoryMapRemoteDataSourceProvider =
    Provider<CategoryMapRemoteDataSource>((ref) {
      return CategoryMapRemoteDataSource(apiClient: ref.watch(apiClientProvider));
    });

final categoryMapRepositoryProvider = Provider<CategoryMapRepository>((ref) {
  return CategoryMapRepositoryImpl(
    remoteDataSource: ref.watch(categoryMapRemoteDataSourceProvider),
  );
});

/// Immutable Riverpod state for a single category's map experience.
/// Preserved per category slug across tab & section transitions.
class CategoryMapState {
  final String categorySlug;
  final MapCategoryConfig config;
  final List<MapPlaceEntity> places;
  final MapPlaceEntity? selectedPlace;
  final String searchQuery;
  final String activeFilterId;
  final bool searchAllCategories;
  final bool verifiedOnly;
  final double? minPrice;
  final double? maxPrice;
  final int? governorateId;
  final int? cityId;
  final LatLng cameraCenter;
  final double cameraZoom;
  final MapBoundingBox? visibleBounds;
  final MapBoundingBox? lastFetchedBounds;
  final bool hasPendingAreaSearch;
  final bool useAlternateTileStyle;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasInitialized;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final Object? error;
  final MapUserLocationState userLocation;

  const CategoryMapState({
    required this.categorySlug,
    required this.config,
    this.places = const [],
    this.selectedPlace,
    this.searchQuery = '',
    this.activeFilterId = 'all',
    this.searchAllCategories = false,
    this.verifiedOnly = false,
    this.minPrice,
    this.maxPrice,
    this.governorateId,
    this.cityId,
    this.cameraCenter = kDefaultEgyptMapCenter,
    this.cameraZoom = kDefaultMapZoom,
    this.visibleBounds,
    this.lastFetchedBounds,
    this.hasPendingAreaSearch = false,
    this.useAlternateTileStyle = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasInitialized = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.error,
    this.userLocation = const MapUserLocationState(),
  });

  bool get hasMore => currentPage < totalPages;

  int get activeFilterCount {
    var count = 0;
    if (activeFilterId != 'all') count++;
    if (verifiedOnly) count++;
    if (searchAllCategories) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (governorateId != null || cityId != null) count++;
    return count;
  }

  /// Places strictly isolated to the current category (unless user opted into
  /// [searchAllCategories]) and matching client-side verified filter.
  List<MapPlaceEntity> get filteredPlaces {
    return places.where((place) {
      if (verifiedOnly && !place.isVerified) {
        return false;
      }
      if (!searchAllCategories && !belongsToActiveCategory(place)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  /// Places that have real valid GPS coordinates from the backend.
  List<MapPlaceEntity> get mappablePlaces =>
      filteredPlaces.where((p) => p.hasCoordinates).toList(growable: false);

  /// Mappable places strictly inside the current visible bounding box (when known),
  /// preventing off-screen markers from cluttering the map.
  List<MapPlaceEntity> get inBoundsMappablePlaces {
    final bounds = visibleBounds;
    if (bounds == null) return mappablePlaces;
    return mappablePlaces
        .where((p) => bounds.contains(p.latitude!, p.longitude!))
        .toList(growable: false);
  }

  /// Clustered markers for the current visible viewport and zoom level.
  List<MapMarkerCluster> get visibleClusters => MapClusterEngine.cluster(
    places: inBoundsMappablePlaces,
    zoom: cameraZoom,
  );

  /// Places returned by backend that do not yet carry exact GPS coordinates.
  List<MapPlaceEntity> get unmappedPlaces =>
      filteredPlaces.where((p) => !p.hasCoordinates).toList(growable: false);

  /// Verifies a place does not belong to one of the OTHER 5 top-level categories.
  bool belongsToActiveCategory(MapPlaceEntity place) {
    final rawSlug = place.categorySlug.trim().toLowerCase().replaceAll('_', '-');
    if (rawSlug.isEmpty) return true;
    if (rawSlug == categorySlug) return true;

    // Reject if the place explicitly matches another top-level section slug.
    for (final otherSlug in MapCategoryRegistry.allSixSlugs) {
      if (otherSlug == categorySlug) continue;
      if (rawSlug == otherSlug || rawSlug.startsWith('$otherSlug-')) {
        return false;
      }
    }
    return true;
  }

  CategoryMapState copyWith({
    List<MapPlaceEntity>? places,
    MapPlaceEntity? selectedPlace,
    bool clearSelectedPlace = false,
    String? searchQuery,
    String? activeFilterId,
    bool? searchAllCategories,
    bool? verifiedOnly,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    int? governorateId,
    bool clearGovernorateId = false,
    int? cityId,
    bool clearCityId = false,
    LatLng? cameraCenter,
    double? cameraZoom,
    MapBoundingBox? visibleBounds,
    MapBoundingBox? lastFetchedBounds,
    bool? hasPendingAreaSearch,
    bool? useAlternateTileStyle,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasInitialized,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    Object? error,
    bool clearError = false,
    MapUserLocationState? userLocation,
  }) {
    return CategoryMapState(
      categorySlug: categorySlug,
      config: config,
      places: places ?? this.places,
      selectedPlace: clearSelectedPlace
          ? null
          : (selectedPlace ?? this.selectedPlace),
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilterId: activeFilterId ?? this.activeFilterId,
      searchAllCategories: searchAllCategories ?? this.searchAllCategories,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      governorateId: clearGovernorateId
          ? null
          : (governorateId ?? this.governorateId),
      cityId: clearCityId ? null : (cityId ?? this.cityId),
      cameraCenter: cameraCenter ?? this.cameraCenter,
      cameraZoom: cameraZoom ?? this.cameraZoom,
      visibleBounds: visibleBounds ?? this.visibleBounds,
      lastFetchedBounds: lastFetchedBounds ?? this.lastFetchedBounds,
      hasPendingAreaSearch: hasPendingAreaSearch ?? this.hasPendingAreaSearch,
      useAlternateTileStyle:
          useAlternateTileStyle ?? this.useAlternateTileStyle,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasInitialized: hasInitialized ?? this.hasInitialized,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      error: clearError ? null : (error ?? this.error),
      userLocation: userLocation ?? this.userLocation,
    );
  }
}

class CategoryMapController extends StateNotifier<CategoryMapState> {
  final CategoryMapRepository repository;
  final MapLocationService locationService;
  Timer? _searchDebounce;
  int _requestSequence = 0;

  CategoryMapController({
    required String categorySlug,
    required this.repository,
    required this.locationService,
  }) : super(
         CategoryMapState(
           categorySlug: MapCategoryRegistry.normalizeSlug(categorySlug),
           config: MapCategoryRegistry.forSlug(categorySlug),
         ),
       );

  @override
  void dispose() {
    _searchDebounce?.cancel();
    repository.cancelInFlight(state.categorySlug);
    super.dispose();
  }

  /// Loads initial places once per category, preserving state on subsequent visits.
  Future<void> ensureInitialized({MapPlaceEntity? focusedPlace}) async {
    if (focusedPlace != null) {
      final merged = <MapPlaceEntity>[
        focusedPlace,
        ...state.places.where((p) => p.id != focusedPlace.id),
      ];
      state = state.copyWith(
        places: merged,
        selectedPlace: focusedPlace,
        cameraCenter: focusedPlace.point ?? state.cameraCenter,
        cameraZoom: focusedPlace.hasCoordinates ? 14.0 : state.cameraZoom,
      );
    }

    if (state.hasInitialized && state.places.isNotEmpty) {
      return;
    }
    await fetchPlaces(resetPage: true);
  }

  /// Debounced search query update (450ms) that cancels superseded requests.
  void setSearchQuery(String query) {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      fetchPlaces(resetPage: true);
    });
  }

  /// Immediate search submit (e.g. keyboard Done button).
  Future<void> submitSearch(String query) async {
    _searchDebounce?.cancel();
    state = state.copyWith(searchQuery: query);
    await fetchPlaces(resetPage: true);
  }

  Future<void> selectQuickFilter(String filterId) async {
    if (filterId == state.activeFilterId) return;
    final option = state.config.quickFilters.firstWhere(
      (f) => f.id == filterId,
      orElse: () => state.config.quickFilters.first,
    );
    state = state.copyWith(
      activeFilterId: option.id,
      verifiedOnly: option.verifiedOnly ?? false,
      clearSelectedPlace: true,
    );
    await fetchPlaces(resetPage: true);
  }

  Future<void> toggleSearchAllCategories(bool value) async {
    if (value == state.searchAllCategories) return;
    state = state.copyWith(
      searchAllCategories: value,
      clearSelectedPlace: true,
    );
    await fetchPlaces(resetPage: true);
  }

  Future<void> applyAdvancedFilters({
    bool? verifiedOnly,
    bool? searchAllCategories,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    int? governorateId,
    bool clearGovernorateId = false,
    int? cityId,
    bool clearCityId = false,
  }) async {
    state = state.copyWith(
      verifiedOnly: verifiedOnly ?? state.verifiedOnly,
      searchAllCategories: searchAllCategories ?? state.searchAllCategories,
      minPrice: minPrice,
      clearMinPrice: clearMinPrice,
      maxPrice: maxPrice,
      clearMaxPrice: clearMaxPrice,
      governorateId: governorateId,
      clearGovernorateId: clearGovernorateId,
      cityId: cityId,
      clearCityId: clearCityId,
      clearSelectedPlace: true,
    );
    await fetchPlaces(resetPage: true);
  }

  Future<void> resetFilters() async {
    _searchDebounce?.cancel();
    state = state.copyWith(
      searchQuery: '',
      activeFilterId: 'all',
      searchAllCategories: false,
      verifiedOnly: false,
      clearMinPrice: true,
      clearMaxPrice: true,
      clearGovernorateId: true,
      clearCityId: true,
      clearSelectedPlace: true,
      hasPendingAreaSearch: false,
    );
    await fetchPlaces(resetPage: true);
  }

  /// Selects a marker WITHOUT reloading the map or re-querying the backend.
  void selectPlace(MapPlaceEntity? place) {
    if (place == null) {
      state = state.copyWith(clearSelectedPlace: true);
    } else {
      state = state.copyWith(selectedPlace: place);
    }
  }

  void toggleTileStyle() {
    state = state.copyWith(
      useAlternateTileStyle: !state.useAlternateTileStyle,
    );
  }

  /// Tracks camera movement without triggering an API call on every small pan.
  /// Shows "Search this area" CTA only after a meaningful viewport shift.
  void onCameraChanged({
    required LatLng center,
    required double zoom,
    MapBoundingBox? bounds,
  }) {
    final movedSignificantly =
        bounds != null &&
        bounds.hasMovedSignificantlyFrom(state.lastFetchedBounds);
    state = state.copyWith(
      cameraCenter: center,
      cameraZoom: zoom,
      visibleBounds: bounds ?? state.visibleBounds,
      hasPendingAreaSearch:
          state.hasInitialized &&
          (movedSignificantly || state.hasPendingAreaSearch),
    );
  }

  /// Explicitly searches within the currently visible geographic bounding box.
  Future<void> searchInVisibleArea() async {
    state = state.copyWith(hasPendingAreaSearch: false);
    await fetchPlaces(resetPage: true, useVisibleBounds: true);
  }

  /// Requests user's current location ONLY after explicit tap + rationale consent.
  Future<MapLocationRequestResult> requestCurrentLocation({
    required bool consentedToNearbySearch,
  }) async {
    state = state.copyWith(
      userLocation: state.userLocation.copyWith(
        status: MapLocationPermissionStatus.requesting,
        clearMessage: true,
      ),
    );

    final result = await locationService.requestCurrentLocation();
    if (!mounted) return result;

    if (result.status == MapLocationPermissionStatus.granted &&
        result.coordinates != null) {
      state = state.copyWith(
        cameraCenter: result.coordinates!,
        cameraZoom: 13.5,
        userLocation: MapUserLocationState(
          status: MapLocationPermissionStatus.granted,
          coordinates: result.coordinates,
          userConsentedToShareWithBackend: consentedToNearbySearch,
        ),
      );
      if (consentedToNearbySearch) {
        await fetchPlaces(resetPage: true, useUserLocation: true);
      }
    } else {
      state = state.copyWith(
        userLocation: MapUserLocationState(
          status: result.status,
          coordinates: null,
          userConsentedToShareWithBackend: false,
          message: result.messageAr,
        ),
      );
    }
    return result;
  }

  Future<void> fetchPlaces({
    bool resetPage = true,
    bool useVisibleBounds = false,
    bool useUserLocation = false,
  }) async {
    final nextPage = resetPage ? 1 : state.currentPage + 1;
    if (!resetPage && (state.isLoadingMore || !state.hasMore)) {
      return;
    }

    final seq = ++_requestSequence;
    if (resetPage) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    }

    final activeFilter = state.config.quickFilters.firstWhere(
      (f) => f.id == state.activeFilterId,
      orElse: () => state.config.quickFilters.first,
    );

    double? centerLat;
    double? centerLng;
    double? radiusKm;

    if (useUserLocation &&
        state.userLocation.hasLocation &&
        state.userLocation.userConsentedToShareWithBackend) {
      centerLat = state.userLocation.coordinates!.latitude;
      centerLng = state.userLocation.coordinates!.longitude;
      radiusKm = 25.0;
    } else if (useVisibleBounds && state.visibleBounds != null) {
      centerLat = state.visibleBounds!.center.latitude;
      centerLng = state.visibleBounds!.center.longitude;
      radiusKm = state.visibleBounds!.radiusKm;
    }

    final query = MapPlacesQuery(
      categorySlug: state.categorySlug,
      searchAllCategories: state.searchAllCategories,
      query: state.searchQuery,
      listingKind: activeFilter.listingKind,
      condition: activeFilter.condition,
      featuredOnly: activeFilter.featuredOnly ?? false,
      verifiedOnly: state.verifiedOnly,
      minPrice: state.minPrice,
      maxPrice: state.maxPrice,
      governorateId: state.governorateId,
      cityId: state.cityId,
      centerLat: centerLat,
      centerLng: centerLng,
      radiusKm: radiusKm,
      page: nextPage,
      limit: 40,
    );

    try {
      final result = await repository.fetchPlaces(
        requestScopeKey: state.categorySlug,
        query: query,
      );

      if (!mounted || seq != _requestSequence) return;

      final combined = resetPage
          ? _mergeSelectedIfNeeded(result.items, state.selectedPlace)
          : _dedupePlaces([...state.places, ...result.items]);

      LatLng nextCenter = state.cameraCenter;
      if (resetPage &&
          !state.hasInitialized &&
          state.selectedPlace == null &&
          !useVisibleBounds &&
          !useUserLocation) {
        final firstWithCoords = combined.where((p) => p.hasCoordinates).firstOrNull;
        if (firstWithCoords != null) {
          nextCenter = firstWithCoords.point!;
        }
      }

      state = state.copyWith(
        places: combined,
        cameraCenter: nextCenter,
        lastFetchedBounds: useVisibleBounds
            ? state.visibleBounds
            : state.lastFetchedBounds,
        hasPendingAreaSearch: false,
        isLoading: false,
        isLoadingMore: false,
        hasInitialized: true,
        currentPage: result.page,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        clearError: true,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return;
      }
      if (!mounted || seq != _requestSequence) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasInitialized: true,
        error: e,
      );
    } catch (e) {
      if (!mounted || seq != _requestSequence) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasInitialized: true,
        error: e,
      );
    }
  }

  List<MapPlaceEntity> _mergeSelectedIfNeeded(
    List<MapPlaceEntity> fetched,
    MapPlaceEntity? selected,
  ) {
    if (selected == null) return fetched;
    final alreadyPresent = fetched.any((p) => p.id == selected.id);
    if (alreadyPresent) return fetched;
    if (!state.searchAllCategories && !state.belongsToActiveCategory(selected)) {
      return fetched;
    }
    return [selected, ...fetched];
  }

  List<MapPlaceEntity> _dedupePlaces(List<MapPlaceEntity> items) {
    final seen = <String>{};
    final result = <MapPlaceEntity>[];
    for (final item in items) {
      if (seen.add(item.id)) {
        result.add(item);
      }
    }
    return result;
  }
}

/// Family provider keyed by canonical section slug (`real-estate`, `services`,
/// `building-materials`, `home-appliances`, `cars`, `fashion`).
/// Kept alive so each category preserves its map state across navigation switches.
final categoryMapControllerProvider = StateNotifierProvider.family<
  CategoryMapController,
  CategoryMapState,
  String
>((ref, rawSlug) {
  final normalized = MapCategoryRegistry.normalizeSlug(rawSlug);
  return CategoryMapController(
    categorySlug: normalized,
    repository: ref.watch(categoryMapRepositoryProvider),
    locationService: ref.watch(mapLocationServiceProvider),
  );
});
