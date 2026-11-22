# 12 — Backend Implementation vs. Documentation Comprehensive Audit Report

**Project:** Deal One (`market-space-backend` v1.0.0)  
**Audit Date:** 2026-11-22  
**Audit Scope:** Full evidence-based audit of `src/`, `prisma/`, `scripts/`, `test/`, `Dockerfile`, `docker-compose.yml`, and runtime configuration against all 14 documentation files in `docs/activity-hub-backend/`.  
**Audit Mode:** Read-only (zero existing source, schema, migration, or config files modified).

---

## 1. Executive Summary

The Deal One backend is a well-structured NestJS + Fastify + Prisma + PostgreSQL (PostGIS) + Redis + BullMQ **Modular Monolith**. All five Unified Activity & Commerce Hub modules (`FavoritesModule`, `BookingsModule`, `RfqModule`, `CartModule`, `ActivityHubModule`) and their additive database migration (`20261121213256_add_activity_hub_domains`) **exist, compile cleanly, pass all 45 unit test suites (282 tests) and all 6 Activity Hub E2E tests**, and preserve the V1 non-transactional commerce boundary (no fake checkout/orders/payments).

However, deep code-path verification (`Request → Controller → Validation → Auth/AuthZ → Service → DB → Response`) revealed **critical security, concurrency, authorization, and deployment defects** that were missed by the existing documentation and tests:

| Severity | Count | Headline Findings |
|---|---:|---|
| **CRITICAL** | 2 | (1) `GET /api/v1/rfqs?scope=open_for_suppliers&status=DRAFT` leaks **other users' private DRAFT/CANCELLED/ACCEPTED RFQs** due to object key overwrite in `RfqService.getRfqs`. (2) `Dockerfile` + `docker-compose.yml` execute `scripts/migrate-deploy.js` (which uses session-level `pg_advisory_lock` and `prisma migrate deploy`) through **PgBouncer in `transaction` pool mode** on every `api` and `worker` container startup. |
| **HIGH** | 8 | (1) TOCTOU race conditions in `BookingsService.updateBookingStatus`, `BookingsService.cancelBooking`, and `RfqService.updateQuotationStatus` (state transitions checked outside `$transaction`, allowing concurrent double-acceptance of quotations and contradictory booking states). (2) `CartController.getCart` lacks DTO validation (`limit=999999` DoS / unvalidated `categoryId`). (3) Admin/Moderator authorization checks in `BookingsService` and `RfqService` are **unreachable dead code** for real Enterprise Admin staff (`AdminAuthModule` uses `StaffUser` + `deal-one-admin` JWT, rejected by `JwtAuthGuard`). (4) Draft RFQs can never be submitted or edited (dead-end lifecycle). (5) `RFQ` / `Quotation` expiration (`expiresAt`, `validUntil`) is never enforced or processed by any worker. (6) `PATCH /quotations/:id/status` allows RFQ owner to pass `status: "EXPIRED"` (violating API contract) and ignores `reason`. (7) `OutboxPublisherProcessor` never retries `FAILED` events and cannot recover stuck `PROCESSING` rows after worker crashes. (8) `env.config.ts` validates `ENABLE_V2_PAYMENTS` with `z.coerce.boolean()` where string `"false"` coerces to `true`. |
| **MEDIUM** | 9 | `FavoritesService.getFavoriteStatus` always returns `isListingAvailable: false` when not favorited; `CartService.getCart` computes `estimatedSubtotal` over only the current page; Activity Hub summary counts diverge from section totals; self-booking/cart checks miss `AccountMember`s; `CartService.addItem` non-atomic upsert race condition; booking type not validated against listing category; Egypt DST (`+02:00` hardcoded vs `+03:00` summer); unvalidated `sortBy` and unpaginated `GET /rfqs/:id/quotations`; double-wrapped `{ success: true, data: { success: true, ... } }` envelopes; FCM OAuth token minted on every push with no fetch timeout. |
| **LOW** | 5 | Documentation count errors (`02-database-design.md` says 5 new tables instead of 6, omits `ALTER TABLE` statements); `00-audit-report.md` is stale (pre-implementation snapshot); `RfqController.cancelRfq` reuses `CancelBookingDto`; `test/activity-hub.e2e-spec.ts` leaks test users/accounts in `afterAll`; 10 pre-existing ESLint warnings + Jest open handles warning. |

**Production Readiness Verdict:** **NOT PRODUCTION-READY** until Phase 0 (Critical Security & Production Deployment fixes) and Phase 1 (Concurrency/State-Machine & Authorization fixes) are remediated and verified.

---

## 2. Backend Architecture Assessment

| Architectural Pillar | Documented Expectation (`00`, `01`, `08`, `10`) | Actual Implementation | Status |
|---|---|---|---|
| **Modular Monolith** | NestJS 10 + Fastify + Prisma + PostgreSQL (PostGIS) + Redis + BullMQ | Verified in `package.json`, `src/main.ts`, `src/app.module.ts`. 25 feature modules + `WorkerModule` + core modules. | `IMPLEMENTED` |
| **Activity Hub Aggregation** | `ActivityHubModule` is a pure aggregation layer injecting `CartService`, `BookingsService`, `RfqService`, `FavoritesService` with no logic duplication | Verified in `src/modules/activity-hub/activity-hub.service.ts:19-86`. Uses `Promise.all` and selective `?include=` loading. | `IMPLEMENTED` |
| **Domain Independence** | Each domain owns its own Prisma tables, DTOs, state machines, auth checks, and REST endpoints | Mostly preserved, except `RfqController.cancelRfq` (`src/modules/rfq/rfq.controller.ts:28,90`) imports `CancelBookingDto` from `bookings`. | `PARTIALLY_IMPLEMENTED` |
| **V1 Commerce Boundary** | No online product checkout, orders, or product payments; `PaymentsModule` strictly V2 promotions gated by `ENABLE_V2_PAYMENTS === 'true'` | Verified in `src/app.module.ts:38,74`, `src/modules/cart/`, `src/modules/payments/`. Note `env.config.ts:314` has a `z.coerce.boolean()` bug for `ENABLE_V2_PAYMENTS`. | `IMPLEMENTED_BUT_INCORRECT` |
| **Transactional Outbox** | Domain state transitions write `OutboxEvent` inside `$transaction`, relayed asynchronously by `OutboxPublisherProcessor` -> `NotificationProcessor` -> `NotificationsService` | Verified for Bookings (`create`, `cancel`, `updateStatus`) and RFQs (`create`, `submitQuotation`, `updateQuotationStatus`). Missing on `cancelRfq` and Favorite unavailability; lacks retry/stuck-job recovery. | `PARTIALLY_IMPLEMENTED` |
| **API Envelope & Prefix** | Global prefix `/api/v1`, `TransformInterceptor` wraps into `{ success: true, data, meta? }`, `HttpExceptionFilter` standardizes errors | Verified in `src/main.ts:86-102`, `transform.interceptor.ts`, `http-exception.filter.ts`. Some service methods return `{ success: true, ... }` causing nested `data.success`. | `PARTIALLY_IMPLEMENTED` |

---

## 3. Documentation Files Reviewed

All 14 files in `docs/activity-hub-backend/` were read in full prior to code inspection:

