# Deal One — Enterprise Admin Dashboard Implementation Audit (Phase 00)

> **Audit Date:** 2026-11-20  
> **Scope:** Full discovery of `docs/admin/`, `backend/` (NestJS + Fastify + Prisma + PostgreSQL + Dual-Redis), `deal one app/` (Flutter mobile client), and production health verification.  
> **Production Base URL Checked:** `https://one-deal-cjjt-production.up.railway.app/api/v1` (live `/health/ready` returned `200 OK` — `database: up`, `postgis: up`, `redis_cache: up`, `redis_queue: up`, `workers: active`).

---

## 1. Existing Architecture

- **Backend Runtime:** `market-space-backend` (`NestJS 10.3.8`, `@nestjs/platform-fastify`, `@fastify/helmet`, `@fastify/cors`, `Prisma 5.14.0`, PostgreSQL 16 + PostGIS + `pg_trgm` + `pg_stat_statements`, Dual-Redis `ioredis` cache + `bullmq` queue).
- **HTTP Pipeline (`backend/src/main.ts`):**
  - Global prefix `/api/v1` (excluding `/health/*` and `/metrics`).
  - `ValidationPipe` (`whitelist: true`, `forbidNonWhitelisted: true`, `transform: true`).
  - `HttpExceptionFilter` returning `{ success: false, error: { code, message, details, trace_id } }`.
  - `TransformInterceptor` wrapping responses in `{ success: true, data, meta? }`.
  - `MetricsInterceptor` + `LoggingInterceptor` + `RequestIdMiddleware`.
  - Swagger mounted at `/api/docs` when `NODE_ENV !== 'production'` or `ENABLE_SWAGGER=true`.
- **Modules Loaded (`backend/src/app.module.ts`):**
  `PrismaModule`, `RedisModule`, `MetricsModule`, `WorkerModule`, `AuthModule`, `EmailModule`, `UsersModule`, `AccountsModule`, `CategoriesModule`, `MediaModule`, `ListingsModule`, `HomeModule`, `SearchModule`, `ChatModule`, `VideoModule`, `ModerationModule`, `NotificationsModule`, `LocationsModule`, `FavoritesModule`, `QuotasModule`, `PlatformSettingsModule`, `StaffModule`, and conditional `PaymentsModule` (`ENABLE_V2_PAYMENTS=true`).

---

## 2. Existing APIs Inventory

### Mobile Marketplace APIs (`/api/v1/*`)
Consumed by Flutter (`deal one app/lib/core/network/api_endpoints.dart`):
- **Health:** `GET /health/live`, `GET /health/ready`
- **Auth:** `/auth/otp/*`, `/auth/login`, `/auth/password/*`, `/auth/refresh`, `/auth/logout`, `/auth/sessions`, `/auth/me`, `/auth/dev-guest`, `/auth/email/*`
- **Users & Accounts:** `/users/me`, `/accounts/*`, `/accounts/:id/branches/*`, `/accounts/:id/members/*`, `/accounts/:id/service-areas/*`, `/accounts/:id/verifications`
- **Discovery & Listings:** `/categories*`, `/locations/*`, `/listings*`, `/home*`, `/search*`, `/favorites*`, `/media/*`, `/video-feed`
- **Engagement:** `/conversations*`, `/notifications*`, `/quotas/my-usage`, `/reports`

### Existing Partial Admin APIs (`/api/v1/admin/*`)
1. `POST /api/v1/admin/categories`, `POST /api/v1/admin/categories/:id/fields` (`CategoriesModule`)
2. `GET /api/v1/admin/moderation/listings`, `POST /api/v1/admin/moderation/listings/:id/decision` (`ModerationModule`)
3. `GET /api/v1/admin/moderation/queue`, `PATCH /api/v1/admin/moderation/reports/:id` (`ModerationModule`)
4. `GET /api/v1/admin/moderation/verifications`, `POST /api/v1/admin/moderation/verifications/:id/decision` (`ModerationModule`)
5. `GET /api/v1/admin/audit-logs` (`ModerationModule`)
6. `GET /api/v1/admin/settings`, `GET /api/v1/admin/settings/:key`, `PUT /api/v1/admin/settings/:key` (`PlatformSettingsModule`)
7. `GET /api/v1/admin/staff/roles`, `POST /api/v1/admin/staff/roles`, `GET /api/v1/admin/staff`, `POST /api/v1/admin/staff`, `PATCH /api/v1/admin/staff/:id` (`StaffModule`)

---

## 3. Existing Database Models (`backend/prisma/schema.prisma`)

