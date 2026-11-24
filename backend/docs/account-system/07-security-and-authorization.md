# 07 — Security, Authorization & Audit Logging

## Security Controls

1. **Zero Client Trust**: Seller permissions are derived exclusively from PostgreSQL (`User.sellerStatus` and `Account.verificationStatus`) inside `SellerAuthorizationGuard` and service-layer defense-in-depth checks. Request body parameters or Flutter UI visibility cannot bypass verification.
2. **Private Document Isolation**:
   - `PrivateDocumentStorageService` enforces a dedicated private bucket (`R2_PRIVATE_BUCKET_NAME`) and canonical prefix `private/seller-verification/<userId>/<applicationId>/<uuid>.<ext>`.
   - Public listing media paths (`uploads/images/...`), path traversal sequences (`..`, `%2e`, `%2f`, `\`), and cross-user keys are rejected with `403 Forbidden`.
   - Raw `storageKey` values and storage credentials are never returned in user listing/status responses; access is granted solely via short-lived (300s) signed URLs after ownership or `verification.documents.read` verification.
3. **Rate Limiting**: All mutation and document access endpoints under `/api/v1/seller-applications/*` enforce Redis-backed `RateLimitGuard`.
4. **Immediate Revocation on Suspension**: Suspending a seller atomically updates `User.sellerStatus = 'SUSPENDED'` and `Account.verificationStatus = 'suspended'`, and immediately invalidates `account:membership:<userId>:<accountId>` in Redis.
5. **No Sensitive Data in Logs**: `SecurityAuditService.sanitizeMetadata()` redacts tokens, secrets, passwords, OTPs, and private document contents are never logged.

## Structured Audit Log Events (`audit_log`)

Every critical lifecycle and security event records `requestId` (`correlationId`), `userId`, `applicationId`, `adminId` (when applicable), `action`, `result`, `ipAddress`, `userAgent`, and `timestamp`:

- `SELLER_APPLICATION_CREATED`
- `SELLER_APPLICATION_DRAFT_UPDATED`
- `SELLER_DOCUMENT_UPLOAD_URL_ISSUED`
- `SELLER_DOCUMENT_UPLOADED`
- `SELLER_DOCUMENT_DELETED`
- `SELLER_DOCUMENT_ACCESSED`
- `ADMIN_SELLER_DOCUMENT_ACCESSED`
- `UNAUTHORIZED_DOCUMENT_ACCESS_ATTEMPTED`
- `SELLER_APPLICATION_SUBMITTED`
- `SELLER_APPLICATION_RESUBMISSION_DRAFT_OPENED`
- `SELLER_APPLICATION_REVIEWED`
- `SELLER_APPLICATION_APPROVED`
- `SELLER_APPLICATION_REJECTED`
- `SELLER_SUSPENDED`
- `SELLER_PERMISSIONS_GRANTED`
- `SELLER_PERMISSIONS_REVOKED`
- `UNAUTHORIZED_SELLER_OPERATION_ATTEMPTED`