| # | File | Primary Scope | Currency / Accuracy Notes |
|---|---|---|---|
| 1 | `docs/activity-hub-backend/00-audit-report.md` | Pre-implementation baseline audit & feature matrix | **Stale snapshot** — still classifies Bookings, RFQ, Cart, and Activity Hub as "Missing entirely" and cites 9 migrations / 41 test suites (now 10 migrations / 45 test suites). |
| 2 | `docs/activity-hub-backend/01-system-architecture.md` | Modular monolith & Activity Hub aggregation rules | Accurate at high level. |
| 3 | `docs/activity-hub-backend/02-database-design.md` | Migration & 6 Activity Hub models/indexes | Minor inaccuracies: states "creates 5 new tables" (actually 6) and omits `ALTER TABLE` statements present in `migration.sql`. |
| 4 | `docs/activity-hub-backend/03-favorites-module.md` | Favorites endpoints & validation rules | Matches routes; omits bug in `getFavoriteStatus` when unfavorited. |
| 5 | `docs/activity-hub-backend/04-bookings-module.md` | Booking types, state machine, concurrency, auth | Overstates concurrency safety (`cancelBooking` is not Serializable; status checks happen outside `$transaction`) and admin auth (unreachable). |
| 6 | `docs/activity-hub-backend/05-rfq-module.md` | RFQ & Quotation state machines, pricing, V1 boundary | Documents `DRAFT -> SUBMITTED` and `EXPIRED` transitions that have no endpoints/workers. |
| 7 | `docs/activity-hub-backend/06-cart-commerce-boundary.md` | V1 non-transactional saved basket & V2 readiness | Accurate on boundary; misses pagination/subtotal and query validation bugs. |
| 8 | `docs/activity-hub-backend/07-activity-hub-api.md` | `GET /api/v1/activity-hub` query params & response | Accurate on structure; misses summary vs section total discrepancies. |
| 9 | `docs/activity-hub-backend/08-notifications.md` | Transactional Outbox & enqueued events | Accurate for implemented events; does not note missing `cancelRfq` notification or outbox retry gaps. |
| 10 | `docs/activity-hub-backend/09-security-permissions.md` | Auth, validation, IDOR, rate limiting | **Contains false/unmet security claims** (e.g., `providerAccountId` rejection when `listingId` is present; admin/moderator access on `cancelRfq`/`updateQuotationStatus` and via `JwtAuthGuard`; RFQ `open_for_suppliers` leak). |
| 11 | `docs/activity-hub-backend/10-performance.md` | Indexes, `Promise.all`, Serializable tx, cache safety | Accurate on indexes and `Promise.all`; misses unpaginated quotations and unbounded `CartController.getCart` limit. |
| 12 | `docs/activity-hub-backend/11-api-contracts.md` | Flutter-ready endpoint summary & query/body shapes | Minor mismatches on `PATCH /quotations/:id/status` enum enforcement and `GET /rfqs/:id/quotations` unvalidated `sortBy`. |
| 13 | `docs/activity-hub-backend/13-deployment-and-migrations.md` | Migration safety, deploy steps, rollback SQL | Accurate rollback SQL; omits PgBouncer transaction-pooling incompatibility with `migrate-deploy.js`. |
| 14 | `docs/activity-hub-backend/14-known-limitations.md` | V1 policy, favorite notifications, Cairo TZ, Redis test | Accurate; Cairo `+02:00` ignores Egypt DST (`+03:00`). |

---

## 4. Existing Backend Structure

```text
backend/
├── prisma/
│   ├── schema.prisma                   # 1,034 lines, 12 modules, 31+ models
│   ├── migrations/                     # 10 migrations (latest: 20261121213256_add_activity_hub_domains)
│   └── seeds/                          # Geography, taxonomy (6 root categories), demo & admin RBAC seeds
├── scripts/
│   └── migrate-deploy.js               # Advisory-locked migration runner (used by Dockerfile CMD)
├── src/
│   ├── main.ts                         # FastifyAdapter, Helmet, CORS, ValidationPipe, Swagger, /api/v1
│   ├── app.module.ts                   # 25 modules + conditional PaymentsModule (ENABLE_V2_PAYMENTS)
│   ├── core/                           # config, database, filters, guards, health, interceptors, metrics, middleware, redis, security
│   ├── workers/                        # WorkerService (BullMQ + Redis-locked intervals), OutboxPublisherProcessor, NotificationProcessor, ListingExpiry, MediaCleanup, PaymentReconciliation
│   └── modules/
│       ├── activity-hub/               # ActivityHubController, ActivityHubService, GetActivityHubQueryDto
│       ├── favorites/                  # FavoritesController, FavoritesService, DTOs
│       ├── bookings/                   # BookingsController, BookingsService, bookings-state-machine.ts, enums, DTOs
│       ├── rfq/                        # RfqController, RfqService, rfq-state-machine.ts, enums, DTOs
│       ├── cart/                       # CartController, CartService, DTOs
│       ├── notifications/              # NotificationsController, NotificationsService, DTOs
│       ├── auth/ & admin-auth/         # Separate mobile JWT (User) vs enterprise admin JWT (StaffUser)
│       ├── payments/                   # V2 promotion packages (Paymob), feature-flagged
│       └── [17 other domain modules]   # accounts, admin-operations, categories, chat, email, home, listings, locations, media, moderation, platform-settings, quotas, search, staff, users, video
└── test/                               # 9 E2E spec files including activity-hub.e2e-spec.ts
```

---

## 5. Feature-by-Feature Implementation Status

