# 01 — Existing API Inventory

> **Global Prefix:** `/api/v1` (except Health & Metrics routes)  
> **Response Success Envelope (`TransformInterceptor`):** `{ "success": true, "data": <T>, "meta"?: { ... } }`  
> **Response Error Envelope (`HttpExceptionFilter`):** `{ "success": false, "error": { "code": string, "message": string, "details": unknown | null, "trace_id": string } }`  
> **Swagger Mount (non-prod / `ENABLE_SWAGGER=true`):** `/api/docs`

---

## 1. Infrastructure: Health & Metrics

| Method | Full Path | Auth / Guards | Purpose | Source |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/health/live`, `/health/liveness` | Public | Process liveness, uptime, RSS memory | `src/core/health/health.controller.ts` |
| `GET` | `/health/ready`, `/health/readiness` | Public | DB, PostGIS, Redis Cache, Redis Queue, Workers, Email check (`200` / `503`) | `src/core/health/health.controller.ts` |
| `GET` | `/metrics` | `MetricsAuthGuard` | Prometheus text exposition format | `src/core/metrics/metrics.controller.ts` |

---

## 2. Authentication & Email Verification (`/api/v1/auth`)

| Method | Full Path | Guards / Rate Limit | Purpose / Notes | Source |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/auth/otp/send` | `RateLimitGuard` (5/15m, anon 10) | Send SMS/WhatsApp OTP (`AUTH`) | `src/modules/auth/auth.controller.ts` |
| `POST` | `/api/v1/auth/otp/resend` | `RateLimitGuard` (5/15m, anon 10) | Resend OTP subject to cooldown | `src/modules/auth/auth.controller.ts` |
| `POST` | `/api/v1/auth/otp/verify` | `RateLimitGuard` (10/15m, anon 15) | Verify OTP, register `User` + individual `Account`, issue mobile JWT pair | `src/modules/auth/auth.controller.ts` |
| `POST` | `/api/v1/auth/login` | `RateLimitGuard` (5/15m, anon 10) | **Mobile `User` phone + password login ONLY** (issues `role: 'USER'`) | `src/modules/auth/auth.controller.ts` |
| `POST` | `/api/v1/auth/password/login` | `RateLimitGuard` | Alias for `/auth/login` | `src/modules/auth/auth.controller.ts` |
| `POST` | `/api/v1/auth/password/set` | `JwtAuthGuard` | Set initial password for OTP-registered mobile user | `src/modules/auth/auth.controller.ts` |
| `POST` | `/api/v1/auth/password/change` | `JwtAuthGuard` | Change current password & revoke other sessions | `src/modules/auth/auth.controller.ts` |
| `POST` | `/api/v1/auth/password/forgot` | `RateLimitGuard` (3/15m, anon 5) | Send `PASSWORD_RESET` OTP (always returns 200) | `src/modules/auth/auth.controller.ts` |
| `POST` | `/api/v1/auth/password/reset` | `RateLimitGuard` (5/15m, anon 10) | Verify `PASSWORD_RESET` OTP, update hash, revoke all sessions | `src/modules/auth/auth.controller.ts` |
| `POST` | `/api/v1/auth/refresh` | `RateLimitGuard` (20/15m, anon 30) | Rotate `UserSession` refresh token with reuse detection | `src/modules/auth/auth.controller.ts` |
| `POST` | `/api/v1/auth/token/refresh` | `RateLimitGuard` | Alias for `/auth/refresh` | `src/modules/auth/auth.controller.ts` |
| `POST` | `/api/v1/auth/logout` | Open (optional Bearer) | Revoke `UserSession` + denylist access token in Redis | `src/modules/auth/auth.controller.ts` |
| `POST` | `/api/v1/auth/sessions/terminate-all` | `JwtAuthGuard` | Revoke all active `UserSession` records for current user | `src/modules/auth/auth.controller.ts` |
| `GET` | `/api/v1/auth/sessions` | `JwtAuthGuard` | List active `UserSession` records | `src/modules/auth/auth.controller.ts` |
| `GET` | `/api/v1/auth/me` | `JwtAuthGuard` | Return `{ id, phone, fullName, role, status }` | `src/modules/auth/auth.controller.ts` |
| `POST` | `/api/v1/auth/dev-guest` | `RateLimitGuard` | Non-prod only (`ENABLE_DEV_AUTH_BYPASS=true`) | `src/modules/auth/auth.controller.ts` |
| `POST` | `/api/v1/auth/email/verification/request` | `JwtAuthGuard`, `RateLimitGuard` | Request email verification link | `src/modules/email/email-verification.controller.ts` |
| `POST` | `/api/v1/auth/email/verification/resend` | `JwtAuthGuard`, `RateLimitGuard` | Resend email verification link | `src/modules/email/email-verification.controller.ts` |
| `POST` | `/api/v1/auth/email/verify` | `RateLimitGuard` | Verify email token | `src/modules/email/email-verification.controller.ts` |

