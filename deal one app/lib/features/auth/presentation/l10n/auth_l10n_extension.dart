import 'package:flutter/widgets.dart';

import 'package:market_space/l10n/generated/app_localizations.dart';
import 'package:market_space/l10n/generated/app_localizations_ar.dart';
import 'package:market_space/features/auth/data/mappers/auth_error_mapper.dart';
import 'package:market_space/features/auth/domain/validators/auth_validators.dart';

/// Convenience localization helpers for the Authentication & Account module.
extension AuthL10nContext on BuildContext {
  /// Returns the active [AppLocalizations], falling back to Arabic if a widget
  /// is rendered in an isolated harness without localization delegates.
  AppLocalizations get authL10n =>
      AppLocalizations.of(this) ?? AppLocalizationsAr();

  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}

/// Maps typed domain validation and API error enums to localized strings
/// without hardcoding Arabic or English inside presentation widgets.
class AuthLocalizedMessages {
  AuthLocalizedMessages._();

  static String? fullNameError(
    AppLocalizations l10n,
    FullNameValidationError? code, {
    String? fallback,
  }) {
    if (code == null) return fallback;
    switch (code) {
      case FullNameValidationError.required:
        return l10n.validationNameRequired;
      case FullNameValidationError.tooShort:
        return l10n.validationNameTooShort;
      case FullNameValidationError.tooLong:
        return l10n.validationNameTooLong;
      case FullNameValidationError.mustContainLetters:
        return l10n.validationNameLetters;
    }
  }

  static String? phoneError(
    AppLocalizations l10n,
    PhoneValidationError? code, {
    String? fallback,
  }) {
    if (code == null) return fallback;
    switch (code) {
      case PhoneValidationError.required:
        return l10n.validationPhoneRequired;
      case PhoneValidationError.invalidEgyptianMobile:
        return l10n.validationPhoneInvalid;
    }
  }

  static String? emailError(
    AppLocalizations l10n,
    EmailValidationError? code, {
    String? fallback,
  }) {
    if (code == null) return fallback;
    switch (code) {
      case EmailValidationError.required:
        return l10n.validationEmailRequired;
      case EmailValidationError.invalidFormat:
        return l10n.validationEmailInvalid;
    }
  }

  static String? otpError(
    AppLocalizations l10n,
    OtpValidationError? code, {
    String? fallback,
  }) {
    if (code == null) return fallback;
    switch (code) {
      case OtpValidationError.required:
        return l10n.validationOtpRequired;
      case OtpValidationError.incomplete:
        return l10n.validationOtpIncomplete(OtpCodeValidator.requiredLength);
      case OtpValidationError.digitsOnly:
        return l10n.validationOtpDigitsOnly;
    }
  }

  static String authError(
    AppLocalizations l10n,
    AuthErrorKind kind, {
    String? fallback,
  }) {
    switch (kind) {
      case AuthErrorKind.network:
        return l10n.authErrorNetwork;
      case AuthErrorKind.timeout:
        return l10n.authErrorTimeout;
      case AuthErrorKind.unexpectedResponse:
        return l10n.authErrorUnexpectedResponse;
      case AuthErrorKind.whatsappUnavailable:
        return l10n.authErrorWhatsappUnavailable;
      case AuthErrorKind.otpDeliveryFailed:
        return l10n.authErrorOtpDeliveryFailed;
      case AuthErrorKind.maxAttemptsExceeded:
        return l10n.authErrorMaxAttempts;
      case AuthErrorKind.expiredOtp:
        return l10n.authErrorOtpExpired;
      case AuthErrorKind.invalidOtp:
        return l10n.authErrorOtpInvalid;
      case AuthErrorKind.invalidRefreshToken:
        return l10n.authErrorInvalidRefreshToken;
      case AuthErrorKind.rateLimited:
        return l10n.authErrorRateLimited;
      case AuthErrorKind.accountNotFound:
        return l10n.authErrorAccountNotFound;
      case AuthErrorKind.existingAccount:
        return l10n.authErrorExistingAccount;
      case AuthErrorKind.invalidPhoneNumber:
        return l10n.authErrorInvalidPhone;
      case AuthErrorKind.validation:
        return l10n.authErrorValidation;
      case AuthErrorKind.unauthorizedSession:
        return l10n.authErrorUnauthorized;
      case AuthErrorKind.server:
        return fallback ?? l10n.authErrorServer;
    }
  }
}