| # | Feature / Module | Status | Evidence (Files & Symbols) | Key Gaps / Violations |
|---|---|---|---|---|
| 1 | **System Architecture & Modular Monolith** | `IMPLEMENTED` | `src/main.ts`, `src/app.module.ts`, `src/modules/activity-hub/activity-hub.module.ts` | Clean DI; minor cross-module DTO coupling (`RfqController` imports `CancelBookingDto`). |
| 2 | **Database Schema & Migrations** | `PARTIALLY_IMPLEMENTED` | `prisma/schema.prisma:812-958`, `prisma/migrations/20261121213256_add_activity_hub_domains/migration.sql` | Schema & migration valid and applied; missing FK on `rfq_requests.accepted_quotation_id` and `bookings.cancelled_by_user_id`; `migration.sql` also alters `payments.id` default and PostGIS defaults. |
| 3 | **Favorites — CRUD, Search, Pagination, Aliases** | `IMPLEMENTED_BUT_INCORRECT` | `src/modules/favorites/favorites.controller.ts`, `favorites.service.ts` | `getFavoriteStatus` returns `isListingAvailable: false` for all non-favorited listings (`favorites.service.ts:220-256`). `getFavoritesCount` ignores `availabilityStatus` while `getMyFavorites` filters it by default. Double-wrapped `success` in mutation responses. |
| 4 | **Favorites — Unavailability Push Notifications** | `NOT_IMPLEMENTED` | `docs/activity-hub-backend/14-known-limitations.md:7-8`, `src/modules/listings/listings.service.ts` | Explicitly deferred in `14-known-limitations.md`; not hooked into listing status mutations. |
| 5 | **Bookings — Creation, Listing Derivation, Listing/Provider Queries** | `PARTIALLY_IMPLEMENTED` | `src/modules/bookings/bookings.controller.ts`, `bookings.service.ts:126-382` | Self-booking check misses `AccountMember`s; `bookingType` not validated against listing category; direct bookings have `categoryId = null`; Egypt DST ignored (`+02:00` hardcoded). |
| 6 | **Bookings — State Machine & Concurrency** | `IMPLEMENTED_BUT_INCORRECT` | `src/modules/bookings/bookings-state-machine.ts`, `bookings.service.ts:410-593` | TOCTOU race condition: `booking` is read and `assertValidBookingTransition` is called **outside** `$transaction`; `cancelBooking` does not use `Serializable` isolation or optimistic `where: { id, status }`. |
| 7 | **Bookings — Provider & Admin Authorization** | `IMPLEMENTED_BUT_INCORRECT` | `src/modules/bookings/bookings.service.ts:61-86`, `bookings.controller.ts:35` | Provider account owner/member check works; `SUPER_ADMIN` / `MODERATOR` check is unreachable behind mobile-only `JwtAuthGuard`. |
| 8 | **RFQ — Creation, Listing & Filtering** | `IMPLEMENTED_BUT_INCORRECT` | `src/modules/rfq/rfq.controller.ts:42-93`, `rfq.service.ts:114-364` | **CRITICAL:** `getRfqs` with `scope=open_for_suppliers&status=DRAFT` overwrites the open-status filter and leaks other users' private RFQs (`rfq.service.ts:248-255`). Draft RFQs cannot be submitted or edited. No `@Max` on decimal `quantity`. `cancelRfq` has no admin override and emits no notification. |
| 9 | **RFQ — Quotations, Pricing, Comparison & Status Transitions** | `IMPLEMENTED_BUT_INCORRECT` | `src/modules/rfq/rfq.controller.ts:95-159`, `rfq.service.ts:366-706` | Server-side pricing works; however: TOCTOU race on `ACCEPTED` allows two quotations to be accepted simultaneously; `UpdateQuotationStatusDto` allows `EXPIRED`/`SUBMITTED`; `dto.reason` is ignored; `validUntil` & `expiresAt` are never checked; `isSupplierAccountMember` allows `lister` role to withdraw; `GET /rfqs/:id/quotations` is unpaginated with unvalidated `sortBy`. |
| 10 | **RFQ & Quotation Expiration Worker** | `NOT_IMPLEMENTED` | `src/workers/worker.service.ts`, `src/modules/rfq/rfq-state-machine.ts` | `EXPIRED` status and `expiresAt`/`validUntil` columns exist, but no background processor expires stale RFQs or quotations. |
| 11 | **Cart — V1 Saved Product Basket** | `IMPLEMENTED_BUT_INCORRECT` | `src/modules/cart/cart.controller.ts`, `cart.service.ts` | V1 boundary respected (`commerceMode: 'V1_SAVED_BASKET'`, `checkoutSupported: false`, no checkout/orders). **Bugs:** `CartController.getCart` has no query DTO validation (`limit` unbounded, `categoryId` unvalidated UUID); `estimatedSubtotal` sums only current page; `addItem` has non-atomic `findUnique` + `create` race condition; `getCartItemsCount` filters `deletedAt`/`published` while `getCart` does not. |
| 12 | **V1 Commerce Boundary (`PaymentsModule`)** | `PARTIALLY_IMPLEMENTED` | `src/app.module.ts:38,74`, `src/core/config/env.config.ts:314` | `AppModule` correctly checks `process.env.ENABLE_V2_PAYMENTS === 'true'`, but `env.config.ts:314` uses `z.coerce.boolean()` which evaluates `"false"` to `true`. |
| 13 | **Activity Hub Aggregation API** | `PARTIALLY_IMPLEMENTED` | `src/modules/activity-hub/activity-hub.controller.ts`, `activity-hub.service.ts` | Parallel `Promise.all`, `?include=` selective loading, pagination, and user isolation work. **Gaps:** `summary` counts are unfiltered by `categoryId`/`categorySlug` while sections are filtered; `summary.cartItemsCount` and `summary.favoritesCount` use different predicates than section `pagination.total`. |
| 14 | **Notifications & Transactional Outbox** | `PARTIALLY_IMPLEMENTED` | `src/workers/outbox-publisher.processor.ts`, `notification.processor.ts`, `src/modules/notifications/` | CRUD, read/unread, pagination, device tokens, and Outbox relay work. **Gaps:** No notification preferences model/API; no Outbox retry/backoff or stuck `PROCESSING` recovery; FCM OAuth token minted per push without caching or fetch timeout; `NotificationProcessor` treats `{ success: false, sentCount: 0 }` as success. |
| 15 | **Security, Validation & Rate Limiting** | `IMPLEMENTED_BUT_INCORRECT` | `src/main.ts`, `src/core/guards/rate-limit.guard.ts`, `src/modules/auth/`, `src/modules/admin-auth/` | Global `ValidationPipe`, Helmet, CORS, `ParseUUIDPipe`, and `RateLimitGuard` are solid. Broken by `RfqService.getRfqs` data leak, unvalidated `CartController.getCart` query params, and broken admin auth on Activity Hub endpoints. |
| 16 | **Deployment, Health & Migrations** | `CONFLICT` | `Dockerfile:53`, `docker-compose.yml:64,97`, `scripts/migrate-deploy.js:223-286`, `src/core/health/health.controller.ts` | Health checks (`live`/`ready`) and `migrate-deploy.js` safety checks are strong, **but** `docker-compose.yml` routes both `api` and `worker` startup migrations through PgBouncer in `transaction` mode. |

---

## 6. Database Comparison

Comparison of `prisma/schema.prisma` + `prisma/migrations/20261121213256_add_activity_hub_domains/migration.sql` against `docs/activity-hub-backend/02-database-design.md` and `13-deployment-and-migrations.md`:

| Model / Table | Documented (`02-database-design.md`) | Actual (`schema.prisma` & `migration.sql`) | Discrepancies & Risks |
|---|---|---|---|
| `Favorite` (`favorites`) | Existing table + `@@index([listingId])` (`favorites_listing_id_idx`) + `uq_user_favorite` | Exact match (`schema.prisma:410-423`, `migration.sql:180`). | None. |
| `Booking` (`bookings`) | 20 fields, unique `reference`, 4 composite/single indexes | Exact match (`schema.prisma:812-844`, `migration.sql:15-38,129-141`). | **MEDIUM:** `cancelledByUserId` has no FK to `users(id)` (referential integrity not enforced at DB level). No DB-level partial unique index preventing two `CONFIRMED` bookings for the same `(provider_account_id, scheduled_at)` — relies solely on app-level Serializable transactions. |
| `RfqRequest` (`rfq_requests`) | 15 fields, unique `reference`, indexes on `(user_id, status, created_at DESC)`, `(status, created_at DESC)`, `(category_id)` | Exact match (`schema.prisma:846-873`, `migration.sql:41-60,144-153`). | **MEDIUM:** `acceptedQuotationId` has no FK to `quotations(id)` and no `UNIQUE` constraint. No index on `(status, expires_at)` for future expiry worker scans. |
| `RfqItem` (`rfq_items`) | 8 fields, `rfq_id` cascade delete, `listing_id` set null | Exact match (`schema.prisma:875-891`, `migration.sql:63-74,156`). | None. |
| `Quotation` (`quotations`) | 14 fields, `uq_rfq_supplier_quotation` on `(rfq_id, supplier_account_id)` | Exact match (`schema.prisma:893-918`, `migration.sql:77-94,159-165`). | **LOW:** Missing index on `(status, valid_until)` for future expiry worker; missing `rejectionReason`/`statusReason` column despite `UpdateQuotationStatusDto.reason`. |
| `QuotationItem` (`quotation_items`) | 9 fields, `quotation_id` cascade delete, `rfq_item_id` set null | Exact match (`schema.prisma:920-936`, `migration.sql:97-109,168`). | None. |
| `CartItem` (`cart_items`) | 11 fields, `uq_cart_user_listing_variant` on `(user_id, listing_id, variant_key)` | Exact match (`schema.prisma:938-958`, `migration.sql:112-126,171-177`). | None. |
| **Unmentioned `ALTER TABLE`s in `migration.sql`** | Doc says "Purely additive (`CREATE TABLE`, `CREATE INDEX`, `ADD CONSTRAINT`)" and "creates 5 new tables" | `migration.sql:1-12` also runs `ALTER TABLE` on `areas`, `branches`, `listings` (PostGIS defaults) and `ALTER TABLE "payments" ALTER COLUMN "id" DROP DEFAULT;`, and creates **6** new tables. | **LOW/MEDIUM:** `ALTER TABLE` on high-traffic `listings` acquires an `ACCESS EXCLUSIVE` lock briefly during deploy; `payments.id DROP DEFAULT` is harmless only because Prisma supplies UUIDs client-side, but breaks raw SQL inserts into `payments`. |

