# Deal One Backend — Production Deployment & Railway Configuration Checklist

**Target Platform:** Railway (`railway.json` + `Dockerfile`)  
**Production API URL:** `https://one-deal-cjjt-production.up.railway.app/api/v1`

---

## 1. Mandatory Railway Environment Variables

The application now **fails fast on startup** in `NODE_ENV=production` if required security variables are missing, weak, identical, or wildcarded. Configure these in Railway **before** deploying:

| Variable | Required in Prod | Example / Format | Notes |
|---|---|---|---|
| `NODE_ENV` | **YES** | `production` | Activates fail-fast security validation, disables Swagger by default, redacts PostGIS version in `/health/ready` |
| `PORT` | Managed by Railway | `3000` (auto-injected) | Fastify binds `0.0.0.0:${PORT}` |
| `DATABASE_URL` | **YES** | `postgresql://...` | Must point to PostGIS-enabled PostgreSQL; use `DATABASE_CONNECTION_LIMIT=10` (and `PGBOUNCER_ENABLED=true` if PgBouncer is active) |
| `REDIS_URL` (or `REDIS_CACHE_URL` + `REDIS_QUEUE_URL`) | **YES** | `redis://default:...@...` | Required for distributed rate limiting, JWT access-token denylist, webhook idempotency, and BullMQ queues |
| `JWT_ACCESS_SECRET` | **YES** | 64-char random hex (`openssl rand -hex 32`) | Must be ≥32 chars, high entropy, non-placeholder, and **different** from `JWT_REFRESH_SECRET` |
| `JWT_REFRESH_SECRET` | **YES** | 64-char random hex (`openssl rand -hex 32`) | Must be ≥32 chars, high entropy, non-placeholder, and **different** from `JWT_ACCESS_SECRET` |
| `CORS_ORIGIN` | **YES** | `https://dealone.eg,https://admin.dealone.eg` | Explicit comma-separated `https://` origins. Wildcard `*` is **rejected at startup**. Native Flutter mobile apps (no `Origin` header) are always allowed |
| `TRUST_PROXY` | **YES** | `1` (Railway edge) or `2` (Cloudflare → Railway) | **Never** set `TRUST_PROXY=true` (rejected at startup). Confirm hop count in staging by checking logged `req.ip` |
| `METRICS_AUTH_TOKEN` | **YES** | 48-char random hex (`openssl rand -hex 24`) | Required for Prometheus scraping of `/metrics` (`Authorization: Bearer <token>`). Without it, external `/metrics` requests return `401` |
| `ENABLE_SWAGGER` | Optional (`false`) | `false` | Keep `false` in production |
| `CLOUDFLARE_STREAM_WEBHOOK_SECRET` | **YES** (if video used) | Cloudflare Stream signing secret | Enforces HMAC-SHA256 + ±300s timestamp window + Redis replay idempotency |
| `VIDEO_WEBHOOK_TOLERANCE_SEC` | Optional (`300`) | `300` | Max webhook timestamp drift in seconds |
| `AUDIT_QUEUE_ENABLED` | Optional (`false`) | `true` (only when Redis Queue + worker active) | Enable only when `REDIS_QUEUE_URL` (or `REDIS_URL`) is healthy AND at least one replica runs `ENABLE_WORKERS=true` |
| `ENABLE_WORKERS` | Optional (`true`) | `true` (single replica) / `false` (API-only replicas) | If running separate API and Worker services, set `false` on API and `true` on Worker |
| `RATE_LIMIT_LOGIN_MAX` / `WINDOW_SEC` | Optional | `5` / `900` | Login brute-force ceiling |
| `RATE_LIMIT_REFRESH_MAX` / `WINDOW_SEC` | Optional | `20` / `900` | Refresh endpoint ceiling |
| `RATE_LIMIT_OTP_VERIFY_MAX` / `WINDOW_SEC` | Optional | `10` / `900` | OTP verify ceiling |

---

## 2. Database & Migration Safety Verification

Verified in `railway.json`, `Dockerfile`, and `scripts/migrate-deploy.js`:
- **Pre-deploy command:** `node scripts/migrate-deploy.js` (runs before `node dist/src/main.js`).
- **Concurrency safety:** Acquires PostgreSQL advisory lock (`MIGRATION_LOCK_ID = 84920173`) on a dedicated `connection_limit=1` session so simultaneous deploys never race.
- **Data protection:** Aborts immediately if failed migrations exist in `_prisma_migrations` or if tables exist without migration history. Never runs `prisma migrate reset` or destructive commands.
- **Credential redaction:** `sanitizeMessage()` redacts PostgreSQL credentials from all error logs.
- **Backup requirement (Owner Action):** Verify automated daily PostgreSQL backups & point-in-time recovery (PITR) are enabled in Railway PostgreSQL settings, and perform a test restore to a staging database before production cutover.

---

## 3. Railway Deployment Steps (Staging First → Production)

1. **Generate Secrets Locally (never commit):**
   ```bash
   openssl rand -hex 32  # JWT_ACCESS_SECRET
   openssl rand -hex 32  # JWT_REFRESH_SECRET
   openssl rand -hex 24  # METRICS_AUTH_TOKEN
   ```
2. **Configure Staging Railway Service:**
   - Set all mandatory variables from Section 1.
   - Confirm `CORS_ORIGIN` contains staging web/admin origins (no `*`).
   - Set `TRUST_PROXY=1` (or `2` if behind Cloudflare).
3. **Deploy to Staging & Verify:**
   - Check startup logs: confirm no config errors, `Swagger UI disabled in production environment`, and `trustProxy=1`.
   - Verify `GET /health/live` returns `200` and `GET /health/ready` returns `200` with `postgis: "up"` (no version leak).
   - Verify `GET /metrics` without token returns `401`, and with `Authorization: Bearer <METRICS_AUTH_TOKEN>` returns `200`.
   - Verify `GET /api/docs` returns `404`.
   - Verify `X-Forwarded-For: 1.2.3.4` spoofing does not change rate-limit key IP.
   - Verify `POST /auth/logout` immediately invalidates the Bearer access token on `GET /api/v1/auth/me` (`401`).
4. **Run Staging E2E & k6 Performance Tests** (see `docs/PRODUCTION_PERFORMANCE_REPORT.md`).
5. **Promote to Production:**
   - Set production Railway variables (distinct secrets from staging!).
   - Deploy and run post-deploy smoke checks above.
   - Note: rotating `JWT_ACCESS_SECRET` will sign out active access tokens (users will seamlessly refresh via refresh token unless `UserSession` is also cleared).
