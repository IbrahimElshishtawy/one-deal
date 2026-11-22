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

---

## Phase 3 — API Contract Alignment

**Status:** `COMPLETED`

### Findings Addressed
- **BUG-09 (MEDIUM):** Fixed `FavoritesService.getFavoriteStatus` to query `listing.findUnique` in parallel with `favorite.findUnique`, ensuring `isListingAvailable` reflects true listing availability even when not favorited.
- **BUG-10 (MEDIUM):** Fixed `CartService.getCart` to compute `estimatedSubtotal` across the entire matching basket (not just the current paginated slice) and derive `currency` from items.
- **BUG-11 (MEDIUM):** Made `CartService.addItem` atomic against concurrent `P2002` unique constraint races and updated `variantAttributes` on existing items.
- **BUG-12 (MEDIUM):** Aligned `FavoritesService.getFavoritesCount` (`availabilityStatus: 'available'`) and `CartService.getCartItemsCount` (`userId`) with their corresponding section list predicates.
- **P3.3 (MEDIUM):** Added validated `GetRfqQuotationsQueryDto` (`sortBy`, `page`, `limit`) and paginated `{ data, meta }` response on `GET /api/v1/rfqs/:id/quotations`. Created dedicated `CancelRfqDto` (removing cross-module import of `CancelBookingDto`).
- **Nested `success` Envelope Alignment (Flutter-Safe):** Inspected Flutter app (`deal one app/lib/features/favorites/data/dto/favorite_dto.dart:37`), which explicitly reads `json['success'] == true` on Favorites mutations — therefore preserved `success: true` in `FavoritesService` for 100% Flutter compatibility, while removing redundant nested `success: true` from `CartService.removeItem` and `CartService.clearCart` (not yet consumed by Flutter).

### Files Changed
- `src/modules/favorites/favorites.service.ts`
- `src/modules/cart/cart.service.ts`
- `src/modules/rfq/dto/cancel-rfq.dto.ts` (new)
- `src/modules/rfq/dto/get-rfq-quotations-query.dto.ts` (new)
- `src/modules/rfq/rfq.controller.ts`
- `src/modules/rfq/rfq.service.ts`
- `src/modules/favorites/favorites.service.spec.ts`
- `src/modules/cart/cart.service.spec.ts`
- `src/modules/rfq/rfq.service.spec.ts`

### Tests Added & Results
- Added 3 regression unit tests (unfavorited `isListingAvailable`, full-basket `estimatedSubtotal`, concurrent `P2002` cart `addItem`, `GetRfqQuotationsQueryDto`).
- `npx tsc --noEmit && npm run build`: **PASSED**
- `npx jest --runInBand --forceExit`: **PASSED** (46/46 suites, 304/304 tests)
- `npx jest --config ./test/jest-e2e.json test/activity-hub.e2e-spec.ts --forceExit`: **PASSED** (1/1 suite, 6/6 tests)

---

## Phase 4 — Performance & Reliability

**Status:** `COMPLETED`

### Findings Addressed
- **P4.1 (HIGH):** Implemented Outbox retry with exponential backoff (`30s * 2^(attempt-1)`, capped at 1h, up to `maxRetries = 5`), atomic `lockedAt` claim timestamping, and automatic recovery of stale `PROCESSING` rows older than 5 minutes in `OutboxPublisherProcessor`. Fixed `NotificationProcessor` to return `false` when `NotificationsService.sendPushNotification` returns `{ success: false }`.
- **P4.2 (MEDIUM):** Cached Google OAuth2 access tokens (~50 min TTL) in `NotificationsService.mintGoogleAccessToken()` and added `AbortSignal.timeout(5000)` to both OAuth2 and FCM HTTP v1 `fetch()` calls.
- **P4.3 (MEDIUM):** Reduced redundant `COUNT(*)` queries in `ActivityHubService.getActivityHub` by reusing `cartResult.meta.total` and `favoritesResult.meta.total` whenever `cart`/`favorites` sections are loaded without category filters.

### Files Changed
- `src/workers/outbox-publisher.processor.ts`
- `src/workers/notification.processor.ts`
- `src/modules/notifications/notifications.service.ts`
- `src/modules/activity-hub/activity-hub.service.ts`
- `src/workers/outbox-publisher.processor.spec.ts`
- `src/modules/activity-hub/activity-hub.service.spec.ts`

### Tests Added & Results
- Added Outbox exponential backoff retry, `FAILED` exhaustion, stale `PROCESSING` recovery, and Activity Hub query-reduction assertions.
- Verified inside final Phase 5 suite below (`46/46` unit suites, `306/306` unit tests).

---

## Phase 5 — Testing, Documentation Alignment & Verification

**Status:** `COMPLETED` (local verification complete; staging deploy dry-run pending environment deployment)

### Findings Addressed
- Added E2E security & contract tests in `test/activity-hub.e2e-spec.ts` covering `SEC-01` (private DRAFT RFQ isolation), `SEC-02` (Cart query validation), `SEC-04` (`EXPIRED` quotation status rejection), `BUG-09` (unfavorited `isListingAvailable`), draft RFQ edit/submit, and paginated quotation comparison (`sortBy` validation + `meta`).
- Updated all aligned documentation in `docs/activity-hub-backend/` (`02`, `04`, `05`, `08`, `09`, `11`, `13`, `14`) and `docs/backend-audit/12-implementation-vs-documentation.md`.

### Final Verification Results (2026-11-22)
| Check | Command | Result |
|---|---|---|
| Prisma Schema | `npx prisma validate` | **PASSED** |
| Migration Status (local) | `npx prisma migrate status` | **PASSED** (`11/11` applied, up to date) |
| ESLint | `npx eslint "{src,apps,libs,test}/**/*.ts"` | **PASSED** (0 errors, 9 pre-existing warnings) |
| TypeScript | `npx tsc --noEmit` | **PASSED** (0 errors) |
| Production Build | `npm run build` | **PASSED** (0 errors) |
| Unit Tests | `npx jest --runInBand --forceExit` | **PASSED** (**46/46 suites, 306/306 tests**) |
| Activity Hub E2E | `npx jest --config ./test/jest-e2e.json test/activity-hub.e2e-spec.ts --forceExit` | **PASSED** (**1/1 suite, 8/8 tests**) |

### Remaining Items Before Production Sign-Off
1. **Staging Verification (Acceptance Criterion #8):** Run `node scripts/migrate-deploy.js` with `DIRECT_DATABASE_URL` against a staging PostgreSQL + PgBouncer environment and verify `api` + `worker` container startup.
2. **Deferred Non-Blocking Features (Documented in `14-known-limitations.md`):** Per-category notification preferences and favorite unavailability push hooks in `ListingsService`.
