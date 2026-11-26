import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';

/// Client-side input & file validators aligned with backend validation rules.
class SellerVerificationValidators {
  SellerVerificationValidators._();

  static const int globalMaxDocumentBytes = 25 * 1024 * 1024;
  static const List<String> defaultAllowedMimeTypes = [
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  static String? validateName(String? value, {required bool isArabic}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return isArabic ? 'هذا الحقل مطلوب' : 'This field is required';
    }
    if (trimmed.length < 2) {
      return isArabic
          ? 'يجب أن يكون الاسم حرفين على الأقل'
          : 'Must be at least 2 characters';
    }
    if (trimmed.length > 150) {
      return isArabic
          ? 'الحد الأقصى 150 حرفاً'
          : 'Maximum length is 150 characters';
    }
    return null;
  }

  static String? validateNationalId(String? value, {required bool isArabic}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return isArabic
          ? 'الرقم القومي مطلوب'
          : 'National ID number is required';
    }
    if (trimmed.length < 6 || trimmed.length > 50) {
      return isArabic
          ? 'يرجى إدخال رقم قومي صحيح (6 إلى 50 رقماً)'
          : 'Please enter a valid National ID (6-50 characters)';
    }
    return null;
  }

  static String? validateCommercialRegister(
    String? value, {
    required bool isArabic,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return isArabic
          ? 'رقم السجل التجاري مطلوب'
          : 'Commercial registration number is required';
    }
    if (trimmed.length < 3 || trimmed.length > 100) {
      return isArabic
          ? 'رقم السجل التجاري يجب أن يكون 3 أحرف على الأقل'
          : 'Commercial register must be at least 3 characters';
    }
    return null;
  }

  static String? validatePhone(String? value, {required bool isArabic}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null; // optional override; backend falls back to user phone
    final digits = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length < 10 || digits.length > 20) {
      return isArabic
          ? 'يرجى إدخال رقم هاتف صحيح'
          : 'Please enter a valid phone number';
    }
    return null;
  }

  static String? validateEmail(String? value, {required bool isArabic}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(trimmed)) {
      return isArabic
          ? 'يرجى إدخال بريد إلكتروني صحيح'
          : 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates a locally picked document file against a requirement's MIME,
  /// extension, and size constraints before initiating any upload.
  static String? validateDocumentFile(
    PickedDocumentFile file, {
    SellerVerificationRequirementEntity? requirement,
    required bool isArabic,
  }) {
    if (file.bytes.isEmpty) {
      return isArabic ? 'الملف المختار فارغ' : 'Selected file is empty';
    }

    final allowedMimes =
        (requirement != null && requirement.acceptedMimeTypes.isNotEmpty)
            ? requirement.acceptedMimeTypes
            : defaultAllowedMimeTypes;

    final normalizedMime = file.mimeType.trim().toLowerCase();
    if (!allowedMimes.contains(normalizedMime)) {
      return isArabic
          ? 'صيغة الملف غير مدعومة. الصيغ المقبولة: PDF, JPG, PNG, WEBP'
          : 'Unsupported file format. Accepted: PDF, JPG, PNG, WEBP';
    }

    final maxSize = requirement != null && requirement.maxFileSizeBytes > 0
        ? requirement.maxFileSizeBytes.clamp(1, globalMaxDocumentBytes)
        : 10 * 1024 * 1024;

    if (file.sizeBytes > maxSize) {
      final mb = (maxSize / (1024 * 1024)).toStringAsFixed(0);
      return isArabic
          ? 'حجم الملف يتجاوز الحد الأقصى المسموح ($mb ميجابايت)'
          : 'File exceeds maximum allowed size ($mb MB)';
    }

    // Extension vs MIME consistency check
    final dotIdx = file.fileName.lastIndexOf('.');
    if (dotIdx <= 0 || dotIdx == file.fileName.length - 1) {
      return isArabic
          ? 'يجب أن يحتوي اسم الملف على امتداد صحيح'
          : 'File name must include a valid extension';
    }
    final ext = file.fileName.substring(dotIdx + 1).toLowerCase();
    const validExtByMime = <String, List<String>>{
      'application/pdf': ['pdf'],
      'image/jpeg': ['jpg', 'jpeg'],
      'image/png': ['png'],
      'image/webp': ['webp'],
    };
    final expectedExts = validExtByMime[normalizedMime] ?? const [];
    if (!expectedExts.contains(ext)) {
      return isArabic
          ? 'امتداد الملف (.$ext) لا يطابق نوع الملف'
          : 'File extension (.$ext) does not match file type';
    }

    return null;
  }

  /// Derives the MIME type from a filename extension.
  static String? inferMimeType(String fileName) {
    final dotIdx = fileName.lastIndexOf('.');
    if (dotIdx <= 0 || dotIdx == fileName.length - 1) return null;
    switch (fileName.substring(dotIdx + 1).toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  /// Validates that all required documents are uploaded and not rejected.
  static List<SellerVerificationRequirementEntity> findMissingRequiredDocuments({
    required List<SellerVerificationRequirementEntity> requirements,
    required List<SellerDocumentEntity> uploadedDocuments,
  }) {
    final acceptedTypes = uploadedDocuments
        .where((d) => d.isCurrent && d.status.isAcceptedOrUploaded)
        .map((d) => d.documentType)
        .toSet();

    return requirements
        .where((r) => r.isRequired && !acceptedTypes.contains(r.documentType))
        .toList(growable: false);
  }
}
