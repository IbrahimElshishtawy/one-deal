# Deal One — Railway Progressive k6 Load Test Report (Phase Five)

**Date:** 2026-11-19  
**Railway Staging Cloud Load Test Status:** **BLOCKED** (No Railway `staging` environment exists; load testing against `production` is strictly prohibited; creating paid cloud load generators requires owner authorization)  
**Maximum Verified Stable Concurrency (Local Docker Only):** **100 VUs** (`p95 = 154.33 ms`, `227.31 req/s`, `0.00%` errors)  
**5,000 Concurrent VUs Status:** **NOT TESTED / NOT CLAIMED**

---

## 1. Audit of Existing k6 Scripts

| Script | Path | Modeled Traffic | Findings & Limitations |
|---|---|---|---|
| **5,000-VU Script** | `load-tests/k6-5000-online.js` | `ramping-vus`: `50 → 1,000 (2m) → 3,000 (3m) → 5,000 (5m) → 0 (2m)` with `sleep(1)`. Public read mix: 45% `/listings?limit=20`, 15% `/categories`, 25% `/search?q=<arabic>&lat=...&radiusKm=25`, 10% `/locations/governorates`, 5% `/health/ready`. | 1. **Not progressive-gated:** Jumps straight to 1,000 → 3,000 → 5,000 VUs without stop-condition pauses between stages.<br>2. **No authenticated user journey:** Comment mentions "5% OTP request flow", but code actually hits `/health/ready` (no login, no token reuse, no authenticated writes).<br>3. **Not yet executed at 5,000 VUs:** Filename does NOT constitute capacity proof. |
| **Staging Validation Script** | `load-tests/k6-staging-validation.js` | `ramping-vus`: `5 → 25 (10s) → 75 (20s) → 100 (10s) → 0 (5s)` with `sleep(0.2)`. Same read-only public mix + `/health/ready`. | Valid for baseline smoke/ramp validation up to 100 VUs; does not exercise authenticated token-reusing journeys or multi-stage progression beyond 100 VUs. |

### Key Script Recommendations Before Cloud Load Testing
- **Avoid repeated login per iteration:** Rate limits (`RATE_LIMIT_LOGIN_MAX=5` per 15 min per IP) will legitimately return `429` if VUs log in repeatedly from a single load-generator IP. Pre-provision a pool of staging test tokens in `setup()` and reuse them across VU iterations.
- **Seed realistic staging dataset:** Populate staging DB with representative listings (e.g., ≥10,000 listings across governorates/categories) so PostGIS spatial queries and trigram search reflect real index selectivity.
- **Use isolated staging test data:** Never mix load-test accounts or listings with production.

---

## 2. Terminology Distinction (Strict Engineering Definitions)

- **VUs Configured:** Target virtual user count declared in a k6 script (e.g., `5000` in `k6-5000-online.js`). **Proves nothing by itself.**
- **VUs Reached:** Peak concurrent k6 goroutines actually spawned during a run.
- **VUs Sustained:** Concurrent VUs held steady over a plateau window while meeting latency/error SLOs.
- **Active Simulated Users:** VUs performing realistic think-time journeys (typically `1` VU with `sleep(1)` ≈ `~1 req/s` minus response time; real mobile users with 10–30s think time generate far fewer RPS per online user).
- **Requests per Second (RPS):** Actual completed HTTP requests/sec measured at the server.

---

## 3. Previously Measured Local Baseline (Clearly Separated — NOT Railway)

Source: `docs/PRODUCTION_PERFORMANCE_VALIDATION.md` (executed against local Docker `NODE_ENV=production` on `http://127.0.0.1:3099/api/v1`):

| Stage (Local Docker) | VUs Reached | Duration | Total Reqs | RPS | Error Rate | HTTP 429 / 5xx | p50 | p90 | p95 | p99 / Max |
|---|---|---|---|---|---|---|---|---|---|---|
| Local Baseline (`k6-staging-validation.js`) | `100` | `45.2s` | `10,269` | `227.31` | `0.00%` | `0` / `0` | `3.20 ms` | `27.51 ms` | `154.33 ms` | `max 378.52 ms` |

---

## 4. Progressive Railway Staging Load Test Plan (Blocked Until Staging Is Provisioned)

Do **not** launch 5,000 VUs immediately. Execute stages sequentially against `https://<staging-host>.up.railway.app/api/v1`, monitoring Railway metrics (`CPU_USAGE`, `MEMORY_USAGE_GB`, Postgres connections, Redis latency, HTTP 429/5xx) after each stage:

| Stage | Target VUs | Ramp-Up | Sustained | Ramp-Down | Gate to Proceed | Status |
|---|---|---|---|---|---|---|
| **Stage 1** | `100 VUs` | `30s` | `2m` | `30s` | `p95 < 400ms`, `errors < 1%`, `5xx = 0`, CPU < 80% | **BLOCKED** |
| **Stage 2** | `250 VUs` | `30s` | `2m` | `30s` | Same SLO + DB pool < 80% | **BLOCKED** |
| **Stage 3** | `500 VUs` | `1m` | `3m` | `30s` | Same SLO + Redis latency < 20ms | **BLOCKED** |
| **Stage 4** | `1,000 VUs` | `1m` | `3m` | `30s` | Same SLO + zero OOM/restarts | **BLOCKED** |
| **Stage 5** | `2,000 VUs` | `2m` | `3m` | `1m` | Requires horizontal replicas + PgBouncer | **BLOCKED** |
| **Stage 6** | `3,000 VUs` | `2m` | `3m` | `1m` | Requires distributed load generator + scaled DB/API | **BLOCKED** |
| **Stage 7** | `4,000 VUs` | `2m` | `3m` | `1m` | Same | **BLOCKED** |
| **Stage 8** | `5,000 VUs` | `2m` | `5m` | `1m` | Same | **BLOCKED** |

### Mandatory Stop Conditions (Abort Immediately If Any Trigger)
- Staging `/health/ready` returns non-`200` or times out.
- Error rate exceeds `1%` or any sustained HTTP `5xx` occurs.
- PostgreSQL connection pool nears `DATABASE_CONNECTION_LIMIT` or `max_connections` exhaustion.
- Redis latency spikes or memory approaches container limit (`1 GB` on current Railway tier).
- Node.js RSS exceeds `80%` of container memory limit (`800 MB` on current `1 GB` tier).
- BullMQ queue backlog grows uncontrollably.

### Capacity Expectation on Current Railway Footprint
Current Railway `production` services are allocated **`2 vCPU / 1 GB RAM / 1 replica`** each (API, Postgres, Redis) with `DATABASE_CONNECTION_LIMIT=10` and `PGBOUNCER_ENABLED=false`. Based on local profiling (`100 VUs` consumed `75.8%` of 1 CPU core and `441.5 MB` RSS), a single `2 vCPU / 1 GB` replica is expected to saturate well below `5,000 VUs` (likely in the `250–1,000 VU` band depending on cache hit ratio). Reaching sustained `5,000 VUs` will require horizontal API scaling, PgBouncer connection pooling, and scaled Postgres/Redis tiers — to be confirmed empirically during Stages 1–8.
