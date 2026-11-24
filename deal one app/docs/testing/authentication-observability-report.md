# Deal One — Authentication Integration & Development Observability Report

**Date:** 2026-11-24  
**Scope:** Flutter Mobile Application (`deal one app`) + NestJS Backend API (`backend`)  
**Production Base URL:** `https://one-deal-cjjt-production.up.railway.app/api/v1`

---

## 1. Executive Summary & Audit Findings

A full audit was completed across both the Flutter application and the NestJS backend before writing code.

### Verified Backend Auth Contract (No Duplicate Endpoints Created)
Deal One's authoritative backend uses **Egyptian mobile phone + 6-digit OTP** as primary identity provisioning, paired with **Email Verification** (Resend + single-use SHA-256 hashed tokens in Redis), **Password Auth/Reset** (Argon2), and **Rotating JWT Sessions** (access + refresh tokens with reuse detection and Redis denylisting):

| Endpoint | Method | Purpose |
| :--- | :--- | :--- |
| `/api/v1/auth/otp/send` | `POST` | Normalize phone, enforce IP/phone rate limits & 60s cooldown, generate & hash 6-digit OTP in PostgreSQL, dispatch via SMS/WhatsApp adapter. |
| `/api/v1/auth/otp/resend` | `POST` | Resend OTP subject to cooldown & rate limits. |
| `/api/v1/auth/otp/verify` | `POST` | Verify timing-safe SHA-256 hash (max 5 attempts, atomic single-use), provision `User` + default `Account` (`individual`, `approved`) + `AccountMember` (`owner`) in a Prisma transaction, issue JWT pair. |
| `/api/v1/users/me` | `GET` / `PUT` | Fetch/update authenticated user profile (`fullName`, `preferredLanguage`, etc.). |
| `/api/v1/auth/email/verification/request` | `POST` | Generate 256-bit single-use verification token (SHA-256 hashed in Redis, 30m TTL) and dispatch verification email via Resend. |
| `/api/v1/auth/email/verification/resend` | `POST` | Resend email verification link with 60s cooldown. |
| `/api/v1/auth/email/verify` | `POST` | Consume single-use token, update `User.email` + `User.isEmailVerified = true`, send confirmation email. |
| `/api/v1/auth/login` | `POST` | Password login fallback (Argon2 + per-account Redis throttling). |
| `/api/v1/auth/password/set` | `POST` | Set initial password for OTP-registered user. |
| `/api/v1/auth/password/change` | `POST` | Change password & revoke other active sessions. |
| `/api/v1/auth/password/forgot` | `POST` | Request `PASSWORD_RESET` OTP (anti-enumeration generic 200). |
| `/api/v1/auth/password/reset` | `POST` | Verify `PASSWORD_RESET` OTP, update password, revoke all sessions. |
| `/api/v1/auth/refresh` | `POST` | Rotate refresh token with reuse detection. |
| `/api/v1/auth/logout` | `POST` | Revoke active refresh session & denylist access token in Redis. |
| `/api/v1/auth/me` | `GET` | Return current authenticated identity & roles. |

---

## 2. Files Created & Modified

### New Files
| Layer | File | Purpose |
| :--- | :--- | :--- |
| Backend | `backend/src/core/observability/request-context.ts` | `AsyncLocalStorage` request context, fail-closed `isDevelopmentObservabilityEnabled()`, `maskEmail()`, `maskPhone()`, recursive `redactSensitiveData()`. |
| Backend | `backend/src/core/observability/structured-flow.logger.ts` | Unified lifecycle logger (`[REQUEST]`, `[AUTH]`, `[AUTH][DEV]`, `[VALIDATION]`, `[DATABASE]`, `[EMAIL]`, `[RESPONSE]`, `[ERROR]`). |
| Backend Test | `backend/src/core/observability/structured-flow.logger.spec.ts` | Unit tests verifying masking, secret redaction, dev-only OTP logging, and production fail-closed suppression. |
| Flutter Test | `deal one app/test/core/network/api_observability_interceptor_test.dart` | Unit tests verifying `LogSanitizer`, `RequestIdInterceptor`, `[API][REQUEST]`, `[API][RESPONSE]`, `[API][ERROR]`, and production payload suppression. |

