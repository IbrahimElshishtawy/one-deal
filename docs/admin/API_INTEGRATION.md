# Deal One Enterprise Admin Dashboard — API Integration Reference

## 1. Base URLs & Environments

| Environment | Base URL | Transport |
| :--- | :--- | :--- |
| **Production Backend (Provided)** | `https://one-deal-cjjt-production.up.railway.app/api/v1` | HTTPS (`GET /health/ready` verified `200 OK`) |
| **Local Development Backend** | `http://localhost:3000/api/v1` | HTTP (`vite.config.ts` proxies `/api` -> `http://localhost:3000`) |
| **Frontend Configuration** | `VITE_API_BASE_URL` (defaults to `/api/v1`) | Defined in `admin-web/.env` & `admin-web/.env.example` |

---

## 2. Request / Response & Error Envelope Contract

All `/api/v1/*` endpoints return the standard Deal One JSON envelope produced by `TransformInterceptor` and `HttpExceptionFilter`:

- **Success Envelope:**
  ```json
  {
    "success": true,
    "data": { ... },
    "meta": { "total": 100, "page": 1, "limit": 20, "totalPages": 5 }
  }
  ```
- **Error Envelope:**
  ```json
  {
    "success": false,
    "error": {
      "code": "FORBIDDEN",
      "message": "Access denied. Missing required permission(s): [users.ban]",
      "details": null,
      "trace_id": "2c851442-f677-4219-b2cb-a3434a37c385"
    }
  }
  ```

---

## 3. Centralized React API Client (`admin-web/src/core/api/client.ts`)

| Capability | Implementation Details |
| :--- | :--- |
| **In-Memory Token Storage** | Access JWT held strictly in module variable `inMemoryAccessToken` (`setAccessToken` / `getAccessToken`); zero `localStorage` or `sessionStorage` usage. |
| **Cookie Refresh & Single-Flight Lock** | `refreshAdminAccessToken()` deduplicates concurrent refresh attempts via shared `refreshPromise`, sends `credentials: 'include'` + `X-Requested-With: dealone-admin-web`. |
| **Auto-Retry on 401** | Non-auth requests receiving HTTP `401` automatically attempt one cookie refresh and replay the original request with the new Bearer token. |
| **Timeout & Cancellation** | Supports caller `AbortSignal` merged with an internal `AbortController` defaulting to `25,000 ms`. |
| **Safe GET Retry** | When `retrySafe` is enabled on `GET` requests, transient `>= 500` / network errors retry once with `350 ms` backoff. |
| **Normalized Errors** | All non-2xx responses throw `ApiClientError(status, code, message, details, traceId)` with user-facing trace ID support. |

---

## 4. Complete Backend API Endpoint Catalog

### A. Admin Authentication (`/api/v1/admin/auth/*` — `AdminAuthController`)
| Method & Path | Guard / Permission | Purpose |
| :--- | :--- | :--- |
| `POST /admin/auth/login` | Public + `RateLimitGuard` (10/15m) + Staff lockout | Authenticate staff email/password; sets `dealone_admin_rt` HttpOnly cookie or returns `mfaChallengeToken` |
| `POST /admin/auth/mfa/verify` | Public + `RateLimitGuard` (10/15m) | Verify 6-digit TOTP or 8-char recovery code; sets `dealone_admin_rt` HttpOnly cookie |
| `POST /admin/auth/refresh` | `RateLimitGuard` + CSRF header check | Rotate `dealone_admin_rt` refresh cookie (with reuse detection) and return fresh access JWT |
| `POST /admin/auth/logout` | Cookie + CSRF check / Bearer token | Revoke `StaffSession`, denylist `sid`/`jti` in Redis, clear cookie |
| `GET /admin/auth/me` | `AdminJwtAuthGuard` | Current authenticated admin profile, role, and effective permissions |
| `GET /admin/auth/sessions` | `AdminJwtAuthGuard` | List active sessions for current admin |
| `DELETE /admin/auth/sessions/:sessionId` | `AdminJwtAuthGuard` | Revoke specific active session |
| `POST /admin/auth/mfa/setup` | `AdminJwtAuthGuard` | Generate encrypted TOTP secret and `otpauth://` URI |
| `POST /admin/auth/mfa/enable` | `AdminJwtAuthGuard` | Verify TOTP code, enable MFA, issue 8 one-time recovery codes |
| `POST /admin/auth/mfa/disable` | `AdminJwtAuthGuard` | Verify password + TOTP code and disable MFA |
| `POST /admin/auth/password/change` | `AdminJwtAuthGuard` | Change current password (Argon2id) and revoke other sessions |
| `POST /admin/auth/password/forgot` | Public + `RateLimitGuard` (5/15m) | Send single-use reset link via `EmailService` (non-enumerating 200 OK) |
| `POST /admin/auth/password/reset` | Public + `RateLimitGuard` (5/15m) | Reset password via SHA-256 token hash and revoke all staff sessions |