---

## 3. Users, Accounts & Locations

### 3.1 Users (`/api/v1/users`)
| Method | Full Path | Auth / Guards | Purpose | Source |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/users/me` | `JwtAuthGuard` | Current user profile | `src/modules/users/users.controller.ts` |
| `PUT` | `/api/v1/users/me` | `JwtAuthGuard` | Update `fullName`, `avatarUrl`, `preferredLanguage` | `src/modules/users/users.controller.ts` |
| `DELETE` | `/api/v1/users/me` | `JwtAuthGuard` | Self soft-delete & anonymize + revoke sessions | `src/modules/users/users.controller.ts` |

### 3.2 Accounts (`/api/v1/accounts`)
| Method | Full Path | Auth / Guards | Purpose | Source |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/accounts` | `JwtAuthGuard` | Create seller account | `src/modules/accounts/accounts.controller.ts` |
| `GET` | `/api/v1/accounts/my-accounts` | `JwtAuthGuard` | List current user's accounts | `src/modules/accounts/accounts.controller.ts` |
| `GET` | `/api/v1/accounts/:id` | Public | Public seller account profile | `src/modules/accounts/accounts.controller.ts` |
| `POST` | `/api/v1/accounts/:id/branches` | `JwtAuthGuard` | Add branch | `src/modules/accounts/accounts.controller.ts` |
| `GET` | `/api/v1/accounts/:id/branches` | Public | List account branches | `src/modules/accounts/accounts.controller.ts` |
| `PUT` | `/api/v1/accounts/:id/branches/:branchId` | `JwtAuthGuard` | Update branch | `src/modules/accounts/accounts.controller.ts` |
| `DELETE` | `/api/v1/accounts/:id/branches/:branchId` | `JwtAuthGuard` | Delete branch | `src/modules/accounts/accounts.controller.ts` |
| `GET` | `/api/v1/accounts/:id/members` | `JwtAuthGuard` | List team members | `src/modules/accounts/accounts.controller.ts` |
| `POST` | `/api/v1/accounts/:id/members/invite` | `JwtAuthGuard` | Invite/add team member | `src/modules/accounts/accounts.controller.ts` |
| `DELETE` | `/api/v1/accounts/:id/members/:userId` | `JwtAuthGuard` | Remove team member | `src/modules/accounts/accounts.controller.ts` |
| `GET` | `/api/v1/accounts/:id/service-areas` | Public | List service areas (`ParseUUIDPipe`) | `src/modules/accounts/accounts.controller.ts` |
| `POST` | `/api/v1/accounts/:id/service-areas` | `JwtAuthGuard` | Upsert service area (`ParseUUIDPipe`) | `src/modules/accounts/accounts.controller.ts` |
| `DELETE` | `/api/v1/accounts/:id/service-areas/:serviceAreaId` | `JwtAuthGuard` | Remove service area (`ParseUUIDPipe`) | `src/modules/accounts/accounts.controller.ts` |
| `GET` | `/api/v1/accounts/:id/verifications` | `JwtAuthGuard` | List seller verification submissions | `src/modules/accounts/accounts.controller.ts` |
| `POST` | `/api/v1/accounts/:id/verifications` | `JwtAuthGuard` | Submit verification document | `src/modules/accounts/accounts.controller.ts` |