31 Prisma models across 8 applied migrations:
- **Geography:** `Governorate`, `City`, `Area`
- **Identity & Auth:** `User`, `UserSession`, `UserDevice`, `Otp`
- **Multi-Tenant Accounts:** `Account`, `AccountMember`, `AccountVerification`, `Branch`, `ServiceArea`, `Project`
- **Taxonomy:** `Category`, `CategoryField`
- **Listings & Media:** `Listing`, `ListingMedia`
- **Engagement & Reports:** `Favorite`, `Report`
- **Chat:** `Conversation`, `Message`
- **Platform & Governance:** `Notification`, `DailyQuota`, `PlatformSetting`, `StaffRole`, `StaffUser`, `ModerationLog`, `AuditLog`
- **Outbox & V2 Payments:** `OutboxEvent`, `PromotionPackage`, `Payment`

---

## 4. Existing Authentication & Authorization System & Critical Defects

1. **No Staff Login Endpoint (`BROKEN` / `MISSING`):** `StaffService.createStaffUser()` hashes passwords into `staff_users`, while `AuthService.loginWithPassword()` only queries `users.phone` and issues mobile `role: 'USER'` tokens.
2. **`JwtStrategy` Rejects `StaffUser` (`BROKEN`):** `src/modules/auth/strategies/jwt.strategy.ts` requires `payload.phone`, restricts `audience: 'deal-one-mobile'`, and queries `prisma.user.findUnique()`.
3. **Coarse-Grained `RolesGuard` (`EXISTS_BUT_INCOMPLETE`):** Checks only 3 `UserRole` enum values (`USER`, `MODERATOR`, `SUPER_ADMIN`) and ignores `StaffRole.permissions`.
4. **No `HttpOnly` Cookie Auth or CSRF Defense (`MISSING`):** `@fastify/cookie` is not installed; browser admin sessions require `HttpOnly` refresh cookies (`dealone_admin_rt`), in-memory JWT access tokens, and CSRF header verification.
5. **No Admin MFA or Email Password Recovery (`MISSING`):** No TOTP secret/recovery code fields or email password reset flow exist for `StaffUser`.
6. **Moderation & Settings Bugs (`BROKEN`):**
   - `ModerationService.adjudicateReport()` hardcodes `status: 'resolved'` ignoring `dto.status`, and omits `resolvedByStaffId`.
   - `ModerationService.adjudicateListing()` sets `publicationStatus: 'draft'` on reject instead of `'unpublished'`, omits `approvedAt` on approve, and omits `staffId` on `ModerationLog`.
   - `ModerationService.adjudicateVerification()` omits `reviewedByStaffId` and `ModerationLog.staffId`.
   - `PlatformSettingsService.upsertSetting()` omits `updatedByStaffId`.
7. **Missing Privilege Escalation & Last-Super-Admin Guards (`MISSING`):** `StaffService` allows deactivating/demoting any staff account including the caller or last Super Admin.

---

## 5. Missing Functionality & Required Modules

| Module | Current Status | Required Work |
| :--- | :--- | :--- |
| 1. Admin Auth & MFA | Missing | Dedicated `AdminAuthModule`, `StaffSession`, TOTP MFA, `HttpOnly` cookie refresh rotation + CSRF, email reset, `StaffLoginAttempt` lockout |
| 2. Admin Accounts | Incomplete | Paginated filters, detail + activity view, invite/create, suspend/disable, revoke sessions, reset MFA, last-Super-Admin guard |
| 3. Roles & Permissions | Incomplete | Canonical permission catalog, 9 seeded roles, update/clone/delete roles, `PermissionsGuard`, anti-escalation |
| 4. Overview Dashboard | Missing | Real aggregated KPIs, activity time-series, category stats, health summary, recent audit logs |
| 5. Users Management | Missing | Users & accounts search/filter, detail drawer, listings/reports/verification history, internal notes, suspend/unsuspend/ban/unban, session revocation |
| 6. Listings Management | Incomplete | All-status filtering, detail view, approve/reject/request-changes/hide/restore/archive, bulk moderation, feed cache invalidation |
| 7. Categories Management | Incomplete | Full tree (incl. inactive), edit/reorder/activate/deactivate categories & dynamic fields, full Redis cache invalidation |
| 8. Reports & Moderation | Incomplete | Fix hardcoded status bug, filters, priority, assignment, internal notes, resolve/dismiss/escalate, moderation logs |
| 9. Verification Management | Incomplete | Filters, detail view, permission-gated audited document endpoint, reviewer assignment, request resubmission |
| 10. Messaging Oversight | Missing | Complaints & conversation reports queue, technical delivery status, audited limited message inspection |
| 11. Notifications Management | Needs Extension | `NotificationCampaign` model, AR/EN composer, audience preview, schedule/approve/send via existing `NotificationsService` |
| 12. CMS Management | Missing | `CmsItem` model with AR/EN, draft/publish/schedule/archive, revisions, plus public `/api/v1/cms/public` for Flutter |
| 13. Analytics | Missing | Aggregated date-filtered analytics (Users, Listings, Moderation, Verification, Notifications, Categories) + audited CSV/JSON export |
| 14. Audit Logs | Incomplete | Multi-field filters, single event diff inspection, audited export |
| 15. System Health | Needs Extension | Authenticated `/admin/system/health` aggregating PostgreSQL, PostGIS, Dual-Redis, Storage, Email/FCM, Outbox/Queue, latency/memory |
| 16. Feature Flags | Missing | `FeatureFlag` model + Redis cache invalidation + CRUD + environment & change history |
| 17. Platform Settings | Existing | Migrate to `AdminJwtAuthGuard` + `PermissionsGuard` and populate `updatedByStaffId` |

