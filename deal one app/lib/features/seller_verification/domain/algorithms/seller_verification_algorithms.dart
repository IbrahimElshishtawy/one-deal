import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';

/// Result of analyzing and checksum/structure-validating an Egyptian National ID.
class EgyptianNationalIdResult {
  final bool isValid;
  final String normalizedDigits;
  final DateTime? birthDate;
  final int? ageYears;
  final String? governorateNameAr;
  final String? governorateNameEn;
  final String? genderAr;
  final String? genderEn;
  final String? errorMessage;

  const EgyptianNationalIdResult({
    required this.isValid,
    required this.normalizedDigits,
    this.birthDate,
    this.ageYears,
    this.governorateNameAr,
    this.governorateNameEn,
    this.genderAr,
    this.genderEn,
    this.errorMessage,
  });

  String? localizedGovernorate(bool isArabic) =>
      isArabic ? governorateNameAr : governorateNameEn;

  String? localizedGender(bool isArabic) => isArabic ? genderAr : genderEn;

  String? get formattedBirthDate => birthDate == null
      ? null
      : '${birthDate!.year}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}';
}

/// Result of analyzing and normalizing an Egyptian mobile phone number.
class EgyptianPhoneResult {
  final bool isValid;
  final String normalizedLocal;
  final String normalizedE164;
  final String? errorMessage;

  const EgyptianPhoneResult({
    required this.isValid,
    required this.normalizedLocal,
    required this.normalizedE164,
    this.errorMessage,
  });
}

/// Activity option displayed in Step 1 (`نوع النشاط العقاري`) and mapped
/// directly to backend `BusinessAccountType`, `serviceCategory`, and
/// `marketplaceSections`.
class SellerActivityOption {
  final String code;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final IconData icon;
  final BusinessAccountType businessAccountType;
  final List<String> marketplaceSections;

  const SellerActivityOption({
    required this.code,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.icon,
    required this.businessAccountType,
    required this.marketplaceSections,
  });

  String localizedTitle(bool isArabic) => isArabic ? titleAr : titleEn;
  String localizedSubtitle(bool isArabic) => isArabic ? subtitleAr : subtitleEn;
}

/// Aggregated validation result for a wizard step.
class StepValidationResult {
  final bool isValid;
  final Map<String, String> fieldErrors;

  const StepValidationResult({
    required this.isValid,
    this.fieldErrors = const {},
  });
}

/// Algorithmic validation, normalization, and readiness scoring engine for the
/// 3-step Deal One seller conversion wizard.
class SellerVerificationAlgorithms {
  SellerVerificationAlgorithms._();

  static const Map<String, (String ar, String en)> _egyptianGovCodes = {
    '01': ('القاهرة', 'Cairo'),
    '02': ('الإسكندرية', 'Alexandria'),
    '03': ('بورسعيد', 'Port Said'),
    '04': ('السويس', 'Suez'),
    '11': ('دمياط', 'Damietta'),
    '12': ('الدقهلية', 'Dakahlia'),
    '13': ('الشرقية', 'Sharqia'),
    '14': ('القليوبية', 'Qalyubia'),
    '15': ('كفر الشيخ', 'Kafr El Sheikh'),
    '16': ('الغربية', 'Gharbia'),
    '17': ('المنوفية', 'Monufia'),
    '18': ('البحيرة', 'Beheira'),
    '19': ('الإسماعيلية', 'Ismailia'),
    '21': ('الجيزة', 'Giza'),
    '22': ('بني سويف', 'Beni Suef'),
    '23': ('الفيوم', 'Fayoum'),
    '24': ('المنيا', 'Minya'),
    '25': ('أسيوط', 'Asyut'),
    '26': ('سوهاج', 'Sohag'),
    '27': ('قنا', 'Qena'),
    '28': ('أسوان', 'Aswan'),
    '29': ('الأقصر', 'Luxor'),
    '31': ('البحر الأحمر', 'Red Sea'),
    '32': ('الوادي الجديد', 'New Valley'),
    '33': ('مطروح', 'Matrouh'),
    '34': ('شمال سيناء', 'North Sinai'),
    '35': ('جنوب سيناء', 'South Sinai'),
    '88': ('خارج الجمهورية', 'Abroad'),
  };

