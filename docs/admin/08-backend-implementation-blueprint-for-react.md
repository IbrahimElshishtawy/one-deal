# 08 — Backend Implementation Blueprint for React Admin Dashboard

> **Purpose:** This is the complete, actionable backend engineering specification required to make the existing Deal One NestJS + Fastify + Prisma backend fully support the **React Admin Dashboard**.  
> **Non-Negotiable Guarantee:** Preserves 100% backward compatibility with the Flutter mobile app (`/api/v1/*`, `User`, `UserSession`, `JwtStrategy` with `audience: 'deal-one-mobile'`).

---

## 1. Required Backend Dependencies & Environment Changes

### 1.1 Packages to Install in `backend/`
- `@fastify/cookie` — required for `HttpOnly` refresh cookies (`dealone_admin_rt`) on React web sessions.
- `otplib` (or `qrcode` for TOTP URI generation, optional if React renders QR from `otpauth://` URL directly via `qrcode.react`). Using `otplib` (or zero-dep Node `crypto` RFC 6238 TOTP) handles secret generation and verification cleanly on the backend.

### 1.2 Environment Variables (`src/core/config/env.config.ts`)
Add optional/validated admin configuration variables:
- `ADMIN_JWT_ACCESS_SECRET` *(optional distinct secret; or strictly enforce `audience: 'deal-one-admin'` + `actorType: 'staff'` with optional secret separation)*
- `ADMIN_JWT_ACCESS_EXPIRES_IN` (default `'15m'`)
- `ADMIN_REFRESH_EXPIRES_DAYS` (default `7`)
- `ADMIN_MFA_ENCRYPTION_KEY` (32-byte hex/base64 key for AES-256-GCM encryption of `StaffUser.mfaSecretEncrypted` at rest)
- `ADMIN_COOKIE_NAME` (default `'dealone_admin_rt'`)
- `ADMIN_COOKIE_DOMAIN` *(optional for subdomain sharing e.g. `.dealone.eg`)*
- `ADMIN_PUBLIC_URL` (for admin password reset email links)
- `CORS_ORIGIN` — **must** include the React Admin Dashboard origin(s), e.g., `http://localhost:5173,https://admin.dealone.eg`, and `http-security.config.ts` must add `'X-CSRF-Token'` and `'X-Requested-With'` to `allowedHeaders`.

---

## 2. Exact Prisma Schema Changes (No Duplicate Models)

All existing models (`StaffRole`, `StaffUser`, `AuditLog`, `ModerationLog`, `PlatformSetting`, `Report`, `AccountVerification`, `User`) are **reused and extended in-place**.

