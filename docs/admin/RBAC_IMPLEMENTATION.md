# Deal One Enterprise Admin Dashboard — RBAC Implementation

## 1. Design Principles

- **Separate Identity Domain:** Marketplace consumers authenticate against `users` (`UserSession`, `deal-one-mobile` JWT audience). Administrative staff authenticate against `staff_users` (`StaffSession`, `deal-one-admin` JWT audience).
- **Permission-Based Authorization (Not Hardcoded Role Checks):** Endpoints declare required permissions via `@Permissions(...)` or `@AnyPermissions(...)` decorators verified on every HTTP call by `AdminJwtAuthGuard` + `PermissionsGuard`.
- **Database-Authoritative Effective Permissions:** On each authenticated request, `AdminJwtAuthGuard` resolves live `StaffUser` + `StaffRole.permissions` (60s Redis cache invalidated immediately upon role edits, suspension, or session revocation) rather than trusting stale client state.

---

## 2. The 9 Seeded Enterprise Roles (`INITIAL_ADMIN_ROLES`)

Defined authoritatively in `backend/src/modules/admin-auth/constants/admin-permissions.constant.ts` and seeded via `backend/prisma/seeds/seed-admin-rbac.ts`:

| # | Role Key (`staff_roles.name`) | Scope & Responsibility | Count of Permissions |
| :-: | :--- | :--- | :-: |
| 1 | `super_admin` | Full governance, RBAC administration, security controls, emergency overrides | 45 (All) |
| 2 | `platform_admin` | Full marketplace operations, moderation, notifications, CMS, settings; cannot escalate or mutate RBAC/feature flags | 32 |
| 3 | `operations_manager` | Oversees moderation queues, report assignments, category taxonomy, verification approvals, and SLA | 24 |
| 4 | `content_moderator` | Listing approve/reject/hide, report resolution, read-only audit & messaging complaint views | 11 |
| 5 | `verification_officer` | Exclusive KYC verification review including **audited document viewing** (`verification.documents.read`) | 7 |
| 6 | `customer_support` | User support, internal notes, report triage, **audited complaint chat inspection** (`chat.oversight.read`) | 11 |
| 7 | `marketing_manager` | Notification campaign creation/dispatch and CMS publishing/scheduling | 9 |
| 8 | `analyst` | Read-only analytics, marketplace metrics, and **audited analytics export** (`analytics.export`) | 8 |
| 9 | `security_auditor` | Read-only security audit log inspection/export, login history, RBAC view, system health, feature flags view | 12 |

---

## 3. Complete 45-Permission Catalog (`ADMIN_PERMISSION_CATALOG`)

| Module | Permission Keys |
| :--- | :--- |
| **Analytics** | `analytics.read`, `analytics.export` *(sensitive)* |
| **Users & Accounts** | `users.read`, `users.update`, `users.suspend` *(sensitive)*, `users.ban` *(sensitive)* |
| **Listings** | `listings.read`, `listings.approve`, `listings.reject`, `listings.hide`, `listings.delete` *(sensitive)* |
| **Categories** | `categories.read`, `categories.create`, `categories.update`, `categories.delete` *(sensitive)* |
| **Reports** | `reports.read`, `reports.assign`, `reports.resolve` |
| **Verification** | `verification.read`, `verification.documents.read` *(sensitive)*, `verification.approve`, `verification.reject` |
| **Messaging Oversight** | `messaging.complaints.read`, `chat.oversight.read` *(sensitive)*, `messaging.support.resolve` |
| **Notifications** | `notifications.read`, `notifications.create`, `notifications.approve`, `notifications.send` *(sensitive)* |
| **CMS** | `cms.read`, `cms.manage` |
| **Admin Accounts** | `admins.read`, `admins.create` *(sensitive)*, `admins.update` *(sensitive)* |
| **Roles & Permissions** | `roles.read`, `roles.create` *(sensitive)*, `roles.update` *(sensitive)*, `roles.delete` *(sensitive)* |
| **Audit, Health, Flags & Settings** | `audit_logs.read`, `audit_logs.export` *(sensitive)*, `system_health.read`, `feature_flags.read`, `feature_flags.manage` *(sensitive)*, `settings.read`, `settings.update` *(sensitive)* |

---

## 4. Guard Execution Pipeline (`AdminJwtAuthGuard` + `PermissionsGuard`)

1. **`AdminJwtAuthGuard` (`src/modules/admin-auth/guards/admin-jwt-auth.guard.ts`):**
   - Extracts `Authorization: Bearer <token>`.
   - Verifies signature against `ADMIN_JWT_ACCESS_SECRET`, `issuer: 'deal-one.eg'`, `audience: 'deal-one-admin'`.
   - Checks Redis denylist (`admin:revoked:jti:*`, `admin:revoked:sid:*`, `admin:revoked:staff_before:*` using strict `iat < revokedBefore`).
   - Loads active `StaffUser` (`isActive === true`, `status === 'active'`, `deletedAt === null`, `expiresAt` not past) and attaches `AuthenticatedStaff` to `request.user`.
   - **Mobile Isolation:** If a marketplace `USER` mobile token (`audience: 'deal-one-mobile'`) is presented to `/admin/*`, attaches `actorType: 'user', permissions: []`, causing `PermissionsGuard` to fail closed with `403 Forbidden` (never elevations in production).
2. **`PermissionsGuard` (`src/modules/admin-auth/guards/permissions.guard.ts`):**
   - Inspects `@Permissions(...)` (requires ALL listed keys) and `@AnyPermissions(...)` (requires AT LEAST ONE listed key).
   - Throws `ForbiddenException('Access denied. Missing required permission(s): [...]')` on mismatch.

---

## 5. Anti-Privilege-Escalation & Last-Super-Admin Protections

Implemented in `StaffService` (`backend/src/modules/staff/staff.service.ts`):
- **Permission Validation:** Unknown permission keys outside `ADMIN_PERMISSION_SET` (apart from legacy colon format in pre-existing E2E tests) throw `400 Bad Request`.
- **No Upward Privilege Granting:** Non-`super_admin` actors cannot create, update, or clone a role with permissions they do not personally hold (`ForbiddenException`), nor assign a `StaffUser` to a role containing permissions outside their own effective permission set.
- **System Role & Super Admin Protection:**
  - Built-in `isSystem: true` roles cannot be deleted or renamed.
  - `super_admin` cannot be stripped of critical governance permissions (`admins.*`, `roles.*`, `audit_logs.read`, `settings.*`).
  - An admin cannot suspend, deactivate, or demote themselves out of `super_admin`.
  - The platform blocks deactivating, suspending, or reassigning the **last remaining active `super_admin`** account (`403 Forbidden`).

---

## 6. Frontend Permission Enforcement (`admin-web/`)

- `AuthContext` derives `hasPermission(key)` and `hasAnyPermission(...keys)` from `admin.permissions` returned by `/admin/auth/login` and `/admin/auth/me`.
- `AppShell` filters sidebar navigation items dynamically per effective permissions.
- `<PermissionGate>` conditionally hides unauthorized buttons/panels (e.g., Approve, Ban, Reveal Document, Send Campaign).
- `<PagePermissionGuard>` intercepts direct URL navigation to restricted routes and renders an access-denied fallback card without crashing the SPA.
