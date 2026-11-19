# Deal One — Production Secret Rotation Runbook (Phase Seven)

**Date:** 2026-11-19  
**Rotation Execution Status:** **REQUIRES EXPLICIT OWNER AUTHORIZATION** (No production variables were modified automatically)  
**Historical Exposure Confirmed:** **YES** — Commit `de78088` (`2026-11-06`) introduced hardcoded default JWT secrets in `backend/src/core/config/env.config.ts`.

---

## 1. Git History Exposure Audit (Sanitized — Zero Secret Values Printed)

Inspected via `git show --stat de78088` and `src/core/config/env.config.ts`:

| Secret / Credential | Exposure Status | Current Code Protection |
|---|---|---|
| `JWT_ACCESS_SECRET` | **EXPOSED DEFAULT IN GIT (`de78088`)** | Hardcoded default removed in `8d444da` and added to `KNOWN_WEAK_SECRET_EXACT`; `validateProductionSecret()` now fails fast at boot if used in `NODE_ENV=production`. |
| `JWT_REFRESH_SECRET` | **EXPOSED DEFAULT IN GIT (`de78088`)** | Same — permanently blocked in `NODE_ENV=production` and enforced distinct from `JWT_ACCESS_SECRET`. |
| `METRICS_AUTH_TOKEN` | **NOT IN GIT HISTORY** (Not yet configured on Railway `one-deal-cJjt`) | Currently missing from Railway `production` variables (only 5 vars defined on `one-deal-cJjt`). Must be provisioned before production launch. |
| `DATABASE_URL` / `REDIS_URL` / `R2_*` / `SMS_*` / `WHATSAPP_*` / `CLOUDFLARE_STREAM_*` | **NO REAL SECRETS IN GIT** (Verified via `git grep`; `.env` gitignored) | Keep exclusively in Railway encrypted variable store. |

**Security Assumption:** Treat the historical default JWT strings as **permanently compromised** in case any prior Railway deployment booted with them. Mandatory rotation + full session invalidation is required.

---

## 2. Step-by-Step Production Secret Rotation Procedure (Owner Execution)

> **Rules:** Never commit generated secrets. Never reuse staging secrets in production. Never print secret values in logs, PRs, or chat.

### Step 1 — Generate Independent High-Entropy Production Secrets
Run locally on the owner's trusted machine (each secret is ≥256-bit / ≥192-bit CSPRNG hex, passing `validateProductionSecret()` entropy ≥3.0 and length ≥32 checks):
```bash
openssl rand -hex 32   # -> NEW_JWT_ACCESS_SECRET   (64 hex chars, 256-bit)
openssl rand -hex 32   # -> NEW_JWT_REFRESH_SECRET  (64 hex chars, 256-bit, MUST differ)
openssl rand -hex 24   # -> NEW_METRICS_AUTH_TOKEN  (48 hex chars, 192-bit)
```

### Step 2 — Secure Storage
- Store a copy in the organization's password manager / secret vault (e.g., 1Password / Bitwarden) tagged `Deal One — Railway Production — Rotated <YYYY-MM-DD>`.
- Never save secrets in `.env.example`, `.env.staging.example`, `railway.json`, or any tracked file.

### Step 3 — Controlled Deployment Ordering (Railway Production)
1. **Merge & verify `staging-validation` fixes first** (especially `src/main.ts` `{ rawBody: true }` fix so `one-deal-cJjt` boots cleanly instead of crashing with `FST_ERR_CTP_ALREADY_PRESENT`).
2. **Resolve duplicate service:** Confirm whether `one-deal` (`aea455f5-e690-4b2a-b4a9-3ac8ea041ac2`) is an unused duplicate of `one-deal-cJjt` (`054c6588-efa8-4203-b1b6-6515cc8cabc6`) and decommission or align its variables so no stale service runs with old secrets.
3. **Update Railway `production` service variables on `one-deal-cJjt` (single atomic staged change):**
   - `NODE_ENV=production`
   - `JWT_ACCESS_SECRET=<NEW_JWT_ACCESS_SECRET>`
   - `JWT_REFRESH_SECRET=<NEW_JWT_REFRESH_SECRET>`
   - `METRICS_AUTH_TOKEN=<NEW_METRICS_AUTH_TOKEN>`
   - `CORS_ORIGIN=<explicit comma-separated production origins, e.g. https://dealone.eg,https://admin.dealone.eg>`
   - `TRUST_PROXY=<verified value from Phase Three, expected 1>`
   - `ENABLE_SWAGGER=false`
   - `AUDIT_QUEUE_ENABLED=true`
4. **Apply & Redeploy** `one-deal-cJjt`.

### Step 4 — Full Session Invalidation (Mandatory If Old Defaults May Have Been Active)
Because `JWT_ACCESS_SECRET` rotation immediately invalidates all in-flight 15-minute access tokens, also revoke all pre-rotation refresh sessions in PostgreSQL during the rotation window so no compromised session can mint new tokens:
```sql
UPDATE user_sessions
SET is_revoked = true
WHERE is_revoked = false;
```
Optionally flush stale `auth:revoked:*` keys in Redis only after all instances have rolled over to the new `JWT_ACCESS_SECRET` (existing Redis denylist keys expire naturally within 15 minutes).

### Step 5 — Post-Rotation Verification
1. **Startup health:** Confirm Railway deploy logs show `Swagger UI disabled in production environment`, `trustProxy=1`, and `GET /health/live` + `GET /health/ready` return `200`.
2. **Old access token rejected:** Call `GET /api/v1/auth/me` with a pre-rotation Bearer token → expect `401 Unauthorized`.
3. **Old refresh token rejected:** Call `POST /api/v1/auth/refresh` with a pre-rotation refresh token → expect `401 Unauthorized`.
4. **Metrics auth enforced:**
   - `GET /metrics` without header → `401`
   - `GET /metrics` with old token (if any) → `401`
   - `GET /metrics` with `Authorization: Bearer <NEW_METRICS_AUTH_TOKEN>` → `200`
5. **Fresh auth lifecycle:** Verify new login → `GET /api/v1/auth/me` (`200`) → `POST /api/v1/auth/refresh` (`200`) → `POST /api/v1/auth/logout` (`200`) → revoked access token immediately returns `401`.

### Step 6 — Rollback Strategy
- **Code rollback:** If a code regression occurs after deploy, roll back the Git deployment **while keeping the newly rotated secrets** in Railway.
- **Never roll back to the old/default JWT secrets:** `validateProductionSecret()` will intentionally refuse to start the application with any known weak/default secret.
- If a secret itself was mis-entered (e.g., typo or length < 32), generate a brand-new secret via `openssl rand -hex 32` and redeploy — never revert to a previously exposed string.

### Step 7 — Git History Cleanup Assessment
- **Is `git filter-repo` / BFG history rewrite required?** **OPTIONAL / NOT URGENT IF REPO IS PRIVATE**, because:
  1. Only placeholder/default strings (not real production keys) were committed in `de78088`.
  2. Those exact strings are now permanently blocklisted in `KNOWN_WEAK_SECRET_EXACT` and rejected at production startup.
  3. Rewriting Git history force-pushes all branches and invalidates existing PRs/SHAs.
- **When history cleanup IS recommended:** Only if the repository is made public or an audit finds any real third-party API key ever committed (none were found in our scan).
