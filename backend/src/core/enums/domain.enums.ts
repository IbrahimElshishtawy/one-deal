/**
 * Domain Enums for Deal One Backend Architecture
 *
 * Provides strongly-typed enums for compile-time safety and runtime validation
 * across the 28-table Modular Monolith architecture.
 */

export enum UserRole {
  USER = 'USER',
  MODERATOR = 'MODERATOR',
  SUPER_ADMIN = 'SUPER_ADMIN',
}

export enum UserStatus {
  PENDING_VERIFICATION = 'PENDING_VERIFICATION',
  ACTIVE = 'ACTIVE',
  SUSPENDED = 'SUSPENDED',
  DELETED = 'DELETED',
}

export enum AccountType {
  INDIVIDUAL = 'individual',
  COMPANY = 'company',
  FACTORY = 'factory',
  OFFICE = 'office',
  STORE = 'store',
}

export enum AccountMemberRole {
  OWNER = 'owner',
  MANAGER = 'manager',
  LISTER = 'lister',
  RESPONDER = 'responder',
}

export enum VerificationStatus {
  NOT_SUBMITTED = 'not_submitted',
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  NEEDS_CHANGES = 'needs_changes',
  SUSPENDED = 'suspended',
  EXPIRED = 'expired',
}

export enum VerificationTier {
  NONE = 'NONE',
  IDENTITY_VERIFIED = 'IDENTITY_VERIFIED',
  BUSINESS_VERIFIED = 'BUSINESS_VERIFIED',
}

export enum SellerApplicationType {
  INITIAL = 'INITIAL',
  BUSINESS_UPGRADE = 'BUSINESS_UPGRADE',
  RENEWAL = 'RENEWAL',
}

export enum SellerType {
  INDIVIDUAL = 'INDIVIDUAL',
  BUSINESS = 'BUSINESS',
  SERVICE_PROVIDER = 'SERVICE_PROVIDER',
}

export enum MarketplaceSection {
  REAL_ESTATE = 'real-estate',
  BUILDING_MATERIALS = 'building-materials',
  SERVICES = 'services',
  HOME_APPLIANCES = 'home-appliances',
  CARS = 'cars',
  FASHION = 'fashion',
}

export enum SellerApplicationStatus {
  NOT_REQUESTED = 'NOT_REQUESTED',
  DRAFT = 'DRAFT',
  PENDING = 'PENDING',
  UNDER_REVIEW = 'UNDER_REVIEW',
  NEEDS_CORRECTION = 'NEEDS_CORRECTION',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
  WITHDRAWN = 'WITHDRAWN',
  SUSPENDED = 'SUSPENDED',
  EXPIRED = 'EXPIRED',
}

export enum SellerDocumentType {
  NATIONAL_ID_FRONT = 'national_id_front',
  NATIONAL_ID_BACK = 'national_id_back',
  COMMERCIAL_REGISTER = 'commercial_register',
  TAX_CARD = 'tax_card',
  LEGAL_REPRESENTATION_PROOF = 'legal_representation_proof',
  PROFESSIONAL_LICENSE = 'professional_license',
  QUALIFICATION_CERTIFICATE = 'qualification_certificate',
  PROOF_OF_ADDRESS = 'proof_of_address',
  PORTFOLIO_DOCUMENT = 'portfolio_document',
  BUSINESS_LICENSE = 'business_license',
  ADDITIONAL_DOCUMENT = 'additional_document',
}

export enum SellerDocumentReviewDecision {
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
  CORRECTION_REQUIRED = 'CORRECTION_REQUIRED',
}

export enum SellerDocumentStatus {
  PENDING_UPLOAD = 'PENDING_UPLOAD',
  UPLOADED = 'UPLOADED',
  VERIFIED = 'VERIFIED',
  REJECTED = 'REJECTED',
  PURGED = 'PURGED',
}

export enum SellerCapability {
  CAN_CREATE_LISTING = 'canCreateListing',
  CAN_MANAGE_LISTING = 'canManageListing',
  CAN_ACCESS_SELLER_DASHBOARD = 'canAccessSellerDashboard',
  CAN_SUBMIT_SELLER_APPLICATION = 'canSubmitSellerApplication',
}

export enum ModerationStatus {
  DRAFT = 'draft',
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
}

export enum PublicationStatus {
  UNPUBLISHED = 'unpublished',
  PUBLISHED = 'published',
  HIDDEN = 'hidden',
  ARCHIVED = 'archived',
  EXPIRED = 'expired',
}

export enum AvailabilityStatus {
  AVAILABLE = 'available',
  RESERVED = 'reserved',
  SOLD = 'sold',
  RENTED = 'rented',
  OUT_OF_STOCK = 'out_of_stock',
  DISCONTINUED = 'discontinued',
}

export enum ListingStatus {
  DRAFT = 'draft',
  PENDING_REVIEW = 'pending',
  PUBLISHED = 'published',
  REJECTED = 'rejected',
  PAUSED = 'hidden',
  EXPIRED = 'expired',
  SOLD = 'sold',
  ARCHIVED = 'archived',
}

export enum ListingCondition {
  NEW = 'NEW',
  USED = 'USED',
  NOT_APPLICABLE = 'NOT_APPLICABLE',
}

export enum ListingKind {
  SALE = 'sale',
  RENT = 'rent',
  BUY = 'buy',
  SERVICE = 'service',
  PRODUCT = 'product',
}

export enum ContactChannel {
  IN_APP = 'in_app',
  EXTERNAL = 'external',
}

export enum MediaType {
  IMAGE = 'image',
  VIDEO = 'video',
}

export enum MediaStatus {
  PENDING = 'pending',
  READY = 'ready',
  FAILED = 'failed',
}

export enum PaymentStatus {
  PENDING = 'pending',
  SUCCESS = 'success',
  FAILED = 'failed',
  REFUNDED = 'refunded',
}

export enum PromoType {
  BUMP_UP = 'bump_up',
  FEATURED_7_DAYS = 'featured_7_days',
  FEATURED_14_DAYS = 'featured_14_days',
}

export enum ReportReason {
  SCAM = 'scam',
  INAPPROPRIATE = 'inappropriate',
  FALSE_INFO = 'false_info',
  DUPLICATE = 'duplicate',
  PROHIBITED = 'prohibited',
  OTHER = 'other',
}

export enum ReportStatus {
  OPEN = 'open',
  RESOLVED = 'resolved',
  DISMISSED = 'dismissed',
}

export enum ConversationStatus {
  OPEN = 'open',
  CLOSED = 'closed',
  ARCHIVED = 'archived',
}

export enum MessageStatus {
  SENT = 'sent',
  DELIVERED = 'delivered',
  READ = 'read',
}

export enum QuotaType {
  LISTINGS = 'listings',
  MESSAGES = 'messages',
  CONTACT_REVEAL = 'contact_reveal',
}

export enum FieldType {
  TEXT = 'text',
  NUMBER = 'number',
  SELECT = 'select',
  MULTI_SELECT = 'multi_select',
  BOOLEAN = 'boolean',
}
