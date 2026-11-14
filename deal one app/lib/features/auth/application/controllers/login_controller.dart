import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mappers/auth_error_mapper.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/validators/auth_validators.dart';
import '../../presentation/providers/auth_providers.dart';
import '../state/auth_states.dart';

/// Handles Login phone validation, normalization, and OTP dispatch.
class LoginController extends AutoDisposeNotifier<LoginState> {
  @override
  LoginState build() {
    return const LoginState();
  }

  void updatePhone(String value) {
    state = state.copyWith(
      phone: value,
      clearPhoneError: true,
      clearSubmitError: true,
    );
  }

  Future<PendingAuthContext?> submit() async {
    if (state.isSubmitting) return null;

    final phoneError = EgyptianPhoneValidator.validate(state.phone);
    if (phoneError != null) {
      state = state.copyWith(phoneError: phoneError, clearSubmitError: true);
      return null;
    }

    final normalizedPhone = EgyptianPhoneValidator.normalize(state.phone);
    if (normalizedPhone == null) {
      state = state.copyWith(
        phoneError: 'أدخل رقم موبايل مصري صحيح (مثال: 01012345678)',
      );
      return null;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearPhoneError: true,
      clearSubmitError: true,
    );

    try {
      final sendOtp = SendOtpUseCase(ref.read(authRepositoryProvider));
      final dispatchResult = await sendOtp(normalizedPhone);
      final pending = PendingAuthContext(
        normalizedPhone: normalizedPhone,
        displayPhone: EgyptianPhoneValidator.formatForDisplay(normalizedPhone),
        flowMode: AuthFlowMode.login,
        cooldownSeconds: dispatchResult.cooldownSeconds,
        otpExpirySeconds: dispatchResult.otpExpirySeconds,
      );
      state = state.copyWith(isSubmitting: false, pendingContext: pending);
      return pending;
    } catch (error) {
      final feedback = AuthErrorMapper.map(error);
      state = state.copyWith(
        isSubmitting: false,
        submitError: feedback.message,
      );
      return null;
    }
  }

  void consumePendingContext() {
    if (state.pendingContext != null) {
      state = state.copyWith(clearPendingContext: true);
    }
  }
}
