# Deal One Enterprise Admin Dashboard — QA & Test Report

> **Test Date:** 2026-11-20  
> **Environment:** Local PostgreSQL 16 (`127.0.0.1:5432`), Redis Cache (`127.0.0.1:6379`), Redis Queue (`127.0.0.1:6380`), NestJS + Fastify `4.28.1`, Vite + Vitest `2.1.9`.

---

## 1. Production Health Check (Baseline)

Verified live deployed Deal One Backend prior to integration:
- **Endpoint:** `GET https://one-deal-cjjt-production.up.railway.app/health/ready`
- **Result:** `200 OK` (`database: up`, `postgis: up`, `redis_cache: up`, `redis_queue: up`, `workers: active`).

---

## 2. Backend Build & Unit Test Suite (`backend/`)

- **Command:** `cd backend && npm run build && npm test`
- **Build Result:** `nest build` succeeded with **0 errors**.
- **Unit Test Suites:** **41 passed, 41 total**
- **Individual Unit Tests:** **259 passed, 259 total**
- **Key Covered Suites:**
  - `src/modules/admin-auth/admin-auth.spec.ts` (TotpService Base32/AES-256-GCM/TOTP/recovery codes + `PermissionsGuard`)
  - `src/modules/staff/staff.service.spec.ts`
  - `src/modules/moderation/moderation.service.spec.ts`
  - `src/modules/categories/categories.service.spec.ts`
  - `src/modules/platform-settings/platform-settings.service.spec.ts`
  - `src/core/database/migrate-deploy.spec.ts` (verifies all 9 SQL migrations)
  - `src/modules/auth/services/session.service.spec.ts` & `src/modules/listings/listings.service.spec.ts`

---

## 3. Backend E2E & Integration Suites (`backend/test/`)

- **Command:** `npx jest --config ./test/jest-e2e.json test/admin-dashboard.e2e-spec.ts test/new-features.e2e-spec.ts test/security-integration.e2e-spec.ts --runInBand`
- **Result:** **3 passed, 3 total suites | 21 passed, 21 total tests** (0 failures, 0 skipped).

### Workflows Verified in `test/admin-dashboard.e2e-spec.ts`:
| Workflow | Description | Verified Assertions |
| :-: | :--- | :--- |
| **W1** | Super Admin Login, HttpOnly Cookie Refresh & CSRF | `200 OK`, `refreshToken` omitted from JSON body, `dealone_admin_rt` `Set-Cookie`, cookie refresh without `X-Requested-With` blocked (`403`), valid refresh rotates cookie & token, `/admin/auth/me` returns identity |
| **W2** | Create Admin, Create/Clone Role | Custom role created (`201`), cloned (`201`), staff created (`201`) |
| **W3** | MFA Enrollment & Verification + Last Super Admin | MFA setup/enable with TOTP -> subsequent login returns `requiresMfa: true`, `/mfa/verify` issues access token; Super Admin self-deactivation returns `403` |
| **W4** | Listing Moderation -> Flutter Sync | Moderator approves pending listing (`200`, `publicationStatus: 'published'`, `approvedAt` set) -> `GET /api/v1/listings/:id` returns `200`; Hide -> `GET /api/v1/listings/:id` returns `404`; Restore succeeds (`200`) |
| **W5** | User Suspend & Unsuspend | Suspends user (`isActive: false`, `moderationStatus: 'suspended'`), unsuspends back to `isActive: true` |
| **W6** | Report Assignment & Resolution | Assigns high priority + reviewer; resolves/dismisses report verifying status persists (`status: 'dismissed'`, `resolvedByStaffId` populated) — confirms fix of legacy hardcoded-status bug |
| **W7** | KYC Verification & Audited Document Access | Moderator without `verification.documents.read` gets `403`; Verification Officer reads document (`200`), writes audit log, approves KYC (`Account.verificationStatus = 'approved'`) |
| **W8** | Notification Campaign Workflow | Audience preview, Marketing creates campaign (`pending_approval`), self-approve blocked (`403`), Super Admin approves (`200`), Marketing sends (`200`, `status: 'sent'`) |
| **W9** | CMS Publish -> Flutter Public API + Platform Ops | Draft CMS returns `404` on `/api/v1/cms/public/:slug`; publish -> returns `200` on public Flutter endpoint; Overview KPIs, Analytics summary, System Health (`database: up`), Feature Flags creation verified |
| **W10** | Permission & Escalation Enforcement | Moderator attempting `POST /admin/users/:id/ban` -> `403`; attempting role creation with `admins.create` -> `403` |

### Existing Marketplace Regression E2E Verified:
- `test/new-features.e2e-spec.ts`: **PASSED** (Password lifecycle + Notifications Inbox + Service Areas + Account Verification + Platform Settings + Staff RBAC)
- `test/security-integration.e2e-spec.ts`: **PASSED** (Phone privacy, reveal-contact quota, Account Team RBAC, media upload isolation, gated V2 payments `404`)

---

## 4. React Admin Web Tests & Production Build (`admin-web/`)

- **Command:** `cd admin-web && npm test && npm run build`
- **Vitest Result:** **1 passed, 1 total file | 4 passed, 4 total tests** (`src/tests/admin-dashboard.test.tsx`):
  1. Arabic RTL (`dir="rtl"`, `lang="ar"`) <-> English LTR (`dir="ltr"`, `lang="en"`) runtime switching.
  2. `LoginPage` validation & submission via `AuthContext` into `POST /api/v1/admin/auth/login`.
  3. Permission-gated UI hiding restricted buttons (`<PermissionGate>`) and direct page blocking (`<PagePermissionGuard>`).
  4. Backend error normalization into `ApiClientError` preserving `code` and `trace_id`.
- **Production Build (`tsc -b && vite build`):**
  - **0 TypeScript errors**.
  - Output generated cleanly in `admin-web/dist/` (`dist/index.html`, CSS `21.73 kB`, JS bundle `867.49 kB`).
