# 02 — Database & Prisma Schema Analysis

> **Schema File:** `backend/prisma/schema.prisma` (`714` lines)  
> **Database Engine:** PostgreSQL + `postgis` + `pg_trgm` + `pg_stat_statements`  
> **Current Counts:** `31` Prisma models, `10` domain enums, `8` applied migrations

---

## 1. Existing Models Inventory (31 Models)

| Domain | Models (Table Names) | Key Relationships & Indexes |
| :--- | :--- | :--- |
| **Geography (3)** | `Governorate` (`governorates`), `City` (`cities`), `Area` (`areas`) | `Area.centroid` PostGIS `geometry(Point, 4326)` with `Gist` index |
| **Identity & Auth (4)** | `User` (`users`), `UserSession` (`user_sessions`), `UserDevice` (`user_devices`), `Otp` (`otps`) | `UserSession` links strictly to `users(id)` (`onDelete: Cascade`), indexed on `familyId`, `refreshTokenHash` |
| **Multi-Tenant Accounts (6)** | `Account` (`accounts`), `AccountMember` (`account_members`), `AccountVerification` (`account_verifications`), `Branch` (`branches`), `ServiceArea` (`service_areas`), `Project` (`projects`) | `AccountVerification.reviewedByStaffId -> staff_users(id)`; `Branch.location` PostGIS `Gist` |
| **Taxonomy (2)** | `Category` (`categories`), `CategoryField` (`category_fields`) | Self-referential `CategoryHierarchy`, unique `[categoryId, fieldKey]` |
| **Listings & Media (2)** | `Listing` (`listings`), `ListingMedia` (`listing_media`) | 3-axis status columns (`moderationStatus`, `publicationStatus`, `availabilityStatus`), `Gist` spatial indexes, `Gin` index on `attributes`, `searchNormalizedText`, `promotedUntil`, `approvedAt` |
| **Engagement & Reports (2)** | `Favorite` (`favorites`), `Report` (`reports`) | `Report.resolvedByStaffId -> staff_users(id)` |
| **In-App Chat (2)** | `Conversation` (`conversations`), `Message` (`messages`) | Unique `[listingId, buyerUserId]` |
| **Platform Control (3)** | `Notification` (`notifications`), `DailyQuota` (`daily_quotas`), `PlatformSetting` (`platform_settings`) | `PlatformSetting.updatedByStaffId -> staff_users(id)` |
| **Staff & Governance (4)** | `StaffRole` (`staff_roles`), `StaffUser` (`staff_users`), `ModerationLog` (`moderation_log`), `AuditLog` (`audit_log`) | `StaffUser.roleId -> staff_roles(id)`; `ModerationLog.staffId -> staff_users(id)` |
| **Outbox (1)** | `OutboxEvent` (`outbox_events`) | Pattern F transactional outbox (`PENDING`, `PROCESSING`, `PUBLISHED`, `FAILED`) |
| **V2 Payments (2)** | `PromotionPackage` (`promotion_packages`), `Payment` (`payments`) | `Payment` links to `User`, `Listing`, `PromotionPackage` |

---

## 2. Detailed Inspection of Admin-Relevant Models

### 2.1 `StaffRole` (`staff_roles`) — Already Exists
```prisma
model StaffRole {
  id          Int         @id @default(autoincrement())
  name        String      @unique @db.VarChar(50)
  permissions Json        @default("[]")
  staffUsers  StaffUser[]

  @@map("staff_roles")
}
```
- **Observation:** Already stores `permissions` as JSON (`string[]`), but lacks `description`, `isSystem` (to protect built-in roles like `super_admin` from deletion), and `updatedAt` / `createdAt` timestamps.

### 2.2 `StaffUser` (`staff_users`) — Already Exists
```prisma
model StaffUser {
  id           String   @id @default(uuid()) @db.Uuid
  email        String   @unique @db.VarChar(255)
  passwordHash String   @map("password_hash") @db.VarChar(255)
  fullName     String   @map("full_name") @db.VarChar(120)
  roleId       Int      @map("role_id")
  isActive     Boolean  @default(true) @map("is_active")
  createdAt    DateTime @default(now()) @map("created_at") @db.Timestamptz
  ...
}
```
- **Observation:** `StaffUser` is already wired by foreign key to `AccountVerification` (`reviewedVerifications`), `Report` (`resolvedReports`), `PlatformSetting` (`platformSettingsUpdates`), and `ModerationLog` (`moderationActions`).
- **Missing fields on `StaffUser`:**
  - MFA support (`mfaEnabled`, `mfaSecretEncrypted`, `mfaRecoveryCodesHash`, `mfaVerifiedAt`).
  - Account lifecycle / security tracking (`lastLoginAt`, `passwordChangedAt`, `failedLoginCount`, `lockedUntil`, `updatedAt`, `deletedAt`).
  - Password reset support (or dedicated token table `StaffPasswordResetToken`).

### 2.3 `UserSession` (`user_sessions`) — Mobile Only
- `UserSession` has `userId String @db.Uuid` with `User @relation(..., onDelete: Cascade)`.
- Because `StaffUser` lives in `staff_users` (separate UUID namespace from `users`), a `StaffUser` **cannot** create a row in `user_sessions` due to the PostgreSQL foreign key constraint `user_sessions_user_id_fkey`.
- **Required Addition:** A dedicated `StaffSession` (`staff_sessions`) model referencing `staff_users(id)`.

