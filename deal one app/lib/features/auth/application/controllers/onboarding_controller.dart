import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/storage_keys.dart';
import '../state/auth_states.dart';

/// Manages the 3-screen onboarding flow and persists completion locally.
class OnboardingController extends AutoDisposeNotifier<OnboardingState> {
  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  void setPage(int index) {
    final clamped = index.clamp(0, state.totalPages - 1);
    state = state.copyWith(currentPage: clamped);
  }

  Future<bool> advanceOrComplete() async {
    if (!state.isLastPage) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      return false;
    }
    await completeOnboarding();
    return true;
  }

  Future<void> completeOnboarding() async {
    if (state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true);
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setBool(StorageKeys.onboardingCompleted, true);
    state = state.copyWith(isCompleted: true, isSubmitting: false);
  }
}