---

## 6. Required Database Changes (Additive & Non-Destructive)

Reuse existing `StaffRole`, `StaffUser`, `AuditLog`, `ModerationLog`, `PlatformSetting`, `AccountVerification`, `Report`, `User`:
- Extend `StaffRole` (`description`, `isSystem`, `createdAt`, `updatedAt`).
- Extend `StaffUser` (`phone`, `department`, `jobTitle`, `status`, MFA fields, `lastLoginAt`, `passwordChangedAt`, `expiresAt`, `updatedAt`, `deletedAt`).
- Extend `User` (`moderationStatus`, `suspendedUntil`, `suspensionReason`, `bannedAt`, `banReason`, `internalNotes`).
- Extend `Report` (`priority`, `assignedToStaffId`, `assignedAt`, `internalNotes`).
- Extend `AccountVerification` (`assignedToStaffId`, `notes`).
- Add composite query indexes to `AuditLog`.
- Add new non-duplicate tables: `StaffSession`, `StaffLoginAttempt`, `StaffPasswordResetToken`, `FeatureFlag`, `CmsItem`, `NotificationCampaign`.

---

## 7. Required React Pages (`admin-web/`)

Independent Vite + React + TypeScript + Tailwind CSS + shadcn-style UI + TanStack Query + React Hook Form + Zod + Recharts app featuring Dark/Light themes and Arabic RTL / English LTR switching:
1. Login / MFA / Password Reset
2. Overview Dashboard
3. Users Management (Users & Seller Accounts)
4. Listings Management
5. Categories & Attributes Management
6. Reports & Moderation
7. Verification Management
8. Messaging Oversight
9. Notifications Management
10. CMS Management
11. Analytics
12. Admin Accounts
13. Roles & Permissions
14. Audit Logs
15. System Health
16. Feature Flags
17. Platform Settings

---

## 8. Flutter Compatibility & Risks

- **Zero Breaking Changes:** All mobile routes under `/api/v1/*` and `JwtStrategy` (`deal-one-mobile`) remain intact.
- **Entity Sync:** Listing approval/hide updates `Listing.moderationStatus` / `publicationStatus` + Redis `listings:feed:ver` & `home:feed:ver`; user suspension/ban updates `User.isActive = false` and revokes `UserSession`s; verification updates `Account.verificationStatus`; CMS exposes additive public `/api/v1/cms/public`.
- **E2E Compatibility:** Existing E2E tests (`new-features.e2e-spec.ts`, `all-modules-audit.e2e-spec.ts`, `security-integration.e2e-spec.ts`) must continue passing 100%.

---

## 9. Phased Implementation Plan

- **Phase 00:** Complete discovery & `IMPLEMENTATION_AUDIT.md`
- **Phase 01:** Database schema extension, migration, RBAC seed, and React foundation (`admin-web/`)
- **Phase 02:** `AdminAuthModule` (Cookie + CSRF + JWT isolation + TOTP MFA + Lockout + Email reset + `PermissionsGuard`)
- **Phase 03:** Core Operations (Overview, Users, Listings, Categories, Reports — backend + React)
- **Phase 04:** Trust & Communication (Verification, Messaging Oversight, Notifications, CMS — backend + React)
- **Phase 05:** Analytics (Backend aggregations & export + React charts)
- **Phase 06:** Administrative Control (Admins, Roles/Permissions, Audit Logs, System Health, Feature Flags, Platform Settings)
- **Phase 07:** Full QA (Backend Unit + E2E + 10 Admin Workflows + Vitest Frontend + Security + Flutter Compatibility)
- **Phase 08:** Production Readiness & Complete Documentation Suite