  static const List<SellerActivityOption> realEstateActivities = [
    SellerActivityOption(
      code: 'real_estate_marketing',
      titleAr: 'تسويق عقاري',
      titleEn: 'Real Estate Marketing',
      subtitleAr: 'تسويق الوحدات السكنية والتجارية وإدارة الحملات العقارية',
      subtitleEn: 'Residential & commercial property marketing and campaigns',
      icon: Icons.campaign_outlined,
      businessAccountType: BusinessAccountType.office,
      marketplaceSections: ['real-estate'],
    ),
    SellerActivityOption(
      code: 'real_estate_developer',
      titleAr: 'مطور عقاري',
      titleEn: 'Real Estate Developer',
      subtitleAr: 'تطوير المشروعات العمرانية والكمبوندات السكنية والتجارية',
      subtitleEn: 'Residential compounds and commercial project development',
      icon: Icons.apartment_rounded,
      businessAccountType: BusinessAccountType.company,
      marketplaceSections: ['real-estate'],
    ),
    SellerActivityOption(
      code: 'real_estate_brokerage',
      titleAr: 'مكتب وساطة عقارية',
      titleEn: 'Real Estate Brokerage Office',
      subtitleAr: 'بيع وشراء وإيجار العقارات والأراضي بوساطة معتمدة',
      subtitleEn: 'Licensed sales, leasing, and land brokerage',
      icon: Icons.business_center_outlined,
      businessAccountType: BusinessAccountType.office,
      marketplaceSections: ['real-estate'],
    ),
    SellerActivityOption(
      code: 'real_estate_investment',
      titleAr: 'شركة استثمار عقاري',
      titleEn: 'Real Estate Investment Company',
      subtitleAr: 'إدارة المحافظ والأصول والأراضي الاستثمارية',
      subtitleEn: 'Property portfolio and land investment management',
      icon: Icons.account_balance_outlined,
      businessAccountType: BusinessAccountType.company,
      marketplaceSections: ['real-estate'],
    ),
    SellerActivityOption(
      code: 'independent_broker',
      titleAr: 'مسوق عقاري مستقل / فرد',
      titleEn: 'Independent Property Marketer',
      subtitleAr: 'نشاط فردي للوساطة والمعاينات العقارية',
      subtitleEn: 'Individual property brokerage and viewings',
      icon: Icons.person_pin_circle_outlined,
      businessAccountType: BusinessAccountType.individual,
      marketplaceSections: ['real-estate'],
    ),
    SellerActivityOption(
      code: 'engineering_contracting',
      titleAr: 'استشارات هندسية ومقاولات',
      titleEn: 'Engineering & Contracting',
      subtitleAr: 'تشطيبات، تصميمات معمارية، ومقاولات عقارية',
      subtitleEn: 'Finishing, architectural design, and contracting',
      icon: Icons.architecture_outlined,
      businessAccountType: BusinessAccountType.office,
      marketplaceSections: ['real-estate', 'services'],
    ),
    SellerActivityOption(
      code: 'commercial_showroom_store',
      titleAr: 'معرض / متجر تجاري متعدد الأقسام',
      titleEn: 'Commercial Store / Showroom',
      subtitleAr: 'بيع منتجات ومعارض تجارية عبر أقسام صفقة ون',
      subtitleEn: 'Commercial store or showroom across Deal One sections',
      icon: Icons.storefront_outlined,
      businessAccountType: BusinessAccountType.store,
      marketplaceSections: [
        'real-estate',
        'building-materials',
        'home-appliances',
      ],
    ),
  ];

