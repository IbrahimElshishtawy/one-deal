# Deal One — Railway Production Migration Deployment Report

**Status:** `PASS WITH WARNINGS`  
**Date:** 2026-11-14  
**Repository:** `market_space`  
**Scope:** Backend deployment pipeline (`Dockerfile`, `backend/Dockerfile`, `railway.json`, `backend/package.json`, `backend/scripts/migrate-deploy.js`, unit tests)

> [!WARNING]
> **Why `PASS WITH WARNINGS` (and not `PASS`):**
> All code changes, unit tests, production Docker image builds, and end-to-end migration/health/worker verifications succeeded against an isolated local PostgreSQL 16 + PostGIS 3.4.3 + Redis 7.2 container stack. However, **`railway` CLI is not installed and Railway production credentials / `DATABASE_URL` are not present in this local environment**, so live Railway production database inspection and live Railway deployment remain to be executed by the operator against the target Railway service (`one-deal`).

---

## 1. Phase 1 Audit Findings

1. **Migrations already exist in version control:**  
   `backend/prisma/migrations/` contains all **6** PostgreSQL migrations (including `20261102232252_init_database_foundation/migration.sql`, which runs `CREATE EXTENSION IF NOT EXISTS postgis;` and creates `public.listings` plus all indexes and foreign keys).
2. **Why `public.listings` was missing on Railway:**  
   - `railway.json` configured `"startCommand": "node dist/src/main.js"` with no `preDeployCommand`.
   - `Dockerfile` and `backend/Dockerfile` ended with `CMD ["node", "dist/src/main.js"]`.
   - `runner` stage installed only production dependencies (`npm ci --only=production`), excluding the `prisma` CLI (`devDependencies`), so even overriding the start command with `npx prisma migrate deploy` would have attempted a runtime download from npm.
3. **Why `PaymentReconciliationProcessor` did not report the missing table error:**  
   In `backend/src/workers/payment-reconciliation.processor.ts` (lines 25–36), `processStaleTransactions()` guards its query with `if ((this.prisma as any).payment?.updateMany)`. Because `backend/prisma/schema.prisma` does not define a `Payment` model, the branch never executes a SQL query and always logs `0` reconciled rows.

---

## 2. Files Changed

| File | Change |
|---|---|
| `backend/scripts/migrate-deploy.js` *(new)* | Production-safe migration runner with credential redaction, `DATABASE_URL` validation, PostgreSQL & PostGIS preflight checks, session advisory lock (`84920173`), `_prisma_migrations` integrity check, local `prisma migrate deploy` execution (no `npx`), and post-migration verification of `public.listings` and PostGIS. |
| `backend/src/core/database/migrate-deploy.spec.ts` *(new)* | Jest unit tests covering credential redaction, URL validation / `connection_limit=1`, discovery of all 6 migrations, and local Prisma CLI resolution. |
| `railway.json` | Added `"preDeployCommand": ["node scripts/migrate-deploy.js"]` under `deploy` while retaining `"startCommand": "node dist/src/main.js"` and `/health/live`. |
| `Dockerfile` | Consolidated `npm ci` to a single `builder` download, preserved generated `.prisma`, `@prisma/client`, `prisma` CLI, and `@prisma/engines*` before `npm prune --omit=dev`, copied `backend/scripts`, created `node_modules/.bin/prisma` symlink, and set fallback `CMD ["sh", "-c", "node scripts/migrate-deploy.js && exec node dist/src/main.js"]`. |
| `backend/Dockerfile` | Synchronized with root `Dockerfile` for standalone backend / `docker-compose.yml` builds. |
| `backend/package.json` | Added `"prisma:migrate:deploy": "node scripts/migrate-deploy.js"` script. |

**Unchanged per strict rules:**
- Zero Flutter files modified (`deal one app/` untouched).
- Zero existing migration SQL files modified or deleted.
- Zero backend business logic or `schema.prisma` models modified.

