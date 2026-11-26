import 'dart:typed_data';

import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';

/// Public verification badge returned by the backend.
/// Never constructed from client-side sellerType guesses.
class VerificationBadgeEntity {
  final VerificationTier code;
  final String label;

  const VerificationBadgeEntity({
    required this.code,
    required this.label,
  });

  bool get isIdentity => code == VerificationTier.identityVerified;
  bool get isBusiness => code == VerificationTier.businessVerified;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerificationBadgeEntity &&
          code == other.code &&
          label == other.label;

  @override
  int get hashCode => Object.hash(code, label);
}

/// Configurable verification document requirement from `seller_verification_requirements`.
class SellerVerificationRequirementEntity {
  final String id;
  final String sellerType;
  final String? marketplaceSection;
  final String documentType;
  final String displayName;
  final String? displayNameAr;
  final String? description;
  final bool isRequired;
  final List<String> acceptedMimeTypes;
  final int maxFileSizeBytes;
  final bool requiresExpiration;
  final int sortOrder;

  const SellerVerificationRequirementEntity({
    required this.id,
    required this.sellerType,
    this.marketplaceSection,
    required this.documentType,
    required this.displayName,
    this.displayNameAr,
    this.description,
    required this.isRequired,
    this.acceptedMimeTypes = const [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/webp',
    ],
    this.maxFileSizeBytes = 10 * 1024 * 1024,
    this.requiresExpiration = false,
    this.sortOrder = 0,
  });

  String localizedName({required bool isArabic}) {
    if (isArabic && displayNameAr != null && displayNameAr!.trim().isNotEmpty) {
      return displayNameAr!.trim();
    }
    return displayName;
  }

  double get maxFileSizeMb => maxFileSizeBytes / (1024 * 1024);
}

/// Private uploaded verification document metadata (never contains public URLs).
class SellerDocumentEntity {
  final String id;
  final String applicationId;
  final String? requirementId;
  final String documentType;
  final int version;
  final bool isCurrent;
  final String originalFileName;
  final String mimeType;
  final int fileSizeBytes;
  final SellerDocumentStatus status;
  final DateTime? expiresAt;
  final String? rejectionReason;
  final DateTime? uploadedAt;

  const SellerDocumentEntity({
    required this.id,
    required this.applicationId,
    this.requirementId,
    required this.documentType,
    this.version = 1,
    this.isCurrent = true,
    required this.originalFileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.status,
    this.expiresAt,
    this.rejectionReason,
    this.uploadedAt,
  });

  bool get isPdf => mimeType.toLowerCase() == 'application/pdf';
  bool get isImage => mimeType.toLowerCase().startsWith('image/');
}

class ApplicationCompletenessEntity {
  final bool isComplete;
  final List<String> missingFields;
  final List<String> missingDocuments;
  final List<String> rejectedDocuments;
  final List<String> expiredDocuments;
  final List<String> requiredDocuments;

  const ApplicationCompletenessEntity({
    required this.isComplete,
    this.missingFields = const [],
    this.missingDocuments = const [],
    this.rejectedDocuments = const [],
    this.expiredDocuments = const [],
    this.requiredDocuments = const [],
  });
}

class SellerApplicationEntity {
  final String id;
  final String userId;
  final String? accountId;
  final SellerApplicationType applicationType;
  final VerificationStatus status;
  final SellerType sellerType;
  final BusinessAccountType businessType;
  final VerificationTier? derivedVerificationTier;
  final List<String> marketplaceSections;
  final String? businessName;
  final String? businessDescription;
  final String? maskedNationalId;
  final String? maskedTaxId;
  final String? commercialRegisterNumber;
  final String? authorizedRepresentativeName;
  final String? serviceCategory;
  final String? contactPhone;
  final String? contactEmail;
  final int? cityId;
  final String? address;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? suspensionReason;
  final String? correctionReason;
  final List<String> correctionFields;
  final DateTime? correctionRequestedAt;
  final DateTime? verificationExpiresAt;
  final int resubmissionCount;
  final List<String> requiredDocuments;
  final ApplicationCompletenessEntity? completeness;
  final List<SellerDocumentEntity> documents;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SellerApplicationEntity({
    required this.id,
    required this.userId,
    this.accountId,
    this.applicationType = SellerApplicationType.initial,
    required this.status,
    required this.sellerType,
    this.businessType = BusinessAccountType.individual,
    this.derivedVerificationTier,
    this.marketplaceSections = const [],
    this.businessName,
    this.businessDescription,
    this.maskedNationalId,
    this.maskedTaxId,
    this.commercialRegisterNumber,
    this.authorizedRepresentativeName,
    this.serviceCategory,
    this.contactPhone,
    this.contactEmail,
    this.cityId,
    this.address,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.suspensionReason,
    this.correctionReason,
    this.correctionFields = const [],
    this.correctionRequestedAt,
    this.verificationExpiresAt,
    this.resubmissionCount = 0,
    this.requiredDocuments = const [],
    this.completeness,
    this.documents = const [],
    this.createdAt,
    this.updatedAt,
  });

