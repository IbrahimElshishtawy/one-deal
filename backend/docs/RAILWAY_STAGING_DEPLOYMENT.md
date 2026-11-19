# Deal One — Railway Staging Environment & Deployment Plan (Phase Two)

**Date:** 2026-11-19  
**Railway Account Verified (Read-Only):** `Ibrahim Elshishtawy` (`@ibrahimelshishtawy`, workspace `6648bbed-774f-450e-9dff-8a1faec02ba3`)  
**Existing Railway Project:** `airy-creativity` (`036ef563-b1f9-4d6e-b901-802946a28e0a`)  
**Staging Deployment Status:** **BLOCKED — Requires Project Owner Authorization to Provision Paid Railway Staging Environment & Services**

---

## 1. Read-Only Railway Project Inspection Findings

Inspecting `airy-creativity` via Railway MCP (`list-services`, `describe-environment`, `describe-service`, `environment-status`, `get-logs`) revealed:

1. **No Staging Environment Exists:** Only a single environment — `production` (`6e684155-b2d5-4367-a785-0bbccf411428`) — exists in `airy-creativity`. Furthermore, Railway MCP does not expose a `create-environment` tool, and creating a separate staging project or new Railway services creates billable cloud resources, which is prohibited without explicit owner authorization.
2. **Existing Production Services (Do NOT Modify or Test Against):**
   - `one-deal-cJjt` (`054c6588-efa8-4203-b1b6-6515cc8cabc6`): `IbrahimElshishtawy/one-deal@main` (rootDirectory: `backend`), domain `https://one-deal-cjjt-production.up.railway.app` (port `8080`), **currently `[CRASHED]`** (deployment `7b624ca1-7081-4c38-95dd-501d7f936cf7`, 2026-11-18T22:55:50Z).
   - `one-deal` (`aea455f5-e690-4b2a-b4a9-3ac8ea041ac2`): Duplicate service on `IbrahimElshishtawy/one-deal@main`, no domain, **currently `[CRASHED]`**.
   - `Postgres` (`a6a0fc2b-4ae2-4391-abf8-073e91a98886`): `postgis/postgis:16-3.4-alpine`, 500 MB volume `postgres-volume`, **Online**.
   - `Redis` (`f5875c17-167d-44cf-801b-c8cc76c211f3`): `redis:8.2`, 500 MB volume `redis-volume`, **Online**.
3. **Root Cause of Current Production Crash (Observed in Railway Deploy Logs):**
   - Deployment `7b624ca1` booted commit `main` (`8d444da`), which lacked the `staging-validation` fix in `src/main.ts` (`{ rawBody: true }`), throwing `FastifyError [Error]: Content type parser 'application/json' already present`.
   - Additionally, `one-deal-cJjt` only has 5 variables defined (`DATABASE_URL`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `NODE_ENV`, `REDIS_URL`) and logged `OpenAPI Documentation available at http://0.0.0.0:8080/api/docs` before crashing — indicating `CORS_ORIGIN`, `TRUST_PROXY`, and `METRICS_AUTH_TOKEN` are not yet configured and `NODE_ENV` is not enforcing strict production mode on Railway.

---

## 2. Required Staging Service Topology (Isolated from Production)

Create a dedicated `staging` environment inside `airy-creativity` (or a dedicated staging Railway project) containing:

1. **PostgreSQL + PostGIS (`staging-postgres`)**
   - Image: `postgis/postgis:16-3.4-alpine`
   - Mount: `/var/lib/postgresql/data` (≥2 GB volume recommended for staging + load test dataset)
   - Private networking only (no public TCP proxy except temporarily during controlled E2E/backup verification)
2. **Redis (`staging-redis`)**
   - Image: `redis:8.2` (or `redis:7.2-alpine`)
   - Mount: `/data`
   - Persistence enabled (`--save 60 1 --appendonly yes`)
   - Private networking only
3. **Deal One Backend (`staging-api`)**
   - Repo: `IbrahimElshishtawy/one-deal`
   - Branch: `staging-validation` (after review)
   - Root Directory: `backend`
   - Builder: `DOCKERFILE` (`backend/Dockerfile`, matching `../railway.json`)
   - Pre-deploy command: `node scripts/migrate-deploy.js`
   - Start command: `node dist/src/main.js`
   - Healthcheck path: `/health/live` (timeout `120s`)
   - Restart policy: `ON_FAILURE` (max retries `10`)

---

## 3. Mandatory Staging Environment Variables Matrix

Reference: `.env.staging.example` validated against `src/core/config/env.config.ts`. **Never copy production secrets to staging.**

