# Deal One — Final Production Readiness Report (Phases Eight & Eleven)

**Date:** 2026-11-19  
**Branch:** `staging-validation` (`712c254`, branched from `main` @ `8d444da`)  
**Final Release Gate Status:** **`BLOCKED`** *(Local remediation & regression validation are complete — `READY FOR STAGING VALIDATION` — but live Railway Staging deployment, live `TRUST_PROXY` verification, cloud progressive k6 load testing, Railway DB backup/restore drill, and production secret rotation are BLOCKED pending project owner authorization for paid Railway resources and production variable updates.)*

---

## 1. Phase Eight — Railway Infrastructure Review (`airy-creativity`)

Read-only inspection of Railway project `airy-creativity` (`036ef563-b1f9-4d6e-b901-802946a28e0a`, environment `production` `6e684155-b2d5-4367-a785-0bbccf411428`) via `describe-environment`, `describe-service`, `get-service-metrics`, and `get-logs`:

| Component | Current Railway Configuration | Measured 24h Utilization | Findings & Bottlenecks |
|---|---|---|---|
| **Backend (`one-deal-cJjt`)** | `2 vCPU / 1 GB RAM`, 1 replica (`iad`), `RAILPACK` builder, port `8080`, domain `one-deal-cjjt-production.up.railway.app`, **only 5 env vars** (`DATABASE_URL`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `NODE_ENV`, `REDIS_URL`) | `CPU max 0.037`, `MEM max 82.6 MB` — **CURRENTLY `[CRASHED]`** (`7b624ca1`) | 1. Crashed due to `FST_ERR_CTP_ALREADY_PRESENT` on `main` (fixed on `staging-validation`).<br>2. Missing `CORS_ORIGIN`, `TRUST_PROXY`, `METRICS_AUTH_TOKEN`.<br>3. Swagger logged active before crash (verify `NODE_ENV=production`).<br>4. Single replica with `1 GB RAM` cannot sustain 5,000 VUs. |
| **Duplicate Backend (`one-deal`)** | `2 vCPU / 1 GB RAM`, 1 replica (`iad`), no domain, same `main` repo | **CURRENTLY `[CRASHED]`** (`ab0a55d2`) | Redundant service; review and remove to avoid wasted resources or stale deployments. |
| **PostgreSQL (`Postgres`)** | `postgis/postgis:16-3.4-alpine`, `2 vCPU / 1 GB RAM`, 1 replica (`iad`), `500 MB` volume (`postgres-volume`) | `CPU max 0.019`, `MEM 52–65 MB`, `DISK 165.5 MB / 500 MB` (**Online**) | 1. No HA (`postgres-ha` off).<br>2. No PITR (`Buckets: 0`).<br>3. `500 MB` disk is small for production growth.<br>4. `PGBOUNCER_ENABLED=false` + `DATABASE_CONNECTION_LIMIT=10` will bottleneck multi-replica scaling. |
| **Redis (`Redis`)** | `redis:8.2`, `2 vCPU / 1 GB RAM`, 1 replica (`iad`), `500 MB` volume (`redis-volume`), `--save 60 1` | `CPU max 0.007`, `MEM 22–36 MB`, `DISK 57.1 MB / 500 MB` (**Online**) | Shared single Redis serves both Cache and BullMQ Queue on Railway (`REDIS_URL`). Under high load, separate Cache (`allkeys-lru`) and Queue (`noeviction` + AOF) instances are recommended to prevent queue key eviction. |
| **Networking & Health** | Railway Edge TLS (`iad`), private networking (`postgres`, `redis`, `one-deal-cjjt`), `railway.json` defines `/health/live` (`120s`), `ON_FAILURE` (10 retries), `DOCKERFILE` builder | Tracing off | Live service config on `one-deal-cJjt` shows `builder: "RAILPACK"` rather than `DOCKERFILE` because `railway.json` sits at repo root while `rootDirectory: "backend"` is set. Verify Railway picks up `backend/Dockerfile` and `/health/live` healthcheck on staging. |

### Infrastructure Changes Required to Improve Maximum Stable Concurrency
(Evidence-based only — no arbitrary scaling claimed; actual limits must be measured in Phase Five progressive k6 tests):
1. **Horizontal API Replicas + Load Balancing:** Scale API beyond 1 replica when CPU > 70% or p95 > 400ms.
2. **Connection Pooling (PgBouncer):** Enable `PGBOUNCER_ENABLED=true` before running >2 API replicas to avoid PostgreSQL connection exhaustion.
3. **Separate BullMQ Worker Service:** Run `ENABLE_WORKERS=true` in a dedicated worker service and `ENABLE_WORKERS=false` on HTTP API replicas so background jobs do not compete with HTTP event loop latency.
4. **Separate Cache vs. Queue Redis:** Prevent LRU cache pressure from evicting BullMQ job state or JWT revocation keys (`auth:revoked:*`).
5. **PostgreSQL Disk & Memory Headroom:** Expand volume beyond `500 MB` and enable scheduled backups + PITR.