### 2.4 `AuditLog` (`audit_log`) & `ModerationLog` (`moderation_log`) — Already Exist
- `AuditLog` captures `actorType` (`staff`, `user`, `system`), `actorId`, `action`, `targetEntity`, `targetId`, `ipAddress`, `userAgent`, `diffPayload`, `createdAt`.
- **Indexing Gap:** Currently only `@@index([targetEntity, targetId, createdAt(sort: Desc)])` exists. Filtering by `actorId`, `actorType`, `action`, or `createdAt` at millions-of-rows scale requires additional composite indexes:
  - `@@index([actorType, actorId, createdAt(sort: Desc)])`
  - `@@index([action, createdAt(sort: Desc)])`
  - `@@index([createdAt(sort: Desc)])`

### 2.5 `User` (`users`) & `Report` (`reports`) Gaps
- **`User`:** Has `isActive Boolean` and `deletedAt DateTime?`, which works for active vs soft-deleted, but lacks distinct administrative `suspended` vs `banned` states (`suspensionReason`, `suspendedUntil`, `bannedAt`, `banReason`, `moderatedByStaffId`) required by Phase 03/04 (`users.suspend`, `users.ban`). Keeping `isActive = false` synchronized whenever suspended/banned preserves 100% compatibility with existing mobile queries!
- **`Report`:** Has `resolvedByStaffId`, `resolutionNotes`, `resolvedAt`, but lacks `assignedToStaffId` and `assignedAt` required by `reports.assign`.

### 2.6 Schema vs Enum Discrepancy Discovered
- In `prisma/schema.prisma`, `enum ReportStatus` defines `PENDING, REVIEWED, ACTION_TAKEN, DISMISSED`, whereas the `reports.status` column is `String @db.VarChar(20)` defaulting to `"open"`, and `src/core/enums/domain.enums.ts` defines `ReportStatus { OPEN = 'open', RESOLVED = 'resolved', DISMISSED = 'dismissed' }`.
- Similarly, `enum UserRole` in both `schema.prisma` and `domain.enums.ts` only has `USER, MODERATOR, SUPER_ADMIN` — none of the models actually use the Prisma enum columns directly (they use `String` + `StaffRole.name`), so extending admin roles via `StaffRole` + `StaffRole.permissions` requires zero breaking changes to existing columns.

---

## 3. Non-Duplication Database Strategy (Phase 06 Preview)

| Candidate Model in Prompt | Existing Table? | Decision |
| :--- | :--- | :--- |
| `AdminUser` | **YES** (`staff_users` / `StaffUser`) | **DO NOT DUPLICATE.** Extend `StaffUser` in-place to preserve existing FKs from `reports`, `account_verifications`, `platform_settings`, and `moderation_log`. |
| `AdminRole` | **YES** (`staff_roles` / `StaffRole`) | **DO NOT DUPLICATE.** Extend `StaffRole` in-place (`description`, `isSystem`, `createdAt`, `updatedAt`). |
| `AdminPermission` / `AdminRolePermission` | Partial (`StaffRole.permissions` JSON) | Store canonical permission registry in backend constants (`ADMIN_PERMISSIONS`) + normalized `StaffRole.permissions` JSON array (or optional relational join table if needed; `StaffRole.permissions` JSON is already in schema and zero-migration-friction for existing code, OR add `StaffPermission` lookup table while keeping `StaffRole.permissions` in sync). |
| `AdminUserRole` | Single `StaffUser.roleId` FK exists | Keep `StaffUser.roleId` for primary role; optional `StaffUserPermissionOverride` or multi-role if needed, though single primary `StaffRole` matches existing `staff_users` cleanly. |
| `AdminSession` | **NO** (`user_sessions` is `User`-only) | **ADD `StaffSession` (`staff_sessions`)** referencing `staff_users(id)`. |
| `AdminMfaMethod` | **NO** | Add MFA columns on `StaffUser` + optional `StaffMfaRecoveryCode` or `StaffPasswordResetToken` (`staff_password_resets`). |
| `AdminAuditLog` | **YES** (`audit_log` / `AuditLog`) | **DO NOT DUPLICATE.** Reuse `AuditLog` (`actorType = 'staff'`) and add missing indexes. |
| `AdminLoginAttempt` | **NO** | **ADD `StaffLoginAttempt` (`staff_login_attempts`)** for durable login attempt history & lockouts. |
| `ModerationAssignment` | Partial (`reports` lacks assignee) | Add `assignedToStaffId` + `assignedAt` directly on `Report` (and `moderation_notes` if needed). |
| `FeatureFlag` | **NO** | **ADD `FeatureFlag` (`feature_flags`)** for dedicated Feature Flags management. |
| `CmsItem` (for Module 8 CMS) | **NO** | **ADD `CmsItem` (`cms_items`)** for banners, announcements, and static pages (`type`, `slug`, `titleAr`, `titleEn`, `bodyAr`, `bodyEn`, `imageUrl`, `targetUrl`, `isActive`, `startsAt`, `endsAt`, `sortOrder`). |

---

## 4. Applied Migrations (`backend/prisma/migrations/`)

All 8 migrations verified in directory:
1. `20261102232252_init_database_foundation`
2. `20261102232759_`
3. `20261102233251_add_gist_gin_spatial_indexes`
4. `20261103001630_add_geometry_defaults`
5. `20261103155808_phase03_auth_family_and_otp_purpose`
6. `20261104230259_add_demo_marker_and_indexes`
7. `20261117000001_add_payments_and_listing_promotion_search`
8. `20261117000002_add_trgm_jsonb_indexes_and_pg_stat_statements`

> **Production Caution:** `prisma/seeds/seed.ts` guards demo data behind `assertSafeDatabaseTarget()` and `ENABLE_DEMO_DATA`. Any future admin role seed script (`seed-admin-rbac.ts`) must be strictly idempotent (`upsert` by `StaffRole.name`) and safe to run in production without touching demo data or overwriting customized roles.