### 3.3 Locations (`/api/v1/locations`)
| Method | Full Path | Auth / Guards | Purpose | Source |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/locations/governorates` | Public | Active governorates with cities | `src/modules/locations/locations.controller.ts` |
| `GET` | `/api/v1/locations/cities/:cityId/areas` | Public | Active areas in a city (`ParseIntPipe`) | `src/modules/locations/locations.controller.ts` |

---

## 4. Marketplace Taxonomy, Discovery & Listings

### 4.1 Categories (`/api/v1/categories` & `/api/v1/admin/categories`)
| Method | Full Path | Auth / Guards | Purpose | Source |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/categories` | Public | Cached category tree (`categories:tree`) | `src/modules/categories/categories.controller.ts` |
| `GET` | `/api/v1/categories/:slug` | Public | Get category by slug or UUID | `src/modules/categories/categories.controller.ts` |
| `GET` | `/api/v1/categories/:slug/fields` | Public | Active dynamic fields for subcategory | `src/modules/categories/categories.controller.ts` |
| `POST` | `/api/v1/admin/categories` | `JwtAuthGuard`, `RolesGuard` (`SUPER_ADMIN`) | Create category/subcategory (`CreateCategoryDto`) | `src/modules/categories/categories.controller.ts` |
| `POST` | `/api/v1/admin/categories/:id/fields` | `JwtAuthGuard`, `RolesGuard` (`SUPER_ADMIN`) | Upsert dynamic field (`CreateCategoryFieldDto`) | `src/modules/categories/categories.controller.ts` |

### 4.2 Listings, Home, Search, Media, Video, Favorites
| Module | Endpoints | Auth | Source |
| :--- | :--- | :--- | :--- |
| **Listings** | `GET /api/v1/listings`, `POST /api/v1/listings/prices/batch`, `GET /api/v1/listings/:id`, `POST /api/v1/listings`, `PUT /api/v1/listings/:id`, `DELETE /api/v1/listings/:id`, `PATCH /api/v1/listings/:id/availability`, `POST /api/v1/listings/:id/submit`, `PATCH /api/v1/listings/:id/status`, `POST /api/v1/listings/:id/contact`, `POST /api/v1/listings/:id/reveal-contact` | Public `GET`/`batch`; `JwtAuthGuard` on mutations & contact reveal | `src/modules/listings/listings.controller.ts` |
| **Home** | `GET /api/v1/home`, `GET /api/v1/home/featured`, `GET /api/v1/home/latest`, `GET /api/v1/home/recommended`, `GET /api/v1/home/categories`, `GET /api/v1/home/sections/:sectionSlug` | Public | `src/modules/home/home.controller.ts` |
| **Search** | `GET /api/v1/search`, `GET /api/v1/search/suggestions` | Public | `src/modules/search/search.controller.ts` |
| **Media** | `POST /api/v1/media/images/upload-url`, `POST /api/v1/media/upload-urls`, `POST /api/v1/media/presigned-url`, `POST /api/v1/media/confirm-upload`, `POST /api/v1/media/confirm` | `JwtAuthGuard` | `src/modules/media/media.controller.ts` |
| **Video** | `POST /api/v1/media/video/upload-token` (`JwtAuthGuard`), `POST /api/v1/media/video/webhook` (HMAC), `GET /api/v1/video-feed` (Public) | Mixed | `src/modules/video/video.controller.ts` |
| **Favorites** | `GET /api/v1/favorites`, `POST /api/v1/favorites/:listingId`, `DELETE /api/v1/favorites/:listingId`, `GET /api/v1/listings/favorites`, `POST /api/v1/listings/:listingId/favorite` | `JwtAuthGuard` | `src/modules/favorites/favorites.controller.ts` |

---

## 5. Engagement, Quotas, Notifications & Payments

| Module | Endpoints | Auth | Source |
| :--- | :--- | :--- | :--- |
| **Chat** | `SSE /api/v1/conversations/stream`, `GET /api/v1/conversations`, `POST /api/v1/conversations`, `GET /api/v1/conversations/:id/messages`, `POST /api/v1/conversations/:id/messages` | `JwtAuthGuard` | `src/modules/chat/chat.controller.ts` |
| **Quotas** | `GET /api/v1/quotas/my-usage` | `JwtAuthGuard` | `src/modules/quotas/quotas.controller.ts` |
| **Notifications** | `GET /api/v1/notifications`, `PATCH /api/v1/notifications/read-all`, `PATCH /api/v1/notifications/:id/read`, `POST /api/v1/notifications/device-token` | `JwtAuthGuard` | `src/modules/notifications/notifications.controller.ts` |
| **Payments (V2)** | `GET /api/v1/payments/packages`, `POST /api/v1/payments/checkout` (`JwtAuthGuard`), `POST /api/v1/payments/webhook` *(mounted only if `ENABLE_V2_PAYMENTS=true`)* | Mixed | `src/modules/payments/payments.controller.ts` |

---

## 6. Existing Administrative & Moderation Endpoints (`/api/v1/admin/*`)

