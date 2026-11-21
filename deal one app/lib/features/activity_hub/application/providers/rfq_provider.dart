import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:market_space/features/activity_hub/data/repositories/rfq_repository_impl.dart';
import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';
import 'package:market_space/features/activity_hub/domain/repositories/rfq_repository.dart';

final rfqRepositoryProvider = Provider<RfqRepository>((ref) {
  return RfqRepositoryImpl();
});

class RfqState {
  final AsyncValue<List<RfqRequestEntity>> items;
  final bool isBackendSupported;
  final bool isMutating;
  final bool isRefreshing;
  final Object? mutationError;

  const RfqState({
    this.items = const AsyncValue.loading(),
    this.isBackendSupported = false,
    this.isMutating = false,
    this.isRefreshing = false,
    this.mutationError,
  });

  RfqState copyWith({
    AsyncValue<List<RfqRequestEntity>>? items,
    bool? isBackendSupported,
    bool? isMutating,
    bool? isRefreshing,
    Object? mutationError,
    bool clearMutationError = false,
  }) {
    return RfqState(
      items: items ?? this.items,
      isBackendSupported: isBackendSupported ?? this.isBackendSupported,
      isMutating: isMutating ?? this.isMutating,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      mutationError: clearMutationError
          ? null
          : (mutationError ?? this.mutationError),
    );
  }
}

class RfqNotifier extends StateNotifier<RfqState> {
  final RfqRepository _repository;

  RfqNotifier(this._repository)
    : super(RfqState(isBackendSupported: _repository.isBackendSupported)) {
    loadRfqs();
  }

  Future<void> loadRfqs({bool refresh = false}) async {
    if (refresh && state.items.hasValue) {
      state = state.copyWith(isRefreshing: true, clearMutationError: true);
    } else {
      state = state.copyWith(
        items: const AsyncValue.loading(),
        clearMutationError: true,
      );
    }

    try {
      final list = await _repository.getMyRfqs();
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

  Future<bool> createRfq(CreateRfqPayload payload) async {
    if (state.isMutating) return false;
    state = state.copyWith(isMutating: true, clearMutationError: true);
    try {
      await _repository.createRfq(payload);
      await loadRfqs(refresh: true);
      state = state.copyWith(isMutating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isMutating: false, mutationError: e);
      return false;
    }
  }

  Future<bool> acceptQuotation(String rfqId, String quotationId) async {
    if (state.isMutating) return false;
    state = state.copyWith(isMutating: true, clearMutationError: true);
    try {
      await _repository.acceptQuotation(rfqId, quotationId);
      await loadRfqs(refresh: true);
      state = state.copyWith(isMutating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isMutating: false, mutationError: e);
      return false;
    }
  }

  Future<bool> rejectQuotation(String rfqId, String quotationId) async {
    if (state.isMutating) return false;
    state = state.copyWith(isMutating: true, clearMutationError: true);
    try {
      await _repository.rejectQuotation(rfqId, quotationId);
      await loadRfqs(refresh: true);
      state = state.copyWith(isMutating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isMutating: false, mutationError: e);
      return false;
    }
  }
}

final rfqProvider = StateNotifierProvider<RfqNotifier, RfqState>((ref) {
  final repo = ref.watch(rfqRepositoryProvider);
  return RfqNotifier(repo);
});