---

## 2. Phase Eleven — Independent Final Verification Matrix

| Control / Area | Local Evidence (Verified 2026-11-19) | Live Railway Staging Evidence | Final Status |
|---|---|---|---|
| **Critical & High Security Findings (F-01 – F-12)** | All 12 verified in source, unit tests (`222/222`), and real DB/Redis E2E (`43/43`) | Pending staging deployment | **VERIFIED LOCALLY / PENDING STAGING** |
| **`TRUST_PROXY` & Anti-Spoofing** | Verified locally (`trustProxy: 1` + real Redis E2E; `true` rejected) | **BLOCKED** — No Railway staging env to observe live `X-Forwarded-For` | **BLOCKED** |
| **CORS & HTTP Headers** | Verified (`http-security.config.spec.ts` + live local prod-mode HTTP) | Pending staging verification | **VERIFIED LOCALLY / PENDING STAGING** |
| **JWT Secrets & Production Rotation** | Fail-fast validation verified; `de78088` exposure documented; runbook ready | **REQUIRES OWNER AUTHORIZATION** — Production vars not rotated | **BLOCKED (OWNER ACTION)** |
| **Logout & Immediate Token Revocation** | Verified (`session.service.ts` ms-precision `iatMs` + `sid`/`jti` Redis denylist; `43/43` E2E) | Pending staging verification | **VERIFIED LOCALLY / PENDING STAGING** |
| **Redis (Rate Limit, TTL, Queue)** | Verified against real Docker Dual Redis (`redis.service.spec.ts` + E2E) | Production Redis online; staging Redis not provisioned | **VERIFIED LOCALLY / PENDING STAGING** |
| **PostgreSQL & PostGIS** | Verified (`postgis/postgis:16-3.4-alpine`, 8/8 migrations, 37 tables) | Production Postgres online; staging Postgres not provisioned | **VERIFIED LOCALLY / PENDING STAGING** |
| **Webhook Signature & Replay Protection** | Verified (`{ rawBody: true }` + HMAC + ±300s + Redis `SET NX EX`) | Pending staging verification | **VERIFIED LOCALLY / PENDING STAGING** |
| **`/metrics` Auth & Swagger Disable** | Verified (`401` unauth / `200` Bearer; `/api/docs` `404` in prod) | Production currently missing `METRICS_AUTH_TOKEN` & crashed | **VERIFIED LOCALLY / PENDING STAGING** |
| **Flutter Compatibility** | `flutter analyze` (`0` issues), `flutter test` (`81/81` passed), feed contract E2E passed | N/A (client compatibility verified) | **VERIFIED** |
| **Database Backups & Restore Drill** | Local isolated PostGIS restore drill passed (`1.98s` RTO, 8 migrations, 37 tables) | **BLOCKED** — Railway PITR not enabled (`0` buckets); no staging DB restore drill | **BLOCKED** |
| **Progressive k6 Load Testing (toward 5,000 VUs)** | Local baseline only: `100 VUs`, `p95=154.33ms`, `227.31 req/s`, `0%` errors | **BLOCKED** — No Railway staging env; 5,000 VUs **NOT** tested | **BLOCKED** |

---

## 3. Release Gate Decision

- **Current Status:** **`BLOCKED`** (Locally `READY FOR STAGING VALIDATION`, blocked on Railway cloud staging provisioning and owner-authorized production actions).
- **Cannot advance to `STAGING VALIDATION PASSED`, `READY FOR PRODUCTION REVIEW`, or `PRODUCTION READY`** until all 5 external Railway blockers are executed with real cloud evidence:
  1. Provision isolated Railway `staging` environment (`staging-api`, `staging-postgres`, `staging-redis`).
  2. Observe live Railway Staging headers and confirm `TRUST_PROXY=1`.
  3. Execute E2E suite against live Railway Staging URL.
  4. Execute progressive k6 load test stages against Railway Staging and record actual max stable VUs / p95 / p99.
  5. Enable Railway Postgres backups/PITR, execute isolated staging restore drill, and execute owner-authorized production secret rotation (`JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `METRICS_AUTH_TOKEN`, `CORS_ORIGIN`, `TRUST_PROXY`) alongside merging the `staging-validation` crash fix to `main`.