| Variable | Staging Value / Generation Rule | Required in `NODE_ENV=production` | Validated in Code |
|---|---|---|---|
| `NODE_ENV` | `production` | Yes | Enforces strict fail-fast validation & disables Swagger |
| `PORT` | Provided by Railway (e.g. `8080`) | Yes | Binds `0.0.0.0:${PORT}` |
| `DATABASE_URL` | `${{staging-postgres.DATABASE_URL}}` | Yes | Required; Prisma + PostGIS |
| `DATABASE_CONNECTION_LIMIT` | `10` (or tune with PgBouncer) | Optional | Default `10` |
| `REDIS_URL` | `${{staging-redis.REDIS_URL}}` | Yes | Used by both Cache & Queue clients if split URLs unset |
| `JWT_ACCESS_SECRET` | `openssl rand -hex 32` (staging-only) | Yes | ≥32 chars, ≥10 unique chars, entropy ≥3.0, non-placeholder |
| `JWT_REFRESH_SECRET` | `openssl rand -hex 32` (staging-only, distinct) | Yes | Must differ from `JWT_ACCESS_SECRET` |
| `CORS_ORIGIN` | Explicit staging origin(s), e.g. `https://staging.dealone.eg,https://staging-admin.dealone.eg` | Yes | Wildcard `*` rejected at startup |
| `TRUST_PROXY` | `1` (verify in Phase Three against live Railway headers) | Yes | Blanket `true` rejected at startup |
| `METRICS_AUTH_TOKEN` | `openssl rand -hex 24` (staging-only) | Yes | Protects `GET /metrics` via constant-time Bearer/`X-Metrics-Token` |
| `ENABLE_SWAGGER` | `false` | Optional | Must remain `false`; `/api/docs` returns `404` |
| `ENABLE_WORKERS` | `true` | Optional | Enables BullMQ workers |
| `AUDIT_QUEUE_ENABLED` | `true` | Optional | Enables async audit retry queue |
| `CLOUDFLARE_STREAM_WEBHOOK_SECRET` | `openssl rand -hex 24` (staging test secret) | If video used | HMAC-SHA256 + ±300s timestamp + Redis dedup |
| `R2_*` (`R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET_NAME`, `R2_PUBLIC_DOMAIN`) | Staging R2 bucket credentials (never prod bucket) | If media upload used | Fails safely if omitted |
| `SMS_*` / `WHATSAPP_*` | Staging sandbox credentials only | If live OTP tested | Never point staging at production messaging quotas |

---

## 4. Exact Manual Owner Steps to Provision Railway Staging

1. **Create Environment:** In Railway Dashboard → Project `airy-creativity` → Environment dropdown → **New Environment** → name it `staging` (create empty environment — do **not** clone production data or secrets).
2. **Add Isolated Databases:**
   - Add Service → Docker Image → `postgis/postgis:16-3.4-alpine` (`staging-postgres`) + attach volume at `/var/lib/postgresql/data`.
   - Add Service → Docker Image → `redis:8.2` (`staging-redis`) + attach volume at `/data`.
3. **Add Backend Service (`staging-api`):**
   - Add Service → GitHub Repo `IbrahimElshishtawy/one-deal`, branch `staging-validation`, Root Directory `backend`.
   - Set Builder to Dockerfile (`Dockerfile`), Pre-deploy command `node scripts/migrate-deploy.js`, Start command `node dist/src/main.js`, Healthcheck `/health/live`.
4. **Generate & Configure Independent Staging Secrets (Locally, Never Commit):**
   ```bash
   openssl rand -hex 32  # JWT_ACCESS_SECRET (staging)
   openssl rand -hex 32  # JWT_REFRESH_SECRET (staging)
   openssl rand -hex 24  # METRICS_AUTH_TOKEN (staging)
   openssl rand -hex 24  # CLOUDFLARE_STREAM_WEBHOOK_SECRET (staging)
   ```
   Paste them into `staging-api` Variables along with `NODE_ENV=production`, `CORS_ORIGIN`, `TRUST_PROXY=1`, `ENABLE_SWAGGER=false`, `AUDIT_QUEUE_ENABLED=true`, `DATABASE_URL=${{staging-postgres.DATABASE_URL}}`, and `REDIS_URL=${{staging-redis.REDIS_URL}}`.
5. **Generate Staging Domain & Verify:**
   - Networking → Generate Domain (`https://<staging-host>.up.railway.app`).
   - Verify startup logs show `No pending migrations to apply` / `8 migrations applied`, `Swagger UI disabled in production environment`, and `trustProxy=1`.
   - Run smoke checks:
     ```bash
     curl -i https://<staging-host>/health/live
     curl -i https://<staging-host>/health/ready
     curl -i https://<staging-host>/metrics               # expect 401
     curl -i -H "Authorization: Bearer $STAGING_METRICS_TOKEN" https://<staging-host>/metrics  # expect 200
     curl -i https://<staging-host>/api/docs              # expect 404
     ```
6. **Verify Graceful Shutdown:** Trigger a redeploy and confirm logs show NestJS shutdown hooks closing Fastify, Prisma, and Dual Redis cleanly without `SIGKILL` timeout.

---

## 5. Local vs. Railway Verification Summary

- **Verified Locally (`NODE_ENV=production` on Docker PostGIS 16.4/3.4.3 + Dual Redis):** Startup validation, migrations (`8/8`), PostGIS readiness (`postgis: "up"`), Redis cache/queue health, `/health/live`, `/health/ready`, `/metrics` auth (`401`/`200`), Swagger disabled (`404`), CORS enforcement, graceful shutdown.
- **Blocked on Railway Cloud:** Provisioning `staging` environment, deploying `staging-api`, and executing live cloud health/shutdown verification require owner authorization for paid Railway resources.