  static SellerActivityOption? findActivityByCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    for (final item in realEstateActivities) {
      if (item.code == code ||
          item.titleAr == code ||
          item.titleEn.toLowerCase() == code.trim().toLowerCase()) {
        return item;
      }
    }
    return null;
  }

  /// Normalizes Arabic-Indic (`٠-٩`) and Extended Arabic-Indic (`۰-۹`) digits
  /// to standard ASCII digits `0-9`.
  static String normalizeDigits(String input) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const extendedIndic = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final idx1 = arabicIndic.indexOf(ch);
      if (idx1 != -1) {
        buffer.write(idx1);
        continue;
      }
      final idx2 = extendedIndic.indexOf(ch);
      if (idx2 != -1) {
        buffer.write(idx2);
        continue;
      }
      buffer.write(ch);
    }
    return buffer.toString();
  }

  /// Validates and decodes an Egyptian 14-digit National ID:
  /// `[C][YY][MM][DD][GG][SSS][S][Z]`
  static EgyptianNationalIdResult analyzeNationalId(
    String raw, {
    required bool isArabic,
  }) {
    final normalized = normalizeDigits(raw).replaceAll(RegExp(r'\s+'), '');

    if (normalized.isEmpty) {
      return EgyptianNationalIdResult(
        isValid: false,
        normalizedDigits: normalized,
        errorMessage: isArabic
            ? 'يرجى إدخال الرقم القومي المكون من 14 رقماً'
            : 'Please enter the 14-digit National ID number',
      );
    }

    if (!RegExp(r'^\d{14}$').hasMatch(normalized)) {
      return EgyptianNationalIdResult(
        isValid: false,
        normalizedDigits: normalized,
        errorMessage: isArabic
            ? 'يجب أن يتكون الرقم القومي من 14 رقماً بالضبط'
            : 'National ID must be exactly 14 digits',
      );
    }

    final centuryDigit = int.parse(normalized[0]);
    if (centuryDigit != 2 && centuryDigit != 3) {
      return EgyptianNationalIdResult(
        isValid: false,
        normalizedDigits: normalized,
        errorMessage: isArabic
            ? 'الرقم القومي غير صحيح (رقم القرن يجب أن يبدأ بـ 2 أو 3)'
            : 'Invalid National ID century prefix',
      );
    }

    final centuryBase = centuryDigit == 2 ? 1900 : 2000;
    final year = centuryBase + int.parse(normalized.substring(1, 3));
    final month = int.parse(normalized.substring(3, 5));
    final day = int.parse(normalized.substring(5, 7));

    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return EgyptianNationalIdResult(
        isValid: false,
        normalizedDigits: normalized,
        errorMessage: isArabic
            ? 'تاريخ الميلاد داخل الرقم القومي غير صالح'
            : 'Birth date encoded in National ID is invalid',
      );
    }

    final birthDate = DateTime(year, month, day);
    if (birthDate.year != year ||
        birthDate.month != month ||
        birthDate.day != day) {
      return EgyptianNationalIdResult(
        isValid: false,
        normalizedDigits: normalized,
        errorMessage: isArabic
            ? 'تاريخ الميلاد داخل الرقم القومي غير صحيح'
            : 'Invalid calendar birth date in National ID',
      );
    }

    final now = DateTime.now();
    if (birthDate.isAfter(now)) {
      return EgyptianNationalIdResult(
        isValid: false,
        normalizedDigits: normalized,
        errorMessage: isArabic
            ? 'تاريخ الميلاد داخل الرقم القومي لا يمكن أن يكون في المستقبل'
            : 'National ID birth date cannot be in the future',
      );
    }

    final minAgeCutoff = DateTime(now.year - 16, now.month, now.day);
    if (birthDate.isAfter(minAgeCutoff)) {
      return EgyptianNationalIdResult(
        isValid: false,
        normalizedDigits: normalized,
        errorMessage: isArabic
            ? 'يجب أن يكون عمر صاحب البطاقة 16 عاماً على الأقل'
            : 'Applicant must be at least 16 years old',
      );
    }

    final govCode = normalized.substring(7, 9);
    final govEntry = _egyptianGovCodes[govCode];
    if (govEntry == null) {
      return EgyptianNationalIdResult(
        isValid: false,
        normalizedDigits: normalized,
        errorMessage: isArabic
            ? 'كود المحافظة داخل الرقم القومي غير معتمد'
            : 'Unrecognized governorate code in National ID',
      );
    }

    // Reject obviously fabricated trailing serials (e.g. 00000)
    final serialPart = normalized.substring(9, 14);
    if (serialPart == '00000') {
      return EgyptianNationalIdResult(
        isValid: false,
        normalizedDigits: normalized,
        errorMessage: isArabic
            ? 'الرقم القومي غير صالح (تسلسل الأرقام غير صحيح)'
            : 'National ID serial sequence is invalid',
      );
    }

    // Digit 13 (index 12): odd = Male, even = Female in Egyptian National ID standard
    final genderDigit = int.parse(normalized[12]);
    final isMale = genderDigit.isOdd;
    var ageYears = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      ageYears--;
    }

    return EgyptianNationalIdResult(
      isValid: true,
      normalizedDigits: normalized,
      birthDate: birthDate,
      ageYears: ageYears,
      governorateNameAr: govEntry.$1,
      governorateNameEn: govEntry.$2,
      genderAr: isMale ? 'ذكر' : 'أنثى',
      genderEn: isMale ? 'Male' : 'Female',
    );
  }

  /// Validates real file magic bytes client-side before uploading to prevent
  /// corrupted, empty, or disguised files from failing late at server confirm.
  static String? validateMagicBytesAndQuality({
    required Uint8List bytes,
    required String mimeType,
    required bool isArabic,
  }) {
    if (bytes.length < 12) {
      return isArabic
          ? 'الملف المختار فارغ أو تالف. يرجى اختيار صورة واضحة للبطاقة.'
          : 'Selected file is empty or corrupted. Please pick a clear photo.';
    }
    final normalizedMime = mimeType.toLowerCase().trim();
    bool validSignature = false;
    if (normalizedMime == 'image/jpeg') {
      validSignature =
          bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff;
    } else if (normalizedMime == 'image/png') {
      validSignature = bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4e &&
          bytes[3] == 0x47;
    } else if (normalizedMime == 'image/webp') {
      validSignature = bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50;
    } else if (normalizedMime == 'application/pdf') {
      validSignature = bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46 &&
          bytes[4] == 0x2d;
    }

    if (!validSignature) {
      return isArabic
          ? 'صيغة الملف لا تطابق محتواه الفعلي. يرجى رفع صورة أصلية (JPG/PNG/WEBP) أو PDF سليم.'
          : 'File content does not match its declared format. Please upload a valid image or PDF.';
    }
    return null;
  }

  /// Detects if the user accidentally picked the exact same photo for both
  /// National ID Front and Back (only applies to real images >= 256 bytes).
  static bool areDuplicateDocumentBytes(Uint8List a, Uint8List b) {
    if (a.length < 256 || a.length != b.length) return false;
    final sampleCount = a.length < 64 ? a.length : 64;
    for (var i = 0; i < sampleCount; i++) {
      if (a[i] != b[i]) return false;
    }
    for (var i = 1; i <= sampleCount; i++) {
      if (a[a.length - i] != b[b.length - i]) return false;
    }
    return true;
  }

  /// Validates and normalizes an Egyptian mobile number (`010/011/012/015`).
  static EgyptianPhoneResult analyzeEgyptianPhone(
    String raw, {
    required bool isArabic,
  }) {
    final cleaned = normalizeDigits(raw).replaceAll(RegExp(r'[\s\-\(\)]+'), '');

    if (cleaned.isEmpty) {
      return EgyptianPhoneResult(
        isValid: false,
        normalizedLocal: '',
        normalizedE164: '',
        errorMessage: isArabic
            ? 'يرجى إدخال رقم هاتف للتواصل'
            : 'Please enter a contact phone number',
      );
    }

    String localDigits = cleaned;
    if (localDigits.startsWith('+20')) {
      localDigits = localDigits.substring(3);
    } else if (localDigits.startsWith('0020')) {
      localDigits = localDigits.substring(4);
    } else if (localDigits.startsWith('20') && localDigits.length == 12) {
      localDigits = localDigits.substring(2);
    }

    if (!localDigits.startsWith('0') && localDigits.length == 10) {
      localDigits = '0$localDigits';
    }

    if (!RegExp(r'^01[0125]\d{8}$').hasMatch(localDigits)) {
      return EgyptianPhoneResult(
        isValid: false,
        normalizedLocal: localDigits,
        normalizedE164: '',
        errorMessage: isArabic
            ? 'يرجى إدخال رقم موبايل مصري صحيح يبدأ بـ 010 أو 011 أو 012 أو 015'
            : 'Enter a valid 11-digit Egyptian mobile number starting with 010, 011, 012, or 015',
      );
    }

    return EgyptianPhoneResult(
      isValid: true,
      normalizedLocal: localDigits,
      normalizedE164: '+2$localDigits',
    );
  }

  /// Validates Step 1 inputs (`بيانات المكتب والنشاط والتواصل`).
  static StepValidationResult validateStep1({
    required String officeName,
    required String? activityCode,
    required int? governorateId,
    required int? cityId,
    required bool hasLocationsLoaded,
    required String contactPhone,
    required bool isArabic,
  }) {
    final errors = <String, String>{};
    final trimmedName = officeName.trim();

    if (trimmedName.isEmpty) {
      errors['officeName'] = isArabic
          ? 'يرجى إدخال اسم المكتب أو الشركة العقارية'
          : 'Please enter the office or company name';
    } else if (trimmedName.length < 2) {
      errors['officeName'] = isArabic
          ? 'الاسم يجب أن يكون حرفين على الأقل'
          : 'Name must be at least 2 characters';
    } else if (trimmedName.length > 150) {
      errors['officeName'] = isArabic
          ? 'الحد الأقصى للاسم 150 حرفاً'
          : 'Maximum length is 150 characters';
    }

    if (activityCode == null || activityCode.trim().isEmpty) {
      errors['activityCode'] = isArabic
          ? 'يرجى اختيار نوع النشاط العقاري'
          : 'Please choose the real estate activity type';
    }

    if (hasLocationsLoaded) {
      if (governorateId == null) {
        errors['governorateId'] = isArabic
            ? 'يرجى اختيار المحافظة'
            : 'Please select governorate';
      } else if (cityId == null) {
        errors['cityId'] = isArabic
            ? 'يرجى اختيار المدينة'
            : 'Please select city';
      }
    }

    final phoneRes = analyzeEgyptianPhone(contactPhone, isArabic: isArabic);
    if (!phoneRes.isValid && phoneRes.errorMessage != null) {
      errors['contactPhone'] = phoneRes.errorMessage!;
    }

    return StepValidationResult(
      isValid: errors.isEmpty,
      fieldErrors: errors,
    );
  }

  /// Validates Step 2 inputs (`توثيق الهوية والبيانات والمستندات`).
  static StepValidationResult validateStep2({
    required SellerType identityMode,
    required String nationalIdNumber,
    required String commercialRegisterNumber,
    required bool hasFrontDocument,
    required bool hasBackDocument,
    required bool hasCommercialRegisterDocument,
    required bool hasTaxCardDocument,
    required bool isArabic,
  }) {
    final errors = <String, String>{};

    if (identityMode == SellerType.business) {
      final cr = commercialRegisterNumber.trim();
      if (cr.isEmpty) {
        errors['commercialRegisterNumber'] = isArabic
            ? 'يرجى إدخال رقم السجل التجاري'
            : 'Commercial registration number is required';
      } else if (cr.length < 3 || cr.length > 100) {
        errors['commercialRegisterNumber'] = isArabic
            ? 'رقم السجل التجاري يجب أن يكون بين 3 و 100 حرف'
            : 'Commercial register must be 3-100 characters';
      }

      if (!hasCommercialRegisterDocument) {
        errors['commercial_register'] = isArabic
            ? 'يرجى رفع صورة أو ملف السجل التجاري'
            : 'Please upload the commercial registration document';
      }
      if (!hasTaxCardDocument) {
        errors['tax_card'] = isArabic
            ? 'يرجى رفع صورة أو ملف البطاقة الضريبية'
            : 'Please upload the tax registration card';
      }
    } else {
      final nidRes = analyzeNationalId(nationalIdNumber, isArabic: isArabic);
      if (!nidRes.isValid && nidRes.errorMessage != null) {
        errors['nationalIdNumber'] = nidRes.errorMessage!;
      }

      if (!hasFrontDocument) {
        errors['national_id_front'] = isArabic
            ? 'يرجى رفع صورة وجه البطاقة الشخصية'
            : 'Please upload the front side of your National ID';
      }
      if (!hasBackDocument) {
        errors['national_id_back'] = isArabic
            ? 'يرجى رفع صورة ظهر البطاقة الشخصية'
            : 'Please upload the back side of your National ID';
      }
    }

    return StepValidationResult(
      isValid: errors.isEmpty,
      fieldErrors: errors,
    );
  }

  /// Computes an accurate `0.0..1.0` readiness score across all wizard criteria.
  static double computeReadinessProgress({
    required int currentStep,
    required String officeName,
    required String? activityCode,
    required int? cityId,
    required String contactPhone,
    required SellerType identityMode,
    required String nationalIdNumber,
    required String commercialRegisterNumber,
    required bool hasPrimaryDoc1,
    required bool hasPrimaryDoc2,
    required VerificationStatus? applicationStatus,
  }) {
    if (currentStep >= 3 ||
        (applicationStatus != null &&
            (applicationStatus.isInReview || applicationStatus.isApproved))) {
      return 1.0;
    }

    var completed = 0;
    const total = 8;

    if (officeName.trim().length >= 2) completed++;
    if (activityCode != null && activityCode.isNotEmpty) completed++;
    if (cityId != null) completed++;
    if (analyzeEgyptianPhone(contactPhone, isArabic: true).isValid) {
      completed++;
    }

    if (identityMode == SellerType.business) {
      if (commercialRegisterNumber.trim().length >= 3) completed++;
    } else {
      if (analyzeNationalId(nationalIdNumber, isArabic: true).isValid) {
        completed++;
      }
    }

    if (hasPrimaryDoc1) completed++;
    if (hasPrimaryDoc2) completed++;
    if (currentStep >= 2) completed++;

    return (completed / total).clamp(0.15, 1.0);
  }

  /// Resolves document types required by backend for a given identity mode.
  static (String primaryDoc1, String primaryDoc2) documentPairForMode(
    SellerType identityMode,
  ) {
    if (identityMode == SellerType.business) {
      return ('commercial_register', 'tax_card');
    }
    return ('national_id_front', 'national_id_back');
  }
}
