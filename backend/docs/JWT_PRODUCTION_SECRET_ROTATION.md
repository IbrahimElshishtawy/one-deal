# Deal One Backend — JWT Production Secret Rotation Plan

**Date:** 2026-11-19  
**Git History Exposure Status:** **CONFIRMED COMPROMISED DEFAULTS IN GIT HISTORY**

---

## 1. Git History Exposure Findings

`git log -S "dealone_default_access_secret" --oneline` confirmed:
- Commit `de78088` (`fix(config): provide fail-safe defaults for DATABASE_URL and JWT secrets to prevent deployment crash loops`) introduced hardcoded default JWT access and refresh secrets into `src/core/config/env.config.ts`.
- Commit `8d444da` removed those defaults from production execution and added them to `KNOWN_WEAK_SECRET_EXACT` so `validateEnv()` now **rejects them at startup** in `NODE_ENV=production`.
- **Risk Assessment:** Any historical production deployment that booted without explicit `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` environment variables (or failed env parsing) could have minted tokens with publicly committed secrets. Those default strings must be treated as permanently compromised.
- **Git History Cleanup:** Because the defaults are now permanently rejected by `validateProductionSecret()` in production and real production secrets were never committed to Git, rewriting Git history is **optional** (only needed if the repository was public and any real secrets were ever committed — none were found). Generating brand-new independent production secrets is **mandatory**.

---

## 2. Production Secret Rotation Procedure (Owner Execution)

> Do NOT reuse staging secrets in production. Never print or commit generated secrets.

1. **Generate New Independent High-Entropy Secrets (≥64 hex chars / 256-bit entropy):**
   ```bash
   openssl rand -hex 32   # -> JWT_ACCESS_SECRET (Production)
   openssl rand -hex 32   # -> JWT_REFRESH_SECRET (Production — MUST differ)
   openssl rand -hex 24   # -> METRICS_AUTH_TOKEN (Production)
   ```
2. **Coordinate Rotation Window:**
   - Rotating `JWT_ACCESS_SECRET` immediately invalidates all in-flight 15-minute access tokens signed with the old secret.
   - Flutter clients holding valid refresh tokens will automatically refresh seamlessly via `POST /api/v1/auth/refresh`.
3. **Full Session Invalidation (Recommended if old default secrets may have been active):**
   - If there is any possibility that previous production deployments ran with the exposed default secrets, revoke all existing sessions in PostgreSQL during the maintenance window:
     ```sql
     UPDATE user_sessions SET is_revoked = true WHERE is_revoked = false;
     ```
   - This forces all users to re-authenticate cleanly under the new secrets.
4. **Update Railway Production Variables:**
   - Set `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `CORS_ORIGIN`, `TRUST_PROXY=1`, and `METRICS_AUTH_TOKEN` in Railway `production` environment for service `one-deal-cJjt` (and any worker service).
5. **Deploy & Verify:**
   - Confirm startup succeeds (`validateEnv` passes).
   - Confirm an old pre-rotation access token receives `401 Unauthorized` on `GET /api/v1/auth/me`.
   - Confirm fresh OTP/password login → `GET /api/v1/auth/me` (`200`) → `POST /api/v1/auth/refresh` (`200`) → `POST /api/v1/auth/logout` → old access token (`401`).
6. **Rollback Consideration:**
   - If a deployment rollback is required, keep the newly rotated secrets in Railway (never roll back to known weak/default secrets; the new startup validator will refuse to boot with them).
