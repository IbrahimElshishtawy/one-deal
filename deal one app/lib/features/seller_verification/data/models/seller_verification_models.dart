import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final str = value.toString().trim();
  if (str.isEmpty) return null;
  return DateTime.tryParse(str);
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

class VerificationBadgeModel {
  static VerificationBadgeEntity? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final map = _asMap(raw);
    final code = VerificationTier.fromApi(map['code']?.toString());
    final label = map['label']?.toString().trim() ?? '';
    if (!code.isVerified || label.isEmpty) return null;
    return VerificationBadgeEntity(code: code, label: label);
  }

  static Map<String, dynamic> toJson(VerificationBadgeEntity entity) => {
    'code': entity.code.apiValue,
    'label': entity.label,
  };
}

class SellerVerificationRequirementModel {
  static SellerVerificationRequirementEntity fromJson(
    Map<String, dynamic> json,
  ) {
    final mimes = _asList(json['acceptedMimeTypes'])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    return SellerVerificationRequirementEntity(
      id: json['id']?.toString() ?? '',
      sellerType: json['sellerType']?.toString() ?? 'INDIVIDUAL',
      marketplaceSection: json['marketplaceSection']?.toString(),
      documentType: json['documentType']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      displayNameAr: json['displayNameAr']?.toString(),
      description: json['description']?.toString(),
      isRequired: json['isRequired'] == true,
      acceptedMimeTypes: mimes.isNotEmpty
          ? mimes
          : const ['application/pdf', 'image/jpeg', 'image/png', 'image/webp'],
      maxFileSizeBytes:
          _parseInt(json['maxFileSizeBytes']) ?? (10 * 1024 * 1024),
      requiresExpiration: json['requiresExpiration'] == true,
      sortOrder: _parseInt(json['sortOrder']) ?? 0,
    );
  }

  static Map<String, dynamic> toJson(
    SellerVerificationRequirementEntity entity,
  ) => {
    'id': entity.id,
    'sellerType': entity.sellerType,
    'marketplaceSection': entity.marketplaceSection,
    'documentType': entity.documentType,
    'displayName': entity.displayName,
    'displayNameAr': entity.displayNameAr,
    'description': entity.description,
    'isRequired': entity.isRequired,
    'acceptedMimeTypes': entity.acceptedMimeTypes,
    'maxFileSizeBytes': entity.maxFileSizeBytes,
    'requiresExpiration': entity.requiresExpiration,
    'sortOrder': entity.sortOrder,
  };
}

class SellerDocumentModel {
  static SellerDocumentEntity fromJson(Map<String, dynamic> json) {
    return SellerDocumentEntity(
      id: json['id']?.toString() ?? '',
      applicationId: json['applicationId']?.toString() ?? '',
      requirementId: json['requirementId']?.toString(),
      documentType: json['documentType']?.toString() ?? '',
      version: _parseInt(json['version']) ?? 1,
      isCurrent: json['isCurrent'] != false,
      originalFileName: json['originalFileName']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? 'application/octet-stream',
      fileSizeBytes: _parseInt(json['fileSizeBytes']) ?? 0,
      status: SellerDocumentStatus.fromApi(json['status']?.toString()),
      expiresAt: _parseDate(json['expiresAt']),
      rejectionReason: json['rejectionReason']?.toString(),
      uploadedAt: _parseDate(json['uploadedAt']),
    );
  }
}