### Modified Files
| Layer | File | Summary of Changes |
| :--- | :--- | :--- |
| Backend | `backend/src/core/interceptors/logging.interceptor.ts` | Runs every HTTP request inside `AsyncLocalStorage` request context (`x-request-id` / `x-trace-id`), logs `[REQUEST]` and `[RESPONSE]`/`[ERROR]` with `duration_ms`. |
| Backend | `backend/src/core/database/prisma.service.ts` | Added Prisma `$use` Database Activity Monitor classifying `CREATE`/`READ`/`UPDATE`/`DELETE` with model, status, duration, and `requestId` (zero PII/payload leakage; prod logs only errors & slow queries >500ms). |
| Backend | `backend/src/core/filters/http-exception.filter.ts` | Added unified `[ERROR]` structured logging with `layer` (`VALIDATION`, `AUTH`, `AUTHORIZATION`, `DATABASE`, `RATE_LIMIT`, `HTTP`, `SERVER`), `code`, `requestId`, timestamp, and dev-only stack traces. |
| Backend | `backend/src/modules/auth/services/otp.service.ts` | Emits `[AUTH][DEV]` (`OTP_GENERATED` with masked phone, purpose, createdAt, expiresAt, requestId) strictly in `NODE_ENV=development` + `[AUTH]` lifecycle log. |
| Backend | `backend/src/modules/email/email-verification.service.ts` | Emits `[AUTH][DEV]` (`EMAIL_VERIFICATION_TOKEN_GENERATED` with masked email, createdAt, expiresAt, requestId) strictly in `NODE_ENV=development` + `[AUTH]` lifecycle log. |
| Backend | `backend/src/modules/email/email.service.ts` | Emits `[EMAIL]` structured telemetry (`DISPATCHED` / `SKIPPED` / `FAILED`) with `durationMs` and masked recipients. |
| Backend | `backend/src/modules/auth/auth.controller.ts` & `email-verification.controller.ts` | Propagates `x-request-id` fallback alongside `x-trace-id` into all auth/email services and audit logs. |
| Flutter | `lib/core/logging/log_sanitizer.dart` | Masks emails & phones, redacts passwords/tokens/OTP/cookies/chat bodies, and caps huge payload previews cleanly. |
| Flutter | `lib/core/network/interceptors/request_id_interceptor.dart` | Mirrors `X-Request-ID` to `X-Trace-ID` and stamps `request_start_ms` for exact request duration calculation. |
| Flutter | `lib/core/network/interceptors/logging_interceptor.dart` | Emits `[API][REQUEST]`, `[API][RESPONSE]` (with `Duration`), and `[API][ERROR]` (with `Layer` + `Error Code` + `Request ID`); suppresses debug payloads in production. |
| Flutter | `lib/core/network/api_client.dart` | Attaches `NetworkLoggingInterceptor` with explicit `isProduction` separation. |
| Flutter | `lib/core/network/api_endpoints.dart` | Added verified `/auth/email/verification/request`, `/auth/email/verification/resend`, `/auth/email/verify`. |
| Flutter | `lib/features/auth/data/dto/auth_dto.dart`, `domain/entities/auth_session.dart`, `data/mappers/auth_mapper.dart`, `data/datasources/auth_remote_datasource.dart`, `data/repositories/auth_repository_impl.dart` | Added `isEmailVerified` on `AuthUser`/`AuthUserDto` and wired real Email Verification endpoints. |
| Flutter | `lib/core/navigation/drawer/deal_one_navigation_drawer.dart` | Fixed Drawer logout to call `authControllerProvider.notifier.logout()` so backend `POST /api/v1/auth/logout` revokes sessions instead of clearing local storage only. |

---

## 3. Authentication, OTP & Observability Architecture

### End-to-End Request Correlation
1. Flutter `RequestIdInterceptor` generates a unique `req-<micros>-<rand>` and sends it in both `X-Request-ID` and `X-Trace-ID`.
2. NestJS `LoggingInterceptor` reads `x-request-id` / `x-trace-id`, binds it into `AsyncLocalStorage`, and echoes both headers on the HTTP response.
3. Every downstream `[AUTH]`, `[AUTH][DEV]`, `[DATABASE]`, `[EMAIL]`, `[RESPONSE]`, and `[ERROR]` log line automatically carries the exact same `requestId`.

### Environment Separation (Fail-Closed)
| Capability | Development (`NODE_ENV=development`) | Production (`NODE_ENV=production`) |
| :--- | :--- | :--- |
| `[AUTH][DEV]` OTP / Verification Token Logs | **Enabled** (masked target, createdAt, expiresAt, requestId) | **Strictly Disabled** (double-checked against `process.env.NODE_ENV`) |
| OTP in API Response | **Never** | **Never** |
| OTP Storage in PostgreSQL | **SHA-256 + Pepper Hash** | **SHA-256 + Pepper Hash** |
| Flutter `[API][REQUEST]` / `[API][RESPONSE]` Payloads | **Enabled** (sanitized & truncated) | **Disabled** (only safe `[API][ERROR]` metadata) |
| Prisma `[DATABASE]` Activity Monitor | **All CRUD ops** (no user payload) | **Errors & slow queries (>500ms) only** |
| Stack Traces in Error Logs | **Enabled** | **Suppressed** |

---

## 4. Test Execution Results (Real Backend + PostgreSQL + Redis + Flutter)

### A. Live End-to-End Backend + Database Tests (Tests 1–12)
Executed against real local NestJS (`NODE_ENV=development`, `PORT=3099`), real PostgreSQL (`127.0.0.1:5432`), and real Redis (`127.0.0.1:6379`):

