import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/locations/presentation/providers/locations_providers.dart';
import 'package:market_space/core/cache/price_freshness_service.dart';
import 'package:market_space/core/errors/app_failure.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/marketplace/section_home_models.dart';
import 'package:market_space/core/marketplace/section_home_repository.dart';

/// Immutable active filter state for an individual Section Home.
class SectionFilterState {
  final String? subcategorySlug;
  final String? listingKind;
  final String? condition;
  final double? minPrice;
  final double? maxPrice;
  final String sort;
  final String searchQuery;
  final Map<String, dynamic> dynamicFilters;

  const SectionFilterState({
    this.subcategorySlug,
    this.listingKind,
    this.condition,
    this.minPrice,
    this.maxPrice,
    this.sort = 'newest',
    this.searchQuery = '',
    this.dynamicFilters = const {},
  });

  bool get hasActiveFilters =>
      (subcategorySlug != null && subcategorySlug!.isNotEmpty) ||
      (listingKind != null && listingKind!.isNotEmpty) ||
      (condition != null && condition!.isNotEmpty) ||
      minPrice != null ||
      maxPrice != null ||
      sort != 'newest' ||
      searchQuery.trim().isNotEmpty ||
      dynamicFilters.isNotEmpty;

  int get activeFilterCount {
    int count = 0;
    if (subcategorySlug != null && subcategorySlug!.isNotEmpty) count++;
    if (listingKind != null && listingKind!.isNotEmpty) count++;
    if (condition != null && condition!.isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (sort != 'newest') count++;
    count += dynamicFilters.values
        .where((v) => v != null && v.toString().trim().isNotEmpty)
        .length;
    return count;
  }

  SectionFilterState copyWith({
    String? subcategorySlug,
    bool clearSubcategory = false,
    String? listingKind,
    bool clearListingKind = false,
    String? condition,
    bool clearCondition = false,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    String? sort,
    String? searchQuery,
    Map<String, dynamic>? dynamicFilters,
  }) {
    return SectionFilterState(
      subcategorySlug: clearSubcategory
          ? null
          : (subcategorySlug ?? this.subcategorySlug),
      listingKind: clearListingKind ? null : (listingKind ?? this.listingKind),
      condition: clearCondition ? null : (condition ?? this.condition),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      sort: sort ?? this.sort,
      searchQuery: searchQuery ?? this.searchQuery,
      dynamicFilters: dynamicFilters ?? this.dynamicFilters,
    );
  }
}

class SectionHomeState {
  final SectionHomeFeed? feed;
  final List<ListingItem> listings;
  final String? nextCursor;
  final bool hasMore;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isFiltering;
  final bool isLoadingMore;
  final bool isOfflineFallback;
  final Object? error;
  final Object? listingsError;
  final SectionFilterState filters;

  const SectionHomeState({
    this.feed,
    this.listings = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isInitialLoading = true,
    this.isRefreshing = false,
    this.isFiltering = false,
    this.isLoadingMore = false,
    this.isOfflineFallback = false,
    this.error,
    this.listingsError,
    this.filters = const SectionFilterState(),
  });

  SectionHomeState copyWith({
    SectionHomeFeed? feed,
    List<ListingItem>? listings,
    String? nextCursor,
    bool clearCursor = false,
    bool? hasMore,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isFiltering,
    bool? isLoadingMore,
    bool? isOfflineFallback,
    Object? error,
    bool clearError = false,
    Object? listingsError,
    bool clearListingsError = false,
    SectionFilterState? filters,
  }) {
    return SectionHomeState(
      feed: feed ?? this.feed,
      listings: listings ?? this.listings,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFiltering: isFiltering ?? this.isFiltering,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isOfflineFallback: isOfflineFallback ?? this.isOfflineFallback,
      error: clearError ? null : (error ?? this.error),
      listingsError: clearListingsError
          ? null
          : (listingsError ?? this.listingsError),
      filters: filters ?? this.filters,
    );
  }
}

/// Independent controller for each of the 6 Section Homes.
/// Implements Stale-While-Revalidate, Request Cancellation, Server-Side Filtering,
/// Cursor Pagination, and Batch Price Refresh.
class SectionHomeController extends StateNotifier<SectionHomeState> {
  final String sectionSlug;
  final SectionHomeRepository repository;
  final LivePricesNotifier livePrices;
  final int? governorateId;
  final int? cityId;

  CancelToken? _feedCancelToken;
  CancelToken? _filterCancelToken;

  SectionHomeController({
    required this.sectionSlug,
    required this.repository,
    required this.livePrices,
    this.governorateId,
    this.cityId,
  }) : super(const SectionHomeState(isInitialLoading: true)) {
    loadInitial();
  }

