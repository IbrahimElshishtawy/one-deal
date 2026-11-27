# 03 — Infrastructure & Cleanup Reliability (Workstreams B & C)

## B. Redis Dual-Topology Awareness & Health Reporting (`INF-001`)

- **Files:** `backend/src/core/redis/redis.service.ts`, `backend/src/core/health/health.controller.ts`
- **Behavior:**
  - `RedisService.getTopologyStatus()` evaluates whether Cache and Queue resolve to distinct endpoints (`dual_isolated`, `local_split`) or the same shared instance (`single_shared`), without ever exposing URLs, hostnames, ports, or credentials.
  - At startup (`onModuleInit`), logs `✅ Redis Topology: DUAL ISOLATED` when separated or `⚠️ Redis Topology: SINGLE SHARED INSTANCE` when both fall back to `REDIS_URL`.
  - `GET /health/ready` now exposes `checks.redis_topology` and `checks.redis_separated` alongside `redis_cache` and `redis_queue`.
  - Backward compatibility with legacy single `REDIS_URL` is fully preserved.

## C. Safe R2-First Public Media Cleanup (`OPS-001`)

- **Files:** `backend/src/modules/media/media.service.ts`, `backend/src/workers/media-cleanup.processor.ts`, `backend/src/workers/worker.module.ts`
- **Safety Invariants:**
  1. Queries only `processingStatus: 'pending'`, older than 24h, AND `listing.publicationStatus !== 'published'` (protects active published listings).
  2. Validates `storageKey.startsWith('uploads/images/')` and blocks path traversal / private KYC keys (`assertValidPublicMediaKey`).
  3. Deletes the Cloudflare R2 object **first** via SigV4 `DELETE` (`MediaService.deletePublicObject()`); treats `200`/`204`/`404` as idempotently deleted.
  4. Deletes the PostgreSQL `ListingMedia` row **only** after R2 deletion succeeds; on R2 failure, keeps the DB row for retry on the next 6h cycle.
