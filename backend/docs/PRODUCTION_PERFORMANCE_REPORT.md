# Deal One Backend — Production Performance Verification Report

**Date:** 2026-11-19  
**Status:** **BLOCKED (No Dedicated Staging Environment Available)**

---

## 1. Execution Status & Reason for Block

Per Phase 12 execution rules:
- Load testing against the live production URL (`https://one-deal-cjjt-production.up.railway.app/api/v1`) is **strictly prohibited** without explicit authorization.
- No dedicated production-equivalent staging environment URL was provided, and no local PostgreSQL/PostGIS/Redis stack is running in this workspace (`pg_isready` and `redis-cli` returned no active instances).
- Therefore, no fabricated latency or throughput metrics are reported. Performance verification is explicitly classified as **BLOCKED** pending staging availability.

---

## 2. Inspection of Existing k6 Script (`load-tests/k6-5000-online.js`)

Before execution on staging, the existing k6 script was audited:
- **Tooling check:** `k6` is installed locally (`/home/ibrahim-elshishtawy/.local/bin/k6`).
- **Traffic profile in existing script:**
  - Ramping VUs: `50 → 1000 (2m) → 3000 (3m) → 5000 (5m) → 0 (2m)` (12 minutes total).
  - Thresholds: `p(95) < 400ms`, `p(99) < 900ms`, `errors < 1%`.
  - Endpoints covered: `GET /listings?limit=20` (45%), `GET /categories` (15%), `GET /search?...` (25%), `GET /locations/governorates` (10%), `GET /health/ready` (5%).
- **Defects identified in `load-tests/k6-5000-online.js`:**
  1. Line 69 hardcodes `'http://localhost:3000/health/ready'` instead of deriving the root origin from `__ENV.BASE_URL`, which will fail when pointed at a remote staging URL.
  2. Does not yet include authenticated endpoints (`POST /auth/login`, `POST /auth/refresh`, `GET /listings/:id`, `POST /media/images/upload-url`).

---

## 3. Code-Level Performance Improvements Verified

Without claiming unmeasured latency gains, two concrete structural overhead issues were fixed:
1. **Feed Redis cache payload halved (`src/modules/listings/listings.service.ts:536-547`):** Removed the duplicated `items: mappedData` array that was being serialized into Redis alongside `data: mappedData` (and stripped by `TransformInterceptor` on every HTTP response).
2. **Atomic Redis rate limiting (`src/core/redis/redis.service.ts:36-44,418-445`):** Reduced first-hit rate-limit Redis round-trips from 2 (`INCR` + `EXPIRE`) to 1 atomic `EVAL` Lua script.

---

## 4. Exact Staging Performance Test Procedure (Unblock Steps)

Once a production-equivalent staging environment is provisioned on Railway:
1. Fix line 69 of `load-tests/k6-5000-online.js` to derive the health URL from `BASE_URL` (e.g., `BASE_URL.replace(/\/api\/v1$/, '') + '/health/ready'`).
2. Seed realistic staging data (`npm run prisma:seed`).
3. Run a controlled staging smoke test first (50 VUs, 2m), then ramp to target concurrency:
   ```bash
   BASE_URL="https://<staging-host>/api/v1" k6 run load-tests/k6-5000-online.js
   ```
4. Capture and record in this report:
   - `http_req_duration` (`p50`, `p95`, `p99`), RPS, error rate, HTTP 4xx/5xx distribution.
   - Railway container CPU & memory RSS metrics (via authenticated `/metrics` scrape).
   - PostgreSQL connection pool utilization & Redis latency.
