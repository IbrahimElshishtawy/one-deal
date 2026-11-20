# Deal One Enterprise Admin Dashboard — System Architecture

## 1. High-Level Topology

The **Deal One Enterprise Admin Platform** consists of an independent React SPA (`admin-web/`) communicating exclusively over HTTPS/REST with the existing Deal One NestJS Modular Monolith backend (`backend/`), backed by PostgreSQL + PostGIS + pg_trgm, Dual-Redis (Cache & BullMQ Queue), and transactional outbox / email / push infrastructure.

```
+---------------------------------------+         HTTPS (Credentials: include)          +----------------------------------------------+
|  admin-web (React 18 + TypeScript)    |  ==========================================>  |  backend (NestJS 10 + Fastify 4.28.1)        |
|  - Vite 5 / React Router v6 / TW CSS  |   Bearer Access Token (in-memory JS only)     |  - @fastify/cookie + @fastify/helmet + CORS  |
|  - TanStack Query v5 + Zod + RHF      |   HttpOnly Refresh Cookie: dealone_admin_rt   |  - Global Prefix: /api/v1                    |
|  - Recharts + Arabic RTL / English LTR|   CSRF Header: X-Requested-With               |  - AdminJwtAuthGuard + PermissionsGuard       |
+---------------------------------------+                                               +----------------------+-----------------------+
                                                                                                               |
                                                      +--------------------------------------------------------+-----------------------------------+
                                                      |                                                        |                                   |
                                            +---------v----------+                                  +----------v---------+             +-----------v-----------+
                                            | PostgreSQL 16 +    |                                  | Redis Cache (6379) |             | Redis Queue (6380)    |
                                            | PostGIS + pg_trgm  |                                  | - Admin auth cache |             | - BullMQ workers      |
                                            | (37 Prisma models) |                                  | - Revoked SID/JTI  |             | - Outbox publisher    |
                                            +--------------------+                                  | - Feed/Flag cache  |             +-----------------------+
                                                                                                    +--------------------+
```

---

## 2. Repository Layout

| Component | Path | Responsibility |
| :--- | :--- | :--- |
| **React Admin SPA** | `admin-web/` | Independent Vite + TypeScript React web application with 17 operational/governance routes, Light/Dark themes, and Arabic RTL / English LTR localization. |
| **NestJS Backend** | `backend/` | Existing Fastify-powered modular monolith (`src/main.ts`, `src/app.module.ts`) serving both `/api/v1/*` mobile contracts and `/api/v1/admin/*` administrative APIs. |
| **Database Schema & Seeds** | `backend/prisma/` | PostgreSQL Prisma schema (`schema.prisma`), additive migration `20261120000001_add_enterprise_admin_platform`, and idempotent RBAC seed (`prisma/seeds/seed-admin-rbac.ts`). |
| **Flutter Mobile App** | `deal one app/` | Unmodified mobile consumer; receives approved listings (`publicationStatus = 'published'`), live categories, user moderation enforcement, and public CMS content (`/api/v1/cms/public`). |

---

## 3. Backend Modular Architecture (`backend/src/`)

### Core Infrastructure (`src/core/`)
- **HTTP Server (`src/main.ts`):** `@nestjs/platform-fastify` with `@fastify/cookie` (`^9.4.0`), `@fastify/helmet` (`buildHelmetOptions`), strict origin-validated `@fastify/cors` (`buildCorsOptions` allowing `X-CSRF-Token`, `X-Requested-With`, `Authorization`), `bodyLimit: 2MB`, `requestTimeout: 30_000`, `trustProxy` boundary (`parseTrustProxy`), `ValidationPipe` (`whitelist: true`, `forbidNonWhitelisted: true`, `transform: true`), `HttpExceptionFilter`, `MetricsInterceptor`, `LoggingInterceptor`, and `TransformInterceptor`.
- **Configuration (`src/core/config/env.config.ts`):** Zod-validated environment schema (`envSchema`) including `ADMIN_JWT_ACCESS_SECRET`, `ADMIN_JWT_ACCESS_EXPIRES_IN`, `ADMIN_REFRESH_EXPIRES_DAYS`, `ADMIN_MFA_ENCRYPTION_KEY`, `ADMIN_COOKIE_NAME`, `ADMIN_COOKIE_DOMAIN`, `ADMIN_COOKIE_SAMESITE`, and `ADMIN_PUBLIC_URL`.
- **Health & Observability (`src/core/health/`, `src/core/metrics/`):** Public liveness/readiness probes (`/health/live`, `/health/ready`) and token-gated Prometheus metrics (`/metrics`).

### Administrative Security & Domain Modules (`src/modules/`)
1. **`AdminAuthModule` (`src/modules/admin-auth/` — `@Global()`):**
   - `AdminAuthController`, `AdminAuthService`, `StaffSessionService`, `TotpService`, `AdminJwtAuthGuard`, `PermissionsGuard`, `ADMIN_PERMISSION_CATALOG` (45 granular permissions across 9 default roles).
2. **`StaffModule` (`src/modules/staff/`):**
   - Admin accounts management, invitation flow, session revocation, MFA reset, role creation/cloning/updating/deletion, anti-privilege-escalation validation, and last-Super-Admin protection.