| Test | Scenario | Status | Verified Evidence |
| :--- | :--- | :--- | :--- |
| **Test 1 & 4** | Register / Send OTP & extract OTP from `[AUTH][DEV]` logs (never in API response) | **PASS** | `POST /auth/otp/send` returned `200`; 6-digit OTP extracted from `[AUTH][DEV]` log with masked phone; `otpAbsentFromResponse=true`. |
| **Test 2 & 5** | Verify correct OTP & confirm PostgreSQL records (`User`, `Account`, `AccountMember`, `Otp`, `Session`) | **PASS** | `POST /auth/otp/verify` (`200`) + `PUT /users/me` (`200`); verified in PostgreSQL: `isPhoneVerified=true`, `accounts=1`, `sessions=1`, `otpHashedInDb=true` (64-char SHA-256 hash). |
| **Test 3** | Email verification with real user-entered email | **PASS** | `POST /auth/email/verification/request` (`200`) -> token extracted from `[AUTH][DEV]` -> `POST /auth/email/verify` (`200`) -> PostgreSQL `User.isEmailVerified=true` & `User.email` updated. |
| **Test 6** | Wrong OTP rejected | **PASS** | `POST /auth/otp/verify` returned `400 BAD_REQUEST` (`Incorrect OTP code.`). |
| **Test 7** | Expired OTP rejected | **PASS** | Backdated `otp.expiresAt` in PostgreSQL -> `POST /auth/otp/verify` returned `400` (`Invalid or expired OTP code.`). |
| **Test 8** | Duplicate email registration attempt | **PASS** | Second user requesting verification for already-verified email received generic `200` (anti-enumeration), zero token issued, and `User.email` remained `null` in PostgreSQL. |
| **Test 9** | Password login after activation | **PASS** | `POST /auth/password/set` (`200`) + `POST /auth/login` (`200`) returned fresh access & refresh tokens. |
| **Test 10** | Session persistence & Refresh Token rotation | **PASS** | `GET /users/me` (`200`) + `POST /auth/refresh` (`200`) rotated refresh token (`rotated=true`). |
| **Test 11** | Logout & session revocation | **PASS** | `POST /auth/logout` (`200`) revoked session and denylisted access token; subsequent `GET /auth/me` immediately returned `401`. |
| **Test 12** | Validation error & Network failure | **PASS** | Invalid phone returned `400` with `trace_id=req-e2e-bad-phone`; unreachable host caught cleanly as network error. |
| **Log Audit** | Zero secret leaks & full lifecycle markers | **PASS** | `[REQUEST]`, `[AUTH][DEV]`, `[DATABASE]`, `[RESPONSE]`, `[ERROR]` all present; `LEAK_CHECK_PASSWORD=false`, `LEAK_CHECK_RAW_EMAIL=false`. |

### B. Automated Unit & Integration Suites
- **NestJS Backend (`npm run build` + Jest):**
  - `src/core/observability/structured-flow.logger.spec.ts` — **PASS**
  - `src/modules/auth/services/otp.service.spec.ts` — **PASS**
  - `src/modules/email/email-verification.service.spec.ts` — **PASS**
  - `src/core/filters/http-exception.filter.spec.ts` — **PASS**
  - Total: **4 suites, 23/23 tests passed**.
- **Flutter (`flutter analyze` + `flutter test`):**
  - `flutter analyze` on all 12 modified/new files — **0 issues**.
  - `test/core/network/api_observability_interceptor_test.dart` — **3/3 passed**.
  - `test/features/auth/auth_integration_test.dart` (single-flight token refresh, reused refresh token logout, sign-up + OTP + profile update + route guard) — **3/3 passed**.

---

## 5. Issues Discovered & Fixed / Remaining Notes

### Discovered & Fixed
1. **Missing `x-request-id` correlation in Auth/Email controllers:** Flutter sent `X-Request-ID`, while `AuthController` and `EmailVerificationController` only read `x-trace-id`. Fixed on both sides (Flutter now sends both headers; NestJS reads `x-request-id || x-trace-id` + `AsyncLocalStorage`).
2. **Drawer logout bypassed backend session revocation:** `DealOneNavigationDrawer` previously called `sessionProvider.notifier.logout()` directly instead of `authControllerProvider.notifier.logout()`, leaving backend refresh sessions active. Fixed to call `authControllerProvider.notifier.logout()`.
3. **Missing `isEmailVerified` hydration in Flutter:** Added `isEmailVerified` to `AuthUserDto` & `AuthUser` and wired `/auth/email/verification/*` endpoints in `AuthRemoteDataSourceImpl` and `AuthRepositoryImpl`.

### Remaining Operational Notes
- **Resend API Key in Local Dev:** When `RESEND_API_KEY` is unset in local `.env`, `EmailService` safely skips outbound SMTP/Resend delivery and emits `[EMAIL] ... (SKIPPED)` while `[AUTH][DEV]` prints the single-use verification token for local testing. Setting a valid `RESEND_API_KEY` enables real inbox delivery without any code changes.
- **No Database Schema Changes Required:** All existing Prisma models (`User`, `Account`, `AccountMember`, `Otp`, `UserSession`) already supported the complete auth + verification + session lifecycle cleanly.