---

## 7. API Contract Comparison

Comparison of `docs/activity-hub-backend/11-api-contracts.md` against actual NestJS controllers and DTOs:

| Endpoint | Documented Contract | Actual Implementation | Status | Mismatch Details |
|---|---|---|---|---|
| `GET /api/v1/activity-hub` | `?include=&page=1&limit=10&categoryId=&categorySlug=` | `ActivityHubController.getActivityHub` (`GetActivityHubQueryDto`) | `IMPLEMENTED` | Matches contract. |
| `GET /api/v1/favorites` & `GET /api/v1/listings/favorites` | `?page=1&limit=20&categoryId=&categorySlug=&search=&includeUnavailable=false` | `FavoritesController.getMyFavorites` / `getMyFavoritesAlias` (`GetFavoritesQueryDto`) | `IMPLEMENTED` | Matches contract. |
| `POST /api/v1/favorites` | Body `{ listingId }` | `FavoritesController.addFavoriteBody` (`@HttpCode(200)`) | `PARTIALLY_IMPLEMENTED` | Returns `{ success: true, data: { success: true, favoriteId, listingId, isFavorite } }` (double `success`). |
| `POST /api/v1/favorites/:listingId` | Path UUID | `FavoritesController.addFavorite` (`@HttpCode(200)`) | `PARTIALLY_IMPLEMENTED` | Same double `success` nesting. |
| `GET /api/v1/favorites/:listingId/status` | `{ listingId, isFavorite, favoriteId, savedAt, isListingAvailable }` | `FavoritesController.getFavoriteStatus` | `IMPLEMENTED_BUT_INCORRECT` | `isListingAvailable` is always `false` when `isFavorite` is `false`. |
| `DELETE /api/v1/favorites/:listingId` | Path UUID | `FavoritesController.removeFavorite` | `IMPLEMENTED` | Idempotent; double `success` nesting. |
| `POST /api/v1/listings/:listingId/favorite` | Mobile toggle alias | `FavoritesController.toggleFavoriteAlias` | `IMPLEMENTED` | Preserved; double `success` nesting. |
| `POST /api/v1/bookings` | Body `CreateBookingDto`, `@RateLimit(15, 60)` | `BookingsController.createBooking` (`@HttpCode(201)`) | `PARTIALLY_IMPLEMENTED` | `providerAccountId` is silently ignored rather than rejected when `listingId` is provided (contradicts `09-security-permissions.md`). |
| `GET /api/v1/bookings` | `?page=1&limit=20&status=&bookingType=&categoryId=&categorySlug=&role=requester\|provider` | `BookingsController.getBookings` (`GetBookingsQueryDto`) | `IMPLEMENTED` | Matches contract. |
| `GET /api/v1/bookings/:id` | Path UUID | `BookingsController.getBookingById` | `IMPLEMENTED` | Matches contract (admin JWT broken). |
| `PATCH /api/v1/bookings/:id/cancel` | Body `{ reason? }` | `BookingsController.cancelBooking` (`CancelBookingDto`) | `IMPLEMENTED` | Matches contract. |
| `PATCH /api/v1/bookings/:id/status` | Body `{ status: CONFIRMED\|REJECTED\|COMPLETED, reason? }` | `BookingsController.updateBookingStatus` (`UpdateBookingStatusDto`) | `PARTIALLY_IMPLEMENTED` | DTO uses `@IsEnum(BookingStatus)` (includes `PENDING` & `CANCELLED`), rejected at service layer instead of DTO layer. |
| `POST /api/v1/rfqs` | Body `CreateRfqDto`, `@RateLimit(10, 60)` | `RfqController.createRfq` (`@HttpCode(201)`) | `IMPLEMENTED` | Matches contract. |
| `GET /api/v1/rfqs` | `?page=1&limit=20&status=&categoryId=&categorySlug=&scope=mine\|open_for_suppliers` | `RfqController.getRfqs` (`GetRfqsQueryDto`) | `IMPLEMENTED_BUT_INCORRECT` | `scope=open_for_suppliers&status=DRAFT` leaks private RFQs. |
| `GET /api/v1/rfqs/:id` | Path UUID | `RfqController.getRfqById` | `IMPLEMENTED` | Matches contract. |
| `PATCH /api/v1/rfqs/:id/cancel` | Body `{ reason? }` | `RfqController.cancelRfq` (`CancelBookingDto`) | `PARTIALLY_IMPLEMENTED` | Reuses `CancelBookingDto` (Swagger doc says "booking"). |
| `POST /api/v1/rfqs/:id/quotations` | Body `CreateQuotationDto`, `@RateLimit(15, 60)` | `RfqController.submitQuotation` (`@HttpCode(201)`) | `IMPLEMENTED` | Matches contract. |
| `GET /api/v1/rfqs/:id/quotations` | `?sortBy=totalAmount\|estimatedDeliveryDays\|createdAt` | `RfqController.getQuotationsForRfq` | `PARTIALLY_IMPLEMENTED` | `sortBy` is not validated via DTO (`@Query('sortBy')`); unpaginated array response. |
| `GET /api/v1/quotations/:id` | Path UUID | `RfqController.getQuotationById` | `IMPLEMENTED` | Matches contract. |
| `PATCH /api/v1/quotations/:id/status` | Body `{ status: SHORTLISTED\|ACCEPTED\|REJECTED\|WITHDRAWN, reason? }` | `RfqController.updateQuotationStatus` (`UpdateQuotationStatusDto`) | `IMPLEMENTED_BUT_INCORRECT` | `@IsEnum(QuotationStatus)` permits `EXPIRED` and `SUBMITTED`; `EXPIRED` actually succeeds via state machine! `reason` is accepted and silently dropped. |
| `GET /api/v1/cart` | `?page=1&limit=20&categoryId=&categorySlug=` | `CartController.getCart` | `IMPLEMENTED_BUT_INCORRECT` | No DTO validation on query params (`page`, `limit`, `categoryId`, `categorySlug`). |
| `POST /api/v1/cart/items` | Body `AddCartItemDto` | `CartController.addItem` (`@HttpCode(201)`) | `IMPLEMENTED` | Matches contract. |
| `PATCH /api/v1/cart/items/:id` | Body `UpdateCartItemDto` | `CartController.updateItem` | `IMPLEMENTED` | Matches contract. |
| `DELETE /api/v1/cart/items/:id` & `DELETE /api/v1/cart` | Path UUID / clear all | `CartController.removeItem` / `clearCart` | `IMPLEMENTED` | Matches contract (double `success` nesting). |

---

## 8. Security Assessment

