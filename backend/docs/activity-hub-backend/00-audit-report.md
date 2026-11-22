# Deal One — Unified Activity & Commerce Hub: Initial Backend Audit Report

**Date:** 2026-11-22 (Updated Post-Implementation & Flutter Compatibility Alignment)  
**Workspace:** `backend/` (`market-space-backend` v1.0.0)  
**Scope:** Full inspection of source code (`src/`), Prisma schema (`prisma/schema.prisma`), migrations (`prisma/migrations/` — 11 migrations), taxonomy seeds (`prisma/seeds/taxonomy-data.ts`), tests (`test/`), Flutter Activity Hub (`../deal one app/lib/features/activity_hub/`), and runtime configuration.

> **Update Note (2026-11-22):** All Activity Hub backend modules (`FavoritesModule`, `BookingsModule`, `RfqModule`, `CartModule`, `ActivityHubModule`), stabilization fixes (Phases 0–5), and Flutter DTO compatibility adapters are now **implemented and verified**. See `01-flutter-backend-compatibility.md`, `docs/backend-audit/12-implementation-vs-documentation.md`, and `docs/backend-audit/remediation-progress.md` for complete post-implementation evidence.

---

## 1. Executive Summary & Stack Verification

The existing backend is a production-oriented **Modular Monolith** built on:
- **Framework:** NestJS `^10.3.8` with Fastify (`@nestjs/platform-fastify`)
- **ORM & Database:** Prisma `^5.14.0` with PostgreSQL (PostGIS `geometry(Point, 4326)` + `pg_trgm` + GIN/Gist indexes); 9 existing migrations, schema up to date (`prisma migrate status` verified).
- **Cache & Queues:** Redis (`ioredis ^5.4.1`) + BullMQ (`^5.7.12`)
- **Auth & Security:** JWT (`@nestjs/jwt`, `passport-jwt`), `JwtAuthGuard`, `RolesGuard`, `AccountTenantGuard` (`X-Account-ID`), `RateLimitGuard`, `SecurityAuditService`, `@fastify/helmet`, `@fastify/cors`, `@fastify/cookie`.
- **Validation & API Contract:** Global `ValidationPipe` (`whitelist: true`, `forbidNonWhitelisted: true`, `transform: true`), `HttpExceptionFilter`, `TransformInterceptor` (standard `{ success: true, data, meta? }` envelope), global prefix `/api/v1`, Swagger/OpenAPI (`@nestjs/swagger`).
- **Marketplace Taxonomy:** 6 root categories verified in `prisma/seeds/taxonomy-data.ts`:
  1. `real-estate` (Real Estate / عقارات)
  2. `building-materials` (Building Materials & Electrical Supplies / مواد البناء والتوريدات الكهربائية)
  3. `services` (Services & Engineering)
  4. `home-appliances` (Home Appliances & Decor)
  5. `cars` (Cars & Maintenance)
  6. `fashion` (Fashion & Accessories)

### Baseline Verification Results (Pre-Change)
- `npx prisma validate`: **Passed**
- `npm run build` (`nest build`): **Passed**
- `npm run lint`: **Passed** (0 errors, 9 pre-existing warnings)
- `npm test`: **40/41 suites passed** (261/262 tests passed; `src/core/redis/redis.service.spec.ts` timed out on a 5000ms `beforeEach` hook under parallel load)

---

## 2. Feature Classification Matrix

