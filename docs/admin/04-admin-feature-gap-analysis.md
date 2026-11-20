# 04 — Admin Feature Gap Analysis

> **Classification Legend:**  
> - `EXISTS` — Implemented, functional, and ready for reuse.  
> - `EXISTS_BUT_INCOMPLETE` — Implemented partially; missing filters, fields, pagination, or full CRUD actions.  
> - `NEEDS_EXTENSION` — Core service/table exists for mobile or infra; requires admin controller/method extension.  
> - `MISSING` — Not implemented in backend yet.  
> - `BROKEN` — Code exists but fails or misbehaves due to structural bug or missing linkage.

---

## 1. Cross-Cutting Admin Security & RBAC

| Capability | Status | Current State & Exact Gap |
| :--- | :--- | :--- |
| Admin Login (Email + Password) | `BROKEN` / `MISSING` | `StaffUser` exists with `email`/`passwordHash`, but no login endpoint exists; `/auth/login` queries `User.phone` only. |
| Admin JWT Strategy & Guard | `BROKEN` | `JwtStrategy` requires `payload.phone` and queries `users` table (`deal-one-mobile` audience). Needs dedicated `AdminJwtStrategy` (`deal-one-admin`) querying `staff_users`. |
| Admin Refresh Token Rotation & Revocation | `NEEDS_EXTENSION` | `SessionService` + reuse detection + Redis denylisting exist for `UserSession`; needs `StaffSession` + `HttpOnly` cookie transport for React web client. |
| Admin MFA (TOTP + Recovery Codes) | `MISSING` | No MFA fields, challenge tokens, TOTP verification, or recovery codes exist. |
| Admin Login Attempt Tracking & Lockout | `NEEDS_EXTENSION` | Redis rate limit & `AuditLog` exist; durable `StaffLoginAttempt` table and automatic temporary lockout absent. |
| Admin Password Change & Email Recovery | `MISSING` | Mobile password endpoints use SMS OTP on `User`; need email-based reset via `EmailService` (Resend) for `StaffUser`. |
| Granular Permissions (`PermissionsGuard`) | `MISSING` | `RolesGuard` only checks `UserRole` (`USER`, `MODERATOR`, `SUPER_ADMIN`); ignores `StaffRole.permissions`. |
| 9 Initial Admin Roles Seeded | `MISSING` | Only generic `StaffRole` table exists; none of the 9 enterprise roles & permission sets are seeded. |
| Privilege Escalation & Last Super Admin Guard | `MISSING` | `StaffService.updateStaffUser` permits deactivating/demoting the last Super Admin or self-escalation. |

---

## 2. The 16 Required Admin Modules