  SellerDocumentEntity? currentDocumentFor(String documentType) {
    for (final doc in documents) {
      if (doc.documentType == documentType && doc.isCurrent) {
        return doc;
      }
    }
    return null;
  }
}

class SellerCapabilitiesEntity {
  final bool canBuy;
  final bool canCreateListing;
  final bool canManageListing;
  final bool canAccessSellerDashboard;
  final bool canSubmitSellerApplication;
  final bool canUpgradeToBusiness;

  const SellerCapabilitiesEntity({
    this.canBuy = true,
    this.canCreateListing = false,
    this.canManageListing = false,
    this.canAccessSellerDashboard = false,
    this.canSubmitSellerApplication = true,
    this.canUpgradeToBusiness = false,
  });
}

/// Full verification status snapshot returned by `GET /seller-applications/me`.
class VerificationStatusSnapshot {
  final String userId;
  final VerificationStatus sellerStatus;
  final SellerType? sellerType;
  final VerificationTier verificationTier;
  final VerificationBadgeEntity? verificationBadge;
  final SellerCapabilitiesEntity capabilities;
  final DateTime? sellerApprovedAt;
  final DateTime? sellerSuspendedAt;
  final String? sellerSuspensionReason;
  final SellerApplicationEntity? application;
  final SellerApplicationEntity? businessUpgradeApplication;

  const VerificationStatusSnapshot({
    required this.userId,
    required this.sellerStatus,
    this.sellerType,
    this.verificationTier = VerificationTier.none,
    this.verificationBadge,
    this.capabilities = const SellerCapabilitiesEntity(),
    this.sellerApprovedAt,
    this.sellerSuspendedAt,
    this.sellerSuspensionReason,
    this.application,
    this.businessUpgradeApplication,
  });

  /// Authoritative badge display rule: never show a badge unless status is APPROVED
  /// and backend returned a valid non-NONE tier & badge.
  VerificationBadgeEntity? get activeBadge {
    if (!sellerStatus.isApproved || !verificationTier.isVerified) {
      return null;
    }
    return verificationBadge;
  }
}

class VerificationHistoryItemEntity {
  final String id;
  final String applicationId;
  final String actorType;
  final VerificationStatus previousStatus;
  final VerificationStatus newStatus;
  final String? reason;
  final DateTime createdAt;

  const VerificationHistoryItemEntity({
    required this.id,
    required this.applicationId,
    required this.actorType,
    required this.previousStatus,
    required this.newStatus,
    this.reason,
    required this.createdAt,
  });
}

class BusinessUpgradeSnapshot {
  final String? accountId;
  final SellerType? currentSellerType;
  final VerificationTier currentVerificationTier;
  final VerificationBadgeEntity? currentVerificationBadge;
  final bool eligibleForUpgrade;
  final List<SellerVerificationRequirementEntity> businessRequirements;
  final SellerApplicationEntity? application;

  const BusinessUpgradeSnapshot({
    this.accountId,
    this.currentSellerType,
    this.currentVerificationTier = VerificationTier.none,
    this.currentVerificationBadge,
    this.eligibleForUpgrade = false,
    this.businessRequirements = const [],
    this.application,
  });
}

class PrivateUploadTargetEntity {
  final String applicationId;
  final String documentType;
  final String? requirementId;
  final String storageKey;
  final String uploadUrl;
  final int expiresInSeconds;
  final String contentType;
  final int maxSizeBytes;

  const PrivateUploadTargetEntity({
    required this.applicationId,
    required this.documentType,
    this.requirementId,
    required this.storageKey,
    required this.uploadUrl,
    required this.expiresInSeconds,
    required this.contentType,
    required this.maxSizeBytes,
  });
}

/// Locally selected file held only in memory during upload (never persisted to disk/prefs).
class PickedDocumentFile {
  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  const PickedDocumentFile({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  int get sizeBytes => bytes.length;
  bool get isPdf => mimeType.toLowerCase() == 'application/pdf';
  bool get isImage => mimeType.toLowerCase().startsWith('image/');
}