| Method | Full Path | Current Guards & Roles | Request / Query | Known Gaps / Bugs Observed in Code |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/reports` | `JwtAuthGuard` | `CreateReportDto` | User abuse report submission |
| `GET` | `/api/v1/admin/moderation/listings` | `JwtAuthGuard`, `RolesGuard` (`MODERATOR`, `SUPER_ADMIN`) | `page`, `limit` | Only fetches `moderationStatus: 'pending'`; no search/filters |
| `POST` | `/api/v1/admin/moderation/listings/:id/decision` | `JwtAuthGuard`, `RolesGuard` (`MODERATOR`, `SUPER_ADMIN`) | `AdjudicateListingDto` (`action: 'approve' \| 'reject'`, `reasonCode?`, `notes?`) | Does not set `approvedAt`; sets `publicationStatus: 'draft'` on reject (instead of `'unpublished'`); omits `staffId` in `ModerationLog`; no UUID pipe on `:id` |
| `GET` | `/api/v1/admin/moderation/queue` | `JwtAuthGuard`, `RolesGuard` (`MODERATOR`, `SUPER_ADMIN`) | `page`, `limit` | Only fetches `status: 'open'` reports; no filters/assignment |
| `PATCH` | `/api/v1/admin/moderation/reports/:id` | `JwtAuthGuard`, `RolesGuard` (`MODERATOR`, `SUPER_ADMIN`) | `AdjudicateReportDto` (`status`, `actionTaken?`) | **Bug:** Hardcodes `status: 'resolved'` ignoring `dto.status`, omits `resolvedByStaffId: moderatorId` |
| `GET` | `/api/v1/admin/moderation/verifications` | `JwtAuthGuard`, `RolesGuard` (`MODERATOR`, `SUPER_ADMIN`) | `page`, `limit` | Only fetches `status: 'pending'` verifications |
| `POST` | `/api/v1/admin/moderation/verifications/:id/decision` | `JwtAuthGuard`, `RolesGuard` (`MODERATOR`, `SUPER_ADMIN`) | `AdjudicateVerificationDto` (`action`, `rejectionReason?`, `notes?`) | Omits `reviewedByStaffId` on `AccountVerification` and `staffId` on `ModerationLog` |
| `GET` | `/api/v1/admin/audit-logs` | `JwtAuthGuard`, `RolesGuard` (`SUPER_ADMIN`) | `page`, `limit` | No filtering (`actorType`, `actorId`, `action`, `targetEntity`, date range) |
| `GET` | `/api/v1/admin/settings` | `JwtAuthGuard`, `RolesGuard` (`SUPER_ADMIN`) | None | Lists all `platform_settings` |
| `GET` | `/api/v1/admin/settings/:key` | `JwtAuthGuard`, `RolesGuard` (`SUPER_ADMIN`) | `SettingKeyPipe` | Fetches single setting |
| `PUT` | `/api/v1/admin/settings/:key` | `JwtAuthGuard`, `RolesGuard` (`SUPER_ADMIN`) | `UpsertPlatformSettingDto` (`value`, `description?`) | Omits `updatedByStaffId: actorId` on `PlatformSetting` |
| `GET` | `/api/v1/admin/staff/roles` | `JwtAuthGuard`, `RolesGuard` (`SUPER_ADMIN`) | None | Lists `staff_roles`; no permission update/delete |
| `POST` | `/api/v1/admin/staff/roles` | `JwtAuthGuard`, `RolesGuard` (`SUPER_ADMIN`) | `CreateStaffRoleDto` (`name`, `permissions?`) | No validation against canonical permission keys |
| `GET` | `/api/v1/admin/staff` | `JwtAuthGuard`, `RolesGuard` (`SUPER_ADMIN`) | None | Unpaginated list of `staff_users` |
| `POST` | `/api/v1/admin/staff` | `JwtAuthGuard`, `RolesGuard` (`SUPER_ADMIN`) | `CreateStaffUserDto` (`email`, `password`, `fullName`, `roleId`) | Creates `StaffUser`, but **no login endpoint exists for `StaffUser`** |
| `PATCH` | `/api/v1/admin/staff/:id` | `JwtAuthGuard`, `RolesGuard` (`SUPER_ADMIN`) | `UpdateStaffUserDto` (`isActive?`, `roleId?`) | No last-Super-Admin guard; no self-lockout prevention; no session revocation on deactivate |
