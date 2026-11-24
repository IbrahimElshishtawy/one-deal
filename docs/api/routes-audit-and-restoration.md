# Deal One — Backend Routes Audit, Restoration & Stabilization

**Date:** 2026-11-24
**Scope:** Complete NestJS + Fastify backend routing architecture (`backend/src`)
**Global API Prefix:** `/api/v1` (exclusions: `/health/live`, `/health/liveness`, `/health/ready`, `/health/readiness`, `/metrics`)
**OpenAPI / Swagger UI:** `/api/docs` & `/api/docs-json` (enabled in non-production or when `ENABLE_SWAGGER=true`)

---

## 1. Initial Routing Architecture

- **Framework & Adapter:** NestJS 10 with `FastifyAdapter` (`maxParamLength: 200`, `bodyLimit: 2MB`, `requestTimeout: 30s`, `trustProxy` parsed via `parseTrustProxy`).
- **Global Prefix:** Single global prefix `api/v1` configured in `src/main.ts` with explicit exclusions for Kubernetes/Railway liveness/readiness probes and Prometheus `/metrics`. No second global prefix or conflicting URI versioning is configured.
- **Middleware & Pipeline Execution Order:**
  1. Fastify plugins: `@fastify/cookie`, `@fastify/helmet` (CSP tightened in production), `@fastify/cors` (strict origin allowlist in production; native mobile clients with no `Origin` header permitted).
  2. Global middleware (`AppModule.configure`): `RequestIdMiddleware` on `*` (propagates/generates `x-request-id` & `x-trace-id`).
  3. Route guards (controller/handler scoped — no blanket global auth guard that would break public endpoints): `JwtAuthGuard`, `AdminJwtAuthGuard`, `UserOrAdminJwtAuthGuard`, `PermissionsGuard`, `SellerAuthorizationGuard`, `RateLimitGuard`, `MetricsAuthGuard`.
  4. Global `ValidationPipe` (`whitelist: true`, `forbidNonWhitelisted: true`, `transform: true`, `enableImplicitConversion: true`).
  5. Global interceptors: `MetricsInterceptor` -> `LoggingInterceptor` -> `TransformInterceptor` (enforces `{ success: true, data, meta? }` envelope).
  6. Global exception filter: `HttpExceptionFilter` (enforces `{ success: false, error: { code, message, details, trace_id } }` envelope).
- **Modules & Controllers:** 27 active feature/core modules registering **38 controllers** (zero duplicate controller registrations). `PaymentsModule` (3 routes) is conditionally registered when `ENABLE_V2_PAYMENTS=true`.

---

## 2. Problems Discovered

| # | Severity | Area | Problem |
|---|----------|------|---------|
| 1 | **High (Security)** | `AdminAuthController` | Normal marketplace users (`actorType: 'user'`, `permissions: []`) received `200 OK` on `GET /api/v1/admin/auth/me`, `200 OK` (`[]`) on `GET /api/v1/admin/auth/sessions`, and `404` instead of `403` on `DELETE /api/v1/admin/auth/sessions/:sessionId`. |
| 2 | **Medium (Validation / Observability)** | `ListingsController`, `AccountsController`, `ChatController` | UUID path parameters (`:id`, `:branchId`, `:userId`) lacked `ParseUUIDPipe`. Malformed UUIDs bypassed route validation, triggered PostgreSQL `P2023` errors, and logged bogus `500` errors in `LoggingInterceptor` before `HttpExceptionFilter` mapped them to `400`. |
| 3 | **Medium (REST / Error Semantics)** | `BookingsController`, `RfqController` | User-facing endpoints (`GET/PATCH /bookings/:id*`, `GET/PATCH /rfqs/:id*`, `GET/PATCH /quotations/:id*`) used `AdminJwtAuthGuard` directly, returning a misleading `"Admin authentication token is missing, invalid, or expired"` 401 message to unauthenticated mobile users. |
| 4 | **Medium (REST Semantics)** | `AccountsService` / `GET /api/v1/accounts/:id` | Non-existent or inactive seller account UUIDs returned `200 OK` with `{ success: true, data: null }`, contradicting `@ApiResponse({ status: 404 })` and REST 404 semantics. |
| 5 | **Low–Medium (REST Consistency)** | `UsersController`, `ListingsController` | Only `PUT /api/v1/users/me` and `PUT /api/v1/listings/:id` existed; standard REST `PATCH` requests returned `404`. |
| 6 | **Low–Medium (DTO Validation)** | `AdminUsersController` | `GET /api/v1/admin/accounts` used a TypeScript intersection type (`AdminPaginationDto & { ... }`) and `unsuspend`/`unban` used inline `{ notes?: string }`, which erase to `Object` at runtime and bypass `ValidationPipe` & Swagger schema generation. |

---

## 3. Root Cause of Each Problem

1. **`AdminAuthController` access bypass:** `AdminJwtAuthGuard` intentionally accepts mobile JWTs and attaches `{ actorType: 'user', staffId: null, permissions: [] }` so `PermissionsGuard` can return `403 Forbidden` instead of `401`. Because `me`, `listSessions`, and `revokeSession` did not use `PermissionsGuard` and lacked explicit staff/permission checks (unlike `setupMfa`/`changePassword` in the same controller), normal users were allowed through.
2. **Missing `ParseUUIDPipe`:** Earlier controllers (`ListingsController`, `ChatController`, and the first half of `AccountsController`) omitted `ParseUUIDPipe`, relying on Prisma runtime error `P2023` fallback in `HttpExceptionFilter`.
3. **Misleading 401 message on Bookings/RFQ:** `AdminJwtAuthGuard` was reused for dual-actor (User or Admin) routes without customizing the unauthorized message.
4. **`GET /accounts/:id` returning 200 `null`:** `AccountsService.getAccountById` returned `null` instead of throwing `NotFoundException`.
5. **Missing `PATCH` aliases:** Original Flutter integration used `PUT` for profile and listing updates; `PATCH` handlers were never added.
6. **Erased inline DTO types:** TypeScript intersection types and inline object literals do not emit class metadata (`design:paramtypes`), causing `ValidationPipe` to skip validation.

