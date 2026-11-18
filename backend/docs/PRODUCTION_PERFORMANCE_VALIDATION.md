# Deal One Backend — Production Performance Validation (k6)

**Test Date:** 2026-11-19  
**Target Environment:** Local Docker Production-Mode Staging (`NODE_ENV=production`, `TRUST_PROXY=1`, `ENABLE_SWAGGER=false`, `AUDIT_QUEUE_ENABLED=true`, real PostgreSQL 16.4 + PostGIS 3.4.3 + Dual Redis Cache/Queue on `http://127.0.0.1:3099/api/v1`)  
**Remote Railway Staging Status:** **BLOCKED** (No Railway staging environment exists yet; production load testing prohibited)

---

## 1. Script Inspection & Fix

- Audited `load-tests/k6-5000-online.js`: fixed hardcoded `'http://localhost:3000/health/ready'` (line 69) to derive `HEALTH_BASE_URL` dynamically from `__ENV.BASE_URL`.
- Created `load-tests/k6-staging-validation.js` for gradual-ramp staging validation (5 → 25 → 75 → 100 VUs over 45s) covering:
  - `GET /api/v1/listings?limit=20` (40%)
  - `GET /api/v1/categories` (15%)
  - `GET /api/v1/search?q=<arabic>&lat=30.0444&lng=31.2357&radiusKm=25` (25%)
  - `GET /api/v1/locations/governorates` (10%)
  - `GET /health/ready` (10%)

---

## 2. Actual Measured k6 Results (Local Docker `NODE_ENV=production` Staging)

| Metric | Measured Value |
|---|---|
| **Staging URL** | `http://127.0.0.1:3099/api/v1` |
| **Duration** | `45.2 s` |
| **Virtual Users (Ramp)** | `5 → 25 (10s) → 75 (20s) → 100 (10s) → 0 (5s)` (max 100 VUs) |
| **Total Requests** | `10,269` |
| **Throughput (RPS)** | `227.31 req/s` |
| **Failed Requests / Error Rate** | `0` (`0.00%`) |
| **Checks Passed** | `100.00%` (`10,269 / 10,269`) |
| **Latency `min`** | `0.54 ms` |
| **Latency `p50` (median)** | `3.20 ms` |
| **Latency `avg`** | `20.32 ms` |
| **Latency `p90`** | `27.51 ms` |
| **Latency `p95`** | `154.33 ms` |
| **Latency `max`** | `378.52 ms` |
| **Post-Load Node Process CPU / RSS** | `75.8% CPU`, `441.5 MB RSS` (`2.8% MEM`) |

> Note: Existing script thresholds (`p(95) < 400ms`, `p(99) < 900ms`, `errors < 1%`) were met with zero errors on local Docker staging. Railway production-equivalent cloud staging measurements remain required before claiming full cloud-scale capacity validation (e.g., 5,000 online users).
