import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:market_space/features/auth/data/mappers/auth_error_mapper.dart';
import 'package:market_space/features/auth/domain/entities/auth_session.dart';
import 'package:market_space/features/auth/domain/usecases/auth_usecases.dart';
import 'package:market_space/features/auth/domain/validators/auth_validators.dart';
import 'package:market_space/features/auth/presentation/providers/auth_providers.dart';
import 'package:market_space/features/auth/application/state/auth_states.dart';

/// Handles Sign Up validation, Egyptian phone normalization, and OTP dispatch.
class SignUpController extends AutoDisposeNotifier<SignUpState> {
  @override
  SignUpState build() {
    return const SignUpState();
  }

  void updateFullName(String value) {
    state = state.copyWith(
      fullName: value,
      clearFullNameError: true,
      clearSubmitError: true,
      clearErrorKind: true,
      clearDeliveryFailure: true,
    );
  }

  void updatePhone(String value) {
    state = state.copyWith(
      phone: value,
      clearPhoneError: true,
      clearSubmitError: true,
      clearErrorKind: true,
      clearDeliveryFailure: true,
    );
  }

  void updateEmail(String value) {
    state = state.copyWith(
      email: value,
      clearEmailError: true,
      clearSubmitError: true,
      clearErrorKind: true,
    );
  }

  Future<PendingAuthContext?> submit({String? redirectTo}) async {
    if (state.isSubmitting) return null;

    final nameErrorCode = FullNameValidator.validateCode(state.fullName);
    final phoneErrorCode = EgyptianPhoneValidator.validateCode(state.phone);
    final nameError = FullNameValidator.validate(state.fullName);
    final phoneError = EgyptianPhoneValidator.validate(state.phone);
    final trimmedEmail = EmailValidator.normalize(state.email);
    final emailError = trimmedEmail.isEmpty
        ? null
        : EmailValidator.validate(trimmedEmail);

    if (nameErrorCode != null ||
        phoneErrorCode != null ||
        emailError != null) {
      state = state.copyWith(
        fullNameError: nameError,
        fullNameErrorCode: nameErrorCode,
        clearFullNameError: nameErrorCode == null,
        phoneError: phoneError,
        phoneErrorCode: phoneErrorCode,
        clearPhoneError: phoneErrorCode == null,
        emailError: emailError,
        clearEmailError: emailError == null,
        clearSubmitError: true,
        clearErrorKind: true,
        clearDeliveryFailure: true,
      );
      return null;
    }

    final normalizedName = FullNameValidator.normalize(state.fullName);
    final normalizedPhone = EgyptianPhoneValidator.normalize(state.phone);
    if (normalizedPhone == null) {
      state = state.copyWith(
        phoneError: 'أدخل رقم موبايل مصري صحيح (مثال: 01012345678)',
        phoneErrorCode: PhoneValidationError.invalidEgyptianMobile,
      );
      return null;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearFullNameError: true,
      clearPhoneError: true,
      clearSubmitError: true,
      clearErrorKind: true,
      clearDeliveryFailure: true,
    );

    try {
      final sendOtp = SendOtpUseCase(ref.read(authRepositoryProvider));
      final dispatchResult = await sendOtp(normalizedPhone);
      final pending = PendingAuthContext(
        normalizedPhone: normalizedPhone,
        displayPhone: EgyptianPhoneValidator.formatForDisplay(normalizedPhone),
        pendingFullName: normalizedName,
        pendingEmail: trimmedEmail.isNotEmpty ? trimmedEmail.toLowerCase() : null,
        flowMode: AuthFlowMode.signUp,
        cooldownSeconds: dispatchResult.cooldownSeconds,
        otpExpirySeconds: dispatchResult.otpExpirySeconds,
        redirectTo: redirectTo,
      );
      state = state.copyWith(isSubmitting: false, pendingContext: pending);
      return pending;
    } catch (error) {
      final feedback = AuthErrorMapper.map(error);
      state = state.copyWith(
        isSubmitting: false,
        submitError: feedback.message,
        errorKind: feedback.kind,
        deliveryFailurePhone: feedback.isDeliveryFailure
            ? EgyptianPhoneValidator.formatForDisplay(normalizedPhone)
            : null,
      );
      return null;
    }
  }

  void clearDeliveryFailure() {
    if (state.hasDeliveryFailure) {
      state = state.copyWith(clearDeliveryFailure: true, clearErrorKind: true);
    }
  }

  void consumePendingContext() {
    if (state.pendingContext != null) {
      state = state.copyWith(clearPendingContext: true);
    }
  }
}