---

## 4. Routes Repaired

- **`GET /api/v1/admin/auth/me`** — Now rejects non-staff callers without admin permissions with `403 Forbidden`.
- **`GET /api/v1/admin/auth/sessions`** & **`DELETE /api/v1/admin/auth/sessions/:sessionId`** — Now reject non-staff callers with `403 Forbidden`.
- **`GET /api/v1/bookings/:id`**, **`PATCH /api/v1/bookings/:id/cancel`**, **`PATCH /api/v1/bookings/:id/status`**, **`GET /api/v1/rfqs/:id`**, **`PATCH /api/v1/rfqs/:id/cancel`**, **`GET /api/v1/rfqs/:id/quotations`**, **`GET /api/v1/quotations/:id`**, **`PATCH /api/v1/quotations/:id/status`** — Switched to dedicated `UserOrAdminJwtAuthGuard` (exported from `AdminAuthModule`), returning accurate `"Authentication token is missing, invalid, or expired"` on 401 while preserving dual-actor User/Admin access.
- **`GET /api/v1/accounts/:id`** — Now throws `NotFoundException` (`404 Not Found`) when account is missing, inactive, or deleted.
- **UUID Parameter Validation (`ParseUUIDPipe`)** added across:
  - `ListingsController`: `GET/PUT/PATCH/DELETE /api/v1/listings/:id`, `PATCH /api/v1/listings/:id/availability`, `POST /api/v1/listings/:id/submit`, `PATCH /api/v1/listings/:id/status`, `POST /api/v1/listings/:id/contact`, `POST /api/v1/listings/:id/reveal-contact`.
  - `AccountsController`: `GET /api/v1/accounts/:id`, `GET/POST /api/v1/accounts/:id/branches`, `PUT/DELETE /api/v1/accounts/:id/branches/:branchId`, `GET /api/v1/accounts/:id/members`, `POST /api/v1/accounts/:id/members/invite`, `DELETE /api/v1/accounts/:id/members/:userId`.
  - `ChatController`: `GET/POST /api/v1/conversations/:id/messages`.
- **Natural REST `PATCH` aliases added** (preserving existing `PUT` contracts):
  - `PATCH /api/v1/users/me`
  - `PATCH /api/v1/listings/:id`
- **Admin DTO validation restored:**
  - `GET /api/v1/admin/accounts` -> `AdminAccountsQueryDto`
  - `POST /api/v1/admin/users/:id/unsuspend` & `POST /api/v1/admin/users/:id/unban` -> `OptionalAdminNotesDto`

---

## 5. Routes Preserved

- **100% backward compatibility** preserved for all existing Flutter mobile contracts (`deal one app/lib/core/network/api_endpoints.dart`) and Admin Web contracts:
  - All `PUT` endpoints (`PUT /api/v1/users/me`, `PUT /api/v1/listings/:id`, etc.) remain unchanged.
  - All mobile/OpenAPI aliases (`/auth/password/login`, `/auth/token/refresh`, `/listings/favorites`, `/listings/:listingId/favorite`, `/listings/:id/reveal-contact`, `/media/upload-urls`, `/media/presigned-url`, `/media/confirm`) remain active.
  - Verified that Fastify's radix router resolves static `GET /api/v1/listings/favorites` ahead of parametric `GET /api/v1/listings/:id`.
  - Buyer + Seller account architecture and mandatory server-side `SellerAuthorizationGuard` enforcement remain intact.

---

## 6. Authentication & Authorization Matrix

| Classification | Guard(s) | Behavior | Route Count |
|----------------|----------|----------|-------------|
| **Public** | None | Open browsing, health probes, public CMS, webhooks (signature-verified in service) | 29 |
| **Public (Rate-Limited)** | `RateLimitGuard` | OTP send/verify, login, refresh, password reset, email verify, dev-guest (disabled in prod) | 16 |
| **Token / Internal IP** | `MetricsAuthGuard` | `GET /metrics` (requires `METRICS_AUTH_TOKEN` or loopback in prod) | 1 |
| **Authenticated (User)** | `JwtAuthGuard` (+ optional `RateLimitGuard`) | Profile, sessions, favorites, cart, bookings list/create, RFQs list/create, chat, media, notifications, quotas, activity-hub, seller-application draft/docs | 58 |
| **Authenticated (User or Admin)** | `UserOrAdminJwtAuthGuard` | Booking detail/cancel/status, RFQ detail/cancel/quotations, Quotation detail/status (owner/participant or admin checked in service) | 8 |
| **Seller-Restricted** | `JwtAuthGuard` + `SellerAuthorizationGuard` | Listing create/update/delete/status/submit, seller dashboard, commercial accounts/branches/members/service-areas, RFQ quotation submit, video upload token | 22 |
| **Admin-Only (Staff)** | `AdminJwtAuthGuard` (staff-enforced) | Admin identity, sessions, MFA management, password change | 7 |
| **Admin Permission-Restricted** | `AdminJwtAuthGuard` + `PermissionsGuard` | All `/api/v1/admin/*` management, moderation, seller verification, RBAC staff, CMS, analytics, settings, feature flags | 97 |

---

## 7. Final Complete Route Inventory (238 Live Fastify Routes)

> Generated directly from the running NestJS + Fastify application (`AppModule`).
> Note: 3 additional V2 routes (`GET /api/v1/payments/packages`, `POST /api/v1/payments/checkout`, `POST /api/v1/payments/webhook`) are registered when `ENABLE_V2_PAYMENTS=true`.

