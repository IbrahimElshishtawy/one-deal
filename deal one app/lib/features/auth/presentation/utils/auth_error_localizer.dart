import 'package:flutter/widgets.dart';

import '../../../../app/app_localization.dart';
import '../../data/mappers/auth_error_mapper.dart';
import '../../domain/validators/auth_validators.dart';

/// Maps semantic [AuthErrorKind]s and validator errors into localized Arabic
/// or English UI strings via [AppLocalizations].
class AuthErrorLocalizer {
  const AuthErrorLocalizer._();

  /// Localizes an [AuthErrorKind] using the active [BuildContext] locale.
  static String localizeErrorKind(BuildContext context, AuthErrorKind kind) {
    final l10n = AppLocalization.of(context);
    switch (kind) {
      case AuthErrorKind.invalidPhoneNumber:
        return l10n.valPhoneInvalid;
      case AuthErrorKind.accountNotFound:
        return l10n.errAuthAccountNotFound;
      case AuthErrorKind.existingAccount:
        return l10n.errAuthExistingAccount;
      case AuthErrorKind.invalidOtp:
        return l10n.errAuthOtpInvalid;
      case AuthErrorKind.expiredOtp:
        return l10n.errAuthOtpExpired;
      case AuthErrorKind.maxAttemptsExceeded:
        return l10n.errAuthMaxAttempts;
      case AuthErrorKind.otpDeliveryFailed:
        return l10n.errAuthOtpDeliveryFailed;
      case AuthErrorKind.whatsappUnavailable:
        return l10n.errAuthWhatsappUnavailable;
      case AuthErrorKind.rateLimited:
        return l10n.errAuthRateLimited;
      case AuthErrorKind.network:
        return l10n.errAuthNetwork;
      case AuthErrorKind.timeout:
        return l10n.errAuthTimeout;
      case AuthErrorKind.unauthorizedSession:
        return l10n.errAuthUnauthorized;
      case AuthErrorKind.invalidRefreshToken:
        return l10n.errAuthInvalidRefresh;
      case AuthErrorKind.validation:
        return l10n.errAuthValidation;
      case AuthErrorKind.server:
        return l10n.errAuthServer;
      case AuthErrorKind.unexpectedResponse:
        return l10n.errAuthUnexpectedResponse;
    }
  }

  /// Resolves a controller-stored error message using [errorKind] when present,
  /// or translates known validator messages into the active locale.
  static String? resolveMessage(
    BuildContext context, {
    String? rawMessage,
    AuthErrorKind? errorKind,
  }) {
    if (errorKind != null) {
      return localizeErrorKind(context, errorKind);
    }
    if (rawMessage == null || rawMessage.isEmpty) {
      return null;
    }
    return localizeValidationMessage(context, rawMessage);
  }

  /// Translates validator error messages into the active [BuildContext] locale.
  static String localizeValidationMessage(
    BuildContext context,
    String rawMessage,
  ) {
    final l10n = AppLocalization.of(context);
    switch (rawMessage) {
      case 'من فضلك أدخل الاسم الكامل':
        return l10n.valFullNameEmpty;
      case 'الاسم الكامل يجب أن يكون حرفين على الأقل':
        return l10n.valFullNameTooShort;
      case 'الاسم الكامل طويل جداً':
        return l10n.valFullNameTooLong;
      case 'يرجى إدخال اسم صحيح يحتوي على حروف':
        return l10n.valFullNameNoLetters;
      case 'من فضلك أدخل رقم الهاتف':
        return l10n.valPhoneEmpty;
      case 'أدخل رقم موبايل مصري صحيح (مثال: 01012345678)':
        return l10n.valPhoneInvalid;
      case 'من فضلك أدخل البريد الإلكتروني':
        return l10n.valEmailEmpty;
      case 'صيغة البريد الإلكتروني غير صحيحة':
        return l10n.valEmailInvalid;
      case 'من فضلك أدخل رمز التحقق':
        return l10n.valOtpEmpty;
      case 'يرجى إدخال رمز التحقق المكون من ${OtpCodeValidator.requiredLength} أرقام':
        return l10n.valOtpLength(OtpCodeValidator.requiredLength);
      case 'رمز التحقق يجب أن يحتوي على أرقام فقط':
        return l10n.valOtpDigitsOnly;
      case 'انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد':
        return l10n.errAuthOtpExpired;
      default:
        return rawMessage;
    }
  }
}
