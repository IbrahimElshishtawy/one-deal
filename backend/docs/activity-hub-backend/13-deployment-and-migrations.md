# 13 — Deployment & Migrations Guide

## Migration File
- `prisma/migrations/20261121213256_add_activity_hub_domains/migration.sql`

## Safety Verification
- Purely additive (`CREATE TABLE`, `CREATE INDEX`, `ADD CONSTRAINT`).
- No existing columns, tables, or data are dropped or altered destructively.
- Verified that `idx_listings_search_norm_trgm` and `idx_listings_title_trgm` GIN indexes are preserved.

## Production Deployment Steps
1. Run `npm run prisma:migrate:deploy` (which executes `node scripts/migrate-deploy.js` -> `prisma migrate deploy`).
2. Run `npm run prisma:generate` if building from source.
3. Build with `npm run build` and start with `npm run start:prod`.
4. Ensure `WorkerModule` / `OutboxPublisherProcessor` is active so Activity Hub `OutboxEvent` push notifications are relayed.

## Rollback Strategy
If rollback is required before application traffic depends on the new tables:
- `DROP TABLE IF EXISTS "cart_items", "quotation_items", "quotations", "rfq_items", "rfq_requests", "bookings" CASCADE;`
- `DROP INDEX IF EXISTS "favorites_listing_id_idx";`
