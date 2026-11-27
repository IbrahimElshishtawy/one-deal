# 06 — Infrastructure, Redis & BullMQ Audit

## 1. Dual-Redis Topology vs. Production Railway Reality

### Finding `INF-001` — HIGH — Single-Redis Fallback Risk in Railway Production
- **Status:** VERIFIED
- **Evidence:**
  - `backend/src/core/redis/redis.service.ts:61-66,89-94`
  - `docker-compose.yml:77-119` (Local dev runs two separate containers: `redis_cache :6379 allkeys-lru` and `redis_queue :6380 AOF noeviction`)
  - `RAILWAY_STAGING_FINAL_CONFIGURATION.md` / `env.config.ts:241-257`
- **Actual Behavior:** `RedisService` supports separate `REDIS_CACHE_URL` and `REDIS_QUEUE_URL`. However, when only Railway's default single `REDIS_URL` is configured, **both `cacheClient` and `queueClient` connect to the exact same Redis instance**. If that single Redis uses an LRU eviction policy (`allkeys-lru`), cache pressure can evict BullMQ job keys, repeat schedules, and distributed lock keys; if it uses `noeviction`, cache writes fail when memory fills.
- **Production Impact:** Potential lost BullMQ jobs, broken distributed locks, or cache OOM errors under load.
- **Recommended Resolution:** Provision two distinct Redis instances in production (`REDIS_CACHE_URL` with `allkeys-lru` and `REDIS_QUEUE_URL` with `noeviction` + AOF) and add a production startup warning/check if `REDIS_CACHE_URL === REDIS_QUEUE_URL`.
- **Business Decision Required:** Yes (infrastructure cost approval for 2nd managed Redis instance).

## 2. Worker Topology, Concurrency & Fallback

- **Verified (`worker.service.ts:50-157`):**
  - Respects `ENABLE_WORKERS=false` to separate API pods from dedicated worker replicas.
  - BullMQ worker runs with `concurrency: 2` on queue `marketspace-maintenance`.
  - Connection fallback: if `redisService.isQueueClientConnected()` is false at startup, falls back cleanly to `setInterval` timers wrapped with Redis distributed locks (`acquireLock` / `releaseLock`).
  - **Note (`INF-002` — LOW):** BullMQ job handler (`worker.service.ts:90-112`) catches exceptions and returns `null`, meaning BullMQ's built-in exponential retry/DLQ mechanism is bypassed in favor of waiting for the next scheduled repeat interval. For periodic sweeps (`verification-expiry`, `listing-expiry`) this is acceptable, but for transient failures on `outbox-publisher`, explicit retry/backoff is preferable.

## 3. Railway Deployment & Healthchecks

- **Verified (`railway.json:1-17`):**
  - `preDeployCommand: ["node scripts/migrate-deploy.js"]` runs migrations before the new API container starts.
  - `healthcheckPath: "/health/live"`, `healthcheckTimeout: 120`.
  - `restartPolicyType: "ON_FAILURE"`, `restartPolicyMaxRetries: 10`.
- **Verified (`backend/src/main.ts:50-56`):**
  - Fastify `bodyLimit: 2MB`, `requestTimeout: 30s`, `parseTrustProxy(TRUST_PROXY)` rejects unsafe blanket `TRUST_PROXY=true`.
