import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/real_estate/data/repositories/reels_repository.dart';
import 'package:market_space/features/real_estate/domain/entities/reel_item_entity.dart';

final reelsRepositoryProvider = Provider<ReelsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReelsRepositoryImpl(apiClient: apiClient);
});

class ReelsFeedState {
  final List<ReelItemEntity> items;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  const ReelsFeedState({
    this.items = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  ReelsFeedState copyWith({
    List<ReelItemEntity>? items,
    String? nextCursor,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return ReelsFeedState(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReelsFeedController extends StateNotifier<ReelsFeedState> {
  final Ref _ref;

  ReelsFeedController(this._ref) : super(const ReelsFeedState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _ref.read(reelsRepositoryProvider).getVideoFeed(
            limit: 10,
          );
      state = state.copyWith(
        items: result.items,
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.nextCursor == null) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _ref.read(reelsRepositoryProvider).getVideoFeed(
            cursor: state.nextCursor,
            limit: 10,
          );
      state = state.copyWith(
        items: [...state.items, ...result.items],
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final reelsFeedControllerProvider =
    StateNotifierProvider.autoDispose<ReelsFeedController, ReelsFeedState>(
  (ref) => ReelsFeedController(ref),
);
