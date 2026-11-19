import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/listings/data/dto/listing_dto.dart';
import 'package:market_space/features/listings/data/repositories/listings_repository_impl.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/listings/domain/repositories/listings_repository.dart';
import 'package:market_space/features/locations/presentation/providers/locations_providers.dart';

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ListingsRepositoryImpl(apiClient: apiClient);
});

final currentFeedFilterProvider = StateProvider<FilterListingsDto>((ref) {
  return const FilterListingsDto();
});

final listingsFeedProvider = FutureProvider<ListingFeed>((ref) async {
  final repository = ref.watch(listingsRepositoryProvider);
  final filter = ref.watch(currentFeedFilterProvider);
  return repository.getListingsFeed(filter);
});

/// Independent Featured Products provider for Home Screen (scoped by selected location/category).
final featuredListingsProvider = FutureProvider<List<ListingItem>>((ref) async {
  final repository = ref.watch(listingsRepositoryProvider);
  final gov = ref.watch(selectedGovernorateProvider);
  final city = ref.watch(selectedCityProvider);
  final filter = ref.watch(currentFeedFilterProvider);
  return repository.getFeaturedListings(
    governorateId: gov?.id,
    cityId: city?.id,
    categorySlug: filter.categorySlug,
    limit: 10,
  );
});

/// Independent Recommended Products provider for Home Screen.
final recommendedListingsProvider = FutureProvider<List<ListingItem>>((ref) async {
  final repository = ref.watch(listingsRepositoryProvider);
  final gov = ref.watch(selectedGovernorateProvider);
  final city = ref.watch(selectedCityProvider);
  final filter = ref.watch(currentFeedFilterProvider);
  return repository.getRecommendedListings(
    governorateId: gov?.id,
    cityId: city?.id,
    categorySlug: filter.categorySlug,
    limit: 8,
  );
});

/// Independent Promotional Hero Banners provider for Home Screen.
final homePromotionsProvider = FutureProvider<List<HomePromotion>>((ref) async {
  final repository = ref.watch(listingsRepositoryProvider);
  return repository.getHomePromotions();
});

class PaginatedListingsState {
  final List<ListingItem> items;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final Object? error;

  const PaginatedListingsState({
    this.items = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.error,
  });

  PaginatedListingsState copyWith({
    List<ListingItem>? items,
    String? nextCursor,
    bool clearCursor = false,
    bool? hasMore,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return PaginatedListingsState(
      items: items ?? this.items,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      hasMore: hasMore ?? this.hasMore,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PaginatedListingsNotifier extends StateNotifier<PaginatedListingsState> {
  final ListingsRepository _repository;
  final FilterListingsDto _baseFilter;

  PaginatedListingsNotifier(this._repository, this._baseFilter)
      : super(const PaginatedListingsState(isLoadingInitial: true)) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = const PaginatedListingsState(isLoadingInitial: true);
    try {
      final feed = await _repository.getListingsFeed(_baseFilter);
      if (!mounted) return;
      state = PaginatedListingsState(
        items: feed.items,
        nextCursor: feed.nextCursor,
        hasMore: feed.hasMore,
        isLoadingInitial: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = PaginatedListingsState(
        isLoadingInitial: false,
        error: e,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.nextCursor == null) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final nextFilter = FilterListingsDto(
        categorySlug: _baseFilter.categorySlug,
        categoryId: _baseFilter.categoryId,
        q: _baseFilter.q,
        sort: _baseFilter.sort,
        governorateId: _baseFilter.governorateId,
        cityId: _baseFilter.cityId,
        minPrice: _baseFilter.minPrice,
        maxPrice: _baseFilter.maxPrice,
        condition: _baseFilter.condition,
        cursor: state.nextCursor,
        limit: _baseFilter.limit,
      );
      final feed = await _repository.getListingsFeed(nextFilter);
      if (!mounted) return;
      state = state.copyWith(
        items: [...state.items, ...feed.items],
        nextCursor: feed.nextCursor,
        clearCursor: feed.nextCursor == null,
        hasMore: feed.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }
}

final paginatedLatestListingsProvider =
    StateNotifierProvider<PaginatedListingsNotifier, PaginatedListingsState>(
  (ref) {
    final repository = ref.watch(listingsRepositoryProvider);
    final baseFilter = ref.watch(currentFeedFilterProvider);
    final gov = ref.watch(selectedGovernorateProvider);
    final city = ref.watch(selectedCityProvider);
    final combinedFilter = FilterListingsDto(
      categorySlug: baseFilter.categorySlug,
      categoryId: baseFilter.categoryId,
      q: baseFilter.q,
      sort: baseFilter.sort,
      governorateId: gov?.id ?? baseFilter.governorateId,
      cityId: city?.id ?? baseFilter.cityId,
      minPrice: baseFilter.minPrice,
      maxPrice: baseFilter.maxPrice,
      condition: baseFilter.condition,
      limit: 12,
    );
    return PaginatedListingsNotifier(repository, combinedFilter);
  },
);

final listingDetailsFamily = FutureProvider.family<ListingItem, String>((ref, id) async {
  final repository = ref.watch(listingsRepositoryProvider);
  return repository.getListingDetails(id);
});

class ContactRevealNotifier extends StateNotifier<AsyncValue<ContactRevealResult?>> {
  final ListingsRepository _repository;

  ContactRevealNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> reveal(String listingId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.revealContact(listingId);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final contactRevealProvider =
    StateNotifierProvider.family<ContactRevealNotifier, AsyncValue<ContactRevealResult?>, String>(
        (ref, listingId) {
  final repository = ref.watch(listingsRepositoryProvider);
  return ContactRevealNotifier(repository);
});
