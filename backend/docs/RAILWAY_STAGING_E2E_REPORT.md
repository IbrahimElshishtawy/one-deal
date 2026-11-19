# Deal One — Railway Staging E2E Verification Report (Phase Four)

**Date:** 2026-11-19  
**Railway Staging E2E Status:** **BLOCKED** (No Railway `staging` environment exists yet; running E2E against `production` is prohibited)  
**Local Docker Real PostgreSQL/PostGIS + Real Redis E2E Status:** **PASS (6/6 suites, 43/43 tests)**

> **Strict Separation Notice:** Local Docker E2E results below are reported strictly as **Local Real DB/Redis E2E Evidence** and are **NOT** claimed as live Railway Staging E2E results.

---

## 1. Local Real PostgreSQL/PostGIS + Real Redis E2E Results (Reproduced 2026-11-19)

Command executed: `npm run test:e2e` against `marketspace-postgres` (`postgis/postgis:16-3.4-alpine`), `marketspace-redis-cache` (`redis:7.2-alpine`), and `marketspace-redis-queue` (`redis:7.2-alpine`).

| Suite | Tests | Status | Key Coverage |
|---|---|---|---|
| `test/app.e2e-spec.ts` | Included | **PASS** | App bootstrap, health & base routing |
| `test/auth-database-redis.e2e-spec.ts` | Included | **PASS** | PostgreSQL uniqueness, Redis OTP/session persistence |
| `test/auth.e2e-spec.ts` | Included | **PASS** | Registration, OTP send/cooldown/verify, login, refresh rotation, reuse detection, logout |
| `test/security-integration.e2e-spec.ts` | Included | **PASS** | Media ownership enforcement (`403` on cross-user key), security headers, unauthorized access |
| `test/new-features.e2e-spec.ts` | Included | **PASS** | Notifications inbox/device-token validation, password reset + immediate re-login, admin moderation/settings validation |
| `test/staging-validation.e2e-spec.ts` | Included | **PASS** | Immediate access-token revocation on logout, Device B preservation, Redis TTL verification, `TRUST_PROXY=1` XFF anti-spoofing + `429` + `Retry-After`, `/metrics` Bearer auth (`401`/`200`), Cloudflare Stream webhook HMAC + expired timestamp (`401`) + Redis replay dedup, Flutter feed contract (`{ success, data, meta }` without duplicate `items`) |
| **TOTAL (Local Docker)** | **43 / 43** | **PASS (9.419s)** | **0 failures, 0 skipped** |

---

## 2. Live Railway Staging E2E Verification Matrix (Pending Staging Provisioning)

Once the owner provisions `https://<staging-host>.up.railway.app` with isolated `staging-postgres` and `staging-redis`:

| Domain | Required Live Railway Staging Checks | Status |
|---|---|---|
| **Health** | `GET /health/live` (`200`), `GET /health/ready` (`200`, DB + PostGIS `"up"` + Redis Cache/Queue `"up"`) | **BLOCKED (Awaiting Staging URL)** |
| **Authentication** | Dedicated staging test user registration, login, OTP flow, refresh rotation, logout, immediate access-token revocation (`401`), refresh-token reuse family termination (`401`) | **BLOCKED (Awaiting Staging URL)** |
| **Security** | Atomic Redis rate limiting (`429` + `Retry-After`), explicit CORS allow/deny, unauthorized access (`401`), `/metrics` auth (`401` unauth / `200` Bearer), Swagger disabled (`404`), media ownership (`403`), webhook signature + replay prevention | **BLOCKED (Awaiting Staging URL)** |
| **Database** | Railway PostgreSQL connectivity, PostGIS extension, `8/8` Prisma migrations, listing CRUD, Arabic + spatial search, filters, cursor pagination | **BLOCKED (Awaiting Staging URL)** |
| **Redis** | Atomic Lua rate-limit TTL, session revocation keys (`auth:revoked:sid:*`, `auth:revoked:jti:*`), BullMQ audit queue operations | **BLOCKED (Awaiting Staging URL)** |

---

## 3. Exact Execution Command Once Railway Staging Is Live

Use dedicated staging test accounts only (never production data):

```bash
export STAGING_BASE_URL="https://<staging-host>.up.railway.app"
export STAGING_METRICS_TOKEN="<staging-metrics-token>"

# 1. Live HTTP smoke & security gate
curl -sf "$STAGING_BASE_URL/health/live"
curl -sf "$STAGING_BASE_URL/health/ready"
test "$(curl -s -o /dev/null -w '%{http_code}' "$STAGING_BASE_URL/metrics")" = "401"
test "$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $STAGING_METRICS_TOKEN" "$STAGING_BASE_URL/metrics")" = "200"
test "$(curl -s -o /dev/null -w '%{http_code}' "$STAGING_BASE_URL/api/docs")" = "404"

# 2. Run E2E against isolated staging DB & Redis (via temporary staging DB/Redis connection)
DATABASE_URL="$STAGING_DATABASE_URL" \
REDIS_URL="$STAGING_REDIS_URL" \
npm run test:e2e
```

Record all actual HTTP status codes, timestamps, and pass/fail counts back into this report upon execution.