3. **`ModerationModule` (`src/modules/moderation/`):**
   - Listing moderation decisions, abuse reports queue + assignment + priority + internal notes + resolution/escalation, audited sensitive KYC document viewing, and immutable `AuditLog` inspection/export.
4. **`CategoriesModule` (`src/modules/categories/`):**
   - Public category read endpoints for Flutter (`/api/v1/categories*`) plus full administrative CRUD, batch reordering, activation/deactivation, dynamic attribute fields management, and Redis feed/category cache invalidation (`/api/v1/admin/categories*`).
5. **`PlatformSettingsModule` (`src/modules/platform-settings/`):**
   - Runtime configuration persistence (`PlatformSetting`) with `SettingKeyPipe` validation and immutable `AuditLog` diff recording.
6. **`AdminOperationsModule` (`src/modules/admin-operations/`):**
   - **Services:** `AdminDashboardAnalyticsService`, `AdminMarketplaceService`, `AdminGrowthPlatformService`.
   - **Controllers:**
     - `AdminDashboardController` (`admin/dashboard`)
     - `AdminUsersController` (`admin/users`, `admin/accounts`)
     - `AdminListingsController` (`admin/listings`)
     - `AdminMessagingController` (`admin/chat`)
     - `AdminNotificationsController` (`admin/notifications`)
     - `AdminCmsController` (`admin/cms`) + `CmsPublicController` (`cms/public` for Flutter)
     - `AdminAnalyticsController` (`admin/analytics`)
     - `AdminSystemController` (`admin/system`)
     - `AdminFeatureFlagsController` (`admin/feature-flags`)

---

## 4. Frontend Feature Architecture (`admin-web/src/`)

- **Core Layer (`src/core/`):**
  - `api/client.ts`: Centralized Fetch API client with `inMemoryAccessToken`, single-flight `refreshPromise` cookie rotation, `X-Requested-With: dealone-admin-web`, `AbortController` 25s timeout, optional safe `GET` retries (`retrySafe`), and normalized `ApiClientError` preserving backend `trace_id`.
  - `auth/AuthContext.tsx` & `auth/PermissionGate.tsx`: Bootstraps session silently via cookie refresh on load; calculates `hasPermission`, `hasAnyPermission`; wraps UI actions (`<PermissionGate>`) and router pages (`<PagePermissionGuard>`).
  - `i18n/I18nContext.tsx`: Full English (`ltr`) and Arabic (`rtl`) translations synchronizing `<html dir>` and `<html lang>`.
  - `theme/ThemeContext.tsx`: Persistent `light` / `dark` Tailwind class toggling.
- **Reusable UI Layer (`src/components/`):**
  - `ui.tsx` (forwardRef-compatible `Input`, `Select`, `Textarea`, plus `Button`, `Card`, `Badge`, `Modal`, `LoadingState`, `EmptyState`, `ErrorState`, `PaginationBar`).
  - `DataTable.tsx` (standardized server-driven tabular grid).
  - `AppShell.tsx` (responsive permission-filtered sidebar, breadcrumbs, global quick search, theme & AR/EN switchers, profile & MFA/sessions menu).
- **Feature Modules (`src/features/`):**
  - `auth/` (`LoginPage`, `SecurityProfilePage`)
  - `overview/` (`OverviewPage` with live KPIs & Recharts visualizations)
  - `users/` (`UsersPage`), `listings/` (`ListingsPage`), `categories/` (`CategoriesPage`)
  - `reports/` (`ReportsPage`), `verification/` (`VerificationPage`), `messaging/` (`MessagingOversightPage`)
  - `notifications/` (`NotificationsPage`), `cms/` (`CmsPage`), `analytics/` (`AnalyticsPage`)
  - `admins/` (`AdminAccountsPage`), `roles/` (`RolesPermissionsPage`), `audit-logs/` (`AuditLogsPage`)
  - `system-health/` (`SystemHealthPage`), `feature-flags/` (`FeatureFlagsPage`), `settings/` (`PlatformSettingsPage`)

---

## 5. Flutter Backward Compatibility & Shared Entity Guarantees

- **Token & Guard Isolation:** Mobile `JwtStrategy` (`audience: 'deal-one-mobile'`) and all customer/seller endpoints remain untouched. `AdminJwtAuthGuard` strictly verifies `audience: 'deal-one-admin'` for staff accounts and refuses mobile `USER` tokens with `403 Forbidden` via `PermissionsGuard`.
- **Real-Time State Synchronization:**
  - Approving a listing transitions `moderationStatus = 'approved'`, `publicationStatus = 'published'`, sets `approvedAt`, and increments Redis keys `listings:feed:ver` & `home:feed:ver`.
  - Hiding, rejecting, requesting changes, archiving, or deleting a listing updates `publicationStatus` / `deletedAt` and makes public `GET /api/v1/listings/:id` return `404` (`ListingsService.getListingById`) while evicting public feed caches.
  - Suspending or banning a mobile user sets `isActive = false`, revokes `UserSession` records, denylists active `sid` + `user_before` in Redis, and (on ban) hides published listings.
  - Publishing a `CmsItem` makes it immediately consumable on `GET /api/v1/cms/public` and `GET /api/v1/cms/public/:slug`.
