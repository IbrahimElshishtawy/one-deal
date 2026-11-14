import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/errors/app_exception.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/security/session_state.dart';
import 'package:market_space/core/security/token_provider.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/core/storage/secure_storage_service.dart';
import 'package:market_space/core/storage/storage_keys.dart';
import 'package:market_space/features/auth/application/state/auth_states.dart';
import 'package:market_space/features/auth/domain/entities/auth_session.dart';
import 'package:market_space/features/auth/domain/repositories/auth_repository.dart';
import 'package:market_space/features/auth/presentation/providers/auth_providers.dart';

class FakeAuthRepository implements AuthRepository {
  OtpDispatchResult nextSendResult = const OtpDispatchResult(
    cooldownSeconds: 60,
    otpExpirySeconds: 180,
  );
  OtpDispatchResult nextResendResult = const OtpDispatchResult(
    cooldownSeconds: 60,
    otpExpirySeconds: 180,
  );
  Object? nextSendError;
  Object? nextVerifyError;
  Object? nextResendError;

  String? lastSendPhone;
  String? lastVerifiedPhone;
  String? lastVerifiedCode;
  String? lastUpdatedFullName;
  bool logoutCalled = false;

  final TokenProvider tokenProvider;

  AuthUser currentUser = const AuthUser(
    id: 'user_1',
    phone: '+201012345678',
    fullName: 'مستخدم 5678',
    isPhoneVerified: true,
  );

  FakeAuthRepository(this.tokenProvider);

  @override
  Future<OtpDispatchResult> sendOtp(String phone) async {
    lastSendPhone = phone;
    if (nextSendError != null) throw nextSendError!;
    return nextSendResult;
  }

  @override
  Future<OtpDispatchResult> resendOtp(String phone) async {
    lastSendPhone = phone;
    if (nextResendError != null) throw nextResendError!;
    return nextResendResult;
  }

  @override
  Future<AuthSession> verifyOtp(String phone, String code) async {
    lastVerifiedPhone = phone;
    lastVerifiedCode = code;
    if (nextVerifyError != null) throw nextVerifyError!;
    await tokenProvider.saveTokens(
      accessToken: 'access_jwt_123',
      refreshToken: 'refresh_opaque_456',
    );
    return AuthSession(
      accessToken: 'access_jwt_123',
      refreshToken: 'refresh_opaque_456',
      user: currentUser,
    );
  }

  @override
  Future<AuthUser> updateProfile({required String fullName}) async {
    lastUpdatedFullName = fullName;
    currentUser = currentUser.copyWith(fullName: fullName);
    return currentUser;
  }

  @override
  Future<AuthUser?> fetchCurrentUser() async {
    if (!await isAuthenticated()) return null;
    return currentUser;
  }

  @override
  Future<AuthSession> loginWithPassword(String phone, String password) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    await tokenProvider.clearTokens();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await tokenProvider.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

class InMemoryTokenProvider implements TokenProvider {
  String? _access;
  String? _refresh;

  @override
  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
  }

  @override
  Future<String?> getAccessToken() async => _access;

  @override
  Future<String?> getRefreshToken() async => _refresh;

  @override
  Future<bool> hasValidToken() async => _access != null && _access!.isNotEmpty;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
  }
}

