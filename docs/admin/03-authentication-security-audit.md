# 03 — Authentication & Security Audit

> **Scope:** Existing authentication, session handling, JWT validation, RBAC guards, CORS/Helmet, rate limiting, and administrative security posture.

---

## 1. Existing Security Strengths

1. **Password Hashing (`auth.service.ts`):** Uses `argon2` with dummy hash verification on unknown accounts (`await argon2.hash(dto.password)`) to mitigate timing-based user enumeration.
2. **Refresh Token Security (`session.service.ts`):**
   - Generates 40-byte cryptographically random tokens (`crypto.randomBytes(40).toString('hex')`).
   - Stores only SHA-256 hashes in PostgreSQL (`user_sessions.refresh_token_hash`).
   - Implements **Token Family Reuse Detection** (`familyId`): presenting a previously revoked token triggers immediate revocation of the entire session family and denylisting of their session IDs in Redis.
   - Uses concurrency-safe atomic `updateMany({ where: { id, isRevoked: false } })` to prevent race-condition double rotation.
3. **Instant Access Token Revocation (`session.service.ts` + `jwt.strategy.ts`):**
   - Short `15m` access tokens carry `sid` and `jti`.
   - Redis denylisting supports per-`jti` (`auth:revoked:jti:*`), per-`sid` (`auth:revoked:sid:*`), and per-user timestamp cutoff (`auth:revoked:user_before:*`).
4. **Startup Secret Hygiene (`env.config.ts`):** Enforces minimum length, weak-pattern rejection, unique character count, Shannon entropy `>= 3.0`, and separation of `JWT_ACCESS_SECRET` vs `JWT_REFRESH_SECRET` in production.
5. **Distributed Rate Limiting (`rate-limit.guard.ts` + `redis.service.ts`):** Atomic Lua `INCR`+`EXPIRE` script with CGNAT-safe `userId` keying for authenticated callers and Fastify-verified `request.ip` keying for anonymous callers.
6. **Audit Log Sanitization (`security-audit.service.ts`):** Recursively redacts sensitive fields (`password`, `secret`, `token`, `otp`, `code`, `jwt`, `cookie`, `authorization`, `apikey`, `privatekey`).

---

## 2. Critical Administrative Security Findings

### Finding 1 — [CRITICAL / BROKEN] No Authentication Endpoint Exists for `StaffUser`
- **Evidence:**
  - `StaffService.createStaffUser()` (`src/modules/staff/staff.service.ts`) hashes passwords with `argon2` and inserts into `staff_users` (`email`, `passwordHash`, `roleId`).
  - `AuthService.loginWithPassword()` (`src/modules/auth/auth.service.ts:268`) normalizes a **phone number**, queries `this.prisma.user.findUnique({ where: { phone } })`, and calls `sessionService.createSession(user.id, user.phone, 'USER', ...)`.
- **Impact:** Created `StaffUser` administrators **cannot log in at all**. Every `POST /auth/login` token always receives hardcoded `role: 'USER'`.

### Finding 2 — [CRITICAL / BROKEN] `JwtStrategy` Rejects `StaffUser` Tokens
- **Evidence (`src/modules/auth/strategies/jwt.strategy.ts:37-75`):**
  ```ts
  if (!payload.sub || !payload.phone) {
    throw new UnauthorizedException('JWT token contains invalid claims.');
  }
  const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
  ```
- **Impact:** Even if an admin token were minted for a `StaffUser`, `JwtStrategy` requires `payload.phone` and looks up `users` instead of `staff_users`, rejecting the request with `401 Unauthorized`.

### Finding 3 — [HIGH / BROKEN] Missing Staff Attribution Across Moderation & Settings
- **Evidence:**
  - `ModerationService.adjudicateListing()` (`src/modules/moderation/moderation.service.ts:101-108`) omits `staffId` in `moderationLog.create` (though it writes `actorId: moderatorId` in `auditLog`).
  - `ModerationService.adjudicateReport()` (`line 275-282`) omits `resolvedByStaffId` and hardcodes `status: 'resolved'` regardless of `dto.status` (`dismissed` / `open`).
  - `ModerationService.adjudicateVerification()` (`line 397-429`) omits `reviewedByStaffId` on `AccountVerification` and `staffId` on `ModerationLog`.
  - `PlatformSettingsService.upsertSetting()` (`src/modules/platform-settings/platform-settings.service.ts:50-63`) omits `updatedByStaffId`.