### 2.1 Extensions to Existing Models
```prisma
// 1) Extend StaffRole (staff_roles)
model StaffRole {
  id          Int         @id @default(autoincrement())
  name        String      @unique @db.VarChar(50)
  description String?     @db.VarChar(255)
  isSystem    Boolean     @default(false) @map("is_system")
  permissions Json        @default("[]")
  createdAt   DateTime    @default(now()) @map("created_at") @db.Timestamptz
  updatedAt   DateTime    @default(now()) @updatedAt @map("updated_at") @db.Timestamptz
  staffUsers  StaffUser[]

  @@map("staff_roles")
}

// 2) Extend StaffUser (staff_users)
model StaffUser {
  id                   String    @id @default(uuid()) @db.Uuid
  email                String    @unique @db.VarChar(255)
  passwordHash         String    @map("password_hash") @db.VarChar(255)
  fullName             String    @map("full_name") @db.VarChar(120)
  phone                String?   @db.VarChar(20)
  avatarUrl            String?   @map("avatar_url") @db.VarChar(500)
  roleId               Int       @map("role_id")
  isActive             Boolean   @default(true) @map("is_active")
  mfaEnabled           Boolean   @default(false) @map("mfa_enabled")
  mfaSecretEncrypted   String?   @map("mfa_secret_encrypted") @db.Text
  mfaRecoveryCodesHash Json?     @map("mfa_recovery_codes_hash")
  lastLoginAt          DateTime? @map("last_login_at") @db.Timestamptz
  passwordChangedAt    DateTime? @map("password_changed_at") @db.Timestamptz
  createdAt            DateTime  @default(now()) @map("created_at") @db.Timestamptz
  updatedAt            DateTime  @default(now()) @updatedAt @map("updated_at") @db.Timestamptz
  deletedAt            DateTime? @map("deleted_at") @db.Timestamptz

  role                    StaffRole                 @relation(fields: [roleId], references: [id], onDelete: Restrict)
  sessions                StaffSession[]
  loginAttempts           StaffLoginAttempt[]
  passwordResetTokens     StaffPasswordResetToken[]
  reviewedVerifications   AccountVerification[]     @relation("ReviewedVerifications")
  resolvedReports         Report[]                  @relation("ResolvedReports")
  assignedReports         Report[]                  @relation("AssignedReports")
  platformSettingsUpdates PlatformSetting[]         @relation("StaffPlatformSettings")
  moderationActions       ModerationLog[]

  @@index([roleId, isActive])
  @@map("staff_users")
}

// 3) Extend User (users) — non-breaking additive fields; keep isActive synchronized!
// Add to existing User model:
//   moderationStatus String    @default("active") @map("moderation_status") @db.VarChar(20) // active, suspended, banned
//   suspendedUntil   DateTime? @map("suspended_until") @db.Timestamptz
//   suspensionReason String?   @map("suspension_reason") @db.Text
//   bannedAt         DateTime? @map("banned_at") @db.Timestamptz
//   banReason        String?   @map("ban_reason") @db.Text

// 4) Extend Report (reports) — support reports.assign
// Add to existing Report model:
//   assignedToStaffId String?    @map("assigned_to_staff_id") @db.Uuid
//   assignedAt        DateTime?  @map("assigned_at") @db.Timestamptz
//   assignedTo        StaffUser? @relation("AssignedReports", fields: [assignedToStaffId], references: [id], onDelete: SetNull)
//   @@index([assignedToStaffId, status])

// 5) Extend AuditLog (audit_log) — add query performance indexes
//   @@index([actorType, actorId, createdAt(sort: Desc)])
//   @@index([action, createdAt(sort: Desc)])
//   @@index([createdAt(sort: Desc)])
```

