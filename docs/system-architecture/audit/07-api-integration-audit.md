# 07 — API & Mobile Integration Audit

## 1. Backend API Contract Verification

- **Global Validation:** `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })` (`backend/src/main.ts:77-84`) blocks mass-assignment (verified by E2E test rejecting client-supplied `verificationTier`).
- **Standard Error Envelope:** `HttpExceptionFilter` (`backend/src/core/filters/http-exception.filter.ts:199-207`) returns `{ success: false, error: { code, message, details, trace_id } }` and sanitizes Prisma `P2*`/`P1*` errors so SQL/schema/host strings are never leaked.
- **Public API Safety:** `formatPublicSellerVerification()` (`verification-tier.helper.ts:214-252`) returns only `id`, `name`, `slug`, `accountType`, `sellerType`, `verificationStatus`, `verificationTier`, `verificationBadge`, `logoUrl` — zero private documents, zero PII, zero rejection reasons.
- **Admin API Masking:** Verified that `listApplicationsForAdmin()` (`seller-application.service.ts:2354-2366`) and `getApplicationDetailForAdmin()` (`seller-application.service.ts:2454-2465`) mask all 4 sensitive identifiers (`nationalIdNumber`, `taxIdNumber`, `commercialRegisterNumber`, `authorizedRepresentativeId`).

## 2. Backend-to-Flutter Contract Gaps

| Feature / Endpoint | Backend Status | Flutter Status | Gap ID |
| :--- | :--- | :--- | :--- |
| `POST /api/v1/seller-applications/me/withdraw` | Implemented & tested | Not defined in `api_endpoints.dart` | `MOB-001` |
| `POST /api/v1/seller-applications/me/renew` | Implemented & tested | Not defined in `api_endpoints.dart` | `MOB-001` |
| `SellerApplicationStatus.WITHDRAWN` | Implemented & tested | Missing from `seller_verification_enums.dart` | `MOB-001` |
| `SellerApplicationStatus.EXPIRED` | Implemented & tested | Present in `seller_verification_enums.dart:56` | Aligned |
| `GET /api/v1/conversations/stream` (SSE) | Implemented (`chat.controller.ts:38`) | Needs verification whether Flutter subscribes to SSE or polls REST | Unverified in mobile UI |
| `POST /api/v1/conversations/:id/messages` | Implemented (no idempotency key) | Safe from `RetryInterceptor` (`GET`/`HEAD` only) | `MSG-001` |
| Presigned R2 PUT/GET | Implemented | `AuthInterceptor` scopes Bearer token to `trustedOrigin` (safe!) | Aligned |
