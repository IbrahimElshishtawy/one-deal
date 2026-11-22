# Deal One — Backend Remediation Progress Log

**Started:** 2026-11-22  
**Audit Baseline:** `docs/backend-audit/12-implementation-vs-documentation.md`

---

## Phase 0 — Critical Security & Production

**Status:** `COMPLETED`

### Findings Addressed
- **SEC-01 (CRITICAL):** Fixed `RfqService.getRfqs` where `scope=open_for_suppliers` + `query.status` overwrote the `status: { in: [...] }` filter and leaked private `DRAFT`/`CANCELLED`/`ACCEPTED` RFQs. Now strictly rejects non-open statuses in `open_for_suppliers` scope with `400 BadRequestException`.
- **SEC-02 (HIGH):** Added strict `GetCartQueryDto` validation (`page >= 1`, `limit 1..100`, `@IsUUID() categoryId`, `categorySlug <= 150`) to `CartController.getCart`.
- **BUG-08 (HIGH):** Fixed `ENABLE_V2_PAYMENTS` in `src/core/config/env.config.ts` from `z.coerce.boolean()` (where `"false"` coerced to `true`) to `boolFlag(false)`. Added optional `DIRECT_DATABASE_URL` to `envSchema`.
- **BUG-02 (CRITICAL):** Updated `scripts/migrate-deploy.js` with `resolveMigrationDatabaseUrl()` preferring `DIRECT_DATABASE_URL` / `MIGRATION_DATABASE_URL` and rejecting PgBouncer transaction-pooled URLs (`pgbouncer=true` or port `6432`). Updated `Dockerfile` to honor `SKIP_MIGRATIONS=true` and `docker-compose.yml` to pass `DIRECT_DATABASE_URL` to `api` and `SKIP_MIGRATIONS=true` to `worker`.
- **SEC-04 & SEC-07 (HIGH/MEDIUM):** Restricted `UpdateQuotationStatusDto.status` to `@IsIn([SHORTLISTED, ACCEPTED, REJECTED, WITHDRAWN])` (blocking `EXPIRED`/`SUBMITTED`). Added `@Max` bounds on RFQ/Quotation decimal DTO fields and a `DECIMAL(14,2)` overflow guard in `RfqService.submitQuotation`.

### Files Changed
- `src/modules/rfq/rfq.service.ts`
- `src/modules/rfq/dto/update-quotation-status.dto.ts`
- `src/modules/rfq/dto/create-rfq.dto.ts`
- `src/modules/rfq/dto/create-quotation.dto.ts`
- `src/modules/cart/dto/get-cart-query.dto.ts` (new)
- `src/modules/cart/cart.controller.ts`
- `src/core/config/env.config.ts`
- `scripts/migrate-deploy.js`
- `Dockerfile`
- `docker-compose.yml`
- `src/modules/rfq/rfq.service.spec.ts`
- `src/modules/cart/cart.service.spec.ts`
- `src/core/config/env.config.spec.ts`
- `src/core/database/migrate-deploy.spec.ts`

### Database / API Changes
- **Database:** None in Phase 0.
- **API:** `GET /api/v1/rfqs?scope=open_for_suppliers&status=<non-open>` now returns `400`; `GET /api/v1/cart` validates query params (`400` on invalid UUID or `limit > 100`); `PATCH /api/v1/quotations/:id/status` rejects `EXPIRED`/`SUBMITTED` with `400`. All changes are fail-closed security fixes compatible with Flutter.

### Tests Added & Results
- Added 6 regression unit tests across `rfq.service.spec.ts`, `cart.service.spec.ts`, `env.config.spec.ts`, and `migrate-deploy.spec.ts`.
- `npx tsc --noEmit`: **PASSED** (0 errors)
- `npm run build`: **PASSED** (0 errors)
- `npx jest --runInBand --forceExit`: **PASSED** (45/45 suites, 288/288 tests)
- `npx jest --config ./test/jest-e2e.json test/activity-hub.e2e-spec.ts --forceExit`: **PASSED** (1/1 suite, 6/6 tests)

### Remaining Issues / Risks
- Phase 1–5 findings remain open; proceeding to Phase 1.