### 2.2 New Non-Duplicate Tables
```prisma
model StaffSession {
  id               String   @id @default(uuid()) @db.Uuid
  staffId          String   @map("staff_id") @db.Uuid
  familyId         String   @map("family_id") @db.Uuid
  refreshTokenHash String   @map("refresh_token_hash") @db.VarChar(255)
  ipAddress        String   @map("ip_address") @db.VarChar(50)
  userAgent        String?  @map("user_agent") @db.VarChar(500)
  mfaVerified      Boolean  @default(false) @map("mfa_verified")
  isRevoked        Boolean  @default(false) @map("is_revoked")
  expiresAt        DateTime @map("expires_at") @db.Timestamptz
  createdAt        DateTime @default(now()) @map("created_at") @db.Timestamptz
  lastUsedAt       DateTime @default(now()) @map("last_used_at") @db.Timestamptz

  staff StaffUser @relation(fields: [staffId], references: [id], onDelete: Cascade)

  @@index([staffId, isRevoked])
  @@index([familyId])
  @@index([refreshTokenHash])
  @@map("staff_sessions")
}

model StaffLoginAttempt {
  id            String   @id @default(uuid()) @db.Uuid
  email         String   @db.VarChar(255)
  staffId       String?  @map("staff_id") @db.Uuid
  ipAddress     String   @map("ip_address") @db.VarChar(50)
  userAgent     String?  @map("user_agent") @db.VarChar(500)
  isSuccess     Boolean  @map("is_success")
  failureReason String?  @map("failure_reason") @db.VarChar(100)
  createdAt     DateTime @default(now()) @map("created_at") @db.Timestamptz

  staff StaffUser? @relation(fields: [staffId], references: [id], onDelete: SetNull)

  @@index([email, createdAt(sort: Desc)])
  @@index([staffId, createdAt(sort: Desc)])
  @@index([ipAddress, createdAt(sort: Desc)])
  @@map("staff_login_attempts")
}

model StaffPasswordResetToken {
  id        String    @id @default(uuid()) @db.Uuid
  staffId   String    @map("staff_id") @db.Uuid
  tokenHash String    @unique @map("token_hash") @db.VarChar(255)
  expiresAt DateTime  @map("expires_at") @db.Timestamptz
  usedAt    DateTime? @map("used_at") @db.Timestamptz
  createdAt DateTime  @default(now()) @map("created_at") @db.Timestamptz

  staff StaffUser @relation(fields: [staffId], references: [id], onDelete: Cascade)

  @@index([staffId, expiresAt])
  @@map("staff_password_resets")
}

model FeatureFlag {
  key               String   @id @db.VarChar(100)
  name              String   @db.VarChar(150)
  description       String?  @db.Text
  isEnabled         Boolean  @default(false) @map("is_enabled")
  rolloutPercentage Int      @default(100) @map("rollout_percentage")
  rules             Json     @default("{}")
  isSystem          Boolean  @default(false) @map("is_system")
  updatedByStaffId  String?  @map("updated_by_staff_id") @db.Uuid
  createdAt         DateTime @default(now()) @map("created_at") @db.Timestamptz
  updatedAt         DateTime @default(now()) @updatedAt @map("updated_at") @db.Timestamptz

  @@map("feature_flags")
}

model CmsItem {
  id               String    @id @default(uuid()) @db.Uuid
  type             String    @db.VarChar(30) // banner, announcement, page, faq
  slug             String    @unique @db.VarChar(150)
  titleAr          String    @map("title_ar") @db.VarChar(255)
  titleEn          String    @map("title_en") @db.VarChar(255)
  bodyAr           String?   @map("body_ar") @db.Text
  bodyEn           String?   @map("body_en") @db.Text
  imageUrl         String?   @map("image_url") @db.VarChar(500)
  targetUrl        String?   @map("target_url") @db.VarChar(500)
  placement        String?   @db.VarChar(50) // home_hero, section_banner, footer
  sortOrder        Int       @default(0) @map("sort_order")
  isActive         Boolean   @default(true) @map("is_active")
  startsAt         DateTime? @map("starts_at") @db.Timestamptz
  endsAt           DateTime? @map("ends_at") @db.Timestamptz
  updatedByStaffId String?   @map("updated_by_staff_id") @db.Uuid
  createdAt        DateTime  @default(now()) @map("created_at") @db.Timestamptz
  updatedAt        DateTime  @default(now()) @updatedAt @map("updated_at") @db.Timestamptz

  @@index([type, isActive, sortOrder])
  @@map("cms_items")
}
```

---

## 3. Canonical RBAC Specification (9 Roles + Granular Permissions)

### 3.1 Permission Catalog (`ADMIN_PERMISSIONS`)
```ts
export const ADMIN_PERMISSIONS = [
  // Users & Accounts
  'users.read',
  'users.update',
  'users.suspend',
  'users.ban',
  // Listings
  'listings.read',
  'listings.approve',
  'listings.reject',
  'listings.hide',
  'listings.delete',
  // Categories
  'categories.read',
  'categories.create',
  'categories.update',
  'categories.delete',
  // Reports & Moderation
  'reports.read',
  'reports.assign',
  'reports.resolve',
  // Verification
  'verification.read',
  'verification.approve',
  'verification.reject',
  // Notifications
  'notifications.read',
  'notifications.send',
  // CMS
  'cms.read',
  'cms.manage',
  // Chat Oversight
  'chat.oversight.read',
  // Analytics
  'analytics.read',
  // Admin Staff
  'admins.read',
  'admins.create',
  'admins.update',
  // Roles
  'roles.read',
  'roles.create',
  'roles.update',
  'roles.delete',
  // Audit, Health, Flags & Settings
  'audit_logs.read',
  'system_health.read',
  'feature_flags.read',
  'feature_flags.manage',
  'settings.read',
  'settings.update',
] as const;
```

