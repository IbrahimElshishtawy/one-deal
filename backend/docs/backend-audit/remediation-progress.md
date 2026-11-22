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

---

## Phase 1 — Architecture, Database & Authorization

**Status:** `COMPLETED`

### Findings Addressed
- **BUG-03 & BUG-04 (HIGH):** Eliminated TOCTOU race conditions in `BookingsService.cancelBooking`, `BookingsService.updateBookingStatus`, `RfqService.cancelRfq`, and `RfqService.updateQuotationStatus` by moving entity reads, authorization, and state transition assertions inside `Prisma.TransactionIsolationLevel.Serializable` transactions with `P2034`/`P2002` mapped to `409 ConflictException`. Persisted `Quotation.statusReason`.
- **P1.2 (MEDIUM):** Created additive migration `20261122000001_stabilize_activity_hub_constraints_and_outbox` adding FKs (`bookings.cancelled_by_user_id -> users.id`, `rfq_requests.accepted_quotation_id -> quotations.id`), partial unique indexes (`uq_bookings_provider_confirmed_slot`, `uq_quotations_rfq_single_accepted`), `quotations.status_reason`, expiry scan indexes, and `outbox_events` retry/lock columns.
- **SEC-03 (HIGH):** Resolved `StaffUser` vs mobile `User` authentication by applying `AdminJwtAuthGuard` (accepts both `deal-one-admin` Staff JWTs and `deal-one-mobile` User JWTs while blocking mobile admin elevation in production) on Bookings/RFQ detail, cancel, and status endpoints, adding `actorType` handling, and ensuring staff cancellations set `cancelledByUserId: null`.
- **SEC-05 (MEDIUM):** Blocked `AccountMember`s (not only `ownerUserId`) from self-booking or adding their own account's listings to Cart.
- **SEC-06 (MEDIUM):** Restricted supplier quotation `WITHDRAWN` transitions to `['owner', 'manager', 'responder']` roles (excluding `lister`).

### Files Changed
- `prisma/schema.prisma`
- `prisma/migrations/20261122000001_stabilize_activity_hub_constraints_and_outbox/migration.sql` (new)
- `src/modules/auth/decorators/current-user.decorator.ts`
- `src/modules/bookings/bookings.controller.ts`
- `src/modules/bookings/bookings.service.ts`
- `src/modules/rfq/rfq.controller.ts`
- `src/modules/rfq/rfq.service.ts`
- `src/modules/cart/cart.service.ts`
- `src/modules/bookings/bookings.service.spec.ts`
- `src/modules/rfq/rfq.service.spec.ts`
- `src/modules/cart/cart.service.spec.ts`
- `src/core/database/migrate-deploy.spec.ts`

### Database / API Changes
- **Database:** Applied additive migration `20261122000001_stabilize_activity_hub_constraints_and_outbox` on local PostgreSQL (`11/11` migrations verified).
- **API:** Backward-compatible for mobile users; Enterprise Admin staff JWTs are now accepted on Bookings/RFQ detail/cancel/status endpoints.

### Tests Added & Results
- Added 6 regression unit tests for TOCTOU concurrency conflicts, `AccountMember` self-booking/cart blocking, `lister` withdrawal denial, and `StaffUser` admin cancellation.
- `npx prisma validate && npx prisma generate && node scripts/migrate-deploy.js`: **PASSED** (11/11 migrations)
- `npx tsc --noEmit && npm run build`: **PASSED**
- `npx jest --runInBand --forceExit`: **PASSED** (45/45 suites, 294/294 tests)
- `npx jest --config ./test/jest-e2e.json test/activity-hub.e2e-spec.ts --forceExit`: **PASSED** (1/1 suite, 6/6 tests)

### Remaining Issues / Risks
- Phase 2–5 items remain open; proceeding to Phase 2.

---

## Phase 2 — Missing Business Functionality

**Status:** `COMPLETED`

### Findings Addressed
- **P2.1 (HIGH):** Added Draft RFQ editing (`PATCH /api/v1/rfqs/:id`, `UpdateRfqDto`, `RfqService.updateDraftRfq`) and Draft RFQ submission (`PATCH /api/v1/rfqs/:id/submit`, `RfqService.submitDraftRfq`) with `RFQ_SUBMITTED` outbox notification.
- **P2.2 / BUG-07 (HIGH):** Enforced `rfq.expiresAt` in `submitQuotation` & `updateQuotationStatus`, and `quotation.validUntil` in `updateQuotationStatus` (`ACCEPTED` / `SHORTLISTED`). Created `RfqExpiryProcessor` (`src/workers/rfq-expiry.processor.ts`) and registered it in `WorkerModule` and `WorkerService` (BullMQ repeatable job + Redis-locked interval every 30 min).
- **P2.3 (MEDIUM):** Enqueued `RFQ_CANCELLED` outbox push notifications to all suppliers with active (`SUBMITTED`/`SHORTLISTED`) quotations inside `RfqService.cancelRfq`.
- **P2.4 / BUG-14 (MEDIUM):** Implemented DST-aware `Africa/Cairo` timezone resolution via `Intl.DateTimeFormat` in `BookingsService.parseAndValidateSlot` (`+03:00` summer DST vs `+02:00` winter standard). Added listing root-category-to-`bookingType` validation (`real-estate`, `cars`, `services`).

### Files Changed
- `src/modules/rfq/dto/update-rfq.dto.ts` (new)
- `src/modules/rfq/rfq.controller.ts`
- `src/modules/rfq/rfq.service.ts`
- `src/workers/rfq-expiry.processor.ts` (new)
- `src/workers/rfq-expiry.processor.spec.ts` (new)
- `src/workers/worker.module.ts`
- `src/workers/worker.service.ts`
- `src/modules/bookings/bookings.service.ts`
- `src/modules/bookings/bookings.service.spec.ts`
- `src/modules/rfq/rfq.service.spec.ts`

### Database / API Changes
- **Database:** None (uses expiry indexes added in Phase 1).
- **API:** Added additive endpoints `PATCH /api/v1/rfqs/:id` and `PATCH /api/v1/rfqs/:id/submit`. V1 commerce boundary preserved (no checkout, orders, or product payments).

### Tests Added & Results
- Added 7 regression unit tests (`RfqExpiryProcessor`, draft edit/submit, expired RFQ/quotation rejection, `cancelRfq` supplier notifications, booking category mismatch, and `Africa/Cairo` DST summer/winter conversion).
- `npx tsc --noEmit && npm run build`: **PASSED**
- `npx jest --runInBand --forceExit`: **PASSED** (46/46 suites, 301/301 tests)
- `npx jest --config ./test/jest-e2e.json test/activity-hub.e2e-spec.ts --forceExit`: **PASSED** (1/1 suite, 6/6 tests)

### Remaining Issues / Risks
- Phase 3–5 items remain open; proceeding to Phase 3.
