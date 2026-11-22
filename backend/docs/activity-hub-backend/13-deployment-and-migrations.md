# 13 — Deployment & Migrations Guide

## Migration Files
- `prisma/migrations/20261121213256_add_activity_hub_domains/migration.sql`
- `prisma/migrations/20261122000001_stabilize_activity_hub_constraints_and_outbox/migration.sql`

## Safety Verification
- Purely additive (`CREATE TABLE`, `ADD COLUMN`, `CREATE INDEX`, `ADD CONSTRAINT`).
- No existing columns, tables, or data are dropped or altered destructively.
- Verified that `idx_listings_search_norm_trgm` and `idx_listings_title_trgm` GIN indexes are preserved.

## Production Deployment Steps
1. Configure `DIRECT_DATABASE_URL` pointing directly to PostgreSQL (port `5432`, bypassing PgBouncer transaction pooling) for migrations, and set `SKIP_MIGRATIONS=true` on dedicated `worker` replicas.
2. Run `npm run prisma:migrate:deploy` (which executes `node scripts/migrate-deploy.js` -> `prisma migrate deploy` over `DIRECT_DATABASE_URL`).
3. Run `npm run prisma:generate` if building from source.
4. Build with `npm run build` and start with `npm run start:prod`.
5. Ensure `WorkerModule` (`OutboxPublisherProcessor` + `RfqExpiryProcessor`) is active on the worker instance.

## Rollback Strategy
If rollback is required before application traffic depends on the new tables:
- `DROP TABLE IF EXISTS "cart_items", "quotation_items", "quotations", "rfq_items", "rfq_requests", "bookings" CASCADE;`
- `DROP INDEX IF EXISTS "favorites_listing_id_idx";`
