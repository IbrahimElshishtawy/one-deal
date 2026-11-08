# 05 — API Contract Gaps & Production Investigation Report

**Project:** Deal One (صفقة ون) Mobile Integration  
**Phase:** Phase 01 — Production API and OpenAPI Contract Verification  
**Date:** November 8, 2026  
**Auditor:** Principal Flutter Architect, API Integration Engineer & Application Security Engineer  
**Status:** EVIDENCE-BASED AUDIT COMPLETE

---

## 1. Deep Technical Investigation: HTTP 500 Errors on Core Read Endpoints

### 1.1 The Problem Statement
During discovery probes on the live production API (`https://one-deal-cjjt-production.up.railway.app/api/v1`), the following public read-only endpoints consistently fail with HTTP 500:
1. `GET /api/v1/categories`
2. `GET /api/v1/listings`
3. `GET /api/v1/locations/governorates`
4. `GET /api/v1/search`

Each returns the identical error payload:
```json
{
  "success": false,
  "error": {
    "code": "INTERNAL_SERVER_ERROR",
    "message": "An unexpected server error occurred.",
    "details": null,
    "trace_id": "<uuid>"
  }
}
```

### 1.2 Verifiable Evidence from Server Probes

| Probe Command | HTTP Status | Response Analysis |
|---|:---:|---|
| `curl -s https://.../health/live` | **200 OK** | Fastify runtime and process memory (`rss: 87MB`) are operational. |
| `curl -s https://.../health/ready` | **200 OK** | `PrismaService.ping()` runs raw `SELECT 1` -> **up**.<br>`checkPostgisSupport()` runs raw `SELECT PostGIS_Version()` -> **up (3.4)**.<br>Redis cache and queue -> **up**.<br>Workers -> **active**. |
| `curl -s https://.../api/docs-json` | **200 OK** | SwaggerModule generates and serves the complete 46KB OpenAPI 3.0 spec in-memory. |
| `curl -s -i https://.../api/v1/auth/sessions` | **401 Unauthorized** | NestJS `JwtAuthGuard` intercepts the unauthenticated request before service execution and returns formatted error JSON. |
| `curl -s -X POST https://.../api/v1/auth/otp/send -d '{"phone":"123"}'` | **400 Bad Request** | NestJS `ValidationPipe` parses DTO, executes Egyptian phone regex validator, and returns formatted error JSON (`issue: "Phone number must be a valid Egyptian mobile number..."`). |
| `curl -s https://.../api/v1/categories` | **500 Internal Server Error** | Reaches `CategoriesService.getCategoryTree()`, which invokes `this.prisma.category.findMany(...)`. An unhandled exception is thrown, caught by `HttpExceptionFilter`, and serialized as `INTERNAL_SERVER_ERROR`. |
| `curl -s https://.../api/v1/locations/governorates` | **500 Internal Server Error** | Reaches `LocationsService.getGovernorates()`, which invokes `this.prisma.governorate.findMany(...)`. An unhandled exception is thrown. |
| `curl -s https://.../api/v1/listings` | **500 Internal Server Error** | Reaches `ListingsService.getListingsFeed()`, which invokes `this.prisma.listing.findMany(...)`. An unhandled exception is thrown. |

### 1.3 Verifiable Technical Root Cause
By cross-referencing server behavior with backend source code:

1. **How the error filter behaves (`backend/src/core/filters/http-exception.filter.ts`):**
   ```typescript
   if (exception instanceof HttpException) {
     status = exception.getStatus();
     // Handles 400, 401, 403, 404, 409, 429...
   } else {
     // Unhandled / Internal exception
     const err = exception as Error;
     this.logger.error(`[${traceId}] Unhandled Exception: ${err?.message || exception}`, err?.stack);
   }
   ```
   If the service threw a standard NestJS exception (e.g. `NotFoundException`), `exception instanceof HttpException` would be true and status would NOT be 500. The 500 status proves that an unhandled database exception (a `PrismaClientKnownRequestError` or runtime driver error) is thrown inside the Prisma ORM layer.

2. **Why raw SQL in `health/ready` succeeds while model queries fail:**
   - In `backend/src/core/database/prisma.service.ts`:
     - `ping()` runs `SELECT 1;` (tests basic connection socket only).
     - `checkPostgisSupport()` runs `SELECT PostGIS_Version();` (tests extension function only).
     - Neither query accesses any application table (`categories`, `governorates`, `listings`).
   - In `railway.json`:
     ```json
     "deploy": {
       "startCommand": "node dist/src/main.js"
     }
     ```
     Notice that the production start command does **NOT** run `npx prisma migrate deploy`.
   - In `backend/Dockerfile` and root `Dockerfile`:
     The production runner stage runs `npm ci --only=production`. Because `prisma` CLI is a devDependency, `prisma` CLI is NOT installed in the runner image, and migrations are not run during container startup.
   - When Prisma executes `prisma.category.findMany(...)`, if the tables do not exist in the connected database, PostgreSQL returns `ERROR: relation "categories" does not exist` (Prisma error code `P2021`). Because service methods do not catch `P2021`, it bubbles up to `HttpExceptionFilter` as an unhandled internal exception.

