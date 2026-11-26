/// Authoritative Seller Verification domain enums aligned 1:1 with the Deal One backend.

enum SellerType {
  individual('INDIVIDUAL'),
  business('BUSINESS'),
  serviceProvider('SERVICE_PROVIDER');

  final String apiValue;
  const SellerType(this.apiValue);

  static SellerType fromApi(String? raw) {
    switch (raw?.trim().toUpperCase()) {
      case 'BUSINESS':
        return SellerType.business;
      case 'SERVICE_PROVIDER':
        return SellerType.serviceProvider;
      case 'INDIVIDUAL':
      default:
        return SellerType.individual;
    }
  }
}

enum VerificationTier {
  none('NONE'),
  identityVerified('IDENTITY_VERIFIED'),
  businessVerified('BUSINESS_VERIFIED');

  final String apiValue;
  const VerificationTier(this.apiValue);

  bool get isVerified => this != VerificationTier.none;

  static VerificationTier fromApi(String? raw) {
    switch (raw?.trim().toUpperCase()) {
      case 'IDENTITY_VERIFIED':
        return VerificationTier.identityVerified;
      case 'BUSINESS_VERIFIED':
        return VerificationTier.businessVerified;
      case 'NONE':
      default:
        return VerificationTier.none;
    }
  }
}

enum VerificationStatus {
  notSubmitted('NOT_REQUESTED'),
  draft('DRAFT'),
  pending('PENDING'),
  underReview('UNDER_REVIEW'),
  needsChanges('NEEDS_CORRECTION'),
  approved('APPROVED'),
  rejected('REJECTED'),
  suspended('SUSPENDED'),
  expired('EXPIRED');

  final String apiValue;
  const VerificationStatus(this.apiValue);

  bool get isApproved => this == VerificationStatus.approved;
  bool get isInReview =>
      this == VerificationStatus.pending ||
      this == VerificationStatus.underReview;
  bool get requiresAction =>
      this == VerificationStatus.rejected ||
      this == VerificationStatus.needsChanges ||
      this == VerificationStatus.expired;
  bool get isEditable =>
      this == VerificationStatus.draft ||
      this == VerificationStatus.needsChanges ||
      this == VerificationStatus.rejected ||
      this == VerificationStatus.expired;

  static VerificationStatus fromApi(String? raw) {
    switch (raw?.trim().toUpperCase()) {
      case 'DRAFT':
        return VerificationStatus.draft;
      case 'PENDING':
        return VerificationStatus.pending;
      case 'UNDER_REVIEW':
        return VerificationStatus.underReview;
      case 'NEEDS_CORRECTION':
      case 'NEEDS_CHANGES':
        return VerificationStatus.needsChanges;
      case 'APPROVED':
        return VerificationStatus.approved;
      case 'REJECTED':
        return VerificationStatus.rejected;
      case 'SUSPENDED':
        return VerificationStatus.suspended;
      case 'EXPIRED':
        return VerificationStatus.expired;
      case 'NOT_SUBMITTED':
      case 'NOT_REQUESTED':
      default:
        return VerificationStatus.notSubmitted;
    }
  }
}

enum SellerApplicationType {
  initial('INITIAL'),
  businessUpgrade('BUSINESS_UPGRADE');

  final String apiValue;
  const SellerApplicationType(this.apiValue);

  static SellerApplicationType fromApi(String? raw) {
    switch (raw?.trim().toUpperCase()) {
      case 'BUSINESS_UPGRADE':
        return SellerApplicationType.businessUpgrade;
      case 'INITIAL':
      default:
        return SellerApplicationType.initial;
    }
  }
}

enum SellerDocumentStatus {
  pendingUpload('PENDING_UPLOAD'),
  uploaded('UPLOADED'),
  verified('VERIFIED'),
  rejected('REJECTED');

  final String apiValue;
  const SellerDocumentStatus(this.apiValue);

  bool get isAcceptedOrUploaded =>
      this == SellerDocumentStatus.uploaded ||
      this == SellerDocumentStatus.verified;

  static SellerDocumentStatus fromApi(String? raw) {
    switch (raw?.trim().toUpperCase()) {
      case 'PENDING_UPLOAD':
        return SellerDocumentStatus.pendingUpload;
      case 'VERIFIED':
        return SellerDocumentStatus.verified;
      case 'REJECTED':
        return SellerDocumentStatus.rejected;
      case 'UPLOADED':
      default:
        return SellerDocumentStatus.uploaded;
    }
  }
}

enum MarketplaceSectionSlug {
  realEstate('real-estate'),
  buildingMaterials('building-materials'),
  services('services'),
  homeAppliances('home-appliances'),
  cars('cars'),
  fashion('fashion');

  final String apiValue;
  const MarketplaceSectionSlug(this.apiValue);

  static MarketplaceSectionSlug? tryFromApi(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    for (final value in MarketplaceSectionSlug.values) {
      if (value.apiValue == normalized) return value;
    }
    return null;
  }
}

enum BusinessAccountType {
  individual('individual'),
  company('company'),
  office('office'),
  store('store'),
  factory('factory');

  final String apiValue;
  const BusinessAccountType(this.apiValue);

  static BusinessAccountType fromApi(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'company':
        return BusinessAccountType.company;
      case 'office':
        return BusinessAccountType.office;
      case 'store':
        return BusinessAccountType.store;
      case 'factory':
        return BusinessAccountType.factory;
      case 'individual':
      default:
        return BusinessAccountType.individual;
    }
  }
}
