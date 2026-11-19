import '../../data/mappers/auth_error_mapper.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/validators/auth_validators.dart';

/// State for the 3-page onboarding carousel.
class OnboardingState {
  final int currentPage;
  final int totalPages;
  final bool isCompleted;
  final bool isSubmitting;

  const OnboardingState({
    this.currentPage = 0,
    this.totalPages = 3,
    this.isCompleted = false,
    this.isSubmitting = false,
  });

  bool get isLastPage => currentPage >= totalPages - 1;

  OnboardingState copyWith({
    int? currentPage,
    int? totalPages,
    bool? isCompleted,
    bool? isSubmitting,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isCompleted: isCompleted ?? this.isCompleted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Form and submission state for the Sign Up screen.
class SignUpState {
  final String fullName;
  final String phone;
  final String? fullNameError;
  final FullNameValidationError? fullNameErrorCode;
  final String? phoneError;
  final PhoneValidationError? phoneErrorCode;
  final String? submitError;
  final AuthErrorKind? errorKind;
  final String? deliveryFailurePhone;
  final bool isSubmitting;
  final PendingAuthContext? pendingContext;

  const SignUpState({
    this.fullName = '',
    this.phone = '',
    this.fullNameError,
    this.fullNameErrorCode,
    this.phoneError,
    this.phoneErrorCode,
    this.submitError,
    this.errorKind,
    this.deliveryFailurePhone,
    this.isSubmitting = false,
    this.pendingContext,
  });

  bool get hasDeliveryFailure =>
      deliveryFailurePhone != null && deliveryFailurePhone!.isNotEmpty;

  SignUpState copyWith({
    String? fullName,
    String? phone,
    String? fullNameError,
    FullNameValidationError? fullNameErrorCode,
    bool clearFullNameError = false,
    String? phoneError,
    PhoneValidationError? phoneErrorCode,
    bool clearPhoneError = false,
    String? submitError,
    bool clearSubmitError = false,
    AuthErrorKind? errorKind,
    bool clearErrorKind = false,
    String? deliveryFailurePhone,
    bool clearDeliveryFailure = false,
    bool? isSubmitting,
    PendingAuthContext? pendingContext,
    bool clearPendingContext = false,
  }) {
    return SignUpState(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      fullNameError: clearFullNameError
          ? null
          : (fullNameError ?? this.fullNameError),
      fullNameErrorCode: clearFullNameError
          ? null
          : (fullNameErrorCode ?? this.fullNameErrorCode),
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
      phoneErrorCode: clearPhoneError
          ? null
          : (phoneErrorCode ?? this.phoneErrorCode),
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      errorKind: clearErrorKind ? null : (errorKind ?? this.errorKind),
      deliveryFailurePhone: clearDeliveryFailure
          ? null
          : (deliveryFailurePhone ?? this.deliveryFailurePhone),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      pendingContext: clearPendingContext
          ? null
          : (pendingContext ?? this.pendingContext),
    );
  }
}

/// Form and submission state for the Login screen.
class LoginState {
  final String phone;
  final String? phoneError;
  final PhoneValidationError? phoneErrorCode;
  final String? submitError;
  final AuthErrorKind? errorKind;
  final String? deliveryFailurePhone;
  final bool isSubmitting;
  final PendingAuthContext? pendingContext;

  const LoginState({
    this.phone = '',
    this.phoneError,
    this.phoneErrorCode,
    this.submitError,
    this.errorKind,
    this.deliveryFailurePhone,
    this.isSubmitting = false,
    this.pendingContext,
  });

  bool get hasDeliveryFailure =>
      deliveryFailurePhone != null && deliveryFailurePhone!.isNotEmpty;

  LoginState copyWith({
    String? phone,
    String? phoneError,
    PhoneValidationError? phoneErrorCode,
    bool clearPhoneError = false,
    String? submitError,
    bool clearSubmitError = false,
    AuthErrorKind? errorKind,
    bool clearErrorKind = false,
    String? deliveryFailurePhone,
    bool clearDeliveryFailure = false,
    bool? isSubmitting,
    PendingAuthContext? pendingContext,
    bool clearPendingContext = false,
  }) {
    return LoginState(
      phone: phone ?? this.phone,
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
      phoneErrorCode: clearPhoneError
          ? null
          : (phoneErrorCode ?? this.phoneErrorCode),
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      errorKind: clearErrorKind ? null : (errorKind ?? this.errorKind),
      deliveryFailurePhone: clearDeliveryFailure
          ? null
          : (deliveryFailurePhone ?? this.deliveryFailurePhone),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      pendingContext: clearPendingContext
          ? null
          : (pendingContext ?? this.pendingContext),
    );
  }
}

/// Explicit visual and behavioral status for the OTP verification screen.
enum OtpStatus {
  initial,
  verifying,
  resending,
  invalid,
  expired,
  locked,
  rateLimited,
  deliveryFailed,
  networkError,
  serverError,
  verified,
}

/// Complete immutable state for the OTP verification step.
class OtpVerificationState {
  final String normalizedPhone;
  final String displayPhone;
  final String? pendingFullName;
  final AuthFlowMode flowMode;
  final String? redirectTo;
  final String code;
  final OtpStatus status;
  final String? errorMessage;
  final AuthErrorKind? errorKind;
  final OtpValidationError? validationErrorCode;
  final int cooldownRemainingSeconds;
  final int expiryRemainingSeconds;
  final int failedAttempts;
  final int maxAttempts;
  final AuthSession? authenticatedSession;

  const OtpVerificationState({
    required this.normalizedPhone,
    required this.displayPhone,
    this.pendingFullName,
    required this.flowMode,
    this.redirectTo,
    this.code = '',
    this.status = OtpStatus.initial,
    this.errorMessage,
    this.errorKind,
    this.validationErrorCode,
    this.cooldownRemainingSeconds = 60,
    this.expiryRemainingSeconds = 180,
    this.failedAttempts = 0,
    this.maxAttempts = 5,
    this.authenticatedSession,
  });

  bool get isVerifying => status == OtpStatus.verifying;
  bool get isResending => status == OtpStatus.resending;
  bool get isBusy => isVerifying || isResending;
  bool get isExpired =>
      status == OtpStatus.expired || expiryRemainingSeconds <= 0;
  bool get isLocked => status == OtpStatus.locked;
  bool get isInvalid => status == OtpStatus.invalid;
  bool get isDeliveryFailed => status == OtpStatus.deliveryFailed;
  bool get hasFieldError =>
      status == OtpStatus.invalid ||
      status == OtpStatus.expired ||
      status == OtpStatus.locked;
  bool get hasBannerError =>
      (errorMessage != null && errorMessage!.trim().isNotEmpty) ||
      errorKind != null ||
      validationErrorCode != null;
  int get remainingAttempts =>
      (maxAttempts - failedAttempts).clamp(0, maxAttempts);
  bool get canSubmit =>
      code.length == OtpCodeValidator.requiredLength &&
      !isBusy &&
      !isExpired &&
      !isLocked;
  bool get canResend => cooldownRemainingSeconds <= 0 && !isBusy;

  /// Formats `cooldownRemainingSeconds` as `M:SS` (e.g. `0:59`).
  String get formattedCooldown => _formatShortSeconds(cooldownRemainingSeconds);

  /// Formats `expiryRemainingSeconds` as `MM:SS` (e.g. `02:59`).
  String get formattedExpiry => _formatSeconds(expiryRemainingSeconds);

  static String _formatSeconds(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = (safe ~/ 60).toString().padLeft(2, '0');
    final seconds = (safe % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static String _formatShortSeconds(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = (safe ~/ 60).toString();
    final seconds = (safe % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  OtpVerificationState copyWith({
    String? normalizedPhone,
    String? displayPhone,
    String? pendingFullName,
    AuthFlowMode? flowMode,
    String? redirectTo,
    String? code,
    OtpStatus? status,
    String? errorMessage,
    AuthErrorKind? errorKind,
    OtpValidationError? validationErrorCode,
    bool clearErrorMessage = false,
    int? cooldownRemainingSeconds,
    int? expiryRemainingSeconds,
    int? failedAttempts,
    int? maxAttempts,
    AuthSession? authenticatedSession,
  }) {
    return OtpVerificationState(
      normalizedPhone: normalizedPhone ?? this.normalizedPhone,
      displayPhone: displayPhone ?? this.displayPhone,
      pendingFullName: pendingFullName ?? this.pendingFullName,
      flowMode: flowMode ?? this.flowMode,
      redirectTo: redirectTo ?? this.redirectTo,
      code: code ?? this.code,
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      errorKind: clearErrorMessage ? null : (errorKind ?? this.errorKind),
      validationErrorCode: clearErrorMessage
          ? null
          : (validationErrorCode ?? this.validationErrorCode),
      cooldownRemainingSeconds:
          cooldownRemainingSeconds ?? this.cooldownRemainingSeconds,
      expiryRemainingSeconds:
          expiryRemainingSeconds ?? this.expiryRemainingSeconds,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      authenticatedSession: authenticatedSession ?? this.authenticatedSession,
    );
  }
}