  Future<void> loadInitial({bool forceRefresh = false}) async {
    _feedCancelToken?.cancel('Superseded by newer load');
    _feedCancelToken = CancelToken();

    // 1. Stale-While-Revalidate: emit cached feed immediately with zero flicker
    if (!forceRefresh) {
      final cached = await repository.readCachedSectionHome(
        sectionSlug,
        governorateId: governorateId,
        cityId: cityId,
      );
      if (cached != null && mounted) {
        state = state.copyWith(
          feed: cached,
          listings: cached.latest,
          isInitialLoading: false,
          isRefreshing: true,
          clearError: true,
        );
      }
    } else if (state.feed != null) {
      state = state.copyWith(isRefreshing: true, clearError: true);
    }

    // 2. Revalidate from Backend in background
    try {
      final fresh = await repository.fetchSectionHome(
        sectionSlug,
        governorateId: governorateId,
        cityId: cityId,
        limit: 12,
        cancelToken: _feedCancelToken,
      );
      if (!mounted) return;

      final shouldKeepFiltered = state.filters.hasActiveFilters;
      state = state.copyWith(
        feed: fresh,
        listings: shouldKeepFiltered ? state.listings : fresh.latest,
        hasMore: shouldKeepFiltered ? state.hasMore : fresh.latest.length >= 12,
        nextCursor: shouldKeepFiltered
            ? state.nextCursor
            : (fresh.latest.isNotEmpty
                  ? fresh.latest.last.createdAt?.toIso8601String()
                  : null),
        isInitialLoading: false,
        isRefreshing: false,
        isOfflineFallback: false,
        clearError: true,
      );

      // Trigger authoritative batch price refresh for visible items
      unawaited(
        livePrices.refreshBatch(
          fresh.allListingIds,
          freshnessTtl: Duration(seconds: fresh.priceFreshnessTtlSeconds),
        ),
      );
    } catch (err) {
      if (!mounted) return;
      if (err is DioException && err.type == DioExceptionType.cancel) return;
      final isOffline = err is NetworkFailure;
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        isOfflineFallback: state.feed != null && isOffline,
        error: state.feed == null ? err : null,
      );
    }
  }

  /// Applies server-side filters (cancelling any stale in-flight filter request)
  /// and resets pagination to page 1.
  Future<void> applyFilters(SectionFilterState newFilters) async {
    _filterCancelToken?.cancel('Superseded by new filter state');
    final token = CancelToken();
    _filterCancelToken = token;

    state = state.copyWith(
      filters: newFilters,
      isFiltering: true,
      clearListingsError: true,
      clearCursor: true,
    );

    if (!newFilters.hasActiveFilters && state.feed != null) {
      state = state.copyWith(
        listings: state.feed!.latest,
        hasMore: state.feed!.latest.length >= 12,
        isFiltering: false,
      );
      return;
    }

    try {
      final result = await repository.fetchFilteredSectionListings(
        sectionSlug: sectionSlug,
        subcategorySlug: newFilters.subcategorySlug,
        query: newFilters.searchQuery,
        sort: newFilters.sort,
        governorateId: governorateId,
        cityId: cityId,
        minPrice: newFilters.minPrice,
        maxPrice: newFilters.maxPrice,
        listingKind: newFilters.listingKind,
        condition: newFilters.condition,
        dynamicFilters: newFilters.dynamicFilters,
        limit: 12,
        cancelToken: token,
      );
      if (!mounted || token.isCancelled) return;
      state = state.copyWith(
        listings: result.items,
        nextCursor: result.nextCursor,
        clearCursor: result.nextCursor == null,
        hasMore: result.hasMore,
        isFiltering: false,
        clearListingsError: true,
      );
      unawaited(livePrices.refreshBatch(result.items.map((e) => e.id)));
    } catch (err) {
      if (!mounted || token.isCancelled) return;
      if (err is DioException && err.type == DioExceptionType.cancel) return;
      state = state.copyWith(
        isFiltering: false,
        listingsError: err,
      );
    }
  }

  Future<void> clearFilters() => applyFilters(const SectionFilterState());

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        state.isFiltering ||
        !state.hasMore ||
        state.nextCursor == null) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearListingsError: true);
    try {
      final f = state.filters;
      final result = await repository.fetchFilteredSectionListings(
        sectionSlug: sectionSlug,
        subcategorySlug: f.subcategorySlug,
        query: f.searchQuery,
        sort: f.sort,
        governorateId: governorateId,
        cityId: cityId,
        minPrice: f.minPrice,
        maxPrice: f.maxPrice,
        listingKind: f.listingKind,
        condition: f.condition,
        dynamicFilters: f.dynamicFilters,
        cursor: state.nextCursor,
        limit: 12,
      );
      if (!mounted) return;
      final existingIds = state.listings.map((e) => e.id).toSet();
      final deduped = [
        ...state.listings,
        ...result.items.where((item) => !existingIds.contains(item.id)),
      ];
      state = state.copyWith(
        listings: deduped,
        nextCursor: result.nextCursor,
        clearCursor: result.nextCursor == null,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
      unawaited(livePrices.refreshBatch(result.items.map((e) => e.id)));
    } catch (err) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false, listingsError: err);
    }
  }

  @override
  void dispose() {
    _feedCancelToken?.cancel('Controller disposed');
    _filterCancelToken?.cancel('Controller disposed');
    super.dispose();
  }
}

/// Independent family provider — each of the 6 sections gets its own isolated state!
/// Failure in `cars` NEVER affects `real-estate` or `main_hub`.
final sectionHomeControllerProvider = StateNotifierProvider.family<
    SectionHomeController, SectionHomeState, String>((ref, sectionSlug) {
  final repository = ref.watch(sectionHomeRepositoryProvider);
  final livePrices = ref.watch(livePricesProvider.notifier);
  final gov = ref.watch(selectedGovernorateProvider);
  final city = ref.watch(selectedCityProvider);

  return SectionHomeController(
    sectionSlug: sectionSlug,
    repository: repository,
    livePrices: livePrices,
    governorateId: gov?.id,
    cityId: city?.id,
  );
});
