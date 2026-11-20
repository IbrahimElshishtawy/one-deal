# 00 — Complete Backend Discovery

> **Phase:** PHASE 00 — Complete Backend Discovery (Read-Only)  
> **Target Repository:** `/home/ibrahim-elshishtawy/flutter project/deal one/backend`  
> **Production Base URL:** `https://one-deal-cjjt-production.up.railway.app/api/v1`  
> **Date:** `2026-11-20`

---

## 1. Executive Summary

The existing Deal One backend (`market-space-backend` v1.0.0) is a production-oriented **Modular Monolith** built with **NestJS 10.3.8** on **Fastify** (`@nestjs/platform-fastify`), **Prisma ORM 5.14.0**, **PostgreSQL** (with PostGIS, `pg_trgm`, and `pg_stat_statements`), and a **Dual-Redis** architecture (`ioredis` + `bullmq`).

The backend already contains foundational administrative tables (`staff_roles`, `staff_users`, `moderation_log`, `audit_log`, `platform_settings`, `account_verifications`, `reports`) and a subset of `/api/v1/admin/*` endpoints. However, **administrative authentication, granular RBAC permissions, and most operational admin modules are incomplete or disconnected from `StaffUser`**, because existing authentication (`AuthModule` / `JwtStrategy`) only authenticates mobile `User` records by Egyptian phone number.

---

## 2. Repository & Runtime Architecture

### 2.1 Technology Stack (`backend/package.json`)
| Layer | Package / Version | Purpose |
| :--- | :--- | :--- |
| Framework | `@nestjs/core`, `@nestjs/common` `^10.3.8` | Modular Monolith IoC container & HTTP routing |
| HTTP Engine | `@nestjs/platform-fastify` `^10.3.8` | High-throughput Fastify adapter |
| Security Headers & CORS | `@fastify/helmet` `^11.1.1`, `@fastify/cors` `^9.0.1` | CSP, HSTS, Frameguard, origin allowlist |
| ORM & Database | `prisma` / `@prisma/client` `^5.14.0` | PostgreSQL + PostGIS raw queries & transactions |
| Cache & Queues | `ioredis` `^5.4.1`, `bullmq` `^5.7.12` | Dual-Redis caching, rate limits, Pub/Sub, async jobs |
| Auth & Hashing | `@nestjs/jwt` `^10.2.0`, `@nestjs/passport` `^10.0.3`, `passport-jwt` `^4.0.1`, `argon2` `^0.40.1` | HS256 JWTs & Argon2id/argon2 password hashing |
| Validation | `class-validator` `^0.14.1`, `class-transformer` `^0.5.1`, `zod` `^3.23.8` | DTO validation & startup env validation |
| OpenAPI / Swagger | `@nestjs/swagger` `^7.3.1` | API spec at `/api/docs` (disabled in production by default) |
| Email & Phone | `resend` `^6.39.0`, `libphonenumber-js` `^1.13.15` | Transactional emails & Egyptian E.164 normalization |
| Testing | `jest` `^29.7.0`, `ts-jest` `^29.1.2`, `supertest` `^7.0.0` | Unit (`40` `*.spec.ts`) & E2E (`8` `*.e2e-spec.ts`) suites |

> **Important Note for Cookie Auth:** `@fastify/cookie` is **not** currently installed in `backend/package.json`. It must be added in Phase 02 to support `HttpOnly` refresh token cookies for the React Admin Dashboard.

### 2.2 Bootstrap & HTTP Pipeline (`backend/src/main.ts`)
- **Fastify Options:**
  - `bodyLimit: 2 * 1024 * 1024` (2 MB cap)
  - `requestTimeout: 30_000` (30 seconds)
  - `maxParamLength: 200`
  - `trustProxy`: validated strictly by `parseTrustProxy()` (rejects blanket `true`; allows `false`, hop count `0..10`, `loopback`/`linklocal`/`uniquelocal`, or explicit IP/CIDR list)
  - `rawBody: true` (used for webhook HMAC verification such as Cloudflare Stream)
- **Global Prefix:** `api/v1` excluding `health/live`, `health/ready`, `health/liveness`, `health/readiness`, and `metrics`.
- **Global `ValidationPipe`:** `whitelist: true`, `forbidNonWhitelisted: true`, `transform: true`, `enableImplicitConversion: true`.
- **Global Filter & Interceptors:**
  1. `HttpExceptionFilter`: returns `{ success: false, error: { code, message, details, trace_id } }` and attaches `x-trace-id` / `x-request-id`.
  2. `MetricsInterceptor`: records Prometheus HTTP counters, histograms, and in-flight gauges.
  3. `LoggingInterceptor`: structured JSON HTTP request/error logging with `trace_id`, `user_id`, `duration_ms`.
  4. `TransformInterceptor`: wraps responses into `{ success: true, data, meta? }` unless already enveloped.
- **Swagger:** mounted at `/api/docs` when `NODE_ENV !== 'production'` or `ENABLE_SWAGGER=true`. Bearer auth scheme name is `'BearerAuth'`.

---

## 3. Core Infrastructure (`backend/src/core/`)