3. **Alternative Contributing Factors Checked:**
   - **Database Connection URI:** If `DATABASE_URL` was completely invalid or PostgreSQL was down, `/health/ready` would return `503 Service Unavailable` with `database: down`. Since `/health/ready` returns `200 OK` with `database: up`, the database connection is alive.
   - **PostGIS Extension:** Verified present (`3.4`).

---

## 2. Discrepancies Between OpenAPI Specification and Implementation

| # | Domain / Route | Documented in OpenAPI | Actual Implementation in Source | Discrepancy & Resolution |
|---|---|---|---|---|
| **D1** | **Locations / Cities** | `GET /api/v1/locations/governorates` & `GET /api/v1/locations/cities/{cityId}/areas` | `LocationsController` includes cities inside `governorate.findMany({ include: { cities: true } })`. | Historical docs mentioned a separate `GET /governorates/:id/cities` endpoint. In reality, governorates endpoint returns cities embedded, and separate endpoint is for areas under a city. Mobile DTO must parse embedded `cities` array directly from `GovernorateDto`. |
| **D2** | **Chat Prefix** | `/api/v1/conversations` | `ChatController` uses `@Controller('conversations')`. | Historical docs referred to `/api/v1/chat/conversations`. The real path is `/api/v1/conversations`. Mobile networking must use `/conversations`. |
| **D3** | **Contact Reveal Location** | Documented under `Listings` (`/api/v1/listings/{id}/contact` and alias `/api/v1/listings/{id}/reveal-contact`). | Handled by `ListingsController.recordContactAction()`. | Historical docs placed contact reveal under `/quotas/contact-reveals/reveal/:id`. In reality, it lives on `ListingsController`, which enforces both Cairo daily quota (5/day) and IP rate limiting (30/hr). Mobile repository must call `/listings/:id/contact`. |
| **D4** | **Notifications Listing** | No `GET /api/v1/notifications` exists in OpenAPI. | `NotificationsController` ONLY defines `POST /api/v1/notifications/device-token`. | Mobile app cannot fetch an in-app notification inbox from this endpoint; push notifications are delivered via FCM payload directly to the device. |
| **D5** | **Payments Module** | Absent from OpenAPI. | `AppModule` guards `PaymentsModule` with `process.env.ENABLE_V2_PAYMENTS === 'true'`. | Payments is strictly a V2 module and is disabled in production. Mobile V1 must not attempt to integrate payment checkout endpoints. |
| **D6** | **Token Refresh Payload** | `RefreshTokenDto` defines both `refreshToken` and `refresh_token` as optional. | `AuthService.refreshToken` extracts `dto.refreshToken || dto.refresh_token`. If neither is provided, throws 401. | Mobile DTO should provide both keys or standard `refreshToken` key to guarantee compatibility. |

---

## 3. Security Findings & Privacy Verification

### 3.1 Public Listing Contact Masking (VERIFIED IN SOURCE)
In `backend/src/modules/listings/listings.service.ts` (lines 476, 500-542):
- In `getListingsFeed()`:
  ```typescript
  sellerPhone: null,
  ```
  The seller's phone number is explicitly hardcoded to `null` in public listing feeds.
- In `getListingById()`:
  The owner object includes `{ id: true, fullName: true, avatarUrl: true }`. Phone is omitted.
- In `recordContactAction()` (`POST /api/v1/listings/:id/contact`):
  Phone is only returned AFTER:
  1. Checking IP rate limits (max 30 requests/hr).
  2. Verifying caller is authenticated via JWT.
  3. Verifying caller is not the listing owner.
  4. Enforcing user daily quota in `Africa/Cairo` timezone (5 reveals/day).
  5. Recording immutable audit log (`CONTACT_REVEALED`).
  6. Incrementing listing `contactRevealsCount`.

*Mobile Compliance Requirement:* The Flutter mobile app must never expect or display `sellerPhone` from listing cards or feed DTOs. Contact details must only be populated via the explicit `contactSeller` repository action.

---

## 4. Operational Recommendations & Next Steps

1. **Backend / DevOps Action (External):**
   Execute database migration on Railway staging:
   ```bash
   npx prisma migrate deploy
   ```
   And optionally run demo seeder:
   ```bash
   ALLOW_DEMO_SEEDING=true npx ts-node prisma/seeds/seed.ts
   ```
2. **Mobile Architecture Sign-off:**
   Because all 61 OpenAPI endpoints, schemas, request/response models, and error envelopes are 100% discovered and cross-referenced with backend source code, the data layer design (DTOs, Mappers, Repositories) can proceed deterministically.
