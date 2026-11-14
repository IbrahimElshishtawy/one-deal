import '../../../../core/utils/input_normalizers.dart';

/// Validators and normalizers specific to the Deal One authentication module.
class FullNameValidator {
  static const int minLength = 2;
  static const int maxLength = 80;

  /// Trims leading/trailing whitespace and collapses internal runs of spaces.
  static String normalize(String input) =>
      InputNormalizers.trimAndCollapseSpaces(input);

  /// Validates the user's full name and returns an Arabic error message if invalid.
  static String? validate(String? value) {
    final cleaned = normalize(value ?? '');
    if (cleaned.isEmpty) {
      return 'من فضلك أدخل الاسم الكامل';
    }
    if (cleaned.length < minLength) {
      return 'الاسم الكامل يجب أن يكون حرفين على الأقل';
    }
    if (cleaned.length > maxLength) {
      return 'الاسم الكامل طويل جداً';
    }
    final hasLetter = RegExp(r'[a-zA-Z\u0600-\u06FF]').hasMatch(cleaned);
    if (!hasLetter) {
      return 'يرجى إدخال اسم صحيح يحتوي على حروف';
    }
    return null;
  }
}

class EgyptianPhoneValidator {
  static final RegExp _e164EgyptianRegex =
      RegExp(r'^\+20(10|11|12|15)[0-9]{8}$');

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

  /// Validates Egyptian mobile numbers and returns an Arabic error message.
  static String? validate(String? rawPhone) {
    final cleaned = (rawPhone ?? '').trim();
    if (cleaned.isEmpty) {
      return 'من فضلك أدخل رقم الهاتف';
    }
    final normalized = normalize(cleaned);
    if (normalized == null || !_e164EgyptianRegex.hasMatch(normalized)) {
      return 'أدخل رقم موبايل مصري صحيح (مثال: 01012345678)';
    }
    return null;
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

  /// Validates an email address and returns an Arabic error message if invalid.
  static String? validate(String? rawEmail) {
    final cleaned = normalize(rawEmail ?? '');
    if (cleaned.isEmpty) {
      return 'من فضلك أدخل البريد الإلكتروني';
    }
    if (!_emailRegex.hasMatch(cleaned)) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return null;
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

  /// Validates that the OTP contains exactly [requiredLength] digits.
  static String? validate(String? rawCode) {
    final digits = normalizeDigits(rawCode ?? '');
    if (digits.isEmpty) {
      return 'من فضلك أدخل رمز التحقق';
    }
    if (digits.length < requiredLength) {
      return 'يرجى إدخال رمز التحقق المكون من $requiredLength أرقام';
    }
    if (!RegExp('^[0-9]{$requiredLength}\$').hasMatch(digits)) {
      return 'رمز التحقق يجب أن يحتوي على أرقام فقط';
    }
    return null;
  }
}
