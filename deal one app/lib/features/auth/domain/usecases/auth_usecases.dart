import 'package:market_space/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:market_space/features/auth/domain/entities/auth_session.dart';
import 'package:market_space/features/auth/domain/repositories/auth_repository.dart';

/// Sends a one-time verification code to an Egyptian mobile number.
class SendOtpUseCase {
  final AuthRepository _repository;

  const SendOtpUseCase(this._repository);

  Future<OtpDispatchResult> call(String normalizedPhone) {
    return _repository.sendOtp(normalizedPhone);
  }
}

/// Resends a one-time verification code respecting backend cooldown rules.
class ResendOtpUseCase {
  final AuthRepository _repository;

  const ResendOtpUseCase(this._repository);

  Future<OtpDispatchResult> call(String normalizedPhone) {
    return _repository.resendOtp(normalizedPhone);
  }
}

/// Verifies the 6-digit OTP, optionally persists [pendingFullName], and
/// dispatches real email verification for [pendingEmail] when provided.
class VerifyOtpAndCompleteProfileUseCase {
  final AuthRepository _repository;

  const VerifyOtpAndCompleteProfileUseCase(this._repository);

  Future<AuthSession> call({
    required String normalizedPhone,
    required String code,
    String? pendingFullName,
    String? pendingEmail,
  }) async {
    var session = await _repository.verifyOtp(normalizedPhone, code);
    final trimmedName = pendingFullName?.trim();
    if (trimmedName != null &&
        trimmedName.isNotEmpty &&
        trimmedName != session.user.fullName) {
      try {
        final updatedUser = await _repository.updateProfile(
          fullName: trimmedName,
        );
        session = session.copyWith(user: updatedUser);
      } catch (_) {
        // Keep authenticated session even if the optional profile name sync fails.
      }
    }

    final trimmedEmail = pendingEmail?.trim().toLowerCase();
    if (trimmedEmail != null &&
        trimmedEmail.isNotEmpty &&
        _repository is AuthRepositoryImpl) {
      try {
        await _repository.requestEmailVerification(trimmedEmail);
        session = session.copyWith(
          user: session.user.copyWith(email: trimmedEmail),
        );
      } catch (_) {
        // Non-blocking: keep authenticated session if email dispatch is rate-limited.
      }
    }

    return session;
  }
}

/// Restores the currently authenticated user profile if tokens exist.
class RestoreAuthUserUseCase {
  final AuthRepository _repository;

  const RestoreAuthUserUseCase(this._repository);

  Future<AuthUser?> call() async {
    final hasToken = await _repository.isAuthenticated();
    if (!hasToken) {
      return null;
    }
    return _repository.fetchCurrentUser();
  }
}

/// Logs out the current session cleanly.
class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  Future<void> call() => _repository.logout();
}