| ID | Finding | Severity | Location | Evidence & Impact |
|---|---|---|---|---|
| **SEC-01** | **IDOR / Private RFQ Data Leak via `status` Filter Override** | **CRITICAL** | `src/modules/rfq/rfq.service.ts:244-257` | In `scope === 'open_for_suppliers'`, spreading `...(query.status ? { status: query.status } : {})` overwrites `status: { in: [SUBMITTED, UNDER_REVIEW, QUOTATIONS_RECEIVED] }`. Any authenticated user can request `GET /api/v1/rfqs?scope=open_for_suppliers&status=DRAFT` (or `CANCELLED`/`ACCEPTED`) and read all other users' private draft RFQs, delivery addresses, notes, and image URLs. |
| **SEC-02** | **Unvalidated Query Parameters on `GET /api/v1/cart`** | **HIGH** | `src/modules/cart/cart.controller.ts:50-63` | Raw `@Query('limit')` allows `limit=1000000` (memory/DB DoS) or negative/NaN values (`take: NaN` / `-1` crashing Prisma). Raw `@Query('categoryId')` bypasses UUID validation. Raw query params also bypass `forbidNonWhitelisted`. |
| **SEC-03** | **Broken Enterprise Admin / Moderator Authorization** | **HIGH** | `src/modules/bookings/bookings.controller.ts:35`, `bookings.service.ts:66`, `src/modules/rfq/rfq.controller.ts:37`, `rfq.service.ts:322,542,605`, `src/modules/auth/strategies/jwt.strategy.ts:30-75`, `src/modules/admin-auth/guards/admin-jwt-auth.guard.ts:49-106` | `JwtAuthGuard` only accepts mobile tokens (`audience: 'deal-one-mobile'`, `User` table which has no `role` column). Real staff admins authenticate via `AdminAuthModule` (`audience: 'deal-one-admin'`, `StaffUser` table) and receive 401 on all Bookings/RFQ endpoints. Furthermore, `cancelRfq` and `updateQuotationStatus` do not even check `userRole`, contradicting `09-security-permissions.md`. |
| **SEC-04** | **Unauthorized `EXPIRED` State Manipulation on Quotations** | **HIGH** | `src/modules/rfq/dto/update-quotation-status.dto.ts:14`, `src/modules/rfq/rfq.service.ts:643-658` | `UpdateQuotationStatusDto` validates `@IsEnum(QuotationStatus)` instead of restricting to `[SHORTLISTED, ACCEPTED, REJECTED, WITHDRAWN]`. An RFQ owner can send `{ "status": "EXPIRED" }` and illegally expire a valid supplier quotation. |
| **SEC-05** | **Self-Booking & Self-Cart Bypass via `AccountMember`** | **MEDIUM** | `src/modules/bookings/bookings.service.ts:179-183,204-208`, `src/modules/cart/cart.service.ts:187-191` | Only `account.ownerUserId === userId` is checked. A company `manager` or `responder` in `AccountMember` can book their own account's listing and then confirm/complete it via `PATCH /bookings/:id/status`. |
| **SEC-06** | **Over-Permissive Supplier Role Check on Quotation Withdrawal** | **MEDIUM** | `src/modules/rfq/rfq.service.ts:96-112,638-648` | `resolveAuthorizedSupplierAccount` restricts quotation submission to `['owner', 'manager', 'responder']`, but `isSupplierAccountMember` omits the role filter — allowing a `lister`-role member to withdraw quotations. |
| **SEC-07** | **Decimal Overflow Unhandled 500 on RFQ/Quotation Amounts** | **MEDIUM** | `src/modules/rfq/dto/create-rfq.dto.ts:41-45`, `create-quotation.dto.ts:35-51,70-75` | `quantity`, `unitPrice`, and `deliveryFee` lack `@Max(...)` bounds. Values exceeding PostgreSQL `DECIMAL(12,3)` / `DECIMAL(14,2)` trigger unhandled Prisma/Postgres numeric overflow errors (500). |
| **SEC-08** | **Positive Security Controls Verified** | INFO | `src/main.ts`, `src/core/config/env.config.ts`, `src/core/guards/rate-limit.guard.ts` | Global `ValidationPipe` (`whitelist`, `forbidNonWhitelisted`, `transform`), Helmet, strict prod CORS & secret entropy checks, `TRUST_PROXY=true` ban, `ParseUUIDPipe`, user-scoped `RateLimitGuard`, server-side pricing for Cart & Quotations, and sanitized `HttpExceptionFilter` (no SQL/stack leaks) are all properly implemented. |

---

## 9. Performance Assessment

| Area | Assessment | Evidence | Severity |
|---|---|---|---|
| **Database Indexing** | Composite indexes on `bookings`, `rfq_requests`, `quotations`, `cart_items`, and `favorites(listing_id)` match primary query patterns. Missing indexes for future expiry scans: `rfq_requests(status, expires_at)` and `quotations(status, valid_until)`. | `prisma/schema.prisma:839-957` | `LOW` |
| **N+1 Queries** | No N+1 queries found in Activity Hub, Bookings, RFQ, Cart, or Favorites; all list queries use Prisma `include`/`select` and `_count`. | `bookings.service.ts:88-124`, `rfq.service.ts:266-278`, `favorites.service.ts:118-158`, `cart.service.ts:55-91` | Pass |
| **Unbounded List & Pagination Bugs** | (1) `CartController.getCart` has no `limit` max cap (DoS risk). (2) `GET /rfqs/:id/quotations` (`rfq.service.ts:557-572`) returns all quotations with nested `items` without pagination. | `cart.controller.ts:53,59`, `rfq.service.ts:557-572` | `HIGH` / `MEDIUM` |
| **Activity Hub Query Count** | Default `GET /activity-hub` (all 4 sections) executes **12 concurrent Prisma queries** (4 `count`s + 4 section `count`s + 4 `findMany`s) via `Promise.all`. With `DATABASE_CONNECTION_LIMIT=10` (`docker-compose.yml:66`), a single request can saturate a pod's Prisma pool if multiple users hit `/activity-hub` concurrently. | `activity-hub.service.ts:38-86`, `docker-compose.yml:66` | `MEDIUM` |
| **FCM OAuth Token Minting & Timeouts** | `NotificationsService.mintGoogleAccessToken()` (`notifications.service.ts:254-290`) makes an HTTP call to `oauth2.googleapis.com/token` on **every single push notification** without caching the 1-hour access token and without a `fetch` timeout (`AbortSignal.timeout`). | `src/modules/notifications/notifications.service.ts:128-146,254-290` | `MEDIUM` |
| **Cache Safety** | Verified: mutable per-user private Activity Hub data is not cached in shared Redis keys, preventing cross-user leaks and stale statuses. | `activity-hub.service.ts`, `bookings.service.ts`, `rfq.service.ts`, `cart.service.ts`, `favorites.service.ts` | Pass |

---

## 10. Testing Results

All safe read-only and local test verification commands were executed on **2026-11-22**:

| Check | Exact Command Executed | Result | Details |
|---|---|---|---|
| **Prisma Schema Validation** | `npx prisma validate` | **PASSED** | `The schema at prisma/schema.prisma is valid` |
| **TypeScript Typecheck** | `npx tsc --noEmit` | **PASSED** | 0 errors |
| **Production Build** | `npm run build` (`nest build`) | **PASSED** | 0 errors |
| **ESLint (Read-Only, no `--fix`)** | `npx eslint "{src,apps,libs,test}/**/*.ts"` | **PASSED (with warnings)** | 0 errors, **10 warnings** (`@typescript-eslint/no-unused-vars`, including unused `crypto` in `test/activity-hub.e2e-spec.ts:7`). Note: TypeScript `5.9.3` is newer than `@typescript-eslint/typescript-estree` supported `<5.6.0`. |
| **Prisma Migration Status** | `npx prisma migrate status` | **PASSED** | 10 migrations found; `Database schema is up to date!` (against local `localhost:5432/marketspace`) |
| **Full Unit Test Suite** | `npx jest --runInBand` | **PASSED (open handles)** | **45/45 suites passed, 282/282 tests passed** (5.02s). Jest reported open async handles and did not exit cleanly without `--forceExit`. |
| **Activity Hub E2E Suite** | `npx jest --config ./test/jest-e2e.json test/activity-hub.e2e-spec.ts --forceExit` | **PASSED** | **1/1 suite passed, 6/6 tests passed** (5.36s). |