### B. Admin Accounts & Roles (`/api/v1/admin/staff/*` — `StaffController`)
| Method & Path | Permission | Purpose |
| :--- | :--- | :--- |
| `GET /admin/staff/permissions` | `roles.read` | Full 45-permission bilingual catalog |
| `GET /admin/staff/roles` | `roles.read` | List all roles with user counts |
| `POST /admin/staff/roles` | `roles.create` | Create role (anti-escalation checked) |
| `PATCH /admin/staff/roles/:roleId` | `roles.update` | Update role & invalidate Redis auth cache |
| `POST /admin/staff/roles/:roleId/clone` | `roles.create` | Clone role permissions |
| `DELETE /admin/staff/roles/:roleId` | `roles.delete` | Delete custom role with zero assignees |
| `GET /admin/staff` | `admins.read` | Paginated, filtered staff directory |
| `GET /admin/staff/:id` | `admins.read` | Admin detail, sessions, recent audit logs, login attempts |
| `POST /admin/staff` | `admins.create` | Create staff user (Argon2id, anti-escalation) |
| `POST /admin/staff/invitations` | `admins.create` | Invite admin & send onboarding/reset email |
| `PATCH /admin/staff/:id` | `admins.update` | Activate/suspend/disable/update role (blocks self/last Super Admin lockout) |
| `POST /admin/staff/:id/revoke-sessions` | `admins.update` | Terminate all active sessions for target admin |
| `POST /admin/staff/:id/reset-mfa` | `admins.update` | Emergency MFA reset for locked-out admin |

### C. Overview & Analytics (`/api/v1/admin/dashboard/*`, `/api/v1/admin/analytics/*`)
| Method & Path | Permission | Purpose |
| :--- | :--- | :--- |
| `GET /admin/dashboard/overview` | `analytics.read` | KPI totals (users, listings, open reports, pending verifications), category breakdown, health snapshot, recent audit logs |
| `GET /admin/dashboard/charts` | `analytics.read` | Daily activity time-series (`?days=30`) |
| `GET /admin/analytics/summary` | `analytics.read` | Date-filtered V1 metrics (users, listings, moderation, verification, notifications, categories) |
| `GET /admin/analytics/export` | `analytics.export` | Audited CSV/JSON export of V1 analytics |

