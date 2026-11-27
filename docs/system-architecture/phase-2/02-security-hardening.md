# 02 — Security Hardening (Workstreams A & G)

## A. Server-Side R2 Ranged-GET Magic-Byte Verification (`SEC-001`, `SEC-002`)

- **File:** `backend/src/modules/accounts/services/private-document-storage.service.ts`
- **Mechanism:**
  1. `verifyUploadedObject()` runs SigV4 `HEAD` (`AbortSignal.timeout(10_000)`) to verify existence (`404 -> DOCUMENT_NOT_UPLOADED`), size (`1..maxSizeBytes`), and `content-type`.
  2. Immediately executes a SigV4 signed ranged `GET` (`Range: bytes=0-15`, `AbortSignal.timeout(10_000)`) against Cloudflare R2 and validates the actual stored file header bytes via `validateMagicBytesBuffer()` (`%PDF-`, JPEG `FF D8 FF`, PNG 8-byte header, WebP `RIFF....WEBP`).
  3. Rejects spoofed executables (e.g., `MZ` header claiming `application/pdf`), empty/truncated files (`HTTP 416 -> INVALID_FILE_CONTENT`), and R2 timeouts/5xx (`500 DOCUMENT_STORAGE_VERIFICATION_FAILED`).
- **Honest Upload Constraint Note (`SEC-002`):** Presigned `PUT` signs `content-type;host` (not `content-length`) to avoid mobile HTTP client header mismatches; exact `content-length` and real file bytes are enforced server-side before the document is accepted into PostgreSQL.

## G. Recursive PII & Presigned URL Log Redaction (`SEC-003`)

- **Files:** `backend/src/core/observability/request-context.ts`, `structured-flow.logger.ts`, `backend/src/core/filters/http-exception.filter.ts`, `backend/src/core/interceptors/logging.interceptor.ts`
- **Redacted Keys:** `nationalIdNumber`, `taxIdNumber`, `commercialRegisterNumber`, `authorizedRepresentativeId`, `uploadUrl`, `accessUrl`, `presigned*`, `signedUrl`, `X-Amz-Signature`, `X-Amz-Credential`, `fileHeaderBase64`, plus existing auth/token/password/OTP keys.
- **Redacted String Values (`sanitizeLogString`):** Any string matching `Bearer ...`, `X-Amz-Signature=`, `X-Amz-Credential=`, `X-Amz-Security-Token=`, `&sig=...`, `redis(s)://user:pass@`, `postgres(ql)://user:pass@`, inline `password=/token=/nationalId=`, or `enc:v<N>:...` ciphertext is sanitized across `StructuredFlowLogger`, `HttpExceptionFilter`, and `LoggingInterceptor`. Circular objects and `Error` instances are handled safely without throwing.
- **Test Evidence:** Verified in `backend/src/workers/phase2-hardening.spec.ts` and `backend/src/modules/accounts/services/seller-verification-hardening.spec.ts`.