### Missing Test Coverage Identified
- No tests for `GET /rfqs?scope=open_for_suppliers&status=DRAFT` (would have caught **SEC-01**).
- No concurrency tests for simultaneous `updateBookingStatus` / `cancelBooking`, simultaneous `updateQuotationStatus(ACCEPTED)`, or simultaneous `CartService.addItem`.
- No controller/DTO validation tests for `CartController.getCart`, `UpdateQuotationStatusDto` (`EXPIRED`), or `RfqController.getQuotationsForRfq` (`sortBy`).
- No test for `FavoritesService.getFavoriteStatus` when the listing is **not** favorited (would have caught `isListingAvailable: false` bug).
- No test for `AccountMember` self-booking or `lister` withdrawing a quotation.
- No test for `AdminJwtAuthGuard` / staff access to Bookings and RFQs.

---

## 11. Production Readiness Assessment

| Dimension | Status | Assessment |
|---|---|---|
| **Security** | **BLOCKED** | **SEC-01** (private DRAFT RFQ leak) and **SEC-02** (unbounded cart pagination/DoS) must be fixed before production launch. |
| **Data Integrity & Concurrency** | **BLOCKED** | TOCTOU race conditions in Bookings (`cancelBooking`, `updateBookingStatus`) and RFQ (`updateQuotationStatus` double-accept) can corrupt state under concurrent mobile/provider traffic. |
| **Deployment & Migrations** | **BLOCKED** | `Dockerfile:53` runs `node scripts/migrate-deploy.js` on startup for both `api` and `worker` containers, while `docker-compose.yml:64,97` points `DATABASE_URL` at **PgBouncer (`POOL_MODE: transaction`)**. Session-level `pg_advisory_lock` and `prisma migrate deploy` are incompatible with transaction pooling and risk hanging/failing deployments. |
| **Configuration Safety** | **AT RISK** | `env.config.ts:314` uses `z.coerce.boolean()` for `ENABLE_V2_PAYMENTS`, turning `"false"` into `true` in `ConfigService`. |
| **Reliability & Observability** | **NEEDS HARDENING** | Health probes (`/health/live`, `/health/ready`), Prometheus `/metrics`, structured logging, and `OutboxPublisherProcessor` are in place, but Outbox lacks retry/DLQ/stuck-row recovery, and FCM calls lack token caching and HTTP timeouts. |
| **Overall Verdict** | **NOT PRODUCTION-READY** | Requires completion of **Phase 0** and **Phase 1** before deploying Activity Hub to production. |

---

## 12. Documentation Contradictions

1. **`00-audit-report.md` vs. `01`–`14` and Actual Codebase:** `00-audit-report.md` still reports Bookings, RFQ, Cart, and Activity Hub as *"Missing entirely"* and cites 9 migrations / 41 test suites, whereas `01`–`14` and the codebase reflect the post-implementation state (10 migrations, 45 test suites).
2. **`02-database-design.md` & `13-deployment-and-migrations.md` vs. `migration.sql`:** `02-database-design.md:5` states the migration *"creates 5 new tables"* (it actually creates **6**: `bookings`, `rfq_requests`, `rfq_items`, `quotations`, `quotation_items`, `cart_items`), and `13-deployment-and-migrations.md:7` states it is *"Purely additive (`CREATE TABLE`, `CREATE INDEX`, `ADD CONSTRAINT`)"* while `migration.sql:1-12` also runs `ALTER TABLE` on `areas`, `branches`, `listings`, and `payments` (`DROP DEFAULT`).
3. **`09-security-permissions.md` vs. `CreateBookingDto`:** `09-security-permissions.md:8` claims `ValidationPipe` rejects client-supplied `providerAccountId` when `listingId` is present. In `create-booking.dto.ts:28-30`, `@ValidateIf((o) => !o.listingId)` causes `providerAccountId` to be accepted and silently ignored instead of rejected.
4. **`09-security-permissions.md` vs. `RfqService` & `AdminAuthModule`:** `09-security-permissions.md:13-14` states `MODERATOR`/`SUPER_ADMIN` can manage bookings, cancel RFQs, and shortlist/accept/reject quotations. In reality: (a) `RfqService.cancelRfq` and `RfqService.updateQuotationStatus` never check `userRole`; (b) `JwtAuthGuard` rejects real `AdminAuthModule` staff JWTs.
5. **`04-bookings-module.md` & `10-performance.md` vs. `BookingsService`:** Docs claim concurrency protection via `Serializable` transactions, but `cancelBooking` uses default isolation and both `cancelBooking` and `updateBookingStatus` perform state validation outside the transaction.
6. **`05-rfq-module.md` vs. `11-api-contracts.md` & `RfqController`:** `05-rfq-module.md:6-7` defines `DRAFT -> SUBMITTED`, `UNDER_REVIEW`, and `EXPIRED` transitions, none of which have endpoints or worker jobs.
7. **`00-audit-report.md` vs. `03-favorites-module.md`:** `00-audit-report.md:38` says to validate `availabilityStatus === 'available'`, whereas `03-favorites-module.md:7` and `favorites.service.ts:34-41` intentionally omit `availabilityStatus` on `addFavorite` (allowing favoriting reserved/sold items if published & approved). Needs explicit product decision.

---

## 13. Missing Implementations

1. **Draft RFQ Submission & Update Endpoints:** No `PATCH /api/v1/rfqs/:id` or `PATCH /api/v1/rfqs/:id/submit` exists; RFQs created with `isDraft: true` cannot be submitted.
2. **RFQ & Quotation Expiration Worker:** No scheduled processor transitions expired `RfqRequest` (`expiresAt < now`) or `Quotation` (`validUntil < now`) rows to `EXPIRED`.
3. **Notification Preferences:** No `NotificationPreference` model, service, or endpoints exist (only in-app notifications + FCM device token registration).
4. **Favorite Unavailability Notifications:** Not hooked into `ListingsService` status/delete mutations (acknowledged in `14-known-limitations.md`).
5. **RFQ Cancellation Notifications to Suppliers:** `RfqService.cancelRfq` does not enqueue `OutboxEvent` notifications to suppliers who already submitted quotations.
6. **Outbox Retry & Stuck-Event Recovery:** No retry counter, exponential backoff, DLQ alerting, or stale `PROCESSING` sweeper in `OutboxPublisherProcessor`.
7. **Admin Support for Activity Hub Domains:** No `AdminOperations` endpoints or dual-auth guard allowing `StaffUser` admins/moderators to inspect or intervene on Bookings/RFQs.

---

## 14. Critical Bugs and Risks

