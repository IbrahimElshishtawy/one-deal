# 03 — Secure Document Management

## Private Storage Isolation

- Verification documents are **never** stored in public listing media paths (`uploads/images/...`) and **never** served via `R2_PUBLIC_DOMAIN`.
- Dedicated private bucket: `R2_PRIVATE_BUCKET_NAME` (default `${R2_BUCKET_NAME}-private`).
- Strict canonical storage key structure:
  `private/seller-verification/<userId>/<applicationId>/<uuid>.<ext>`
- `PrivateDocumentStorageService.assertPrivateStorageKeyFormat()` rejects path traversal (`..`, `\`, URL-encoded `%2e`/`%2f`/`%5c`), null bytes, query/fragment characters, non-UUID segments, and non-private prefixes.
- Raw `storageKey` is **never** returned in user or admin application metadata responses; access is granted solely via short-lived AWS SigV4 presigned URLs (15 min for `PUT`, 5 min for `GET`).

## Supported Document Types

- `national_id_front`
- `national_id_back`
- `commercial_register`
- `tax_card`
- `legal_representation_proof`
- `professional_license`
- `qualification_certificate`
- `proof_of_address`
- `portfolio_document`
- `business_license`

## Multi-Layer File Validation

1. **MIME Type Allowlist**: Enforced against both global allowlist (`application/pdf`, `image/jpeg`, `image/png`, `image/webp`) and requirement-specific `acceptedMimeTypes`.
2. **Actual File Content Validation (Magic Bytes)**: `validateFileContentSignature()` verifies file header bytes (`%PDF-`, `FF D8 FF`, `89 50 4E 47 0D 0A 1A 0A`, `RIFF....WEBP`) against the declared MIME type to block spoofed executables or HTML/script payloads.
3. **File Size Enforcement**: Enforced against requirement-specific `maxFileSizeBytes` (default 10 MB, hard global cap 25 MB).
4. **Ownership Validation**: `validatePrivateDocumentOwnership()` verifies that `storageKey` embeds the authenticated user's `userId` and active `applicationId`.
5. **Upload Limits**: Enforces a maximum of 25 total document records per application (`DOCUMENT_UPLOAD_LIMIT_EXCEEDED`).
6. **Expiration Enforcement**: When a requirement has `requiresExpiration = true`, `expiresAt` is mandatory and must be a future date. Expired documents fail completeness checks during submission and admin approval.

## Versioning & Replacement

- Uploading a new file for an existing `documentType` or calling `PUT /api/v1/seller-applications/me/documents/:documentId/replace`:
  - Creates a new `SellerApplicationDocument` record with `version = previousVersion + 1`, `isCurrent = true`.
  - Marks the previous record `isCurrent = false` and links `replacedByDocumentId = newDocument.id`.
  - Previous versions remain preserved in PostgreSQL and audit history.
- During `NEEDS_CORRECTION`, users can **only** replace documents currently in `REJECTED` status; attempting to replace an accepted or unaffected document returns `403 UNAUTHORIZED_DOCUMENT_REPLACEMENT`.
- Removing a document in `DRAFT` (`DELETE /me/documents/:documentId`) performs a soft delete (`deletedAt = now()`, `isCurrent = false`).