---

## 3. Migration Execution Strategy & Image Efficiency

1. **Primary Railway path (`railway.json`):**  
   Railway executes `preDeployCommand` (`node scripts/migrate-deploy.js`) once inside an isolated pre-deploy container before starting or routing traffic to application containers. If any safety check or migration fails, the deployment aborts automatically before replacing the running service. Application containers then boot directly via `startCommand` (`node dist/src/main.js`).
2. **Fallback container entrypoint (`Dockerfile` / `backend/Dockerfile`):**  
   If deployed via `docker-compose.yml` or any orchestrator without Railway's `preDeployCommand`, `CMD` runs `node scripts/migrate-deploy.js && exec node dist/src/main.js`.
3. **Concurrency protection across multiple instances:**  
   `migrate-deploy.js` enforces `connection_limit=1` on its preflight `PrismaClient` connection and acquires PostgreSQL session advisory lock `84920173` (`pg_try_advisory_lock` / `pg_advisory_lock`) before inspecting `_prisma_migrations` and running `prisma migrate deploy` (which also uses Prisma's internal lock), releasing the lock in `finally`.
4. **Offline Prisma CLI & Docker image efficiency:**  
   Instead of keeping all `devDependencies` in production or calling `npx`, `builder` runs `npm ci` once, runs `npx prisma generate` and `npm run build`, preserves `.prisma`, `@prisma/client`, `prisma`, and `@prisma/engines*`, and runs `npm prune --omit=dev`.  
   - Measured root production image size (`dealone-railway-verify:root`): **534 MB** disk usage (**126 MB** compressed content size), smaller than the prior 573 MB / 144 MB image.
   - Verified offline inside the container (`docker run --rm --network=none`): `./node_modules/.bin/prisma --version` reports `prisma: 5.22.0`, `@prisma/client: 5.22.0`, `linux-musl-openssl-3.0.x`, and `PrismaClient` exposes `listing.updateMany`.

---

## 4. Database Safety Checks Implemented

Before invoking `prisma migrate deploy`, `backend/scripts/migrate-deploy.js` enforces:
1. **`DATABASE_URL` validation:** Aborts if missing, empty, invalid URL, or non-PostgreSQL protocol. Error output redacts credentials (`postgres(ql)://***:***@`).
2. **Connectivity & version check:** Runs `SELECT 1` and logs `SELECT version()`.
3. **PostGIS availability check:** Queries `pg_available_extensions WHERE name = 'postgis'`; aborts safely if PostGIS is unavailable on the PostgreSQL server.
4. **Migration history & partial migration detection:**
   - If `public._prisma_migrations` exists, inspects all rows and aborts immediately if any migration has `finished_at IS NULL AND rolled_back_at IS NULL`.
   - If `public._prisma_migrations` does not exist, checks `pg_tables` in `public` (excluding `spatial_ref_sys`) and aborts if user tables already exist without Prisma migration tracking (preventing blind schema clashes).
5. **No destructive commands:** Never executes `prisma migrate dev`, `prisma db push`, or database resets.

---

## 5. Build & Verification Results

### A. Automated Tests & TypeScript Build
* `cd backend && npm test`: **25 test suites passed, 142 tests passed** (including `src/core/database/migrate-deploy.spec.ts`).
* `docker build` (both root `Dockerfile` and `backend/Dockerfile`): **Succeeded** (with `--network=host` in local sandbox to avoid local Docker bridge timeout to npm/Prisma CDN).

### B. Isolated Production Container + PostGIS + Redis Verification
Tested against ephemeral `postgis/postgis:16-3.4-alpine` and `redis:7.2-alpine` containers:

| Check | Result | Observed Evidence |
|---|---|---|
| Missing `DATABASE_URL` guard | **PASS** | Exited with code `1`: `DATABASE_URL environment variable is missing or empty. Aborting migration.` |
| Fresh DB migration (`railway_fresh`) | **PASS** | Applied all **6** migrations cleanly; verified `public.listings` exists and `PostGIS_Version()` = `3.4 USE_GEOS=1 USE_PROJ=1 USE_STATS=1`. |
| Concurrent migration execution | **PASS** | Parallel executions logged `Another migration process holds the lock; waiting...`, serialized cleanly, and both exited `0`. |
| Partial migration guard | **PASS** | Simulated `finished_at = NULL` row in `_prisma_migrations`; aborted with exit code `1` before calling `prisma migrate deploy`. |
| `/health/live` | **PASS** | `HTTP 200` — `{"success":true,"data":{"status":"ok",...}}` |
| `/health/ready` | **PASS** | `HTTP 200` — `database: "up"`, `postgis: "up (3.4 USE_GEOS=1 USE_PROJ=1 USE_STATS=1)"`, `redis_cache: "up"`, `redis_queue: "up"`, `workers: "active"`. |
| `ListingExpiryProcessor` | **PASS** | Executed `processExpiredListings()` inside running container against migrated `public.listings` -> `{"expiredCount":0}`. |

### C. Payment Reconciliation Worker Assessment
* `PaymentReconciliationProcessor.processStaleTransactions()` (`backend/src/workers/payment-reconciliation.processor.ts`) executed without error and returned `{"reconciledCount":0}`.
* **Limitation documented (no code modified):** Because `schema.prisma` has no `Payment` model, `if ((this.prisma as any).payment?.updateMany)` is currently a no-op and does not persist or reconcile real payment records in PostgreSQL.

### D. Live Railway Environment Status
* **Not executed in this session:** `railway` CLI is unavailable and live Railway production `DATABASE_URL` / service access is not configured in this workspace.

---

## 6. Exact Railway Configuration Requirements & Remaining Risks

Before deploying to the live Railway service (`one-deal`):
1. **Verify `DATABASE_URL`:** Ensure `one-deal`'s `DATABASE_URL` variable points to the intended Railway PostgreSQL service (containing PostGIS).
2. **Verify PostGIS support on Railway PostgreSQL:** The Railway PostgreSQL image/instance must provide the `postgis` extension (`pg_available_extensions` must include `postgis`), otherwise the first migration (`CREATE EXTENSION IF NOT EXISTS postgis;`) and `/health/ready` will fail.
3. **Do not override `preDeployCommand` or `startCommand` negatively in Railway UI:** Ensure Railway service settings honor `railway.json` (`preDeployCommand: ["node scripts/migrate-deploy.js"]`, `startCommand: "node dist/src/main.js"`). Also ensure Railway Root Directory is set to repository root `/` (matching `dockerfilePath: "Dockerfile"`).
4. **Required Environment Variables on Railway:**
   - `NODE_ENV` (`production` for production with SMS Misr credentials, or `development` for temporary staging per `RAILWAY_STAGING_FINAL_CONFIGURATION.md` — never `staging`)
   - `DATABASE_URL`
   - `REDIS_URL` (or explicit cache/queue Redis host/port/password variables)
   - `JWT_ACCESS_SECRET` (min 16 chars)
   - `JWT_REFRESH_SECRET` (min 16 chars)
5. **Remaining Risk — Non-empty Production Database Without `_prisma_migrations`:**  
   If the target Railway Postgres instance already contains manually created tables without `_prisma_migrations`, `migrate-deploy.js` will intentionally abort to protect existing data; in that case, inspect the database tables and baseline via `prisma migrate resolve --applied ...` rather than resetting.
6. **Post-Deploy Live Verification Checklist:**  
   After pushing and deploying to Railway, confirm in Railway deployment logs:
   - `[migrate-deploy] All 6 migration(s) verified successfully.`
   - `GET https://<railway-domain>/health/ready` returns `HTTP 200` with `database: "up"` and `postgis: "up (...)"`.
   - `ListingExpiryProcessor` runs on schedule without `The table public.listings does not exist`.