| ID | Bug / Risk | Severity | File & Line |
|---|---|---|---|
| **BUG-01** | `RfqService.getRfqs` overwrites `status: { in: [...] }` when `query.status` is passed with `scope=open_for_suppliers`, leaking other users' `DRAFT`/`CANCELLED`/`ACCEPTED` RFQs. | **CRITICAL** | `src/modules/rfq/rfq.service.ts:244-257` |
| **BUG-02** | `Dockerfile` runs `scripts/migrate-deploy.js` (session-level `pg_advisory_lock` + `prisma migrate deploy`) against PgBouncer `POOL_MODE: transaction` in `docker-compose.yml` on both `api` and `worker` startup. | **CRITICAL** | `Dockerfile:53`, `docker-compose.yml:64,97`, `scripts/migrate-deploy.js:223-286` |
| **BUG-03** | TOCTOU race condition in `BookingsService.updateBookingStatus` and `cancelBooking` (reads and validates status outside `$transaction`; `cancelBooking` not Serializable). | **HIGH** | `src/modules/bookings/bookings.service.ts:416-477,492-584` |
| **BUG-04** | TOCTOU race condition in `RfqService.updateQuotationStatus` allows two concurrent `ACCEPTED` calls on different quotations to both succeed and corrupt `rfq_requests.accepted_quotation_id`. | **HIGH** | `src/modules/rfq/rfq.service.ts:625-705` |
| **BUG-05** | `CartController.getCart` uses raw `@Query()` params without DTO validation (unbounded `limit` DoS, invalid UUID `categoryId`, `NaN`/negative `page`/`limit`). | **HIGH** | `src/modules/cart/cart.controller.ts:50-63` |
| **BUG-06** | `UpdateQuotationStatusDto` allows `EXPIRED` and `SUBMITTED`, enabling RFQ owner to forcibly expire a supplier quotation; `dto.reason` is silently dropped. | **HIGH** | `src/modules/rfq/dto/update-quotation-status.dto.ts:14`, `rfq.service.ts:657-673` |
| **BUG-07** | `RfqService.submitQuotation` and `updateQuotationStatus` ignore `rfq.expiresAt` and `quotation.validUntil`, allowing quotes on expired RFQs and acceptance of expired quotations. | **HIGH** | `src/modules/rfq/rfq.service.ts:386-396,657-661` |
| **BUG-08** | `env.config.ts` uses `z.coerce.boolean()` for `ENABLE_V2_PAYMENTS` (`"false"` coerces to `true`). | **HIGH** | `src/core/config/env.config.ts:314` |
| **BUG-09** | `FavoritesService.getFavoriteStatus` returns `isListingAvailable: false` for all non-favorited listings because it only queries `prisma.favorite.findUnique`. | **MEDIUM** | `src/modules/favorites/favorites.service.ts:220-256` |
| **BUG-10** | `CartService.getCart` computes `estimatedSubtotal` from only the paginated slice (`mapped`) rather than the entire basket, and hardcodes `currency: 'EGP'`. | **MEDIUM** | `src/modules/cart/cart.service.ts:128-140` |
| **BUG-11** | `CartService.addItem` uses non-atomic `findUnique` + `create`/`update` instead of `upsert` / `P2002` handling. | **MEDIUM** | `src/modules/cart/cart.service.ts:196-231` |
| **BUG-12** | Activity Hub `summary.favoritesCount` and `summary.cartItemsCount` use different filters than `favorites.pagination.total` and `cart.pagination.total` (and ignore `categoryId`/`categorySlug`). | **MEDIUM** | `favorites.service.ts:102-110,204-215`, `cart.service.ts:48-51,152-162`, `activity-hub.service.ts:38-86` |
| **BUG-13** | `NotificationProcessor` returns `true` even when `sendPushNotification` returns `{ success: false, sentCount: 0 }`, causing `OutboxPublisherProcessor` to mark failed pushes `PUBLISHED`. | **MEDIUM** | `src/workers/notification.processor.ts:28-34`, `notifications.service.ts:154-155` |
| **BUG-14** | `BookingsService.parseAndValidateSlot` hardcodes `+02:00` instead of IANA `Africa/Cairo`, causing a 1-hour offset error during Egypt Daylight Saving Time (`+03:00`). | **MEDIUM** | `src/modules/bookings/bookings.service.ts:47` |

---

## 15. Recommended Fixes

1. **SEC-01 (`RfqService.getRfqs`):** Restrict `scope === 'open_for_suppliers'` to `OPEN_STATUSES = [SUBMITTED, UNDER_REVIEW, QUOTATIONS_RECEIVED]`; if `query.status` is provided and not in `OPEN_STATUSES`, return empty results or throw `400 BadRequestException` — never overwrite the `in` clause.
2. **BUG-02 (Migrations & PgBouncer):** Introduce `DIRECT_DATABASE_URL` (pointing directly to PostgreSQL port `5432`, bypassing PgBouncer) for `scripts/migrate-deploy.js` and `prisma migrate deploy`, and run migrations as a dedicated one-off release/init job rather than inside both `api` and `worker` `CMD`s.
3. **BUG-03 & BUG-04 (TOCTOU Race Conditions):** Move `findUnique` + `assertValid*Transition` **inside** `Prisma.TransactionIsolationLevel.Serializable` transactions (or use optimistic `updateMany({ where: { id, status: expectedStatus } })`) in `BookingsService.cancelBooking`, `BookingsService.updateBookingStatus`, and `RfqService.updateQuotationStatus`. Also add partial unique DB indexes on `bookings(provider_account_id, scheduled_at) WHERE status = 'CONFIRMED'` and `quotations(rfq_id) WHERE status = 'ACCEPTED'`.
4. **SEC-02 (`CartController.getCart`):** Create `GetCartQueryDto` (`page`, `limit` max 100, `@IsUUID() categoryId`, `categorySlug`) and apply `@Query() query: GetCartQueryDto`.
5. **SEC-04 & BUG-07 (`RfqService`):** Restrict `UpdateQuotationStatusDto.status` to `@IsIn([SHORTLISTED, ACCEPTED, REJECTED, WITHDRAWN])`; enforce `rfq.expiresAt > now` and `quotation.validUntil > now`; persist `reason` (add `status_reason` column or map clearly).
6. **SEC-03 (Admin Authorization):** Decide whether admin moderation of Bookings/RFQs belongs in `AdminOperationsModule` (behind `AdminJwtAuthGuard` + `PermissionsGuard`) and remove dead `userRole` checks from mobile-only controllers, or implement a dual-token guard.
7. **BUG-08 (`env.config.ts`):** Replace `z.coerce.boolean()` on `ENABLE_V2_PAYMENTS` with `boolFlag(false)`.
8. **BUG-09 (`FavoritesService.getFavoriteStatus`):** Query `prisma.listing.findUnique` (or parallel query with `favorite.findUnique`) so `isListingAvailable` reflects true listing availability regardless of favorite state.
9. **BUG-10 & BUG-11 (`CartService`):** Compute `estimatedSubtotal` across all available items in the user's cart (not just current page) and make `addItem` atomic via `upsert` or `P2002` retry.
10. **Outbox & FCM:** Add `retryCount` + `nextRetryAt` + stale `PROCESSING` recovery to `OutboxEvent`/`OutboxPublisherProcessor`; cache Google OAuth2 token in `NotificationsService` for ~50 minutes and add `AbortSignal.timeout(5000)` to `fetch` calls.

---

## 16. Prioritized Implementation Roadmap

### Phase 0: Critical Security & Production Issues (Immediate — Pre-Deploy Blockers)
| Task | Affected Modules | Dependencies | Risks | Acceptance Criteria |
|---|---|---|---|---|
| **P0.1** Fix `RfqService.getRfqs` `open_for_suppliers` status filter override (**SEC-01**) | `src/modules/rfq/` | None | Low | `GET /rfqs?scope=open_for_suppliers&status=DRAFT` never returns other users' drafts; E2E security test added and passing. |
| **P0.2** Add `GetCartQueryDto` validation to `CartController.getCart` (**SEC-02**) | `src/modules/cart/` | None | Low | Invalid `categoryId`, `limit > 100`, `page < 1`, and unknown query params return `400 Bad Request`. |
| **P0.3** Fix `ENABLE_V2_PAYMENTS` parsing in `env.config.ts` (`boolFlag(false)`) (**BUG-08**) | `src/core/config/` | None | Low | `ENABLE_V2_PAYMENTS="false"` parses to `false` in `env.config.spec.ts`. |
| **P0.4** Separate direct DB URL (`DIRECT_DATABASE_URL`) for `migrate-deploy.js` & decouple migration from `worker` startup (**BUG-02**) | `Dockerfile`, `docker-compose.yml`, `scripts/migrate-deploy.js`, `prisma/schema.prisma` | Ops / env var alignment | Medium (deploy pipeline change) | Migrations run directly against PostgreSQL (never PgBouncer transaction pool) once per deploy; `migrate-deploy.spec.ts` updated. |
| **P0.5** Restrict `UpdateQuotationStatusDto` enum (`@IsIn`) and add `@Max` bounds on RFQ/Quotation decimals (**SEC-04**, **SEC-07**) | `src/modules/rfq/` | None | Low | `PATCH /quotations/:id/status` rejects `EXPIRED`/`SUBMITTED` with `400`; huge decimal values return `400` instead of `500`. |