| # | Feature / Domain | Classification | Current State & Evidence | Required Action |
|---|---|---|---|---|
| 1 | **Authentication, Users, Accounts, RBAC** | **Already implemented and verified** | `AuthModule`, `UsersModule`, `AccountsModule`, `JwtAuthGuard`, `RolesGuard`, `AccountTenantGuard` (`X-Account-ID`). `User` and `Account` / `AccountMember` models exist in `prisma/schema.prisma`. | Reuse as-is; consume `JwtAuthGuard` and `CurrentUser` without modifying auth contracts. |
| 2 | **Categories & Listings** | **Already implemented and verified** | `CategoriesModule` and `ListingsModule` support all 6 root categories, orthogonal lifecycle (`moderationStatus`, `publicationStatus`, `availabilityStatus`), `Account` ownership, and `Area`/`Branch` relations. | Reuse as-is; validate listing existence, `deletedAt === null`, `publicationStatus === 'published'`, and `availabilityStatus === 'available'` where applicable. |
| 3 | **Notifications & Transactional Outbox** | **Already implemented and verified (infra)** / **Implemented but incomplete (domain events)** | `NotificationsModule` (`NotificationsService`, `NotificationsController`), `Notification` model, `UserDevice` model, `OutboxEvent` model, `OutboxPublisherProcessor`, and `NotificationProcessor` exist. | Integrate Activity Hub domain events (bookings, RFQs, quotations, favorite unavailability) via `OutboxEvent` / `NotificationsService` without blocking main transactions. |
| 4 | **Favorites Module** | **Implemented but incomplete** | `Favorite` model exists (`uq_user_favorite` on `[userId, listingId]`, index on `[userId, createdAt]`). `FavoritesController` has `GET /favorites`, `POST /favorites/:listingId`, `DELETE /favorites/:listingId`, and mobile aliases (`GET /listings/favorites`, `POST /listings/:listingId/favorite`). | **Gaps:** Missing `POST /favorites` (body), `GET /favorites/:listingId/status`, pagination (`page`, `limit`, `meta`), category filter, search filter, `listingId` index, and strict visibility/availability checks. Extend without breaking existing mobile aliases. |
| 5 | **Bookings & Appointments Module** | **Missing entirely** | No `Booking` model, controller, service, or DTOs exist in `src/` or `prisma/`. | **Requires DB migration** + new `BookingsModule` (`POST /bookings`, `GET /bookings`, `GET /bookings/:id`, `PATCH /bookings/:id/cancel`, `PATCH /bookings/:id/status`), state machine, race-condition protection, and provider authorization. |
| 6 | **RFQ & Quotations Module** | **Missing entirely** | No `Rfq` or `Quotation` models, controllers, services, or DTOs exist in `src/` or `prisma/`. | **Requires DB migration** + new `RfqModule` (`POST /rfqs`, `GET /rfqs`, `GET /rfqs/:id`, `PATCH /rfqs/:id/cancel`, `POST /rfqs/:id/quotations`, `GET /rfqs/:id/quotations`, `GET /quotations/:id`, plus quotation status/comparison). |
| 7 | **Cart & Future Commerce** | **Missing entirely** | No `Cart` / `CartItem` / `Order` models exist. Existing `PaymentsModule` is strictly for V2 listing promotions (`PromotionPackage`, `Payment`) and gated by `ENABLE_V2_PAYMENTS`. | **Requires DB migration** for a **non-transactional V1 Saved Product Basket (`CartItem`)** with future-ready fields (variant metadata, quantity, price snapshot), exposing `GET/POST/PATCH/DELETE /cart` **without** fake checkout, orders, or payments. |
| 8 | **Unified Activity Hub API** | **Missing entirely** | No `/activity-hub` endpoint or aggregation module exists. | Create `ActivityHubModule` (`GET /activity-hub`) consuming `CartService`, `BookingsService`, `RfqService`, and `FavoritesService` with `?include=`, pagination, category filtering, and strict user isolation. |
| 9 | **Frontend Integration Contracts & Swagger** | **Requires a frontend integration contract** | Existing Swagger covers Auth, Listings, Favorites (partially), Notifications, Chat, etc. | Update Swagger decorators on all new/updated endpoints and document contracts in `docs/activity-hub-backend/11-api-contracts.md`. |

---

## 3. Existing Code Findings & Constraints

1. **API Envelope & Route Prefix:**
   - All routes are served under `/api/v1/...`.
   - `TransformInterceptor` automatically wraps controller return values in `{ success: true, data, meta? }`. Returning `{ data, meta }` from a service/controller maps cleanly to `{ success: true, data, meta }`.
2. **Favorites Duplication Prevention:**
   - `FavoritesController` currently exposes `GET /favorites`, `POST /favorites/:listingId`, `DELETE /favorites/:listingId`, `GET /listings/favorites`, and `POST /listings/:listingId/favorite`.
   - We MUST preserve all existing routes and response shapes where Flutter depends on them, while adding `POST /favorites`, `GET /favorites/:listingId/status`, and optional pagination/filtering query parameters (`page`, `limit`, `categoryId`, `categorySlug`, `search`) on `GET /favorites`.
3. **Provider / Advertiser Ownership Model:**
   - Listings belong to an `Account` (`listing.accountId`), which has `ownerUserId` and `AccountMember` rows (`owner`, `manager`, `lister`, `responder`).
   - Therefore, provider authorization for Bookings (and supplier/account authorization for RFQs) must check `account.ownerUserId === userId` OR active `AccountMember` membership on that `accountId`, never trusting client-supplied provider IDs.
4. **V1 Commerce Boundary:**
   - `PaymentsModule` is gated by `ENABLE_V2_PAYMENTS === 'true'` and only handles `PromotionPackage` purchases.
   - No `Order`, `Cart`, or online product checkout exists. V1 Cart must be strictly a non-transactional saved product basket / shopping list.
5. **Transactional Outbox:**
   - `OutboxPublisherProcessor` already polls `outbox_events` (`status = 'PENDING'`) and dispatches `PUSH_NOTIFICATION` events to `NotificationProcessor` -> `NotificationsService.sendPushNotification()`. Writing `OutboxEvent` records inside domain `$transaction` blocks guarantees at-least-once notification delivery without failing business transactions.