void main() {
  late InMemoryPreferencesService prefs;
  late InMemorySecureStorageService secureStorage;
  late InMemoryTokenProvider tokens;
  late FakeAuthRepository repo;

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        preferencesServiceProvider.overrideWithValue(prefs),
        secureStorageServiceProvider.overrideWithValue(secureStorage),
        tokenProvider.overrideWithValue(tokens),
        authRepositoryProvider.overrideWithValue(repo),
        otpAutoTimerEnabledProvider.overrideWithValue(false),
      ],
    );
  }

  setUp(() {
    prefs = InMemoryPreferencesService();
    secureStorage = InMemorySecureStorageService();
    tokens = InMemoryTokenProvider();
    repo = FakeAuthRepository(tokens);
  });

  group('OnboardingController', () {
    test('advances pages and persists onboardingCompleted', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(onboardingControllerProvider.notifier);
      expect(container.read(onboardingControllerProvider).currentPage, 0);

      expect(await notifier.advanceOrComplete(), isFalse);
      expect(container.read(onboardingControllerProvider).currentPage, 1);

      expect(await notifier.advanceOrComplete(), isFalse);
      expect(container.read(onboardingControllerProvider).currentPage, 2);

      expect(await notifier.advanceOrComplete(), isTrue);
      expect(container.read(onboardingControllerProvider).isCompleted, isTrue);
      expect(await prefs.getBool(StorageKeys.onboardingCompleted), isTrue);
    });
  });

  group('SignUpController & LoginController', () {
    test(
      'SignUpController validates fields and dispatches normalized phone',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        final notifier = container.read(signUpControllerProvider.notifier);
        expect(await notifier.submit(), isNull);
        var state = container.read(signUpControllerProvider);
        expect(state.fullNameError, isNotNull);
        expect(state.phoneError, isNotNull);

        notifier.updateFullName('  أحمد   طارق ');
        notifier.updatePhone('01012345678');
        final pending = await notifier.submit();

        expect(pending, isNotNull);
        expect(pending!.normalizedPhone, '+201012345678');
        expect(pending.pendingFullName, 'أحمد طارق');
        expect(pending.flowMode, AuthFlowMode.signUp);
        expect(repo.lastSendPhone, '+201012345678');
      },
    );

    test(
      'LoginController validates phone and maps rate-limit errors',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        final notifier = container.read(loginControllerProvider.notifier);
        notifier.updatePhone('01312345678');
        expect(await notifier.submit(), isNull);
        expect(container.read(loginControllerProvider).phoneError, isNotNull);

        repo.nextSendError = const RateLimitException(
          message: 'Too many OTP requests',
        );
        notifier.updatePhone('01112345678');
        expect(await notifier.submit(), isNull);
        expect(container.read(loginControllerProvider).submitError, isNotNull);
      },
    );
  });

  group('OtpVerificationController', () {
    const signUpContext = PendingAuthContext(
      normalizedPhone: '+201012345678',
      displayPhone: '+20 101 234 5678',
      pendingFullName: 'أحمد طارق',
      flowMode: AuthFlowMode.signUp,
      cooldownSeconds: 45,
      otpExpirySeconds: 180,
    );

    test('verifies 6-digit OTP, updates profile fullName on SignUp, and authenticates session', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final provider = otpVerificationControllerProvider(signUpContext);
      final notifier = container.read(provider.notifier);

      notifier.updateCode('١٢٣٤٥٦');
      final session = await notifier.verifyCode();

      expect(session, isNotNull);
      expect(repo.lastVerifiedCode, '123456');
      expect(repo.lastUpdatedFullName, 'أحمد طارق');
      expect(session!.user.fullName, 'أحمد طارق');
      expect(container.read(provider).status, OtpStatus.verified);
      expect(
        container.read(sessionProvider).status,
        SessionStatus.authenticated,
      );
      expect(
        await secureStorage.read(StorageKeys.userId),
        equals('user_1'),
      );
    });

    test('handles invalid OTP, max attempts locked state, timer expiration, and resend reset', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final provider = otpVerificationControllerProvider(signUpContext);
      final notifier = container.read(provider.notifier);

      repo.nextVerifyError = const UnauthorizedException(
        message: 'Incorrect OTP code.',
      );
      notifier.updateCode('111111');
      expect(await notifier.verifyCode(), isNull);
      expect(container.read(provider).status, OtpStatus.invalid);
      expect(container.read(provider).failedAttempts, 1);

      repo.nextVerifyError = const UnauthorizedException(
        message: 'Maximum verification attempts exceeded. Please request a new OTP code.',
      );
      notifier.updateCode('222222');
      expect(await notifier.verifyCode(), isNull);
      expect(container.read(provider).status, OtpStatus.locked);

      // Cooldown reaches 0 -> canResend unlocks and resend clears error state
      notifier.advanceSecondsForTest(45);
      expect(container.read(provider).canResend, isTrue);

      final resent = await notifier.resendCode();
      expect(resent, isTrue);
      expect(container.read(provider).status, OtpStatus.initial);
      expect(container.read(provider).code, isEmpty);
      expect(container.read(provider).failedAttempts, 0);

      // Expiry reaches 0 -> status becomes expired
      notifier.advanceSecondsForTest(180);
      expect(container.read(provider).status, OtpStatus.expired);
      expect(container.read(provider).isExpired, isTrue);
    });

    test(
      'SessionNotifier restoreSession and logout manage token and userId',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        await tokens.saveTokens(
          accessToken: 'restored_access',
          refreshToken: 'restored_refresh',
        );
        await secureStorage.write(StorageKeys.userId, 'user_1');

        await container.read(sessionProvider.notifier).restoreSession();
        final restored = container.read(sessionProvider);
        expect(restored.status, SessionStatus.authenticated);
        expect(restored.userId, 'user_1');

        await container.read(authControllerProvider.notifier).logout();
        expect(repo.logoutCalled, isTrue);
        expect(
          container.read(sessionProvider).status,
          SessionStatus.unauthenticated,
        );
        expect(await secureStorage.read(StorageKeys.userId), isNull);
      },
    );
  });
}