### Phase 1: Architecture & Database Corrections
| Task | Affected Modules | Dependencies | Risks | Acceptance Criteria |
|---|---|---|---|---|
| **P1.1** Fix TOCTOU race conditions in `BookingsService` (`cancelBooking`, `updateBookingStatus`) and `RfqService` (`updateQuotationStatus`) (**BUG-03**, **BUG-04**) | `src/modules/bookings/`, `src/modules/rfq/` | None | Medium (Serializable retry handling) | All status reads + transition assertions happen inside `Serializable` tx; concurrent double-accept or confirm+cancel returns `409 Conflict` / `400` cleanly. |
| **P1.2** Additive DB hardening migration: FKs on `bookings.cancelled_by_user_id` & `rfq_requests.accepted_quotation_id`, partial unique indexes (`CONFIRMED` booking slot, `ACCEPTED` quotation), expiry indexes, and `quotations.status_reason` | `prisma/` | P1.1 | Low (additive) | `prisma migrate deploy` succeeds cleanly; DB enforces single confirmed slot and single accepted quotation. |
| **P1.3** Resolve Admin/Moderator authorization architecture for Bookings & RFQs (**SEC-03**) | `src/modules/bookings/`, `src/modules/rfq/`, `src/modules/admin-operations/` | Product decision on admin routes | Medium | Staff admins authenticated via `AdminAuthModule` can manage Bookings/RFQs via dedicated admin endpoints (or dual guard), and dead `userRole` checks are cleaned up. |
| **P1.4** Fix `AccountMember` self-booking/cart bypass and `lister` quotation withdrawal role check (**SEC-05**, **SEC-06**) | `src/modules/bookings/`, `src/modules/cart/`, `src/modules/rfq/` | None | Low | Any member of the seller/provider account is blocked from self-booking/cart; only `owner`/`manager`/`responder` can withdraw quotations. |

### Phase 2: Missing Core Business Functionality
| Task | Affected Modules | Dependencies | Risks | Acceptance Criteria |
|---|---|---|---|---|
| **P2.1** Add Draft RFQ update & submission endpoints (`PATCH /rfqs/:id`, `PATCH /rfqs/:id/submit`) | `src/modules/rfq/` | P1.1 | Low | Users can edit a `DRAFT` RFQ and transition it `DRAFT -> SUBMITTED` with outbox notification. |
| **P2.2** Enforce `rfq.expiresAt` and `quotation.validUntil` + add scheduled expiration worker processor | `src/modules/rfq/`, `src/workers/` | P1.2 | Low | Expired RFQs cannot receive quotations; expired quotations cannot be accepted; BullMQ/interval job marks stale rows `EXPIRED`. |
| **P2.3** Enqueue supplier notifications on `cancelRfq` and optionally hook favorite unavailability notifications into `ListingsService` | `src/modules/rfq/`, `src/modules/listings/` | None | Low | Suppliers with submitted quotes receive `RFQ_CANCELLED` outbox notification; product decision confirmed for favorite unavailability. |
| **P2.4** Implement IANA `Africa/Cairo` timezone conversion (DST-aware) and category-to-`bookingType` validation | `src/modules/bookings/` | Product confirmation on allowed category-booking mappings | Low | Summer (`+03:00`) and winter (`+02:00`) bookings resolve accurately to UTC; invalid category/type pairs return `400`. |

### Phase 3: API Contract Alignment & Bug Fixes
| Task | Affected Modules | Dependencies | Risks | Acceptance Criteria |
|---|---|---|---|---|
| **P3.1** Fix `FavoritesService.getFavoriteStatus` `isListingAvailable` for non-favorited listings (**BUG-09**) | `src/modules/favorites/` | None | Low | Returns `isListingAvailable: true` for available non-favorited listings, `false` for unavailable/missing ones. |
| **P3.2** Fix `CartService.getCart` full-basket `estimatedSubtotal`, atomic `addItem`, and `summary` vs `pagination.total` alignment (**BUG-10**, **BUG-11**, **BUG-12**) | `src/modules/cart/`, `src/modules/favorites/`, `src/modules/activity-hub/` | P0.2 | Low | `estimatedSubtotal` reflects full cart; concurrent `addItem` never 500s; `summary` counts align with section predicates. |
| **P3.3** Standardize DTOs & pagination: dedicated `CancelRfqDto`, validated `GetRfqQuotationsQueryDto` (`sortBy`, `page`, `limit`), remove double-nested `{ success: true }` returns | `src/modules/rfq/`, `src/modules/favorites/`, `src/modules/cart/` | Mobile/Flutter client coordination (breaking check on `data.success`) | Medium (client contract) | Clean OpenAPI/Swagger spec; `GET /rfqs/:id/quotations` paginated & validated. |
| **P3.4** Update `docs/activity-hub-backend/` (`00`, `02`, `04`, `05`, `09`, `11`, `13`) to resolve all 7 documented contradictions | `docs/activity-hub-backend/` | P0–P3.3 | None | 100% alignment between docs and verified code. |

### Phase 4: Performance & Scalability
| Task | Affected Modules | Dependencies | Risks | Acceptance Criteria |
|---|---|---|---|---|
| **P4.1** Harden `OutboxPublisherProcessor` (retry count, backoff, stuck `PROCESSING` sweeper) & `NotificationProcessor` (`sentCount` handling) | `src/workers/`, `prisma/` | None | Low | Transient FCM failures retry automatically; crashed workers' `PROCESSING` rows recover after timeout. |
| **P4.2** Cache Google OAuth2 access token (~50m TTL) and add `AbortSignal.timeout(5000)` to FCM `fetch` calls | `src/modules/notifications/` | None | Low | OAuth2 minting reduced from 1/push to 1/hour; hanging FCM endpoints cannot stall worker concurrency. |
| **P4.3** Optimize `ActivityHubService` connection usage (avoid redundant count queries when section is already loaded) | `src/modules/activity-hub/` | P3.2 | Low | Default `GET /activity-hub` drops from 12 DB queries to 8 or fewer without changing response contract. |

### Phase 5: Testing & Production Verification
| Task | Affected Modules | Dependencies | Risks | Acceptance Criteria |
|---|---|---|---|---|
| **P5.1** Add unit & E2E regression tests for all Phase 0–4 fixes (IDOR, concurrency, expiry, cart query validation, unfavorited status, admin auth) | `src/**/*.spec.ts`, `test/activity-hub.e2e-spec.ts` | P0–P4 | Low | All new & existing unit and E2E suites pass with zero open handles; `activity-hub.e2e-spec.ts` cleans up test users/accounts. |
| **P5.2** Clean up 10 pre-existing ESLint warnings and align TypeScript / `@typescript-eslint` versions | Workspace-wide | None | Low | `eslint` reports 0 errors, 0 warnings; `tsc --noEmit` and `npm run build` pass cleanly. |
| **P5.3** Staging dry-run of `migrate-deploy.js` (direct DB URL) + k6 load test of `/api/v1/activity-hub` | `infra/`, `load-tests/` | P0.4, P4.3 | Low | Zero-downtime migration verified on staging; p95 latency & DB pool utilization within SLA. |
