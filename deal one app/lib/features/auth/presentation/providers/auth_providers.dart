import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../application/controllers/login_controller.dart';
import '../../application/controllers/onboarding_controller.dart';
import '../../application/controllers/otp_verification_controller.dart';
import '../../application/controllers/sign_up_controller.dart';
import '../../application/state/auth_states.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

/// Controls whether the OTP verification periodic countdown timer runs automatically.
final otpAutoTimerEnabledProvider = Provider<bool>((ref) => true);

/// Provides the authentication repository backed by Dio and secure token storage.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final token = ref.watch(tokenProvider);
  return AuthRepositoryImpl(apiClient: apiClient, tokenProvider: token);
});

/// Manages the currently authenticated user profile across the application.
class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final restoreUser = RestoreAuthUserUseCase(repo);
    try {
      return await restoreUser();
    } catch (_) {
      return null;
    }
  }

  Future<void> sendOtp(String phone) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = SendOtpUseCase(ref.read(authRepositoryProvider));
      await useCase(phone);
      return state.valueOrNull;
    });
  }

  Future<void> verifyOtp(
    String phone,
    String code, {
    String? pendingFullName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = VerifyOtpAndCompleteProfileUseCase(
        ref.read(authRepositoryProvider),
      );
      final session = await useCase(
        normalizedPhone: phone,
        code: code,
        pendingFullName: pendingFullName,
      );
      ref
          .read(sessionProvider.notifier)
          .setAuthenticated(userId: session.user.id);
      return session.user;
    });
  }

  void setAuthenticatedUser(AuthUser user) {
    state = AsyncValue.data(user);
  }

  Future<void> refreshProfile() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final user = await repo.fetchCurrentUser();
      state = AsyncValue.data(user);
    } catch (_) {
      // Retain last cached user profile if network refresh is temporarily unavailable.
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final useCase = LogoutUseCase(ref.read(authRepositoryProvider));
    await useCase();
    await ref.read(sessionProvider.notifier).logout();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  () {
    return AuthController();
  },
);

final onboardingControllerProvider =
    AutoDisposeNotifierProvider<OnboardingController, OnboardingState>(() {
      return OnboardingController();
    });

final signUpControllerProvider =
    AutoDisposeNotifierProvider<SignUpController, SignUpState>(() {
      return SignUpController();
    });

final loginControllerProvider =
    AutoDisposeNotifierProvider<LoginController, LoginState>(() {
      return LoginController();
    });

final otpVerificationControllerProvider =
    AutoDisposeNotifierProviderFamily<
      OtpVerificationController,
      OtpVerificationState,
      PendingAuthContext
    >(() {
      return OtpVerificationController();
    });
