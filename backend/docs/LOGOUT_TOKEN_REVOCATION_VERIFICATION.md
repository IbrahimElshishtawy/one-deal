# Deal One Backend — Logout & Access Token Revocation Verification

**Verification Date:** 2026-11-19  
**Revocation Strategy Implemented:** **Immediate Access-Token Revocation via Redis Denylist** (TTL-bounded to access-token expiration, zero extra DB queries on authenticated requests) + PostgreSQL `UserSession` refresh-token revocation.

---

## 1. Architecture Verified

- **Minted Access Tokens (`src/modules/auth/services/session.service.ts:90-108`):** Include `sub`, `phone`, `role`, `sid` (session UUID), `jti` (token UUID), and `iatMs` (millisecond issuance timestamp).
- **On `POST /api/v1/auth/logout`:**
  - Revokes `UserSession` in PostgreSQL (`isRevoked = true`).
  - Denylists `auth:revoked:sid:<sessionId>` in Redis with TTL = 900s (15m).
  - If `Authorization: Bearer <token>` is present, also denylists `auth:revoked:jti:<jti>` and `auth:revoked:sid:<sid>` for its remaining lifetime (`exp - now`).
- **On `POST /api/v1/auth/sessions/terminate-all` & `POST /api/v1/auth/password/reset`:**
  - Denylists every active `sid` in Redis AND sets `auth:revoked:user_before:<userId>` to `Date.now()` (millisecond precision).
- **On `POST /api/v1/auth/password/change`:**
  - Denylists all *other* active session IDs while preserving the current device's session.
- **Critical Bug Caught & Fixed During Real E2E Testing:**
  - Initial second-precision `iat <= revokedBefore` caused a false-positive `401` when `resetPassword` was immediately followed by `login` within the same Unix second (`test/new-features.e2e-spec.ts:223-291`).
  - Fixed by denylisting all active `sid`s directly and upgrading `user_before` cutoff to millisecond precision (`iatMs <= revokedBeforeMs`). Re-verified: `new-features.e2e-spec.ts` and `staging-validation.e2e-spec.ts` now pass 100%.

---

## 2. Real PostgreSQL + Real Redis E2E Test Evidence

Executed in `test/staging-validation.e2e-spec.ts` and `src/modules/auth/strategies/jwt.strategy.spec.ts`:

| Step | Action | Expected | Observed | Status |
|---|---|---|---|---|
| 1 | Authenticate Device A & Device B via OTP | `200` + distinct token pairs | `200` | **PASS** |
| 2 | `GET /api/v1/auth/me` with Device A access token | `200` | `200` | **PASS** |
| 3 | `POST /api/v1/auth/logout` (Device A refresh + Bearer) | `200` | `200` | **PASS** |
| 4 | Inspect Redis TTL for `auth:revoked:sid:<deviceA.sid>` | `0 < TTL <= 900` | Positive TTL `<= 900` | **PASS** |
| 5 | Reuse Device A original access token on `GET /api/v1/auth/me` | `401 Unauthorized` | `401` | **PASS** |
| 6 | Reuse Device A refresh token on `POST /api/v1/auth/refresh` | `401` (reuse detected) | `401` | **PASS** |
| 7 | Duplicate `POST /api/v1/auth/logout` with same refresh token | `200` (idempotent) | `200` | **PASS** |
| 8 | `GET /api/v1/auth/me` with Device B access token | `200` (multi-device preserved) | `200` | **PASS** |

---

## 3. Redis Unavailability Behavior

- If Redis Cache is temporarily unreachable during logout, `UserSession.isRevoked = true` is still durably persisted in PostgreSQL (refresh tokens are immediately unusable), while `RedisService.set()` degrades cleanly without crashing logout. Access tokens remain valid up to their 15-minute `exp` window only during a Redis Cache outage.