### 3.1 Configuration & Secret Validation (`src/core/config/env.config.ts`)
- Uses **Zod** (`envSchema`) and fails fast on invalid startup state.
- **Production Enforcement:**
  - Rejects `ENABLE_DEV_AUTH_BYPASS=true` in production.
  - Requires `DATABASE_URL` (with fallback mapping from `POSTGRES_URL`, `POSTGRESQL_URL`, `DATABASE_PUBLIC_URL`).
  - Validates `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET` with `validateProductionSecret()` (`>= 32` chars, rejects known placeholder strings/patterns, requires `>= 10` unique chars, Shannon entropy `>= 3.0`, and enforces `JWT_ACCESS_SECRET !== JWT_REFRESH_SECRET`).
  - Requires explicit `CORS_ORIGIN` list in production without `*` wildcards.
  - Supports `AUTO_APPROVE_LISTINGS`, `ENABLE_WORKERS`, `AUDIT_QUEUE_ENABLED`, `ENABLE_V2_PAYMENTS`, `METRICS_AUTH_TOKEN`, `SENTRY_DSN`, `APP_PUBLIC_URL`.

### 3.2 HTTP Security (`src/core/security/http-security.config.ts`)
- **CORS (`buildCorsOptions`):**
  - Allows requests without an `Origin` header (for native Flutter mobile clients and server-to-server calls).
  - In production, validates browser `Origin` strictly against `CORS_ORIGIN` allowlist (`credentials: true`).
  - Allowed methods: `GET, HEAD, PUT, PATCH, POST, DELETE, OPTIONS`.
  - Allowed headers: `Content-Type`, `Authorization`, `X-Trace-Id`, `X-Request-Id`, `X-Account-Id`, `X-Metrics-Token`.
  - Exposed headers: `X-Trace-Id`, `X-Request-Id`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`, `Retry-After`.
- **Helmet (`buildHelmetOptions`):**
  - When Swagger is disabled (production default): strict CSP (`defaultSrc: ["'none'"]`, `frameAncestors: ["'none'"]`), HSTS (`maxAge: 31536000`, `includeSubDomains: true`), `referrerPolicy: 'no-referrer'`, `frameguard: 'deny'`.

### 3.3 Database Layer (`src/core/database/prisma.service.ts`)
- Extends `PrismaClient` (Prisma `5.14.0`).
- Appends `connection_limit` (default `10`) and `pgbouncer=true` (when `PGBOUNCER_ENABLED=true`) to `DATABASE_URL` via `buildDatabaseDatasourceUrl()`.
- Exposes `ping()` and `checkPostgisSupport()`.

### 3.4 Dual-Redis Topology (`src/core/redis/redis.service.ts`)
- **Client 1 — Cache Client (`REDIS_CACHE_URL` / `REDIS_CACHE_HOST:6379`):**
  - Used for taxonomy caching (`categories:tree`, `categories:item:*`, `categories:fields:*`), home feed versioning (`home:feed:ver`), `AccountTenantGuard` membership cache (`account:membership:{userId}:{accountId}`), atomic Lua rate limiting (`RATE_LIMIT_LUA_SCRIPT`), JWT denylisting (`auth:revoked:jti:*`, `auth:revoked:sid:*`, `auth:revoked:user_before:*`), distributed locks (`lock:*`), and Chat SSE Pub/Sub (`createSubscriber()`).
  - Non-production fallback (`inMemoryFallback` / `inMemoryRateLimits`) is disabled for general caching in `NODE_ENV=production` (rate limiting keeps a bounded 10k-key in-memory fallback if Redis is temporarily unreachable).
- **Client 2 — Queue Client (`REDIS_QUEUE_URL` / `REDIS_QUEUE_HOST:6380`):**
  - Dedicated `ioredis` connection (`maxRetriesPerRequest: null`) for BullMQ queues (`marketspace-maintenance` and `audit-logs`).

### 3.5 Security Audit, Rate Limiting, Health & Observability
- **Security Audit (`src/core/security/security-audit.service.ts`):**
  - Redacts keys matching exact `code`, `otp`, `jwt`, `cookie` or substrings `password`, `secret`, `token`, `authorization`, `apikey`, `api_key`, `privatekey`, `private_key`.
  - Enqueues to BullMQ `audit-logs` queue when `AUDIT_QUEUE_ENABLED=true` and Queue Redis is connected; otherwise writes directly to `audit_log` via Prisma.
- **Rate Limiting (`src/core/guards/rate-limit.guard.ts`):**
  - Keys authenticated callers by `userId` (`ratelimit:user:{userId}:{route}`) and anonymous callers by Fastify `request.ip` (`ratelimit:ip:{ip}:{route}`).
  - Sets `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`, `X-RateLimit-Scope`, and `Retry-After` on 429.
- **Health & Metrics:**
  - `HealthController` (`src/core/health/health.controller.ts`): `GET /health/live` (`liveness`) and `GET /health/ready` (`readiness`) checking PostgreSQL, PostGIS, Redis Cache, Redis Queue, WorkerService, and EmailService.
  - `MetricsController` (`src/core/metrics/metrics.controller.ts`): `GET /metrics` protected by `MetricsAuthGuard` (`Authorization: Bearer <token>` or `X-Metrics-Token` matching `METRICS_AUTH_TOKEN`, or loopback/private IP fallback).

---

## 4. NestJS Modules Inventory (`backend/src/app.module.ts`)

| # | Module | Directory | Responsibility |
| :--- | :--- | :--- | :--- |
| 1 | `PrismaModule` | `src/core/database` | Global Prisma PostgreSQL client |
| 2 | `RedisModule` | `src/core/redis` | Dual-Redis cache, locks, Lua rate-limit, Pub/Sub |
| 3 | `MetricsModule` | `src/core/metrics` | Prometheus metrics registry & `/metrics` guard |
| 4 | `WorkerModule` | `src/workers` | BullMQ / locked-interval background processors |
| 5 | `AuthModule` | `src/modules/auth` | Mobile OTP/Password auth, JWT strategy, Session rotation, `RolesGuard`, `AccountTenantGuard` |
| 6 | `EmailModule` | `src/modules/email` | Resend email templates & single-use email verification |
| 7 | `UsersModule` | `src/modules/users` | Self-service user profile (`/users/me`) |
| 8 | `AccountsModule` | `src/modules/accounts` | Multi-tenant seller accounts, branches, team members, service areas, verification submissions |
| 9 | `CategoriesModule` | `src/modules/categories` | Public category tree + Admin category/field creation |
| 10 | `MediaModule` | `src/modules/media` | Cloudflare R2 / S3 presigned URLs & upload confirmation |
| 11 | `ListingsModule` | `src/modules/listings` | 3-axis orthogonal listing lifecycle, feed, batch prices, contact reveal |
| 12 | `HomeModule` | `src/modules/home` | Aggregated home feed & server-driven section home feeds |
| 13 | `SearchModule` | `src/modules/search` | Arabic-normalized search, faceted filtering, autocomplete |
| 14 | `ChatModule` | `src/modules/chat` | Conversations, messages, SSE stream (`Redis Pub/Sub`) |
| 15 | `VideoModule` | `src/modules/video` | Cloudflare Stream upload tokens, signed webhooks, vertical video feed |
| 16 | `ModerationModule` | `src/modules/moderation` | User abuse reports + Admin listing/report/verification moderation & audit log read |
| 17 | `NotificationsModule` | `src/modules/notifications` | In-app notifications inbox, FCM device tokens & HTTP v1 dispatch |
| 18 | `LocationsModule` | `src/modules/locations` | Egyptian governorates, cities, and PostGIS areas |
| 19 | `FavoritesModule` | `src/modules/favorites` | User saved listings & mobile aliases |
| 20 | `QuotasModule` | `src/modules/quotas` | Daily `Africa/Cairo` account usage limits |
| 21 | `PlatformSettingsModule` | `src/modules/platform-settings` | Admin key-value JSON configuration (`platform_settings`) |
| 22 | `StaffModule` | `src/modules/staff` | Admin staff roles (`staff_roles`) & staff users (`staff_users`) CRUD |
| 23 | `PaymentsModule` *(flagged)* | `src/modules/payments` | Loaded only when `ENABLE_V2_PAYMENTS=true` (Paymob checkout & packages) |

---

## 5. Background Workers (`backend/src/workers/`)

Managed by `WorkerService` (disabled when `ENABLE_WORKERS=false`; uses BullMQ repeatable jobs when `queueClient` is connected, otherwise locked intervals via `redisService.acquireLock`):
1. **`ListingExpiryProcessor`** (`listing-expiry`): every 30 minutes.
2. **`PaymentReconciliationProcessor`** (`payment-reconciliation`): every 15 minutes.
3. **`MediaCleanupProcessor`** (`media-cleanup`): every 6 hours.
4. **`OutboxPublisherProcessor`** (`outbox-publisher`): every 10 seconds (processes `outbox_events`).
5. **`NotificationProcessor`**: on-demand push dispatch via `enqueueNotification()`.

---

## 6. Test & Verification Inventory

- **Unit Test Files (`backend/src/**/*.spec.ts`):** `40` spec files present in `src/`.
- **E2E Test Files (`backend/test/*.e2e-spec.ts`):** `8` spec files (`all-modules-audit.e2e-spec.ts`, `app.e2e-spec.ts`, `auth-database-redis.e2e-spec.ts`, `auth.e2e-spec.ts`, `data-flow.e2e-spec.ts`, `new-features.e2e-spec.ts`, `security-integration.e2e-spec.ts`, plus `jest-e2e.json`).
- **Load Tests (`backend/load-tests/`):** `data-flow-load-test.js`, `k6-5000-online.js`.
- **Prior Verified Baseline (`backend/backend-status-report-verified.md`, dated `2026-11-18`):** documented `npm run build` pass, `eslint` 0 errors/0 warnings, `32` unit suites (`176` tests) passing, `5` E2E suites (`36` tests) passing, and `8` migrations up to date. *(Note: No build or test command was executed during this read-only Phase 00 discovery; runtime re-verification will be executed at Phase 02+ implementation checkpoints.)*
