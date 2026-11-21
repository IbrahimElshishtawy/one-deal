import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:market_space/core/errors/app_failure.dart';
import 'package:market_space/core/errors/error_mapper.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/auth/application/controllers/login_controller.dart';
import 'package:market_space/features/auth/application/controllers/onboarding_controller.dart';
import 'package:market_space/features/auth/application/controllers/otp_verification_controller.dart';
import 'package:market_space/features/auth/application/controllers/sign_up_controller.dart';
import 'package:market_space/features/auth/application/state/auth_states.dart';
import 'package:market_space/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:market_space/features/auth/domain/entities/auth_session.dart';
import 'package:market_space/features/auth/domain/repositories/auth_repository.dart';
import 'package:market_space/features/auth/domain/usecases/auth_usecases.dart';

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
    } catch (error) {
      final failure = ErrorMapper.map(error);
      if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
        await ref.read(sessionProvider.notifier).logout();
      }
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
    try {
      await useCase();
    } finally {
      await ref.read(sessionProvider.notifier).logout();
      state = const AsyncValue.data(null);
    }
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
