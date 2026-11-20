# Deal One Enterprise Admin Dashboard — Security Review

## 1. Authentication & Session Architecture

| Control | Implementation Details |
| :--- | :--- |
| **Separate Staff Identity** | Staff credentials reside in `staff_users` hashed with **Argon2id** (`argon2.hash` / `argon2.verify`), isolated from mobile `users`. |
| **Dual-Audience JWT Isolation** | Admin access tokens are signed with `ADMIN_JWT_ACCESS_SECRET` (fallback `JWT_ACCESS_SECRET`), `issuer: 'deal-one.eg'`, `audience: 'deal-one-admin'`, 15-minute TTL. Mobile tokens (`audience: 'deal-one-mobile'`) are rejected with `403 Forbidden` in production and cannot access `/admin/*`. |
| **Zero `localStorage` Tokens** | React Admin Web stores short-lived access JWTs strictly in JavaScript closure memory (`inMemoryAccessToken` in `admin-web/src/core/api/client.ts`). |
| **HttpOnly Cookie Refresh** | 40-byte CSPRNG refresh tokens are stored in `StaffSession` as SHA-256 hashes and delivered exclusively in `HttpOnly`, `SameSite=strict` (configurable for cross-origin deploys), `path=/api/v1/admin/auth` cookies (`dealone_admin_rt`), stripped from JSON bodies. |
| **Refresh Reuse Detection** | Presenting a previously rotated/revoked cookie in `StaffSessionService.rotateRefreshToken` revokes the entire `familyId` in PostgreSQL, denylists all family `sid`s in Redis, and emits `ADMIN_REFRESH_TOKEN_REUSE_DETECTED`. |
| **Immediate Access Token Revocation** | Logout, session revocation, password change/reset, and admin suspension denylist `jti`, `sid`, and `admin:revoked:staff_before:<id>` in Redis (`isAccessTokenRevoked`). |
| **CSRF Defense** | Cookie-authenticated `POST /admin/auth/refresh` and `POST /admin/auth/logout` strictly require `X-Requested-With: dealone-admin-web` or `X-CSRF-Token` (`403 Forbidden` if missing), enforced alongside CORS origin allowlisting (`http-security.config.ts`). |

---

## 2. MFA, Lockout & Password Recovery

- **RFC 6238 TOTP MFA (`TotpService`):**
  - 20-byte CSPRNG Base32 secret encrypted at rest via **AES-256-GCM** using HKDF/SHA-256 derived key from `ADMIN_MFA_ENCRYPTION_KEY`.
  - Constant-time HMAC comparison with `+/- 1` 30-second window tolerance.
  - 8 single-use uppercase recovery codes stored solely as SHA-256 hashes (`mfaRecoveryCodesHash`) and atomically consumed upon use.
- **Brute-Force Lockout (`AdminAuthService`):**
  - Both Redis `RateLimitGuard` (10 req / 15m per IP) and persistent `StaffLoginAttempt` account lockout (5 failed logins within 15 minutes or since `lastLoginAt` trigger HTTP `429` + `ADMIN_LOGIN_LOCKED` audit event).
  - Non-existent emails execute dummy `argon2.hash(...)` work to mitigate timing side channels.
- **Email Password Recovery:**
  - Single-use 32-byte random reset tokens stored hashed (`SHA-256`) with 30-minute expiration (`StaffPasswordResetToken`).
  - Always returns HTTP `200 OK` on `/password/forgot` to prevent email enumeration; completing `/password/reset` revokes all active `StaffSession`s.

---

## 3. Sensitive Data & Privacy Controls

1. **Audited KYC Verification Documents:** Document metadata and file URLs are stripped from `GET /admin/moderation/verifications` unless caller possesses `verification.documents.read`; accessing `GET /admin/moderation/verifications/:id/document` writes an immutable `VERIFICATION_DOCUMENT_VIEWED` `AuditLog` entry with IP and user-agent.
2. **Restricted Messaging Oversight:** `GET /admin/chat/complaints` returns only complaint metadata and message counts (never message text). Inspecting messages (`GET /admin/chat/conversations/:id/messages`) requires `chat.oversight.read`, enforces an explicit administrative investigation reason (`reason`), limits batch retrieval (max 50), and writes an immutable `CONVERSATION_OVERSIGHT_ACCESSED` `AuditLog`.
3. **Immutable Audit Trail & Secret Exclusion:** All mutating admin endpoints write append-only `AuditLog` records (`actorType`, `actorId`, `action`, `targetEntity`, `targetId`, `ipAddress`, `userAgent`, `diffPayload`). No API endpoint exposes `passwordHash`, `mfaSecretEncrypted`, `mfaRecoveryCodesHash`, `DATABASE_URL`, Redis credentials, or JWT signing secrets.
4. **Privilege Escalation Prevention:** Verified in unit and E2E tests — lower-privileged admins cannot invoke higher-privileged endpoints (`403`), grant unheld permissions (`403`), or disable/demote the last `super_admin` (`403`).
5. **Listing Public Visibility Gate:** `ListingsService.getListingById` was hardened to return `404` for `deletedAt !== null`, `archived`, `hidden`, `unpublished`, or `draft` listings so moderated/hidden listings never leak to public mobile or web callers.