| # | Module | Status | Existing Assets | Missing / Required Work |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Overview Dashboard** | `MISSING` | MetricsService (HTTP only) | Aggregated KPI summary endpoint (users, active accounts, listings by status, open reports, pending verifications, revenue/promotions, 7d/30d trends, recent audit events). |
| **2** | **Users Management** | `MISSING` | `users` & `accounts` tables; `/users/me` self-service only | `GET /admin/users`, `GET /admin/users/:id`, `PATCH /admin/users/:id`, `POST /admin/users/:id/suspend`, `POST /admin/users/:id/ban`, `POST /admin/users/:id/activate`, `POST /admin/users/:id/revoke-sessions`, `GET /admin/accounts`, `PATCH /admin/accounts/:id/status`. |
| **3** | **Listings Management** | `EXISTS_BUT_INCOMPLETE` | `GET /admin/moderation/listings` (pending only), `POST /admin/moderation/listings/:id/decision` | Full admin `GET /admin/listings` (all statuses, search, category, account, governorate, featured, demo filter), `GET /admin/listings/:id`, `PATCH /admin/listings/:id/hide`, `PATCH /admin/listings/:id/restore`, `DELETE /admin/listings/:id` (soft delete), `PATCH /admin/listings/:id/promote`, bulk moderation actions, fix `approvedAt` & `'unpublished'` status & `staffId`. |
| **4** | **Categories Management** | `EXISTS_BUT_INCOMPLETE` | `GET /categories*`, `POST /admin/categories`, `POST /admin/categories/:id/fields` | `GET /admin/categories` (includes inactive categories), `PATCH /admin/categories/:id`, `DELETE /admin/categories/:id` (safe deactivate if listings exist), `PATCH /admin/categories/reorder`, `PATCH /admin/categories/:id/fields/:fieldId`, `DELETE /admin/categories/:id/fields/:fieldId`, Redis cache invalidation (`categories:item:*`, `categories:fields:*`). |
| **5** | **Reports & Moderation** | `EXISTS_BUT_INCOMPLETE` | `GET /admin/moderation/queue` (`open` only), `PATCH /admin/moderation/reports/:id` | Fix hardcoded `'resolved'` bug & missing `resolvedByStaffId`; support filtering all statuses (`open`, `resolved`, `dismissed`), `reason`, date; add `POST /admin/moderation/reports/:id/assign`, `GET /admin/moderation/logs` (`ModerationLog` history). |
| **6** | **Verification Management** | `EXISTS_BUT_INCOMPLETE` | `GET /admin/moderation/verifications` (`pending` only), `POST /admin/moderation/verifications/:id/decision` | Add status/type/search filters on `GET /admin/moderation/verifications`, `GET /admin/moderation/verifications/:id`, fix `reviewedByStaffId` & `ModerationLog.staffId` attribution. |
| **7** | **Notifications Management** | `NEEDS_EXTENSION` | `NotificationsService` (persists to `notifications` + dispatches FCM), user inbox endpoints | Admin notification campaign endpoints: list sent broadcasts/templates (`GET /admin/notifications`), send targeted or segmented push/in-app notification (`POST /admin/notifications/broadcast` queued via BullMQ). |
| **8** | **CMS Management** | `MISSING` | None | `CmsItem` model + `/admin/cms` CRUD (home banners, announcements, static pages/FAQs in AR/EN with scheduling & publish toggle) + public read endpoint for mobile/web if needed. |
| **9** | **Chat Oversight** | `NEEDS_EXTENSION` | `Conversation` & `Message` tables, `ChatModule` | Admin read-only endpoints (`GET /admin/chat/conversations`, `GET /admin/chat/conversations/:id/messages`, `PATCH /admin/chat/conversations/:id/status`) strictly permission-gated (`chat.oversight.read`) and **every read logged to `AuditLog`** for privacy compliance. |
| **10** | **Analytics & Reports** | `MISSING` | PostgreSQL tables + `pg_stat_statements` | Dedicated `/admin/analytics/*` endpoints: user/listing growth series, category/governorate distribution, moderation turnaround SLA, promotion payment revenue (`payments` + `promotion_packages`), and CSV/JSON export with audit logging. |
| **11** | **Admin Management** | `EXISTS_BUT_INCOMPLETE` | `GET /admin/staff`, `POST /admin/staff`, `PATCH /admin/staff/:id` | Add pagination & filters, `GET /admin/staff/:id`, `POST /admin/staff/:id/revoke-sessions`, `POST /admin/staff/:id/reset-mfa`, `POST /admin/staff/:id/reset-password`, enforce last-Super-Admin & privilege escalation checks. |
| **12** | **Roles & Permissions** | `EXISTS_BUT_INCOMPLETE` | `GET /admin/staff/roles`, `POST /admin/staff/roles` | Add `GET /admin/staff/permissions` (authoritative catalog), `PATCH /admin/staff/roles/:id`, `DELETE /admin/staff/roles/:id` (block system roles / assigned roles), permission validation. |
| **13** | **Audit Logs** | `EXISTS_BUT_INCOMPLETE` | `GET /admin/audit-logs` (basic pagination) | Add filtering (`actorType`, `actorId`, `action`, `targetEntity`, `targetId`, `ipAddress`, `from`, `to`), `GET /admin/audit-logs/:id`, and audited CSV/JSON export (`GET /admin/audit-logs/export`). |
| **14** | **System Health** | `NEEDS_EXTENSION` | `GET /health/live`, `GET /health/ready`, `GET /metrics` | `GET /admin/system/health` returning detailed DB pool, PostGIS, Redis cache/queue memory/latency, BullMQ queue job counts (waiting/active/failed/delayed), Email/FCM readiness, and runtime version. |
| **15** | **Feature Flags** | `MISSING` | Env vars only (`ENABLE_V2_PAYMENTS`, `AUTO_APPROVE_LISTINGS`) | `FeatureFlag` DB model + Redis-cached evaluation + `/admin/feature-flags` CRUD (`GET`, `POST`, `PATCH`, `DELETE`) with instant Redis cache invalidation & audit logs. |
| **16** | **Platform Settings** | `EXISTS` *(needs minor fix)* | `GET /admin/settings`, `GET /admin/settings/:key`, `PUT /admin/settings/:key` | Switch from `@Roles(SUPER_ADMIN)` to `@Permissions('settings.read')` / `@Permissions('settings.update')`; populate `updatedByStaffId` in DB; add optional `DELETE /admin/settings/:key` or typed metadata schema. |
