import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:market_space/features/activity_hub/data/repositories/bookings_repository_impl.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/domain/repositories/bookings_repository.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return BookingsRepositoryImpl();
});

class BookingsState {
  final AsyncValue<List<BookingEntity>> items;
  final BookingCategory? selectedCategory;
  final bool isBackendSupported;
  final bool isMutating;
  final bool isRefreshing;
  final Object? mutationError;

  const BookingsState({
    this.items = const AsyncValue.loading(),
    this.selectedCategory,
    this.isBackendSupported = false,
    this.isMutating = false,
    this.isRefreshing = false,
    this.mutationError,
  });

  BookingsState copyWith({
    AsyncValue<List<BookingEntity>>? items,
    BookingCategory? selectedCategory,
    bool clearCategory = false,
    bool? isBackendSupported,
    bool? isMutating,
    bool? isRefreshing,
    Object? mutationError,
    bool clearMutationError = false,
  }) {
    return BookingsState(
      items: items ?? this.items,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      isBackendSupported: isBackendSupported ?? this.isBackendSupported,
      isMutating: isMutating ?? this.isMutating,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      mutationError: clearMutationError
          ? null
          : (mutationError ?? this.mutationError),
    );
  }
}

class BookingsNotifier extends StateNotifier<BookingsState> {
  final BookingsRepository _repository;

  BookingsNotifier(this._repository)
    : super(BookingsState(isBackendSupported: _repository.isBackendSupported)) {
    loadBookings();
  }

  Future<void> loadBookings({bool refresh = false}) async {
    if (refresh && state.items.hasValue) {
      state = state.copyWith(isRefreshing: true, clearMutationError: true);
    } else {
      state = state.copyWith(
        items: const AsyncValue.loading(),
        clearMutationError: true,
      );
    }

    try {
      final list = await _repository.getBookings();
      state = state.copyWith(
        items: AsyncValue.data(list),
        isRefreshing: false,
      );
    } catch (e, st) {
      state = state.copyWith(
        items: AsyncValue.error(e, st),
        isRefreshing: false,
      );
    }
  }

  void setCategoryFilter(BookingCategory? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  Future<bool> createBooking(CreateBookingPayload payload) async {
    if (state.isMutating) return false;
    state = state.copyWith(isMutating: true, clearMutationError: true);
    try {
      await _repository.createBooking(payload);
      await loadBookings(refresh: true);
      state = state.copyWith(isMutating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isMutating: false, mutationError: e);
      return false;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    if (state.isMutating) return false;
    state = state.copyWith(isMutating: true, clearMutationError: true);
    try {
      await _repository.cancelBooking(bookingId);
      await loadBookings(refresh: true);
      state = state.copyWith(isMutating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isMutating: false, mutationError: e);
      return false;
    }
  }
}

final bookingsProvider = StateNotifierProvider<BookingsNotifier, BookingsState>(
  (ref) {
    final repo = ref.watch(bookingsRepositoryProvider);
    return BookingsNotifier(repo);
  },
);