- **Impact:** Database foreign keys (`resolvedByStaffId`, `reviewedByStaffId`, `updatedByStaffId`, `ModerationLog.staffId`) remain `NULL`, breaking relational audit queries and moderation SLA reporting.

### Finding 4 — [HIGH / EXISTS_BUT_INCOMPLETE] Coarse-Grained `RolesGuard` Ignores `StaffRole.permissions`
- **Evidence (`src/modules/auth/guards/roles.guard.ts`):**
  - Only validates `user.role === requiredRoles` against the 3-value `UserRole` enum (`USER`, `MODERATOR`, `SUPER_ADMIN`).
  - Completely ignores `StaffRole.permissions` stored in PostgreSQL.
  - Because `JwtStrategy` sets `role: payload.role || 'USER'`, role changes or deactivation of a `StaffRole`'s permissions in the DB do not take effect until token expiry unless re-loaded per request (or cached in Redis with instant invalidation).

### Finding 5 — [HIGH / MISSING] Privilege Escalation & Last Super Admin Protections Absent
- **Evidence (`src/modules/staff/staff.service.ts:118-169`):**
  - `updateStaffUser()` allows deactivating or reassigning the role of **any** staff user — including the **last active Super Admin** or the caller themselves (`actorId === staffId`).
  - `createRole()` and `createStaffUser()` allow assigning arbitrary permission arrays without validating against an authoritative server-side permission catalog or checking whether the acting admin possesses those permissions.

### Finding 6 — [HIGH / MISSING] Missing Admin MFA, `HttpOnly` Cookie Transport, CSRF Defense, and Admin Password Recovery
- **Evidence:**
  - `@fastify/cookie` is not installed; all current auth endpoints return `refreshToken` in JSON bodies (appropriate for Flutter SecureStorage, **unsafe** for a React web admin panel due to XSS exposure if stored in `localStorage`).
  - No TOTP MFA (`speakeasy` / `otplib`), recovery codes, or `mfaVerified` session claim exist.
  - Password recovery (`POST /auth/password/forgot`) relies exclusively on SMS OTP to `User.phone`, leaving `StaffUser` email accounts with no recovery path.
  - `CORS_ORIGIN` (`http-security.config.ts`) already supports `credentials: true`, which is ready for `HttpOnly` cookies once explicit React admin origin(s) are whitelisted and CSRF protection (custom header / SameSite=Strict + Origin check / double-submit CSRF token) is added on admin cookie-authenticated endpoints (`/api/v1/admin/auth/refresh`, `/api/v1/admin/auth/logout`).

### Finding 7 — [MEDIUM / NEEDS_EXTENSION] `AdminJwtStrategy` Must Be Strictly Isolated From Mobile `JwtStrategy`
- Current mobile tokens use `issuer: 'deal-one.eg'`, `audience: 'deal-one-mobile'`, signed with `JWT_ACCESS_SECRET`.
- **Requirement:** Admin access tokens MUST use a distinct `audience: 'deal-one-admin'` (and optionally `JWT_ADMIN_ACCESS_SECRET` falling back only if explicitly configured, or distinct token claim `actorType: 'staff'` + strict `audience: 'deal-one-admin'`) so a mobile `User` JWT **can never** be accepted by `/api/v1/admin/*` routes, and an admin JWT **can never** be replayed as a mobile buyer/seller session.
- **Note on Existing Mobile Compatibility:** Preserve `JwtStrategy` (`deal-one-mobile`) untouched so zero existing Flutter mobile clients break! Add a dedicated `AdminJwtStrategy` (`PassportStrategy(Strategy, 'admin-jwt')`) + `AdminJwtAuthGuard` + `PermissionsGuard` for all `/api/v1/admin/*` controllers.
