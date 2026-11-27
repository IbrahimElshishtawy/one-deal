# 08 — Production Deployment Requirements (Railway)

> **Important:** No production settings were modified and no production deployment was executed during Phase 2.

## 1. Railway Dual-Redis Provisioning Steps (`INF-001`)

1. In the Railway project, provision a **second Redis service** dedicated to queues (`redis-queue`) with `maxmemory-policy noeviction` and AOF persistence enabled.
2. Keep the first Redis service (`redis-cache`) configured with `allkeys-lru`.
3. Set two explicit environment variables on the Backend service:
   - `REDIS_CACHE_URL` -> connection string of `redis-cache`
   - `REDIS_QUEUE_URL` -> connection string of `redis-queue`
4. Verify after startup via `GET /health/ready` that:
   - `checks.redis_cache === "up"`
   - `checks.redis_queue === "up"`
   - `checks.redis_topology === "dual_isolated"`
   - `checks.redis_separated === true`

*(Until step 1–3 are completed, Railway operates in `single_shared` mode and logs an explicit startup warning.)*

## 2. Cloudflare R2 Production Checklist

- Configure `R2_PRIVATE_BUCKET_NAME` (private bucket with **no public domain**).
- Configure `R2_BUCKET_NAME` + `R2_PUBLIC_DOMAIN` for public listing media.
- Add an R2 lifecycle rule on `R2_PRIVATE_BUCKET_NAME` to abort incomplete multipart uploads after 24 hours.

## 3. Verification & Security Environment Variables

- `SELLER_PII_ENCRYPTION_KEYS="v1:<high-entropy-key>"`
- `SELLER_PII_ENCRYPTION_KEY_VERSION="v1"`
- `ENABLE_FOUR_EYES_VERIFICATION_REVIEW="false"` (or `"true"` per `BIZ-003`)
- `VERIFICATION_VALIDITY_DAYS="365"`
- `VERIFICATION_RENEWAL_REMINDER_DAYS="30"`
- `VERIFICATION_DOC_RETENTION_REJECTED_DAYS="90"` (adjust per `BIZ-001`)
- `VERIFICATION_DOC_RETENTION_WITHDRAWN_DAYS="30"`
- `VERIFICATION_DOC_RETENTION_EXPIRED_DAYS="180"`
- `VERIFICATION_DOC_RETENTION_SUPERSEDED_DAYS="90"`
- `VERIFICATION_DOC_RETENTION_APPROVED_DAYS="0"`

## 4. Migration Execution Order

1. Snapshot production PostgreSQL database.
2. Deploy commit — Railway `preDeployCommand` (`node scripts/migrate-deploy.js`) automatically applies additive Migrations #15 and #16 before starting the API process.
3. Verify `GET /health/live` (`200`) and `GET /health/ready` (`200`).