class SellerApplicationModel {
  static SellerApplicationEntity fromJson(Map<String, dynamic> json) {
    final compRaw = json['completeness'];
    ApplicationCompletenessEntity? completeness;
    if (compRaw is Map) {
      final cm = _asMap(compRaw);
      completeness = ApplicationCompletenessEntity(
        isComplete: cm['isComplete'] == true,
        missingFields: _asList(cm['missingFields'])
            .map((e) => e.toString())
            .toList(),
        missingDocuments: _asList(cm['missingDocuments'])
            .map((e) => e.toString())
            .toList(),
        rejectedDocuments: _asList(cm['rejectedDocuments'])
            .map((e) => e.toString())
            .toList(),
        expiredDocuments: _asList(cm['expiredDocuments'])
            .map((e) => e.toString())
            .toList(),
        requiredDocuments: _asList(cm['requiredDocuments'])
            .map((e) => e.toString())
            .toList(),
      );
    }

    final docs = _asList(json['documents'])
        .whereType<Map>()
        .map((m) => SellerDocumentModel.fromJson(_asMap(m)))
        .toList(growable: false);

    return SellerApplicationEntity(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      accountId: json['accountId']?.toString(),
      applicationType: SellerApplicationType.fromApi(
        json['applicationType']?.toString(),
      ),
      status: VerificationStatus.fromApi(json['status']?.toString()),
      sellerType: SellerType.fromApi(json['sellerType']?.toString()),
      businessType: BusinessAccountType.fromApi(
        json['businessType']?.toString(),
      ),
      derivedVerificationTier: json['derivedVerificationTier'] != null
          ? VerificationTier.fromApi(json['derivedVerificationTier'].toString())
          : null,
      marketplaceSections: _asList(json['marketplaceSections'])
          .map((e) => e.toString())
          .toList(growable: false),
      businessName: json['businessName']?.toString(),
      businessDescription: json['businessDescription']?.toString(),
      maskedNationalId: json['nationalIdNumber']?.toString(),
      maskedTaxId: json['taxIdNumber']?.toString(),
      commercialRegisterNumber: json['commercialRegisterNumber']?.toString(),
      authorizedRepresentativeName: json['authorizedRepresentativeName']
          ?.toString(),
      serviceCategory: json['serviceCategory']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      contactEmail: json['contactEmail']?.toString(),
      cityId: _parseInt(json['cityId']),
      address: json['address']?.toString(),
      submittedAt: _parseDate(json['submittedAt']),
      reviewedAt: _parseDate(json['reviewedAt']),
      rejectionReason: json['rejectionReason']?.toString(),
      suspensionReason: json['suspensionReason']?.toString(),
      correctionReason: json['correctionReason']?.toString(),
      correctionFields: _asList(json['correctionFields'])
          .map((e) => e.toString())
          .toList(growable: false),
      correctionRequestedAt: _parseDate(json['correctionRequestedAt']),
      verificationExpiresAt: _parseDate(json['verificationExpiresAt']),
      resubmissionCount: _parseInt(json['resubmissionCount']) ?? 0,
      requiredDocuments: _asList(json['requiredDocuments'])
          .map((e) => e.toString())
          .toList(growable: false),
      completeness: completeness,
      documents: docs,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

class VerificationStatusModel {
  static VerificationStatusSnapshot fromJson(Map<String, dynamic> json) {
    final capMap = _asMap(json['capabilities']);
    final capabilities = SellerCapabilitiesEntity(
      canBuy: capMap['canBuy'] != false,
      canCreateListing: capMap['canCreateListing'] == true,
      canManageListing: capMap['canManageListing'] == true,
      canAccessSellerDashboard: capMap['canAccessSellerDashboard'] == true,
      canSubmitSellerApplication: capMap['canSubmitSellerApplication'] == true,
      canUpgradeToBusiness: capMap['canUpgradeToBusiness'] == true,
    );

    final appRaw = json['application'];
    final upgradeRaw = json['businessUpgradeApplication'];

    return VerificationStatusSnapshot(
      userId: json['userId']?.toString() ?? '',
      sellerStatus: VerificationStatus.fromApi(
        json['sellerStatus']?.toString(),
      ),
      sellerType: json['sellerType'] != null
          ? SellerType.fromApi(json['sellerType'].toString())
          : null,
      verificationTier: VerificationTier.fromApi(
        json['verificationTier']?.toString(),
      ),
      verificationBadge: VerificationBadgeModel.fromJson(
        json['verificationBadge'],
      ),
      capabilities: capabilities,
      sellerApprovedAt: _parseDate(json['sellerApprovedAt']),
      sellerSuspendedAt: _parseDate(json['sellerSuspendedAt']),
      sellerSuspensionReason: json['sellerSuspensionReason']?.toString(),
      application: appRaw is Map
          ? SellerApplicationModel.fromJson(_asMap(appRaw))
          : null,
      businessUpgradeApplication: upgradeRaw is Map
          ? SellerApplicationModel.fromJson(_asMap(upgradeRaw))
          : null,
    );
  }
}

class VerificationHistoryItemModel {
  static VerificationHistoryItemEntity fromJson(Map<String, dynamic> json) {
    return VerificationHistoryItemEntity(
      id: json['id']?.toString() ?? '',
      applicationId: json['applicationId']?.toString() ?? '',
      actorType: json['actorType']?.toString() ?? 'system',
      previousStatus: VerificationStatus.fromApi(
        json['previousStatus']?.toString(),
      ),
      newStatus: VerificationStatus.fromApi(json['newStatus']?.toString()),
      reason: json['reason']?.toString(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }
}

class BusinessUpgradeModel {
  static BusinessUpgradeSnapshot fromJson(Map<String, dynamic> json) {
    final reqs = _asList(json['businessRequirements'])
        .whereType<Map>()
        .map((m) => SellerVerificationRequirementModel.fromJson(_asMap(m)))
        .toList(growable: false);

    final appRaw = json['application'];

    return BusinessUpgradeSnapshot(
      accountId: json['accountId']?.toString(),
      currentSellerType: json['currentSellerType'] != null
          ? SellerType.fromApi(json['currentSellerType'].toString())
          : null,
      currentVerificationTier: VerificationTier.fromApi(
        json['currentVerificationTier']?.toString(),
      ),
      currentVerificationBadge: VerificationBadgeModel.fromJson(
        json['currentVerificationBadge'],
      ),
      eligibleForUpgrade: json['eligibleForUpgrade'] == true,
      businessRequirements: reqs,
      application: appRaw is Map
          ? SellerApplicationModel.fromJson(_asMap(appRaw))
          : null,
    );
  }
}

class PrivateUploadTargetModel {
  static PrivateUploadTargetEntity fromJson(Map<String, dynamic> json) {
    return PrivateUploadTargetEntity(
      applicationId: json['applicationId']?.toString() ?? '',
      documentType: json['documentType']?.toString() ?? '',
      requirementId: json['requirementId']?.toString(),
      storageKey: json['storageKey']?.toString() ?? '',
      uploadUrl: json['uploadUrl']?.toString() ?? '',
      expiresInSeconds: _parseInt(json['expiresInSeconds']) ?? 900,
      contentType: json['contentType']?.toString() ?? 'image/jpeg',
      maxSizeBytes: _parseInt(json['maxSizeBytes']) ?? (10 * 1024 * 1024),
    );
  }
}
