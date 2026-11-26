# 07 — Database Schema & Migrations

## Migrations

1. `20261124000001_add_seller_verification_system` — Base buyer-to-seller columns on `users`, `seller_applications`, `seller_application_documents`, and `seller_application_history`.
2. `20261126000001_enhance_seller_verification_identity_review` — Non-destructive enhancement adding `seller_verification_requirements`, `seller_document_reviews`, seller types, marketplace sections, encrypted PII storage width (`TEXT`), document versioning & expiration, correction tracking, expiration lifecycle, and soft deletion.

Zero existing users, accounts, listings, or relationships are deleted or altered destructively.

## Prisma Models & Tables

### 1. `SellerApplication` (`seller_applications`)
- **Identity & Relations**: `id` (UUID PK), `userId` (FK → `users.id`), `accountId` (FK → `accounts.id`), `reviewedByStaffId` / `assignedToStaffId` (FK → `staff_users.id`).
- **Classification**: `status` (`CHECK` across all 8 statuses), `sellerType` (`INDIVIDUAL` | `BUSINESS` | `SERVICE_PROVIDER`), `businessType`, `marketplaceSections` (`JSONB`).
- **Profile & Encrypted PII**: `businessName`, `businessDescription`, `nationalIdNumber` (`TEXT`, AES-256-GCM encrypted), `taxIdNumber` (`TEXT`, encrypted), `commercialRegisterNumber`, `authorizedRepresentativeName`, `authorizedRepresentativeId` (`TEXT`, encrypted), `serviceCategory`, `yearsOfExperience`, `qualifications`, `professionalLicenseNumber`, `portfolioUrl`, `contactPhone`, `contactEmail`, `cityId`, `address`.
- **Workflow & Lifecycle**: `submittedAt`, `reviewedAt`, `rejectionReason`, `suspensionReason`, `correctionFields` (`JSONB`), `correctionReason`, `correctionRequestedAt`, `verificationExpiresAt`, `expiredAt`, `resubmissionCount`, `isActive`, `deletedAt`.
- **Indexes & Constraints**:
  - Partial unique index `uq_seller_applications_active_user` on `(user_id)` where `is_active = true AND deleted_at IS NULL AND status IN ('DRAFT', 'PENDING', 'UNDER_REVIEW', 'NEEDS_CORRECTION', 'APPROVED')` — prevents duplicate active applications at the DB level.
  - Indexes on `(user_id, is_active)`, `(status, submitted_at)`, `(seller_type, status)`, `(assigned_to_staff_id, status)`, `(verification_expires_at)`.

### 2. `SellerVerificationRequirement` (`seller_verification_requirements`)
- `id` (UUID PK), `sellerType`, `marketplaceSection` (nullable = all sections), `documentType`, `displayName`, `displayNameAr`, `description`, `isRequired`, `acceptedMimeTypes` (`JSONB`), `maxFileSizeBytes`, `requiresExpiration`, `verificationRules` (`JSONB`), `isActive`, `version`, `sortOrder`, `createdByStaffId`, `updatedByStaffId`, `createdAt`, `updatedAt`, `deletedAt`.
- Indexes on `(seller_type, marketplace_section, is_active)` and `(document_type, is_active)`.

### 3. `SellerApplicationDocument` (`seller_application_documents`)
- `id` (UUID PK), `applicationId` (FK → `seller_applications.id`), `userId` (FK → `users.id`), `requirementId` (FK → `seller_verification_requirements.id`), `documentType`, `storageKey` (UNIQUE), `originalFileName`, `mimeType`, `fileSizeBytes`, `checksumSha256`, `status`, `version`, `isCurrent`, `replacedByDocumentId`, `expiresAt`, `rejectionReason`, `uploadedAt`, `createdAt`, `updatedAt`, `deletedAt`.
- Indexes on `(application_id, document_type)`, `(application_id, document_type, is_current)`, `(user_id)`, `(expires_at)`.

### 4. `SellerDocumentReview` (`seller_document_reviews`)
- `id` (UUID PK), `applicationId` (FK → `seller_applications.id`), `documentId` (FK → `seller_application_documents.id`), `adminId` (FK → `staff_users.id`), `decision` (`APPROVED` | `REJECTED` | `CORRECTION_REQUIRED`), `reason`, `notes`, `reviewedAt`, `createdAt`.
- Indexes on `(application_id, reviewed_at DESC)`, `(document_id, reviewed_at DESC)`, `(admin_id, reviewed_at DESC)`.

### 5. `SellerApplicationHistory` (`seller_application_history`)
- Immutable status transition ledger: `id`, `applicationId`, `userId`, `adminId`, `actorType`, `previousStatus`, `newStatus`, `reason`, `metadata`, `createdAt`.
- Indexes on `(application_id, created_at DESC)`, `(user_id, created_at DESC)`, `(admin_id, created_at DESC)`.