| Method | Full Path | Controller.Handler | Module | Auth Classification | Role / Permission / Capability | Status | Response Structure |
|--------|-----------|-------------------|--------|---------------------|-------------------------------|--------|--------------------|
| `GET` | `/health/liveness` | `HealthController.getLiveness` | `AppModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/health/live` | `HealthController.getLiveness` | `AppModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/health/readiness` | `HealthController.getReadiness` | `AppModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/health/ready` | `HealthController.getReadiness` | `AppModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/metrics` | `MetricsController.getPrometheusMetrics` | `MetricsModule` | Token / Internal IP | METRICS_AUTH_TOKEN or loopback/RFC1918 | 200 | text/plain (Prometheus) |
| `GET` | `/api/v1/notifications` | `NotificationsController.getNotifications` | `NotificationsModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/notifications/read-all` | `NotificationsController.markAllAsRead` | `NotificationsModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/notifications/:id/read` | `NotificationsController.markAsRead` | `NotificationsModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/notifications/device-token` | `NotificationsController.registerToken` | `NotificationsModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/otp/send` | `AuthController.sendOtp` | `AuthModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/otp/resend` | `AuthController.resendOtp` | `AuthModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/otp/verify` | `AuthController.verifyOtp` | `AuthModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/login` | `AuthController.loginWithPassword` | `AuthModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/password/login` | `AuthController.loginPasswordAlias` | `AuthModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/password/set` | `AuthController.setPassword` | `AuthModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/password/change` | `AuthController.changePassword` | `AuthModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/password/forgot` | `AuthController.forgotPassword` | `AuthModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/password/reset` | `AuthController.resetPassword` | `AuthModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/refresh` | `AuthController.refreshToken` | `AuthModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/token/refresh` | `AuthController.refreshTokenAlias` | `AuthModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/logout` | `AuthController.logout` | `AuthModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/sessions/terminate-all` | `AuthController.terminateAllSessions` | `AuthModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/auth/sessions` | `AuthController.getActiveSessions` | `AuthModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/auth/me` | `AuthController.getCurrentIdentity` | `AuthModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/dev-guest` | `AuthController.devGuestLogin` | `AuthModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/email/verification/request` | `EmailVerificationController.requestVerification` | `EmailModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/email/verification/resend` | `EmailVerificationController.resendVerification` | `EmailModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/auth/email/verify` | `EmailVerificationController.verifyEmail` | `EmailModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/users/me` | `UsersController.getMyProfile` | `UsersModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `PUT` | `/api/v1/users/me` | `UsersController.updateMyProfile` | `UsersModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/users/me` | `UsersController.patchMyProfile` | `UsersModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/users/me` | `UsersController.deleteMyAccount` | `UsersModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/accounts` | `AccountsController.createAccount` | `AccountsModule` | Role/Capability-restricted (Seller) | canAccessSellerDashboard | 201 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/accounts/:id/branches` | `AccountsController.createBranch` | `AccountsModule` | Role/Capability-restricted (Seller) | canAccessSellerDashboard | 201 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/accounts/my-accounts` | `AccountsController.getMyAccounts` | `AccountsModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/accounts/:id` | `AccountsController.getAccountById` | `AccountsModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/accounts/:id/branches` | `AccountsController.getAccountBranches` | `AccountsModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `PUT` | `/api/v1/accounts/:id/branches/:branchId` | `AccountsController.updateBranch` | `AccountsModule` | Role/Capability-restricted (Seller) | canAccessSellerDashboard | 200 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/accounts/:id/branches/:branchId` | `AccountsController.deleteBranch` | `AccountsModule` | Role/Capability-restricted (Seller) | canAccessSellerDashboard | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/accounts/:id/members` | `AccountsController.getAccountMembers` | `AccountsModule` | Role/Capability-restricted (Seller) | canAccessSellerDashboard | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/accounts/:id/members/invite` | `AccountsController.inviteMember` | `AccountsModule` | Role/Capability-restricted (Seller) | canAccessSellerDashboard | 201 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/accounts/:id/members/:userId` | `AccountsController.removeMember` | `AccountsModule` | Role/Capability-restricted (Seller) | canAccessSellerDashboard | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/accounts/:id/service-areas` | `AccountsController.getServiceAreas` | `AccountsModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/accounts/:id/service-areas` | `AccountsController.upsertServiceArea` | `AccountsModule` | Role/Capability-restricted (Seller) | canAccessSellerDashboard | 200 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/accounts/:id/service-areas/:serviceAreaId` | `AccountsController.removeServiceArea` | `AccountsModule` | Role/Capability-restricted (Seller) | canAccessSellerDashboard | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/accounts/:id/verifications` | `AccountsController.getAccountVerifications` | `AccountsModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/accounts/:id/verifications` | `AccountsController.submitVerification` | `AccountsModule` | Authenticated (Mobile JWT) | Authenticated User | 201 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/seller-applications` | `SellerApplicationController.requestSellerConversion` | `AccountsModule` | Role/Capability-restricted (Seller) | canSubmitSellerApplication | 201 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/seller-applications/me` | `SellerApplicationController.getMyApplication` | `AccountsModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/seller-applications/me/history` | `SellerApplicationController.getMyApplicationHistory` | `AccountsModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/seller-applications/me` | `SellerApplicationController.updateDraft` | `AccountsModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/seller-applications/me/documents/upload-url` | `SellerApplicationController.requestDocumentUploadUrl` | `AccountsModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/seller-applications/me/documents` | `SellerApplicationController.registerDocument` | `AccountsModule` | Authenticated (Mobile JWT) | Authenticated User | 201 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/seller-applications/me/documents/:documentId/access` | `SellerApplicationController.getOwnDocumentAccessUrl` | `AccountsModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/seller-applications/me/documents/:documentId` | `SellerApplicationController.deleteDocument` | `AccountsModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/seller-applications/me/submit` | `SellerApplicationController.submitApplication` | `AccountsModule` | Role/Capability-restricted (Seller) | canSubmitSellerApplication | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/seller-applications/me/resubmit` | `SellerApplicationController.resubmitApplication` | `AccountsModule` | Role/Capability-restricted (Seller) | canSubmitSellerApplication | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/seller-applications/dashboard` | `SellerApplicationController.getSellerDashboard` | `AccountsModule` | Role/Capability-restricted (Seller) | canAccessSellerDashboard | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/seller-applications` | `AdminSellerApplicationsController.listApplications` | `AccountsModule` | Admin-only (Staff JWT) | verification.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/seller-applications/:id` | `AdminSellerApplicationsController.getApplicationDetail` | `AccountsModule` | Admin-only (Staff JWT) | verification.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/seller-applications/:id/history` | `AdminSellerApplicationsController.getApplicationHistory` | `AccountsModule` | Admin-only (Staff JWT) | verification.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/seller-applications/:id/documents/:documentId` | `AdminSellerApplicationsController.getDocumentAccess` | `AccountsModule` | Admin-only (Staff JWT) | verification.documents.read | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/seller-applications/:id/review` | `AdminSellerApplicationsController.startReview` | `AccountsModule` | Admin-only (Staff JWT) | ANY(verification.approve | verification.reject) | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/seller-applications/:id/approve` | `AdminSellerApplicationsController.approveApplication` | `AccountsModule` | Admin-only (Staff JWT) | verification.approve | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/seller-applications/:id/reject` | `AdminSellerApplicationsController.rejectApplication` | `AccountsModule` | Admin-only (Staff JWT) | verification.reject | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/seller-applications/:id/suspend` | `AdminSellerApplicationsController.suspendSeller` | `AccountsModule` | Admin-only (Staff JWT) | ANY(verification.reject | users.suspend) | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/seller-applications/:id/reinstate` | `AdminSellerApplicationsController.reinstateSeller` | `AccountsModule` | Admin-only (Staff JWT) | verification.approve | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/auth/login` | `AdminAuthController.login` | `AdminAuthModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/auth/mfa/verify` | `AdminAuthController.verifyMfa` | `AdminAuthModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/auth/refresh` | `AdminAuthController.refresh` | `AdminAuthModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/auth/logout` | `AdminAuthController.logout` | `AdminAuthModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/auth/me` | `AdminAuthController.me` | `AdminAuthModule` | Admin-only (Staff JWT) | Staff Only | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/auth/sessions` | `AdminAuthController.listSessions` | `AdminAuthModule` | Admin-only (Staff JWT) | Staff Only | 200 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/admin/auth/sessions/:sessionId` | `AdminAuthController.revokeSession` | `AdminAuthModule` | Admin-only (Staff JWT) | Staff Only | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/auth/mfa/setup` | `AdminAuthController.setupMfa` | `AdminAuthModule` | Admin-only (Staff JWT) | Staff Only | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/auth/mfa/enable` | `AdminAuthController.enableMfa` | `AdminAuthModule` | Admin-only (Staff JWT) | Staff Only | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/auth/mfa/disable` | `AdminAuthController.disableMfa` | `AdminAuthModule` | Admin-only (Staff JWT) | Staff Only | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/auth/password/change` | `AdminAuthController.changePassword` | `AdminAuthModule` | Admin-only (Staff JWT) | Staff Only | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/auth/password/forgot` | `AdminAuthController.forgotPassword` | `AdminAuthModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/auth/password/reset` | `AdminAuthController.resetPassword` | `AdminAuthModule` | Public (Rate-Limited) | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/categories` | `CategoriesController.getCategoryTree` | `CategoriesModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/categories/:slug` | `CategoriesController.getCategoryBySlug` | `CategoriesModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/categories/:slug/fields` | `CategoriesController.getCategoryFields` | `CategoriesModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/categories` | `AdminCategoriesController.listAllAdminCategories` | `CategoriesModule` | Admin-only (Staff JWT) | categories.read | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/categories` | `AdminCategoriesController.createCategory` | `CategoriesModule` | Admin-only (Staff JWT) | categories.create | 201 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/admin/categories/reorder` | `AdminCategoriesController.reorderCategories` | `CategoriesModule` | Admin-only (Staff JWT) | categories.update | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/admin/categories/:id` | `AdminCategoriesController.updateCategory` | `CategoriesModule` | Admin-only (Staff JWT) | categories.update | 200 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/admin/categories/:id` | `AdminCategoriesController.deleteOrDeactivateCategory` | `CategoriesModule` | Admin-only (Staff JWT) | categories.delete | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/categories/:id/fields` | `AdminCategoriesController.listCategoryFields` | `CategoriesModule` | Admin-only (Staff JWT) | categories.read | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/categories/:id/fields` | `AdminCategoriesController.upsertField` | `CategoriesModule` | Admin-only (Staff JWT) | categories.update | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/admin/categories/:id/fields/:fieldId` | `AdminCategoriesController.updateField` | `CategoriesModule` | Admin-only (Staff JWT) | categories.update | 200 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/admin/categories/:id/fields/:fieldId` | `AdminCategoriesController.deactivateField` | `CategoriesModule` | Admin-only (Staff JWT) | categories.delete | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/media/images/upload-url` | `MediaController.requestImageUploadUrls` | `MediaModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/media/upload-urls` | `MediaController.requestUploadUrlsAlias` | `MediaModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/media/presigned-url` | `MediaController.requestPresignedUrlAlias` | `MediaModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/media/confirm-upload` | `MediaController.confirmUpload` | `MediaModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/media/confirm` | `MediaController.confirmUploadAlias` | `MediaModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/listings` | `ListingsController.getFeed` | `ListingsModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/listings/prices/batch` | `ListingsController.getBatchPrices` | `ListingsModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/listings/:id` | `ListingsController.getById` | `ListingsModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/listings` | `ListingsController.createListing` | `ListingsModule` | Role/Capability-restricted (Seller) | canCreateListing | 201 | `{ success: true, data, meta? }` |
| `PUT` | `/api/v1/listings/:id` | `ListingsController.updateListing` | `ListingsModule` | Role/Capability-restricted (Seller) | canManageListing | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/listings/:id` | `ListingsController.patchListing` | `ListingsModule` | Role/Capability-restricted (Seller) | canManageListing | 200 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/listings/:id` | `ListingsController.deleteListing` | `ListingsModule` | Role/Capability-restricted (Seller) | canManageListing | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/listings/:id/availability` | `ListingsController.updateAvailability` | `ListingsModule` | Role/Capability-restricted (Seller) | canManageListing | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/listings/:id/submit` | `ListingsController.submitForModeration` | `ListingsModule` | Role/Capability-restricted (Seller) | canManageListing | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/listings/:id/status` | `ListingsController.updateStatus` | `ListingsModule` | Role/Capability-restricted (Seller) | canManageListing | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/listings/:id/contact` | `ListingsController.contactSeller` | `ListingsModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/listings/:id/reveal-contact` | `ListingsController.revealContactAlias` | `ListingsModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/home` | `HomeController.getHomeFeed` | `HomeModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/home/featured` | `HomeController.getFeatured` | `HomeModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/home/latest` | `HomeController.getLatest` | `HomeModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/home/recommended` | `HomeController.getRecommended` | `HomeModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/home/categories` | `HomeController.getPopularCategories` | `HomeModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/home/sections/:sectionSlug` | `HomeController.getSectionHome` | `HomeModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/search` | `SearchController.search` | `SearchModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/search/suggestions` | `SearchController.suggestions` | `SearchModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/conversations/stream` | `ChatController.streamMessages` | `ChatModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | text/event-stream (SSE) |
| `GET` | `/api/v1/conversations` | `ChatController.getMyConversations` | `ChatModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/conversations` | `ChatController.startConversation` | `ChatModule` | Authenticated (Mobile JWT) | Authenticated User | 201 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/conversations/:id/messages` | `ChatController.getMessages` | `ChatModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/conversations/:id/messages` | `ChatController.sendMessage` | `ChatModule` | Authenticated (Mobile JWT) | Authenticated User | 201 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/media/video/upload-token` | `VideoController.getUploadToken` | `VideoModule` | Role/Capability-restricted (Seller) | canCreateListing | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/media/video/webhook` | `VideoController.handleWebhook` | `VideoModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/video-feed` | `VideoController.getVideoFeed` | `VideoModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/reports` | `ModerationController.fileReport` | `ModerationModule` | Authenticated (Mobile JWT) | Authenticated User | 201 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/moderation/listings` | `ModerationController.getPendingListings` | `ModerationModule` | Admin-only (Staff JWT) | listings.read | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/moderation/listings/:id/decision` | `ModerationController.adjudicateListing` | `ModerationModule` | Admin-only (Staff JWT) | ANY(listings.approve | listings.reject) | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/moderation/queue` | `ModerationController.getQueue` | `ModerationModule` | Admin-only (Staff JWT) | reports.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/moderation/reports/:id` | `ModerationController.getReportDetail` | `ModerationModule` | Admin-only (Staff JWT) | reports.read | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/moderation/reports/:id/assign` | `ModerationController.assignReport` | `ModerationModule` | Admin-only (Staff JWT) | reports.assign | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/moderation/reports/:id/notes` | `ModerationController.addReportNote` | `ModerationModule` | Admin-only (Staff JWT) | reports.resolve | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/admin/moderation/reports/:id` | `ModerationController.adjudicate` | `ModerationModule` | Admin-only (Staff JWT) | reports.resolve | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/moderation/logs` | `ModerationController.getModerationLogs` | `ModerationModule` | Admin-only (Staff JWT) | reports.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/audit-logs` | `ModerationController.getAuditLogs` | `ModerationModule` | Admin-only (Staff JWT) | audit_logs.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/audit-logs/export` | `ModerationController.exportAuditLogs` | `ModerationModule` | Admin-only (Staff JWT) | audit_logs.export | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/audit-logs/:id` | `ModerationController.getAuditLogById` | `ModerationModule` | Admin-only (Staff JWT) | audit_logs.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/moderation/verifications` | `ModerationController.getPendingVerifications` | `ModerationModule` | Admin-only (Staff JWT) | verification.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/moderation/verifications/:id` | `ModerationController.getVerificationDetail` | `ModerationModule` | Admin-only (Staff JWT) | verification.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/moderation/verifications/:id/document` | `ModerationController.getVerificationDocument` | `ModerationModule` | Admin-only (Staff JWT) | verification.documents.read | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/moderation/verifications/:id/assign` | `ModerationController.assignVerification` | `ModerationModule` | Admin-only (Staff JWT) | verification.approve | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/moderation/verifications/:id/decision` | `ModerationController.adjudicateVerification` | `ModerationModule` | Admin-only (Staff JWT) | ANY(verification.approve | verification.reject) | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/locations/governorates` | `LocationsController.getGovernorates` | `LocationsModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/locations/cities/:cityId/areas` | `LocationsController.getAreasByCity` | `LocationsModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/favorites` | `FavoritesController.getMyFavorites` | `FavoritesModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/favorites` | `FavoritesController.addFavoriteBody` | `FavoritesModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/favorites/:listingId` | `FavoritesController.addFavorite` | `FavoritesModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/favorites/:listingId/status` | `FavoritesController.getFavoriteStatus` | `FavoritesModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/favorites/:listingId` | `FavoritesController.removeFavorite` | `FavoritesModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/listings/favorites` | `FavoritesController.getMyFavoritesAlias` | `FavoritesModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/listings/:listingId/favorite` | `FavoritesController.toggleFavoriteAlias` | `FavoritesModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/bookings` | `BookingsController.createBooking` | `BookingsModule` | Authenticated (Mobile JWT) | Authenticated User | 201 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/bookings` | `BookingsController.getBookings` | `BookingsModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/bookings/:id` | `BookingsController.getBookingById` | `BookingsModule` | Authenticated (User or Admin JWT) | Resource Owner/Participant or Admin | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/bookings/:id/cancel` | `BookingsController.cancelBooking` | `BookingsModule` | Authenticated (User or Admin JWT) | Resource Owner/Participant or Admin | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/bookings/:id/status` | `BookingsController.updateBookingStatus` | `BookingsModule` | Authenticated (User or Admin JWT) | Resource Owner/Participant or Admin | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/rfqs` | `RfqController.createRfq` | `RfqModule` | Authenticated (Mobile JWT) | Authenticated User | 201 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/rfqs` | `RfqController.getRfqs` | `RfqModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/rfqs/:id` | `RfqController.getRfqById` | `RfqModule` | Authenticated (User or Admin JWT) | Resource Owner/Participant or Admin | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/rfqs/:id` | `RfqController.updateDraftRfq` | `RfqModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/rfqs/:id/submit` | `RfqController.submitDraftRfq` | `RfqModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/rfqs/:id/cancel` | `RfqController.cancelRfq` | `RfqModule` | Authenticated (User or Admin JWT) | Resource Owner/Participant or Admin | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/rfqs/:id/quotations` | `RfqController.submitQuotation` | `RfqModule` | Role/Capability-restricted (Seller) | canAccessSellerDashboard | 201 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/rfqs/:id/quotations` | `RfqController.getQuotationsForRfq` | `RfqModule` | Authenticated (User or Admin JWT) | Resource Owner/Participant or Admin | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/quotations/:id` | `RfqController.getQuotationById` | `RfqModule` | Authenticated (User or Admin JWT) | Resource Owner/Participant or Admin | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/quotations/:id/status` | `RfqController.updateQuotationStatus` | `RfqModule` | Authenticated (User or Admin JWT) | Resource Owner/Participant or Admin | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/cart` | `CartController.getCart` | `CartModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/cart/items` | `CartController.addItem` | `CartModule` | Authenticated (Mobile JWT) | Authenticated User | 201 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/cart/items/:id` | `CartController.updateItem` | `CartModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/cart/items/:id` | `CartController.removeItem` | `CartModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/cart` | `CartController.clearCart` | `CartModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/activity-hub` | `ActivityHubController.getActivityHub` | `ActivityHubModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/quotas/my-usage` | `QuotasController.getMyQuotaUsage` | `QuotasModule` | Authenticated (Mobile JWT) | Authenticated User | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/settings` | `PlatformSettingsController.listSettings` | `PlatformSettingsModule` | Admin-only (Staff JWT) | settings.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/settings/:key` | `PlatformSettingsController.getSetting` | `PlatformSettingsModule` | Admin-only (Staff JWT) | settings.read | 200 | `{ success: true, data, meta? }` |
| `PUT` | `/api/v1/admin/settings/:key` | `PlatformSettingsController.upsertSetting` | `PlatformSettingsModule` | Admin-only (Staff JWT) | settings.update | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/staff/permissions` | `StaffController.getPermissionCatalog` | `StaffModule` | Admin-only (Staff JWT) | roles.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/staff/roles` | `StaffController.listRoles` | `StaffModule` | Admin-only (Staff JWT) | roles.read | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/staff/roles` | `StaffController.createRole` | `StaffModule` | Admin-only (Staff JWT) | roles.create | 201 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/admin/staff/roles/:roleId` | `StaffController.updateRole` | `StaffModule` | Admin-only (Staff JWT) | roles.update | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/staff/roles/:roleId/clone` | `StaffController.cloneRole` | `StaffModule` | Admin-only (Staff JWT) | roles.create | 201 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/admin/staff/roles/:roleId` | `StaffController.deleteRole` | `StaffModule` | Admin-only (Staff JWT) | roles.delete | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/staff` | `StaffController.listStaffUsers` | `StaffModule` | Admin-only (Staff JWT) | admins.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/staff/:id` | `StaffController.getStaffUserDetail` | `StaffModule` | Admin-only (Staff JWT) | admins.read | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/staff` | `StaffController.createStaffUser` | `StaffModule` | Admin-only (Staff JWT) | admins.create | 201 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/staff/invitations` | `StaffController.inviteStaffUser` | `StaffModule` | Admin-only (Staff JWT) | admins.create | 201 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/admin/staff/:id` | `StaffController.updateStaffUser` | `StaffModule` | Admin-only (Staff JWT) | admins.update | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/staff/:id/revoke-sessions` | `StaffController.revokeSessions` | `StaffModule` | Admin-only (Staff JWT) | admins.update | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/staff/:id/reset-mfa` | `StaffController.resetMfa` | `StaffModule` | Admin-only (Staff JWT) | admins.update | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/dashboard/overview` | `AdminDashboardController.getOverview` | `AdminOperationsModule` | Admin-only (Staff JWT) | analytics.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/dashboard/charts` | `AdminDashboardController.getCharts` | `AdminOperationsModule` | Admin-only (Staff JWT) | analytics.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/users` | `AdminUsersController.listUsers` | `AdminOperationsModule` | Admin-only (Staff JWT) | users.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/users/:id` | `AdminUsersController.getUserDetail` | `AdminOperationsModule` | Admin-only (Staff JWT) | users.read | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/admin/users/:id` | `AdminUsersController.updateUser` | `AdminOperationsModule` | Admin-only (Staff JWT) | users.update | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/users/:id/suspend` | `AdminUsersController.suspendUser` | `AdminOperationsModule` | Admin-only (Staff JWT) | users.suspend | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/users/:id/unsuspend` | `AdminUsersController.unsuspendUser` | `AdminOperationsModule` | Admin-only (Staff JWT) | users.suspend | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/users/:id/ban` | `AdminUsersController.banUser` | `AdminOperationsModule` | Admin-only (Staff JWT) | users.ban | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/users/:id/unban` | `AdminUsersController.unbanUser` | `AdminOperationsModule` | Admin-only (Staff JWT) | users.ban | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/users/:id/notes` | `AdminUsersController.addUserNote` | `AdminOperationsModule` | Admin-only (Staff JWT) | users.update | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/users/:id/revoke-sessions` | `AdminUsersController.revokeUserSessions` | `AdminOperationsModule` | Admin-only (Staff JWT) | users.suspend | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/accounts` | `AdminUsersController.listAccounts` | `AdminOperationsModule` | Admin-only (Staff JWT) | users.read | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/admin/accounts/:id/status` | `AdminUsersController.updateAccountStatus` | `AdminOperationsModule` | Admin-only (Staff JWT) | users.update | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/listings` | `AdminListingsController.listListings` | `AdminOperationsModule` | Admin-only (Staff JWT) | listings.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/listings/:id` | `AdminListingsController.getListingDetail` | `AdminOperationsModule` | Admin-only (Staff JWT) | listings.read | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/listings/:id/approve` | `AdminListingsController.approveListing` | `AdminOperationsModule` | Admin-only (Staff JWT) | listings.approve | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/listings/:id/reject` | `AdminListingsController.rejectListing` | `AdminOperationsModule` | Admin-only (Staff JWT) | listings.reject | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/listings/:id/request-changes` | `AdminListingsController.requestChanges` | `AdminOperationsModule` | Admin-only (Staff JWT) | listings.reject | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/admin/listings/:id/hide` | `AdminListingsController.hideListing` | `AdminOperationsModule` | Admin-only (Staff JWT) | listings.hide | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/admin/listings/:id/restore` | `AdminListingsController.restoreListing` | `AdminOperationsModule` | Admin-only (Staff JWT) | listings.approve | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/admin/listings/:id/archive` | `AdminListingsController.archiveListing` | `AdminOperationsModule` | Admin-only (Staff JWT) | listings.hide | 200 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/admin/listings/:id` | `AdminListingsController.deleteListing` | `AdminOperationsModule` | Admin-only (Staff JWT) | listings.delete | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/listings/bulk-decision` | `AdminListingsController.bulkDecision` | `AdminOperationsModule` | Admin-only (Staff JWT) | ANY(listings.approve | listings.reject | listings.hide) | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/chat/complaints` | `AdminMessagingController.listComplaints` | `AdminOperationsModule` | Admin-only (Staff JWT) | messaging.complaints.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/chat/conversations/:id/messages` | `AdminMessagingController.getConversationMessages` | `AdminOperationsModule` | Admin-only (Staff JWT) | chat.oversight.read | 200 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/admin/chat/conversations/:id/status` | `AdminMessagingController.updateStatus` | `AdminOperationsModule` | Admin-only (Staff JWT) | messaging.support.resolve | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/notifications/campaigns` | `AdminNotificationsController.listCampaigns` | `AdminOperationsModule` | Admin-only (Staff JWT) | notifications.read | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/notifications/audience-preview` | `AdminNotificationsController.previewAudience` | `AdminOperationsModule` | Admin-only (Staff JWT) | notifications.read | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/notifications/campaigns` | `AdminNotificationsController.createCampaign` | `AdminOperationsModule` | Admin-only (Staff JWT) | notifications.create | 201 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/notifications/campaigns/:id/approve` | `AdminNotificationsController.approveCampaign` | `AdminOperationsModule` | Admin-only (Staff JWT) | notifications.approve | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/notifications/campaigns/:id/send` | `AdminNotificationsController.sendCampaign` | `AdminOperationsModule` | Admin-only (Staff JWT) | notifications.send | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/notifications/campaigns/:id/cancel` | `AdminNotificationsController.cancelCampaign` | `AdminOperationsModule` | Admin-only (Staff JWT) | notifications.create | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/cms` | `AdminCmsController.listCms` | `AdminOperationsModule` | Admin-only (Staff JWT) | cms.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/cms/:id` | `AdminCmsController.getCmsItem` | `AdminOperationsModule` | Admin-only (Staff JWT) | cms.read | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/cms` | `AdminCmsController.createCms` | `AdminOperationsModule` | Admin-only (Staff JWT) | cms.manage | 201 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/admin/cms/:id` | `AdminCmsController.updateCms` | `AdminOperationsModule` | Admin-only (Staff JWT) | cms.manage | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/cms/:id/publish` | `AdminCmsController.publishCms` | `AdminOperationsModule` | Admin-only (Staff JWT) | cms.manage | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/cms/:id/unpublish` | `AdminCmsController.unpublishCms` | `AdminOperationsModule` | Admin-only (Staff JWT) | cms.manage | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/cms/:id/archive` | `AdminCmsController.archiveCms` | `AdminOperationsModule` | Admin-only (Staff JWT) | cms.manage | 200 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/admin/cms/:id` | `AdminCmsController.deleteCms` | `AdminOperationsModule` | Admin-only (Staff JWT) | cms.manage | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/cms/public` | `CmsPublicController.listPublicCms` | `AdminOperationsModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/cms/public/:slug` | `CmsPublicController.getPublicCmsBySlug` | `AdminOperationsModule` | Public | Public | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/analytics/summary` | `AdminAnalyticsController.getSummary` | `AdminOperationsModule` | Admin-only (Staff JWT) | analytics.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/analytics/export` | `AdminAnalyticsController.exportAnalytics` | `AdminOperationsModule` | Admin-only (Staff JWT) | analytics.export | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/system/health` | `AdminSystemController.getSystemHealth` | `AdminOperationsModule` | Admin-only (Staff JWT) | system_health.read | 200 | `{ success: true, data, meta? }` |
| `GET` | `/api/v1/admin/feature-flags` | `AdminFeatureFlagsController.listFlags` | `AdminOperationsModule` | Admin-only (Staff JWT) | feature_flags.read | 200 | `{ success: true, data, meta? }` |
| `POST` | `/api/v1/admin/feature-flags` | `AdminFeatureFlagsController.createFlag` | `AdminOperationsModule` | Admin-only (Staff JWT) | feature_flags.manage | 201 | `{ success: true, data, meta? }` |
| `PATCH` | `/api/v1/admin/feature-flags/:key` | `AdminFeatureFlagsController.updateFlag` | `AdminOperationsModule` | Admin-only (Staff JWT) | feature_flags.manage | 200 | `{ success: true, data, meta? }` |
| `DELETE` | `/api/v1/admin/feature-flags/:key` | `AdminFeatureFlagsController.deleteFlag` | `AdminOperationsModule` | Admin-only (Staff JWT) | feature_flags.manage | 200 | `{ success: true, data, meta? }` |

---

## 8. Swagger / OpenAPI Comparison

- **Total Fastify Registered Routes (excluding `/api/docs*`):** **238**
- **Total OpenAPI Document Paths/Operations (`/api/docs-json`):** **237**
- **Discrepancies:** **0 unexpected discrepancies.**
  - The single excluded route is `GET /metrics`, which is intentionally hidden from public OpenAPI documentation via `@ApiExcludeController()` in `MetricsController`.
  - Every guarded endpoint declares `@ApiBearerAuth('BearerAuth')`; every public endpoint omits bearer security.
  - Verified programmatically in `test/routes-audit.e2e-spec.ts` (Test #2).

---

## 9. Test Results

All verification was executed against the compiled NestJS + Fastify application and live PostgreSQL + Redis instances:

1. **Production Build (`npm run build`):** **PASS** (0 TypeScript errors).
2. **Unit Test Suite (`npm test`):** **50 / 50 suites passed (345 / 345 tests passed)**.
3. **New Routes Audit E2E Suite (`test/routes-audit.e2e-spec.ts`):** **9 / 9 tests passed**, verifying:
   - Zero duplicate controllers & zero duplicate routes
   - Single `/api/v1` prefix with zero double-prefixes
   - 100% Swagger-to-Fastify parity (excluding `/metrics`)
   - All public endpoints return `200 OK` + `{ success: true }` + `x-request-id`/`x-trace-id`
   - All protected endpoints reject unauthenticated callers with `401` and accurate non-admin error messages
   - Normal users receive `403 Forbidden` on all admin endpoints including `/admin/auth/me` and `/admin/auth/sessions`
   - Non-approved buyers/pending sellers receive `403` on seller-only endpoints; approved sellers receive `200` on seller dashboard
   - Static route `GET /api/v1/listings/favorites` takes priority over `GET /api/v1/listings/:id`
   - `PATCH /api/v1/users/me` and `PATCH /api/v1/listings/:id` REST aliases work
   - Invalid HTTP methods return `404` standard envelope; invalid UUIDs fail fast with `400`; missing resources (including `GET /api/v1/accounts/:id`) return `404`
   - Admin DTO validation accepts valid filters and rejects invalid pagination (`?page=-5` -> `400 VALIDATION_FAILED`)
4. **Seller Verification E2E (`test/seller-verification.e2e-spec.ts`):** **PASS** (full buyer -> pending -> approved / rejected / suspended lifecycle).
5. **Admin Dashboard E2E (`test/admin-dashboard.e2e-spec.ts`):** **PASS**.
6. **Live TCP Server Boot Verification (`PORT=3199 node dist/src/main.js` + `curl`):**
   - `GET /health/live` -> `200`
   - `GET /health/ready` -> `200`
   - `GET /api/docs-json` -> `200`
   - `GET /api/v1/home` -> `200`
   - `GET /api/v1/categories` -> `200`
   - `GET /api/v1/listings` -> `200`
   - `GET /api/v1/listings/not-a-uuid` -> `400`
   - `GET /api/v1/accounts/00000000-0000-4000-8000-000000000000` -> `404`
   - `GET /api/v1/users/me` (unauthenticated) -> `401`

---

## 10. Remaining Issues & Observations

1. **Conditional `PaymentsModule` evaluation order (`src/app.module.ts:38`):** `const isPaymentsEnabled = process.env.ENABLE_V2_PAYMENTS === 'true'` is evaluated at module import time before `ConfigModule.forRoot()` loads `.env`. In containerized production (Railway/Docker) where env vars are injected into `process.env`, this works as expected; in local dev, `ENABLE_V2_PAYMENTS=true` must be passed in the shell environment if testing V2 payments.
2. **Legacy E2E suites requiring external running server or clean DB state:** `test/all-modules-audit.e2e-spec.ts` and `test/data-flow.e2e-spec.ts` target `http://localhost:3000/api/v1` externally (they do not bootstrap NestJS in-process), and `test/auth.e2e-spec.ts` assumes an empty `user_sessions` table when asserting `terminate-all` session count. These are test-harness assumptions, not backend routing defects.
3. **Fastify 404 vs 405 on unsupported HTTP methods:** NestJS + Fastify's default router returns `404 NOT_FOUND` (`Cannot DELETE /api/v1/home`) for unregistered HTTP methods on existing paths, formatted cleanly by `HttpExceptionFilter`. This is standard NestJS behavior and preserved for backward compatibility.
