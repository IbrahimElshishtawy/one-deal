import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/price_freshness_service.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/marketplace/section_home_models.dart';
import '../../../../core/marketplace/section_home_repository.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../locations/presentation/providers/locations_providers.dart';

class MainHubState {
  final MainHubFeed? feed;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isOfflineFallback;
  final Object? error;

  const MainHubState({
    this.feed,
    this.isInitialLoading = true,
    this.isRefreshing = false,
    this.isOfflineFallback = false,
    this.error,
  });

  MainHubState copyWith({
    MainHubFeed? feed,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isOfflineFallback,
    Object? error,
    bool clearError = false,
  }) {
    return MainHubState(
      feed: feed ?? this.feed,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isOfflineFallback: isOfflineFallback ?? this.isOfflineFallback,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Manages Home 1 — Main Hub with Hybrid Cache (Stale-While-Revalidate),
/// background batch price refresh, and offline graceful fallback.
/// Kept alive across section navigations so returning to Main Hub is instant.
class MainHubController extends StateNotifier<MainHubState> {
  final SectionHomeRepository repository;
  final LivePricesNotifier livePrices;
  final int? governorateId;
  final int? cityId;
  CancelToken? _cancelToken;

  MainHubController({
    required this.repository,
    required this.livePrices,
    this.governorateId,
    this.cityId,
  }) : super(const MainHubState(isInitialLoading: true)) {
    loadInitial();
  }

  Future<void> loadInitial({bool forceRefresh = false}) async {
    _cancelToken?.cancel('Superseded');
    _cancelToken = CancelToken();

    if (!forceRefresh) {
      final cached = await _repository.readCachedMainHub(
        governorateId: _governorateId,
        cityId: _cityId,
      );
      if (cached != null && mounted) {
        state = state.copyWith(
          feed: cached,
          isInitialLoading: false,
          isRefreshing: true,
          clearError: true,
        );
      }
    } else if (state.feed != null) {
      state = state.copyWith(isRefreshing: true, clearError: true);
    }

    try {
      final fresh = await _repository.fetchMainHub(
        governorateId: _governorateId,
        cityId: _cityId,
        limit: 10,
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      state = state.copyWith(
        feed: fresh,
        isInitialLoading: false,
        isRefreshing: false,
        isOfflineFallback: false,
        clearError: true,
      );
      unawaited(
        _livePrices.refreshBatch(
          fresh.allListingIds,
          freshnessTtl: Duration(seconds: fresh.priceFreshnessTtlSeconds),
        ),
      );
    } catch (err) {
      if (!mounted) return;
      if (err is DioException && err.type == DioExceptionType.cancel) return;
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        isOfflineFallback: state.feed != null && err is NetworkFailure,
        error: state.feed == null ? err : null,
      );
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Disposed');
    super.dispose();
  }
}

final mainHubControllerProvider =
    StateNotifierProvider<MainHubController, MainHubState>((ref) {
  final repository = ref.watch(sectionHomeRepositoryProvider);
  final livePrices = ref.watch(livePricesProvider.notifier);
  final gov = ref.watch(selectedGovernorateProvider);
  final city = ref.watch(selectedCityProvider);

  return MainHubController(
    repository: repository,
    livePrices: livePrices,
    governorateId: gov?.id,
    cityId: city?.id,
  );
});
