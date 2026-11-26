# 08 — Security, Privacy & Compliance

## Encryption at Rest & PII Masking

- `SensitiveDataCryptoService` encrypts `nationalIdNumber`, `taxIdNumber`, and `authorizedRepresentativeId` using **AES-256-GCM** with a random 12-byte IV and authentication tag (`enc:v1:<ivHex>:<tagHex>:<cipherHex>`), derived via SHA-256 from `SELLER_PII_ENCRYPTION_KEY` (falling back to `ADMIN_MFA_ENCRYPTION_KEY` / `JWT_ACCESS_SECRET` in non-production).
- Normal API responses (both user `/me` and admin list/detail views) **never** expose raw national ID numbers or tax IDs — values are always returned masked (e.g., `**********4567`).

## Zero-Leakage Logging & Audit Sanitization

- `SecurityAuditService.sanitizeMetadata()` automatically redacts sensitive keys before writing to `audit_log`:
  `password`, `secret`, `token`, `otp`, `jwt`, `cookie`, `authorization`, `api_key`, `private_key`, `nationalId`, `national_id`, `taxId`, `tax_id`, `representativeId`, `accessUrl`, `uploadUrl`, `signedUrl`, `documentContent`, `fileContent`, `fileHeaderBase64`.
- In-app notifications (`Notification` table) contain safe user-facing messages only — never national ID numbers, signed URLs, or internal admin notes.

## Access Control & Authorization

- **Server-Side Enforcement**: `SellerAuthorizationGuard` enforces seller capabilities (`CAN_CREATE_LISTING`, `CAN_MANAGE_LISTING`, `CAN_ACCESS_SELLER_DASHBOARD`, `CAN_SUBMIT_SELLER_APPLICATION`) on every request directly against PostgreSQL `User.sellerStatus` and `Account.verificationStatus` + `Account.isActive`. Flutter UI state is never trusted.
- **Buyer Permission Preservation**: Suspension (`SUSPENDED`) and expiration (`EXPIRED`) revoke seller-only capabilities without modifying `User.isActive` or `User.moderationStatus`, ensuring buyer browsing, favorites, cart, bookings, RFQs, and chat remain 100% functional.
- **Admin RBAC & Self-Approval Prevention**: Admin endpoints enforce granular permissions via `PermissionsGuard`, and `assertNotSelfAction()` blocks any admin from reviewing, approving, rejecting, suspending, or expiring their own application.
- **Private Document Access**: Ownership checks (`doc.userId === userId`) block cross-user access; admin document access requires `verification.documents.read` and generates an audited 5-minute signed URL.

## Abuse Prevention & Rate Limiting

- Per-endpoint `RateLimitGuard` limits:
  - Application creation / submission / resubmission: `10 req / hour`
  - Draft updates: `30 req / hour`
  - Document upload URL / confirm / replace / delete: `20 req / hour`
  - Own document access URL: `30 req / hour`
- Per-application document cap: maximum `25` document records per application.
- Database-level partial unique index `uq_seller_applications_active_user` + optimistic concurrency updates prevent duplicate submissions and duplicate admin approvals.
