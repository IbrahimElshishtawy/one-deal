import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/auth/data/mappers/auth_error_mapper.dart';
import 'package:market_space/features/auth/domain/entities/auth_session.dart';
import 'package:market_space/features/auth/domain/usecases/auth_usecases.dart';
import 'package:market_space/features/auth/domain/validators/auth_validators.dart';
import 'package:market_space/features/auth/presentation/providers/auth_providers.dart';
import 'package:market_space/features/auth/application/state/auth_states.dart';

/// Controls the OTP countdown timers, 6-digit verification submission,
/// invalid/expired error handling, and cooldown-protected resend flow.
class OtpVerificationController
    extends
        AutoDisposeFamilyNotifier<OtpVerificationState, PendingAuthContext> {
  Timer? _countdownTimer;

  @override
  OtpVerificationState build(PendingAuthContext arg) {
    ref.onDispose(_cancelTimer);
    if (ref.watch(otpAutoTimerEnabledProvider)) {
      _startTimer();
    }
    return OtpVerificationState(
      normalizedPhone: arg.normalizedPhone,
      displayPhone: arg.displayPhone,
      pendingFullName: arg.pendingFullName,
      pendingEmail: arg.pendingEmail,
      flowMode: arg.flowMode,
      redirectTo: arg.redirectTo,
      cooldownRemainingSeconds: arg.cooldownSeconds,
      expiryRemainingSeconds: arg.otpExpirySeconds,
      devOtp: arg.devOtp,
    );
  }

  void _startTimer() {
    _cancelTimer();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickOneSecond();
    });
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _tickOneSecond() {
    if (state.status == OtpStatus.verified) {
      _cancelTimer();
      return;
    }

    final nextCooldown = state.cooldownRemainingSeconds > 0
        ? state.cooldownRemainingSeconds - 1
        : 0;
    final nextExpiry = state.expiryRemainingSeconds > 0
        ? state.expiryRemainingSeconds - 1
        : 0;

    if (nextExpiry == 0 && state.status != OtpStatus.expired) {
      state = state.copyWith(
        cooldownRemainingSeconds: nextCooldown,
        expiryRemainingSeconds: 0,
        status: OtpStatus.expired,
        errorKind: AuthErrorKind.expiredOtp,
        errorMessage: 'انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد',
      );
      return;
    }

    if (nextCooldown != state.cooldownRemainingSeconds ||
        nextExpiry != state.expiryRemainingSeconds) {
      state = state.copyWith(
        cooldownRemainingSeconds: nextCooldown,
        expiryRemainingSeconds: nextExpiry,
      );
    }
  }

  /// Exposed for deterministic timer progression in unit/widget tests.
  void advanceSecondsForTest(int seconds) {
    for (var i = 0; i < seconds; i++) {
      _tickOneSecond();
    }
  }

  void updateCode(String rawCode) {
    final normalized = OtpCodeValidator.normalizeDigits(rawCode);
    final clipped = normalized.length > OtpCodeValidator.requiredLength
        ? normalized.substring(0, OtpCodeValidator.requiredLength)
        : normalized;

    final shouldClearError =
        state.status == OtpStatus.invalid ||
        state.status == OtpStatus.networkError ||
        state.status == OtpStatus.serverError ||
        state.status == OtpStatus.rateLimited ||
        state.status == OtpStatus.deliveryFailed;

    state = state.copyWith(
      code: clipped,
      status: shouldClearError ? OtpStatus.initial : state.status,
      clearErrorMessage: shouldClearError,
    );
  }

  /// Clears invalid OTP input and resets status to allow a clean retry.
  void retryAfterError() {
    if (state.isBusy || state.isExpired || state.isLocked) return;
    state = state.copyWith(
      code: '',
      status: OtpStatus.initial,
      clearErrorMessage: true,
    );
  }

  Future<AuthSession?> verifyCode() async {
    if (state.isBusy) return null;

    if (state.isExpired) {
      state = state.copyWith(
        status: OtpStatus.expired,
        errorKind: AuthErrorKind.expiredOtp,
        errorMessage: 'انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد',
      );
      return null;
    }

    if (state.isLocked) {
      return null;
    }

    final validationErrorCode = OtpCodeValidator.validateCode(state.code);
    final validationError = OtpCodeValidator.validate(state.code);
    if (validationErrorCode != null) {
      state = state.copyWith(
        status: OtpStatus.invalid,
        validationErrorCode: validationErrorCode,
        errorMessage: validationError,
      );
      return null;
    }

    state = state.copyWith(
      status: OtpStatus.verifying,
      clearErrorMessage: true,
    );

    try {
      final useCase = VerifyOtpAndCompleteProfileUseCase(
        ref.read(authRepositoryProvider),
      );
      final session = await useCase(
        normalizedPhone: state.normalizedPhone,
        code: state.code,
        pendingFullName: state.pendingFullName,
        pendingEmail: state.pendingEmail,
      );

      _cancelTimer();
      ref
          .read(sessionProvider.notifier)
          .setAuthenticated(userId: session.user.id);
      ref
          .read(authControllerProvider.notifier)
          .setAuthenticatedUser(session.user);

      state = state.copyWith(
        status: OtpStatus.verified,
        authenticatedSession: session,
        clearErrorMessage: true,
      );
      return session;
    } catch (error) {
      final feedback = AuthErrorMapper.map(error);
      final mappedStatus = _mapErrorKindToOtpStatus(feedback.kind);
      final nextAttempts = mappedStatus == OtpStatus.invalid
          ? state.failedAttempts + 1
          : state.failedAttempts;

      state = state.copyWith(
        status: mappedStatus,
        errorKind: feedback.kind,
        errorMessage: feedback.message,
        failedAttempts: nextAttempts,
        expiryRemainingSeconds: mappedStatus == OtpStatus.expired
            ? 0
            : state.expiryRemainingSeconds,
      );
      return null;
    }
  }

  Future<bool> resendCode() async {
    if (!state.canResend) return false;

    state = state.copyWith(
      status: OtpStatus.resending,
      clearErrorMessage: true,
    );

    try {
      final useCase = ResendOtpUseCase(ref.read(authRepositoryProvider));
      final dispatch = await useCase(state.normalizedPhone);

      state = state.copyWith(
        code: '',
        status: OtpStatus.initial,
        clearErrorMessage: true,
        cooldownRemainingSeconds: dispatch.cooldownSeconds,
        expiryRemainingSeconds: dispatch.otpExpirySeconds,
        failedAttempts: 0,
        devOtp: dispatch.devOtp,
      );

      if (ref.read(otpAutoTimerEnabledProvider)) {
        _startTimer();
      }
      return true;
    } catch (error) {
      final feedback = AuthErrorMapper.map(error);
      final mappedStatus = _mapErrorKindToOtpStatus(feedback.kind);
      state = state.copyWith(
        status: mappedStatus,
        errorKind: feedback.kind,
        errorMessage: feedback.message,
      );
      return false;
    }
  }

  OtpStatus _mapErrorKindToOtpStatus(AuthErrorKind kind) {
    switch (kind) {
      case AuthErrorKind.invalidOtp:
      case AuthErrorKind.validation:
      case AuthErrorKind.invalidPhoneNumber:
        return OtpStatus.invalid;
      case AuthErrorKind.expiredOtp:
        return OtpStatus.expired;
      case AuthErrorKind.maxAttemptsExceeded:
        return OtpStatus.locked;
      case AuthErrorKind.rateLimited:
        return OtpStatus.rateLimited;
      case AuthErrorKind.whatsappUnavailable:
      case AuthErrorKind.otpDeliveryFailed:
        return OtpStatus.deliveryFailed;
      case AuthErrorKind.network:
      case AuthErrorKind.timeout:
        return OtpStatus.networkError;
      case AuthErrorKind.accountNotFound:
      case AuthErrorKind.existingAccount:
      case AuthErrorKind.unauthorizedSession:
      case AuthErrorKind.invalidRefreshToken:
      case AuthErrorKind.server:
      case AuthErrorKind.unexpectedResponse:
        return OtpStatus.serverError;
    }
  }
}