### 3.2 Initial 9 Roles Matrix
| Role Slug (`StaffRole.name`) | `isSystem` | Default Permissions |
| :--- | :--- | :--- |
| `super_admin` | `true` | All `38` permissions (cannot be deleted or stripped of `admins.*`/`roles.*`/`settings.*`) |
| `platform_admin` | `true` | All except `roles.delete` and `admins.create`/`admins.update` escalation |
| `operations_manager` | `true` | `users.read`, `users.update`, `users.suspend`, `listings.*`, `categories.*`, `reports.*`, `verification.*`, `analytics.read`, `notifications.read`, `notifications.send` |
| `content_moderator` | `true` | `listings.read`, `listings.approve`, `listings.reject`, `listings.hide`, `reports.read`, `reports.resolve`, `users.read`, `chat.oversight.read` |
| `verification_officer` | `true` | `verification.read`, `verification.approve`, `verification.reject`, `users.read`, `listings.read` |
| `customer_support` | `true` | `users.read`, `users.update`, `listings.read`, `reports.read`, `reports.assign`, `verification.read`, `notifications.read`, `chat.oversight.read` |
| `marketing_manager` | `true` | `cms.read`, `cms.manage`, `notifications.read`, `notifications.send`, `analytics.read`, `categories.read`, `listings.read` |
| `analyst` | `true` | `analytics.read`, `listings.read`, `users.read`, `categories.read`, `reports.read` |
| `security_auditor` | `true` | `audit_logs.read`, `system_health.read`, `admins.read`, `roles.read`, `users.read`, `settings.read`, `feature_flags.read` |

### 3.3 Mandatory RBAC Enforcement Rules
1. `PermissionsGuard` reads the `StaffUser` + `StaffRole` permissions **from PostgreSQL (with short Redis cache `staff:perms:{staffId}` invalidated immediately on role/staff update)** — never trust stale JWT permission claims alone!
2. **Last Super Admin Guard:** `PATCH /admin/staff/:id` and `PATCH /admin/staff/roles/:id` MUST execute inside a serializable/locked Prisma transaction ensuring at least `1` active `StaffUser` remains assigned to `super_admin`.
3. **Anti-Privilege Escalation Guard:** A staff user cannot create/update a role with permissions they do not possess (unless `super_admin`), and cannot assign a role containing permissions outside their own scope, nor modify their own `roleId` or `isActive`.

---

## 4. Backend Auth & Guard Architecture (`src/modules/admin-auth/`)

### 4.1 `AdminJwtStrategy` (`PassportStrategy(Strategy, 'admin-jwt')`)
- Extracts JWT from `Authorization: Bearer <token>`.
- Validates `issuer: 'deal-one.eg'`, `audience: 'deal-one-admin'` (strictly rejecting mobile `deal-one-mobile` tokens!).
- Checks Redis denylist (`admin:revoked:jti:{jti}`, `admin:revoked:sid:{sid}`, `admin:revoked:staff_before:{sub}`).
- Queries `prisma.staffUser.findUnique({ where: { id: payload.sub }, include: { role: true } })` and rejects if `!staff || !staff.isActive || staff.deletedAt`.
- Attaches `AuthenticatedStaff` (`id`, `email`, `fullName`, `roleId`, `roleName`, `permissions`, `sessionId`, `mfaVerified`) to `request.user`.

### 4.2 Cookie + CSRF Contract for React
- Login / MFA Verify / Refresh sets:
  - Cookie `dealone_admin_rt=<raw40BytesHex>` (`httpOnly: true`, `sameSite: 'strict'`, `secure: isProd`, `path: '/api/v1/admin/auth'`, `maxAge: 7d`).
- `/admin/auth/refresh` and `/admin/auth/logout` require:
  - Header `X-Requested-With: dealone-admin-web` (or `X-CSRF-Token`) + valid `Origin` in production.
  - Reuse detection on `StaffSession.isRevoked` revokes the entire `familyId` + Redis denylists all active access tokens of that staff user.

---

## 5. Required Bug Fixes to Existing Admin Modules

1. **`ModerationService.adjudicateListing()`:**
   - Accept `staffId` from `AuthenticatedStaff` and store `staffId` in `ModerationLog`.
   - Set `approvedAt: new Date()` when `dto.action === 'approve'`.
   - Set `publicationStatus: 'unpublished'` (not `'draft'`) when `dto.action === 'reject'`.
