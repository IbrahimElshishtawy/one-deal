# Deal One Enterprise Admin Dashboard — Database Changes & Migration

## 1. Migration Strategy

- **Migration Directory:** `backend/prisma/migrations/20261120000001_add_enterprise_admin_platform/migration.sql`
- **Guarantee:** 100% additive and idempotent (`ADD COLUMN IF NOT EXISTS`, `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`). Zero tables dropped, zero existing columns renamed, zero existing marketplace rows modified.
- **Prisma Application Status:** Applied cleanly via `npx prisma migrate deploy` and client generated (`npx prisma generate`). Total migrations in repository: **9** (verified by `migrate-deploy.spec.ts`).

---

## 2. Extended Existing Tables

### A. `staff_roles` (`StaffRole`)
Added enterprise governance metadata:
- `description VARCHAR(255)`
- `is_system BOOLEAN NOT NULL DEFAULT false`
- `created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP`
- `updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP`

### B. `staff_users` (`StaffUser`)
Added enterprise identity lifecycle & MFA support:
- `phone VARCHAR(20)`, `department VARCHAR(100)`, `job_title VARCHAR(100)`
- `status VARCHAR(20) NOT NULL DEFAULT 'active'` (`active`, `suspended`, `disabled`, `invited`)
- `mfa_enabled BOOLEAN NOT NULL DEFAULT false`, `mfa_secret_encrypted TEXT`, `mfa_recovery_codes_hash JSONB`
- `last_login_at TIMESTAMPTZ`, `password_changed_at TIMESTAMPTZ`, `expires_at TIMESTAMPTZ`
- `updated_at TIMESTAMPTZ`, `deleted_at TIMESTAMPTZ`
- Index: `staff_users_role_id_is_active_idx (role_id, is_active)`

### C. `users` (`User`)
Added moderation state metadata while keeping `is_active` synchronized with mobile login/guard checks:
- `moderation_status VARCHAR(20) NOT NULL DEFAULT 'active'` (`active`, `suspended`, `banned`)
- `suspended_until TIMESTAMPTZ`, `suspension_reason TEXT`
- `banned_at TIMESTAMPTZ`, `ban_reason TEXT`
- `internal_notes JSONB DEFAULT '[]'`

### D. `reports` (`Report`)
Added triage & collaboration fields:
- `priority VARCHAR(20) NOT NULL DEFAULT 'medium'` (`low`, `medium`, `high`, `critical`)
- `assigned_to_staff_id UUID` (FK `-> staff_users(id) ON DELETE SET NULL`), `assigned_at TIMESTAMPTZ`
- `internal_notes JSONB DEFAULT '[]'`
- Index: `reports_assigned_to_staff_id_status_idx (assigned_to_staff_id, status)`

### E. `account_verifications` (`AccountVerification`)
Added reviewer workflow fields:
- `assigned_to_staff_id UUID`
- `notes TEXT`

### F. `audit_log` (`AuditLog`)
Added query performance indexes:
- `audit_log_actor_type_actor_id_created_at_idx (actor_type, actor_id, created_at DESC)`
- `audit_log_action_created_at_idx (action, created_at DESC)`
- `audit_log_created_at_idx (created_at DESC)`

---

## 3. Newly Added Tables

| Table (`@@map`) | Prisma Model | Purpose | Key Columns & Indexes |
| :--- | :--- | :--- | :--- |
| `staff_sessions` | `StaffSession` | Refresh token session family tracking for admins | `staff_id` (FK -> `staff_users`), `family_id`, `refresh_token_hash`, `mfa_verified`, `is_revoked`, `expires_at` |
| `staff_login_attempts` | `StaffLoginAttempt` | Persistent authentication telemetry & lockout counter | `email`, `staff_id`, `ip_address`, `is_success`, `failure_reason`, indexed by `(email, created_at DESC)` |
| `staff_password_resets` | `StaffPasswordResetToken` | Single-use SHA-256 reset token store | `staff_id` (FK), `token_hash` (UNIQUE), `expires_at`, `used_at` |
| `feature_flags` | `FeatureFlag` | Runtime feature switches & environment targeting | `key` (PK), `is_enabled`, `environment`, `rollout_percentage`, `rules` (history JSONB), `is_system` |
| `cms_items` | `CmsItem` | Bilingual AR/EN banners, pages, FAQ, terms, privacy & revisions | `id`, `type`, `slug` (UNIQUE), `status` (`draft`, `published`, `scheduled`, `archived`), `revisions` JSONB |
| `notification_campaigns` | `NotificationCampaign` | Bilingual marketing/operational push & inbox campaigns | `id`, `audience_type`, `audience_filter`, `status`, `scheduled_at`, `estimated_recipients`, `sent_count`, `delivered_count` |

---

## 4. Administrative Seed (`backend/prisma/seeds/seed-admin-rbac.ts`)

Run via `cd backend && npm run prisma:seed:admin`:
- Upserts all **9 system roles** with exact permission arrays (`45` permissions in `super_admin`).
- Creates initial Super Admin (`superadmin@dealone.eg` in dev/staging, or via `BOOTSTRAP_SUPER_ADMIN_EMAIL` / `BOOTSTRAP_SUPER_ADMIN_PASSWORD` in production).
- In non-production (`NODE_ENV !== 'production'`), seeds 6 verification personas (`moderator@`, `verification@`, `support@`, `marketing@`, `analyst@`, `auditor@` `@dealone.eg`).
- Idempotently seeds **5 system Feature Flags**, **7 Platform Settings**, and **4 published bilingual CMS items** (`home-hero-welcome`, `terms-and-conditions`, `privacy-policy`, `faq-how-to-post`).
