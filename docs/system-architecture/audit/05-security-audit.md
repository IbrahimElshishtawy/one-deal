# 05 — Security, Privacy, Storage & RBAC Audit

## A. Private Storage & Upload Security (`private-document-storage.service.ts`)

### Finding `SEC-001` — HIGH — Magic-Byte Validation Relies on Client-Supplied Base64, Not Server Ranged-GET
- **Status:** VERIFIED
- **Evidence:** `backend/src/modules/accounts/services/private-document-storage.service.ts:165-236,385-445`
- **Actual Behavior:** `validateFileContentSignature(mimeType, fileHeaderBase64)` validates magic bytes from the **client-supplied** `dto.fileHeaderBase64` (and skips silently if omitted, line 169). `verifyUploadedObject()` performs an R2 SigV4 `HEAD` request which validates object existence, `content-length`, and `content-type`, **but `HEAD` does NOT inspect actual stored file bytes**. A malicious client could upload a spoofed payload to R2 and submit valid JPEG magic bytes in `fileHeaderBase64` (or omit it).
- **Recommended Resolution:** Perform a server-side R2 SigV4 ranged `GET` (`Range: bytes=0-15`) during `verifyUploadedObject()` to verify the actual stored magic bytes on R2.
- **Business Decision Required:** No.

### Finding `SEC-002` — MEDIUM — Presigned PUT URL Does Not Bind `Content-Length`
- **Status:** VERIFIED
- **Evidence:** `backend/src/modules/accounts/services/private-document-storage.service.ts:386-408`
- **Actual Behavior:** `signR2PresignedUrl('PUT', storageKey, 900, mimeType)` signs `content-type;host` only. A client could PUT a file larger than `maxFileSizeBytes` to R2 (which would later be rejected at `confirm` via `HEAD` check, leaving an oversized unconfirmed object in R2).
- **Recommended Resolution:** Bind `content-length` in the signed PUT headers (when client provides exact `fileSizeBytes`) or enforce R2 bucket lifecycle cleanup.
- **Business Decision Required:** No.

### Malware Scanning (`private-document-storage.service.ts:471-478`)
- **Status:** NOT IMPLEMENTED (Explicitly Documented Boundary)
- **Actual Behavior:** `scanDocumentBoundary()` returns `{ status: 'SCANNER_NOT_CONFIGURED', provider: 'none' }`. No AV/malware engine is active.
- **Business Decision Required:** Yes — decide whether to launch with MIME/extension/ranged-GET magic-byte/private-bucket controls or gate uploads until ClamAV / Cloudflare R2 Security Scan is provisioned.

---

## B. PII, Logging & Monitoring (`request-context.ts`, `logging.interceptor.ts`, `main.ts`)

### Finding `SEC-003` — MEDIUM — Log Redaction Regex Omits KYC Identifiers & Presigned URL Keys
- **Status:** VERIFIED
- **Evidence:** `backend/src/core/observability/request-context.ts:71-72`
- **Actual Behavior:** `SENSITIVE_KEY_PATTERN` matches `password|passcode|token|authorization|secret|otp|codehash|cookie|cvv|card|credit|apikey|privatekey|messagecontent|chatbody`, but omits `nationalid`, `taxid`, `commercialregister`, `authorizedrepresentativeid`, `uploadurl`, `accessurl`, `x-amz-signature`. While `LoggingInterceptor` does not log request/response bodies (verified `logging.interceptor.ts:75-120`), any future `StructuredFlowLogger.stage()` call passing those keys would not auto-redact them.
- **Recommended Resolution:** Expand `SENSITIVE_KEY_PATTERN` to include KYC identifier and signed URL key names.
- **Business Decision Required:** No.

### Finding `OBS-001` — MEDIUM — Sentry SDK Declared in Env Config But Not Initialized in Code
- **Status:** NOT IMPLEMENTED
- **Evidence:** `backend/src/core/config/env.config.ts:342` (`SENTRY_DSN`); `grep -rn "Sentry\|@sentry" backend/src/` returned zero matches.
- **Actual Behavior:** Setting `SENTRY_DSN` in production has no effect; unhandled exceptions are only logged to stdout.
- **Recommended Resolution:** Integrate `@sentry/node` with `beforeSend` PII scrubbing (or remove `SENTRY_DSN` from production docs until integrated).
- **Business Decision Required:** No.

### Finding `SEC-004` — LOW — No Automated Batch Re-Encryption CLI/Job for Key Rotation or Legacy Plaintext
- **Status:** PARTIALLY VERIFIED
- **Evidence:** `backend/src/modules/accounts/services/sensitive-data-crypto.service.ts:218-238`
- **Actual Behavior:** `SensitiveDataCryptoService` provides `needsReencryption()` and `reencrypt()` primitives, and transparently decrypts legacy `v1` and plaintext rows. However, no standalone resumable CLI/worker job exists yet to batch-migrate older rows before retiring an old key version.
- **Recommended Resolution:** Add an idempotent, resumable re-encryption script before the first production key rotation.
- **Business Decision Required:** No.

---

## C. Admin RBAC & MFA (`admin-auth/`)

### Finding `RBAC-001` — MEDIUM — Admin MFA Is Not Enforced by Any Guard on Sensitive Endpoints
- **Status:** VERIFIED
- **Evidence:** `backend/src/modules/admin-auth/guards/admin-jwt-auth.guard.ts:102`, `grep -rn "mfaVerified" backend/src/`
- **Actual Behavior:** `AdminJwtAuthGuard` populates `request.user.mfaVerified`, but no guard or decorator rejects `mfaVerified === false` on sensitive admin endpoints (`verification.approve`, `verification.documents.read`, `roles.update`, `users.ban`). MFA only triggers if a staff account has opted into `mfaEnabled = true`.
- **Recommended Resolution:** Add `@RequireMfa()` guard enforcement for privileged roles (`super_admin`, `verification_officer`, `platform_admin`) in production.
- **Business Decision Required:** Yes (rollout policy for staff MFA).

### Finding `RBAC-002` — MEDIUM — `operations_manager` Has `verification.approve` Without `verification.documents.read`
- **Status:** VERIFIED
- **Evidence:** `backend/src/modules/admin-auth/constants/admin-permissions.constant.ts:534-564`
- **Actual Behavior:** `operations_manager` holds `verification.read` and `verification.approve` (lines 553-554) without `verification.documents.read`, enabling blind approval without inspecting KYC documents.
- **Business Decision Required:** Yes — confirm whether `operations_manager` should lose `verification.approve` or be granted audited `verification.documents.read`.