### D. Marketplace Operations (`Users`, `Listings`, `Categories`, `Reports`, `Verification`)
| Module & Controller | Endpoints & Permissions |
| :--- | :--- |
| **Users (`AdminUsersController`)** | `GET /admin/users` (`users.read`), `GET /admin/users/:id` (`users.read`), `PATCH /admin/users/:id` (`users.update`), `POST /admin/users/:id/suspend` & `/unsuspend` (`users.suspend`), `POST /admin/users/:id/ban` & `/unban` (`users.ban`), `POST /admin/users/:id/notes` (`users.update`), `POST /admin/users/:id/revoke-sessions` (`users.suspend`), `GET /admin/accounts` (`users.read`), `PATCH /admin/accounts/:id/status` (`users.update`) |
| **Listings (`AdminListingsController`)** | `GET /admin/listings` (`listings.read`), `GET /admin/listings/:id` (`listings.read`), `POST /admin/listings/:id/approve` (`listings.approve`), `POST /admin/listings/:id/reject` & `/request-changes` (`listings.reject`), `PATCH /admin/listings/:id/hide` & `/archive` (`listings.hide`), `PATCH /admin/listings/:id/restore` (`listings.approve`), `DELETE /admin/listings/:id` (`listings.delete`), `POST /admin/listings/bulk-decision` (`listings.approve \| reject \| hide`) |
| **Categories (`AdminCategoriesController`)** | `GET /admin/categories` (`categories.read`), `POST /admin/categories` (`categories.create`), `PATCH /admin/categories/reorder` (`categories.update`), `PATCH /admin/categories/:id` (`categories.update`), `DELETE /admin/categories/:id` (`categories.delete`), `GET /admin/categories/:id/fields` (`categories.read`), `POST /admin/categories/:id/fields` (`categories.update`), `PATCH /admin/categories/:id/fields/:fieldId` (`categories.update`), `DELETE /admin/categories/:id/fields/:fieldId` (`categories.delete`) |
| **Reports (`ModerationController`)** | `GET /admin/moderation/listings` (`listings.read`), `POST /admin/moderation/listings/:id/decision`, `GET /admin/moderation/queue` (`reports.read`), `GET /admin/moderation/reports/:id` (`reports.read`), `POST /admin/moderation/reports/:id/assign` (`reports.assign`), `POST /admin/moderation/reports/:id/notes` (`reports.resolve`), `PATCH /admin/moderation/reports/:id` (`reports.resolve`), `GET /admin/moderation/logs` (`reports.read`) |
| **Verification (`ModerationController`)** | `GET /admin/moderation/verifications` (`verification.read`), `GET /admin/moderation/verifications/:id` (`verification.read`), `GET /admin/moderation/verifications/:id/document` (`verification.documents.read` — audited!), `POST /admin/moderation/verifications/:id/assign` (`verification.approve`), `POST /admin/moderation/verifications/:id/decision` (`verification.approve \| reject`) |

### E. Messaging Oversight, Notifications, CMS, Audit, Health, Flags & Settings
| Module & Controller | Endpoints & Permissions |
| :--- | :--- |
| **Messaging Oversight (`AdminMessagingController`)** | `GET /admin/chat/complaints` (`messaging.complaints.read`), `GET /admin/chat/conversations/:id/messages` (`chat.oversight.read` — audited with required reason), `PATCH /admin/chat/conversations/:id/status` (`messaging.support.resolve`) |
| **Notifications (`AdminNotificationsController`)** | `GET /admin/notifications/campaigns` (`notifications.read`), `POST /admin/notifications/audience-preview` (`notifications.read`), `POST /admin/notifications/campaigns` (`notifications.create`), `POST .../approve` (`notifications.approve`), `POST .../send` (`notifications.send`), `POST .../cancel` (`notifications.create`) |
| **CMS (`AdminCmsController` & `CmsPublicController`)** | Admin: `GET/POST /admin/cms`, `GET/PATCH/DELETE /admin/cms/:id`, `POST /admin/cms/:id/{publish,unpublish,archive}` (`cms.read` / `cms.manage`). Public for Flutter: `GET /cms/public`, `GET /cms/public/:slug` |
| **Audit Logs (`ModerationController`)** | `GET /admin/audit-logs` (`audit_logs.read`), `GET /admin/audit-logs/:id` (`audit_logs.read`), `GET /admin/audit-logs/export` (`audit_logs.export`) |
| **System Health (`AdminSystemController`)** | `GET /admin/system/health` (`system_health.read`) |
| **Feature Flags (`AdminFeatureFlagsController`)** | `GET /admin/feature-flags` (`feature_flags.read`), `POST /admin/feature-flags` (`feature_flags.manage`), `PATCH /admin/feature-flags/:key` (`feature_flags.manage`), `DELETE /admin/feature-flags/:key` (`feature_flags.manage`) |
| **Platform Settings (`PlatformSettingsController`)** | `GET /admin/settings` (`settings.read`), `GET /admin/settings/:key` (`settings.read`), `PUT /admin/settings/:key` (`settings.update`) |