2. **`ModerationService.adjudicateReport()`:**
   - **Critical Bug Fix:** Persist `status: dto.status` (`open` | `resolved` | `dismissed`) instead of hardcoded `'resolved'`, and set `resolvedByStaffId: moderatorId`.
3. **`ModerationService.adjudicateVerification()`:**
   - Persist `reviewedByStaffId: moderatorId` on `AccountVerification` and `staffId: moderatorId` on `ModerationLog`.
4. **`PlatformSettingsService.upsertSetting()`:**
   - Persist `updatedByStaffId: actorId` on `PlatformSetting`.
5. **All Existing Admin Controllers (`CategoriesController`'s `AdminCategoriesController`, `ModerationController`, `PlatformSettingsController`, `StaffController`):**
   - Replace `@UseGuards(JwtAuthGuard, RolesGuard)` + `@Roles(...)` with `@UseGuards(AdminJwtAuthGuard, PermissionsGuard)` + `@Permissions(...)` so `StaffUser` accounts actually authenticate and obey granular permissions.

---

## 6. Standardized Request & Response Contracts for React

### 6.1 Standard Paginated Query DTO (`AdminPaginationQueryDto`)
All admin list endpoints (`users`, `accounts`, `listings`, `reports`, `verifications`, `staff`, `audit-logs`, `cms`, `notifications`) support:
```ts
export interface AdminListQuery {
  page?: number;      // default 1, min 1
  limit?: number;     // default 20, min 1, max 100
  q?: string;         // trimmed search term
  sortBy?: string;    // whitelisted per endpoint
  sortOrder?: 'asc' | 'desc';
}
```

### 6.2 Standard Paginated Response Envelope
All new/updated admin list endpoints return via `TransformInterceptor`:
```json
{
  "success": true,
  "data": {
    "items": [],
    "meta": {
      "total": 120,
      "page": 1,
      "limit": 20,
      "totalPages": 6
    }
  }
}
```
*(Note: for existing endpoints consumed by any test — `/admin/moderation/listings`, `/admin/moderation/queue`, `/admin/moderation/verifications`, `/admin/audit-logs` — preserve their existing keys `listings` / `reports` / `verifications` / `logs` alongside `meta`, OR provide normalized aliases cleanly without breaking existing E2E assertions.)*

### 6.3 Standard Error Response (Already Live in `HttpExceptionFilter`)
React `apiClient` must parse:
```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Missing required permission: listings.delete",
    "details": null,
    "trace_id": "550e8400-e29b-41d4-a716-446655440000"
  }
}
```

---

## 7. Backend Implementation Checklist Before React Feature Integration

1. **Migration:** Create & review Prisma migration for `StaffRole`, `StaffUser`, `StaffSession`, `StaffLoginAttempt`, `StaffPasswordResetToken`, `FeatureFlag`, `CmsItem`, `Report` (`assignedToStaffId`), `User` (`moderationStatus` fields), and `AuditLog` indexes.
2. **RBAC Seed:** Create idempotent `prisma/seeds/seed-admin-rbac.ts` seeding the 9 roles and optionally an env-configured initial Super Admin (`BOOTSTRAP_SUPER_ADMIN_EMAIL` / password via secure CLI/env, never hardcoded).
3. **Auth & Security:** Implement `AdminAuthModule` (`@fastify/cookie`, `AdminJwtStrategy`, `StaffSessionService`, MFA TOTP, password reset via `EmailService`).
4. **Guards:** Implement `AdminJwtAuthGuard` & `PermissionsGuard`, and migrate `AdminCategoriesController`, `ModerationController`, `PlatformSettingsController`, and `StaffController`.
5. **Module APIs:** Implement the remaining 11 new/extended `/api/v1/admin/*` controllers (`dashboard`, `users`, `accounts`, `listings`, `notifications`, `cms`, `chat`, `analytics`, `system`, `feature-flags`, plus extended `categories`, `moderation`, `staff`, `audit-logs`).
6. **Swagger & Verification:** Enable Swagger in local/staging (`/api/docs`) so React TypeScript schemas/hooks can be verified directly against live OpenAPI contracts, and run all NestJS unit + E2E tests including existing mobile Flutter E2E regression tests.
