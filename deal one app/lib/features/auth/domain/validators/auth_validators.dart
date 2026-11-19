import '../../../../core/utils/input_normalizers.dart';

/// Typed validation errors for full-name input so UI layers can render
/// localized messages in Arabic or English dynamically.
enum FullNameValidationError { required, tooShort, tooLong, mustContainLetters }

/// Typed validation errors for Egyptian mobile numbers.
enum PhoneValidationError { required, invalidEgyptianMobile }

/// Typed validation errors for email input.
enum EmailValidationError { required, invalidFormat }

/// Typed validation errors for OTP code input.
enum OtpValidationError { required, incomplete, digitsOnly }

/// Validators and normalizers specific to the Deal One authentication module.
class FullNameValidator {
  static const int minLength = 2;
  static const int maxLength = 80;

  /// Trims leading/trailing whitespace and collapses internal runs of spaces.
  static String normalize(String input) =>
      InputNormalizers.trimAndCollapseSpaces(input);

  /// Returns a typed [FullNameValidationError] or `null` if valid.
  static FullNameValidationError? validateCode(String? value) {
    final cleaned = normalize(value ?? '');
    if (cleaned.isEmpty) {
      return FullNameValidationError.required;
    }
    if (cleaned.length < minLength) {
      return FullNameValidationError.tooShort;
    }
    if (cleaned.length > maxLength) {
      return FullNameValidationError.tooLong;
    }
    final hasLetter = RegExp(r'[a-zA-Z\u0600-\u06FF]').hasMatch(cleaned);
    if (!hasLetter) {
      return FullNameValidationError.mustContainLetters;
    }
    return null;
  }

  /// Validates the user's full name and returns a default Arabic message if invalid.
  static String? validate(String? value) {
    switch (validateCode(value)) {
      case null:
        return null;
      case FullNameValidationError.required:
        return 'من فضلك أدخل الاسم الكامل';
      case FullNameValidationError.tooShort:
        return 'الاسم الكامل يجب أن يكون حرفين على الأقل';
      case FullNameValidationError.tooLong:
        return 'الاسم الكامل طويل جداً';
      case FullNameValidationError.mustContainLetters:
        return 'يرجى إدخال اسم صحيح يحتوي على حروف';
    }
  }
}

class EgyptianPhoneValidator {
  static final RegExp _e164EgyptianRegex = RegExp(
    r'^\+20(10|11|12|15)[0-9]{8}$',
  );

  /// Normalizes Egyptian phone inputs (Arabic or Western digits, `01...`,
  /// `10...` entered after `+20`, `201...`, `00201...`, `+201...`) to `+201...`.
  static String? normalize(String rawPhone) {
    var cleaned = InputNormalizers.convertArabicNumeralsToWestern(rawPhone)
        .replaceAll(RegExp(r'[\s\-\(\)]'), '')
        .trim();

    if (cleaned.isEmpty) {
      return null;
    }

    if (RegExp(r'^(10|11|12|15)[0-9]{8}$').hasMatch(cleaned)) {
      cleaned = '0$cleaned';
    }

    return InputNormalizers.normalizeEgyptianPhoneNumber(cleaned);
  }

  /// Returns a typed [PhoneValidationError] or `null` if valid.
  static PhoneValidationError? validateCode(String? rawPhone) {
    final cleaned = (rawPhone ?? '').trim();
    if (cleaned.isEmpty) {
      return PhoneValidationError.required;
    }
    final normalized = normalize(cleaned);
    if (normalized == null || !_e164EgyptianRegex.hasMatch(normalized)) {
      return PhoneValidationError.invalidEgyptianMobile;
    }
    return null;
  }

  /// Validates Egyptian mobile numbers and returns a default Arabic message.
  static String? validate(String? rawPhone) {
    switch (validateCode(rawPhone)) {
      case null:
        return null;
      case PhoneValidationError.required:
        return 'من فضلك أدخل رقم الهاتف';
      case PhoneValidationError.invalidEgyptianMobile:
        return 'أدخل رقم موبايل مصري صحيح (مثال: 01012345678)';
    }
  }

  /// Formats a normalized `+201012345678` string for clean UI presentation.
  static String formatForDisplay(String rawOrNormalized) {
    final normalized = normalize(rawOrNormalized);
    if (normalized == null) {
      return rawOrNormalized;
    }
    // +201012345678 -> +20 101 234 5678
    final local = normalized.substring(3); // 10 digits e.g. 1012345678
    return '+20 ${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
  }
}

class EmailValidator {
  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );

  /// Normalizes an email address by converting numerals if any and trimming.
  static String normalize(String rawEmail) =>
      InputNormalizers.convertArabicNumeralsToWestern(rawEmail).trim();

  /// Returns a typed [EmailValidationError] or `null` if valid.
  static EmailValidationError? validateCode(String? rawEmail) {
    final cleaned = normalize(rawEmail ?? '');
    if (cleaned.isEmpty) {
      return EmailValidationError.required;
    }
    if (!_emailRegex.hasMatch(cleaned)) {
      return EmailValidationError.invalidFormat;
    }
    return null;
  }

  /// Validates an email address and returns a default Arabic message if invalid.
  static String? validate(String? rawEmail) {
    switch (validateCode(rawEmail)) {
      case null:
        return null;
      case EmailValidationError.required:
        return 'من فضلك أدخل البريد الإلكتروني';
      case EmailValidationError.invalidFormat:
        return 'صيغة البريد الإلكتروني غير صحيحة';
    }
  }
}

class OtpCodeValidator {
  /// Backend `VerifyOtpDto` requires 6 numeric digits (`100000`–`999999`).
  static const int requiredLength = 6;

  /// Extracts normalized Western ASCII digits from any OTP string.
  static String normalizeDigits(String rawCode) {
    final western = InputNormalizers.convertArabicNumeralsToWestern(rawCode);
    return western.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Returns a typed [OtpValidationError] or `null` if valid.
  static OtpValidationError? validateCode(String? rawCode) {
    final digits = normalizeDigits(rawCode ?? '');
    if (digits.isEmpty) {
      return OtpValidationError.required;
    }
    if (digits.length < requiredLength) {
      return OtpValidationError.incomplete;
    }
    if (!RegExp('^[0-9]{$requiredLength}\$').hasMatch(digits)) {
      return OtpValidationError.digitsOnly;
    }
    return null;
  }

  /// Validates that the OTP contains exactly [requiredLength] digits.
  static String? validate(String? rawCode) {
    switch (validateCode(rawCode)) {
      case null:
        return null;
      case OtpValidationError.required:
        return 'من فضلك أدخل رمز التحقق';
      case OtpValidationError.incomplete:
        return 'يرجى إدخال رمز التحقق المكون من $requiredLength أرقام';
      case OtpValidationError.digitsOnly:
        return 'رمز التحقق يجب أن يحتوي على أرقام فقط';
    }
  }
}
