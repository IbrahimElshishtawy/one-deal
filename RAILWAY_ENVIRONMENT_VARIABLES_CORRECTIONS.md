# Deal One — Second-Pass Railway Environment Audit & Contradiction Resolution

**Project:** Deal One Backend Modular Monolith  
**Audit Context:** Railway Deployment & Configuration Integrity  
**Date:** November 7, 2026  
**Auditor:** Senior DevOps Engineer & Prisma/NestJS Specialist  
**Verification Method:** Exact Codebase & AST Static Analysis (Read-Only)  

---

## 1. Executive Summary & Audit Purpose

This document provides a second-pass technical verification and authoritative contradiction resolution for the Deal One backend environment variables configuration on Railway.

The previous audit (`RAILWAY_ENVIRONMENT_VARIABLES_AUDIT.md`) identified general requirements but contained numerical discrepancies (reporting 38 variables while listing ~50), ambiguous required-variable classifications (5 mandatory vs. 4 missing), and incomplete explanations of runtime fallbacks.

This audit resolves every contradiction using direct source code evidence, precise file paths, and exact line numbers.

---

## 2. Mathematical Reconciliation of Environment Variables

### 2.1 The Count Discrepancy Resolved

| Category | Count | Code Reference / Source |
|---|---|---|
| **`envSchema` Declared Keys** | **45** | [`backend/src/core/config/env.config.ts#L3-L80`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L3-L80) |
| **`validateEnv` Compatibility Aliases** | **3** | [`backend/src/core/config/env.config.ts#L91-L93`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L91-L93) (`POSTGRES_URL`, `POSTGRESQL_URL`, `DATABASE_PUBLIC_URL`) |
| **CLI Seed Script Flags** | **2** | [`backend/prisma/seeds/seed.ts#L54-L56`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/prisma/seeds/seed.ts#L54-L56) (`RESET_DEMO`, `ALLOW_DEMO_SEEDING`) |
| **Total Unique Application-Defined Variables** | **50** | Exact deduplicated set across application code |
| **Direct Runtime References in Code** | **35** | Variables queried via `ConfigService.get()` or `process.env` |
| **Schema-Validated Only (Reserved/Defaulted)** | **12** | Keys validated in Zod schema but not directly called at runtime |
| **Railway Auto-Injected Platform Metadata** | **7** | Injected by Railway runtime (`PORT`, `RAILWAY_*`) |

> [!NOTE]
> **Why Pass 1 stated "38":** Pass 1 conflated grouping categories and omitted compatibility aliases (`POSTGRES_URL`, `POSTGRESQL_URL`, `DATABASE_PUBLIC_URL`), seed flags, and certain cloud variants from its summary line while printing them in the inventory table. The exact, verified count of application-defined environment variables is **50**.

---

### 2.2 Complete Code References of Direct Runtime Variables (35)

1. `PORT`: [`backend/src/main.ts#L28`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/main.ts#L28)
2. `CORS_ORIGIN`: [`backend/src/main.ts#L29`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/main.ts#L29)
3. `NODE_ENV`: [`backend/src/core/database/prisma.service.ts#L20`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/database/prisma.service.ts#L20), [`backend/src/modules/auth/auth.module.ts#L49`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/auth.module.ts#L49), [`backend/src/modules/auth/services/otp.service.ts#L166`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/services/otp.service.ts#L166), [`backend/src/modules/auth/adapters/mock-sms.adapter.ts#L26,L44`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/adapters/mock-sms.adapter.ts#L26-L44), [`backend/src/core/redis/redis.service.ts#L298,L329`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L298-L329), [`backend/prisma/seeds/seed.ts#L55,L60`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/prisma/seeds/seed.ts#L55-L60)
4. `DATABASE_URL`: [`backend/prisma/schema.prisma#L3`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/prisma/schema.prisma#L3), [`backend/src/core/config/env.config.ts#L89-L95`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L89-L95)
5. `REDIS_CACHE_URL`: [`backend/src/core/redis/redis.service.ts#L41`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L41)
6. `REDIS_URL`: [`backend/src/core/redis/redis.service.ts#L42,L65`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L42-L65)
7. `REDIS_CACHE_HOST`: [`backend/src/core/redis/redis.service.ts#L47`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L47)
8. `REDISHOST`: [`backend/src/core/redis/redis.service.ts#L48,L71`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L48-L71)
9. `REDIS_HOST`: [`backend/src/core/redis/redis.service.ts#L49`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L49)
10. `REDIS_CACHE_PORT`: [`backend/src/core/redis/redis.service.ts#L51`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L51)
11. `REDISPORT`: [`backend/src/core/redis/redis.service.ts#L52,L74`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L52-L74)
12. `REDIS_PORT`: [`backend/src/core/redis/redis.service.ts#L53`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L53)
13. `REDIS_CACHE_PASSWORD`: [`backend/src/core/redis/redis.service.ts#L55`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L55)
14. `REDISPASSWORD`: [`backend/src/core/redis/redis.service.ts#L56,L77`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L56-L77)
15. `REDIS_PASSWORD`: [`backend/src/core/redis/redis.service.ts#L57`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L57)
16. `REDIS_QUEUE_URL`: [`backend/src/core/redis/redis.service.ts#L64`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L64)
17. `REDIS_QUEUE_HOST`: [`backend/src/core/redis/redis.service.ts#L70`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L70)
18. `REDIS_QUEUE_PORT`: [`backend/src/core/redis/redis.service.ts#L73`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L73)
19. `REDIS_QUEUE_PASSWORD`: [`backend/src/core/redis/redis.service.ts#L76`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L76)
20. `JWT_ACCESS_SECRET`: [`backend/src/modules/auth/auth.module.ts#L25`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/auth.module.ts#L25), [`backend/src/modules/auth/strategies/jwt.strategy.ts#L26`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/strategies/jwt.strategy.ts#L26), [`backend/src/modules/auth/services/session.service.ts#L53`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/services/session.service.ts#L53), [`backend/src/modules/auth/services/otp.service.ts#L45`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/services/otp.service.ts#L45)
21. `JWT_ACCESS_EXPIRES_IN`: [`backend/src/modules/auth/auth.module.ts#L27`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/auth.module.ts#L27)
22. `SMS_PROVIDER`: [`backend/src/modules/auth/auth.module.ts#L48`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/auth.module.ts#L48)
23. `SMS_MISR_USERNAME`: [`backend/src/modules/auth/adapters/sms-misr.adapter.ts#L20`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/adapters/sms-misr.adapter.ts#L20)
24. `SMS_MISR_PASSWORD`: [`backend/src/modules/auth/adapters/sms-misr.adapter.ts#L21`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/adapters/sms-misr.adapter.ts#L21)
25. `SMS_MISR_SENDER_ID`: [`backend/src/modules/auth/adapters/sms-misr.adapter.ts#L23`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/adapters/sms-misr.adapter.ts#L23)
26. `R2_PUBLIC_DOMAIN`: [`backend/src/modules/listings/listings.service.ts#L30`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/listings/listings.service.ts#L30), [`backend/src/modules/media/media.service.ts#L32`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/media/media.service.ts#L32)
27. `R2_BUCKET_NAME`: [`backend/src/modules/media/media.service.ts#L36`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/media/media.service.ts#L36)
28. `CLOUDFLARE_STREAM_API_TOKEN`: [`backend/src/modules/video/video.service.ts#L17`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/video/video.service.ts#L17)
29. `CLOUDFLARE_STREAM_ACCOUNT_ID`: [`backend/src/modules/video/video.service.ts#L21`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/video/video.service.ts#L21)
30. `CLOUDFLARE_STREAM_WEBHOOK_SECRET`: [`backend/src/modules/video/video.service.ts#L25`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/video/video.service.ts#L25)
31. `ENABLE_V2_PAYMENTS`: [`backend/src/app.module.ts#L27`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/app.module.ts#L27)
32. `PAYMOB_HMAC_SECRET`: [`backend/src/modules/payments/payments.service.ts#L55`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/payments/payments.service.ts#L55)
33. `FIREBASE_PROJECT_ID`: [`backend/src/modules/notifications/notifications.service.ts#L11`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/notifications/notifications.service.ts#L11)
34. `RESET_DEMO`: [`backend/prisma/seeds/seed.ts#L54`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/prisma/seeds/seed.ts#L54)
35. `ALLOW_DEMO_SEEDING`: [`backend/prisma/seeds/seed.ts#L56`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/prisma/seeds/seed.ts#L56)

---

## 3. Resolving Required-Variable Classification (The 5 Tiers)

The previous report claimed "5 mandatory variables" but subsequently identified "4 missing variables in Railway canvas". This contradiction arose because `PORT` is mandatory for the process to bind to Railway's routing mesh, but Railway injects it automatically, leaving 4 variables requiring user intervention.

To eliminate ambiguity, variables are strictly partitioned into five operational tiers:

```
┌────────────────────────────────────────────────────────┐
│  Tier 1: Process Startup  (PORT)                       │
└──────────────────────────┬─────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│  Tier 2: Secure Production Operation (NODE_ENV, JWT)   │
└──────────────────────────┬─────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│  Tier 3: Database-Backed Functionality (DATABASE_URL)  │
└──────────────────────────┬─────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│  Tier 4: Full Application Readiness (REDIS_URL)        │
└──────────────────────────┬─────────────────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│  Tier 5: Optional External Integrations (SMS, R2, etc) │
└────────────────────────────────────────────────────────┘
```

### Tier 1: Required for Process Startup
* **Variables:** `PORT`
* **Behavior:** In `backend/src/main.ts#L28,L86`, Fastify listens on `port` bound to `0.0.0.0`.
* **Application Failure without it:** None (defaults to 3000), but Railway's HTTP ingress edge cannot route traffic to the container unless it binds to Railway's injected `$PORT`.
* **Railway Status:** **AUTOMATICALLY INJECTED** by Railway.

### Tier 2: Required for Secure Production Operation
* **Variables:** `NODE_ENV=production`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`
* **Behavior:**
  - `NODE_ENV`: Activates production logging, disables insecure in-memory mock fallbacks, and prevents dev-level OTP leaks.
  - `JWT_ACCESS_SECRET`: Signs JWT access tokens (`session.service.ts#L68`) and acts as HMAC pepper for hashing user OTPs (`otp.service.ts#L45,L353`).
  - `JWT_REFRESH_SECRET`: Validated by `envSchema` (`.min(16)`).
* **Application Failure without it:** Process boots (using fallback strings from `env.config.ts`), but **CRITICAL SECURITY VULNERABILITY**: tokens and OTPs can be forged or reversed.

### Tier 3: Required for Database-Backed Functionality
* **Variables:** `DATABASE_URL` (or aliases `POSTGRES_URL`, `DATABASE_PUBLIC_URL`)
* **Behavior:** In `backend/prisma/schema.prisma#L3` and `backend/src/core/database/prisma.service.ts#L26`, establishes connection pool to PostgreSQL.
* **Application Failure without it:** The container starts and `/health/live` returns HTTP 200, but:
  - `PrismaService.onModuleInit()` catches connection error and logs error (`prisma.service.ts#L40`).
  - Any API endpoint calling Prisma throws 500.
  - `/health/ready` returns HTTP 503 (`database: down`).

### Tier 4: Required for Full Application Readiness
* **Variables:** `REDIS_URL` (or pair `REDIS_CACHE_URL` + `REDIS_QUEUE_URL`)
* **Behavior:** Initialized by `RedisService.onModuleInit()` for both Cache (Port 6379) and Queue (Port 6380).
* **Application Failure without it:**
  - In `NODE_ENV=production`, cache fallback is **DISABLED** (`redis.service.ts#L298,L329`), causing all cache lookups to return `null`.
  - Rate limiting and OTP cooldowns fail open or reject.
  - BullMQ queue workers fail.
  - `/health/ready` returns **HTTP 503 Service Unavailable** (`redis_cache: down, redis_queue: down`).

### Tier 5: Optional External Integrations
* **Variables:** `SMS_MISR_*`, `R2_*`, `CLOUDFLARE_STREAM_*`, `FIREBASE_*`, `PAYMOB_*`
* **Behavior:** Modular integrations. The backend has graceful fallbacks (e.g. `MockSmsAdapter` in development, local storage stubs, disabled payment flag `ENABLE_V2_PAYMENTS=false`).
* **Application Failure without it:** None. The core marketplace, authentication, search, and health endpoints function without them.

---

## 4. Deep Redis Implementation Audit (8 Authoritative Answers)

### Question 1: Can the application start without Redis?
**YES.**  
**Code Evidence:** In [`backend/src/core/redis/redis.service.ts#L126-L131`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L126-L131) and [`#L182-L187`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L182-L187):
```typescript
await this.cacheClient.connect().catch((err) => {
  this.isCacheHealthy = false;
  this.logger.warn(`Redis Cache not accessible at startup (${err.message}) at ${displayEndpoint}.`);
});
```
Connection rejections are caught in `catch` blocks and logged as warnings. They do **not** throw or reject during `onModuleInit()`.

---

### Question 2: Can it serve API requests without Redis?
**YES, but with degraded performance and no caching.**  
**Code Evidence:** API controllers communicate with services that check `isCacheHealthy`. If Redis is down, reads proceed directly to Prisma PostgreSQL. However, background queues and OTP cooldown tracking are degraded.

---

### Question 3: Does the cache use an in-memory fallback?
**YES in development and test, but EXPLICITLY DISABLED in production.**  
**Code Evidence:** In [`backend/src/core/redis/redis.service.ts#L297-L300`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L297-L300) and [`#L329-L331`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L329-L331):
```typescript
// Controlled fallback for test mode only
if (this.configService.get('NODE_ENV') === 'production') {
  return null;
}
```
In `production`, if Redis Cache is down, `get()` immediately returns `null` and `set()` performs a no-op instead of populating `inMemoryFallback`. This prevents uncontrolled memory growth and cross-replica inconsistency in containerized deployments.

---

### Question 4: Does BullMQ have an in-memory fallback?
**NO.**  
**Code Evidence:** In [`backend/src/core/redis/redis.service.ts#L145,L251`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L145-L251), BullMQ requires a live Redis client connection (`maxRetriesPerRequest: null`). BullMQ has no in-memory queue adapter. Note that while [`backend/src/workers/worker.service.ts#L42-L76`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/workers/worker.service.ts#L42-L76) runs cron-like maintenance via `setInterval` in-process, any queue-based jobs routed through BullMQ cannot be enqueued or processed without Redis.

---

### Question 5: Does `/health/ready` require both Redis connections?
**YES.**  
**Code Evidence:** In [`backend/src/core/health/health.controller.ts#L40-L64`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/health/health.controller.ts#L40-L64):
```typescript
const [dbResult, postgisResult, cacheResult, queueResult] =
  await Promise.allSettled([
    this.prisma.ping(),
    this.prisma.checkPostgisSupport(),
    this.redisService.pingCache(),
    this.redisService.pingQueue(),
  ]);

const isHealthy = dbHealthy && postgisHealthy && cacheHealthy && queueHealthy;
```
If either `cacheHealthy` or `queueHealthy` is `false`, `isHealthy` evaluates to `false`, and line 85 returns **HTTP 503 Service Unavailable**.

---

### Question 6: Does `REDIS_URL` configure both cache and queue?
**YES.**  
**Code Evidence:** In [`backend/src/core/redis/redis.service.ts#L41-L44`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L41-L44) (`resolveCacheTarget`) and [`#L64-L67`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L64-L67) (`resolveQueueTarget`):
```typescript
const url = this.configService.get<string>('REDIS_CACHE_URL') || this.configService.get<string>('REDIS_URL');
```
and
```typescript
const url = this.configService.get<string>('REDIS_QUEUE_URL') || this.configService.get<string>('REDIS_URL');
```
When `REDIS_URL` is supplied, both clients connect to that single Redis endpoint.

---

### Question 7: Can `REDIS_CACHE_URL` and `REDIS_QUEUE_URL` configure independent connections?
**YES.**  
**Code Evidence:** `resolveCacheTarget()` checks `REDIS_CACHE_URL` first. `resolveQueueTarget()` checks `REDIS_QUEUE_URL` first. If both are set, they point to separate physical Redis instances (e.g. Cache on port 6379, Queue on port 6380).

---

### Question 8: What happens when only one Redis connection is available?
If only one target is reachable:
- If only Cache is up: Cache read/write succeeds, but Queue operations fail, and `/health/ready` returns HTTP 503 (`redis_queue: down`).
- If only Queue is up: BullMQ operates, but Cache operations fail, and `/health/ready` returns HTTP 503 (`redis_cache: down`).
- **If unified `REDIS_URL` is set:** Both clients point to that same instance. Both `pingCache()` and `pingQueue()` succeed against that instance, resulting in HTTP 200 on `/health/ready`.

### Architectural Trade-offs: Single Redis (`REDIS_URL`) vs. Dual Topology (ADR-013)
* **ADR-013 Dual Topology:**
  - *Redis Cache (Port 6379):* Configured with `maxmemory-policy: allkeys-lru`. Used for volatile session cache, rate-limiting counters, and listing query caches. When memory fills up, least-recently-used keys are evicted harmlessly.
  - *Redis Queue (Port 6380):* Configured with `maxmemory-policy: noeviction` and `appendonly yes` (AOF persistence). Used for BullMQ queues and transactional outbox.
* **Unified Redis (`REDIS_URL`):**
  - **Trade-off:** If a single Redis instance is shared in high-traffic production, an LRU eviction policy may accidentally evict BullMQ queue state, delayed jobs, or pending outbox events. Conversely, a `noeviction` policy on a shared instance will crash cache writes with `OOM command not allowed` once memory is exhausted.
  - **Recommendation:** A single `REDIS_URL` is fully acceptable for **staging and testing**, but production should use separated Redis instances or an instance configured with careful prefix-based memory limits.

---

## 5. Deep JWT Security Audit

### 5.1 Secrets Configuration & Default Values
In [`backend/src/core/config/env.config.ts#L40-L47`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L40-L47):
* `JWT_ACCESS_SECRET` default: `'dealone_default_access_secret_key_32chars_min_production!'`
* `JWT_REFRESH_SECRET` default: `'dealone_default_refresh_secret_key_32chars_min_production!'`

### 5.2 Does Production Reject Default Secrets?
* **Code Finding:** In [`backend/src/core/config/env.config.ts#L123-L125`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L123-L125), `validateEnv` logs a console warning (`console.warn`) when defaults are used, but does **not** throw an unhandled exception unless `NODE_ENV === 'test'`.
* **Security Finding:** Although the container boots, running with default secrets in production is an extreme risk.

### 5.3 Minimum Secret Length
* Schema constraint: `.min(16, 'JWT_ACCESS_SECRET must be at least 16 chars')` at [`env.config.ts#L42`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L42).
* Runtime assertion: In [`backend/src/modules/auth/services/session.service.ts#L54-L58`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/services/session.service.ts#L54-L58):
  ```typescript
  if (!accessSecret || accessSecret.length < 16) {
    throw new Error('JWT_ACCESS_SECRET must be at least 16 characters in configuration.');
  }
  ```

### 5.4 Must Access and Refresh Secrets Differ?
* The Zod validation schema does not enforce `JWT_ACCESS_SECRET !== JWT_REFRESH_SECRET`.
* However, in [`backend/src/modules/auth/services/session.service.ts#L76-L95`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/services/session.service.ts#L76-L95), **refresh tokens are NOT JWTs!**
* **Architectural Discovery:** Refresh tokens in Deal One are 40-byte cryptographically random hex strings (`crypto.randomBytes(40).toString('hex')`) hashed with SHA-256 (`hashRefreshToken`) and stored in the PostgreSQL database table `UserSession`.
* Therefore, `JWT_REFRESH_SECRET` is defined in `envSchema` for forward compatibility, but runtime refresh rotation relies on cryptographic random generation and database hashing.

### 5.5 Critical Discovery: OTP Dependency on `JWT_ACCESS_SECRET`
* **Finding:** OTP generation and validation **directly depend on `JWT_ACCESS_SECRET`**.
* **Code Evidence:** In [`backend/src/modules/auth/services/otp.service.ts#L44-L47,L350-L355`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/services/otp.service.ts#L44-L47):
  ```typescript
  this.otpPepper = this.configService.get<string>(
    'JWT_ACCESS_SECRET',
    'deal_one_fallback_pepper',
  );
  ...
  hashOtp(code: string): string {
    return crypto
      .createHash('sha256')
      .update(code + this.otpPepper)
      .digest('hex');
  }
  ```
* **Security Implication:** The OTP hash stored in PostgreSQL is `SHA256(code + JWT_ACCESS_SECRET)`. If `JWT_ACCESS_SECRET` is rotated while users have pending OTP challenges, those OTPs cannot be verified. Furthermore, if `JWT_ACCESS_SECRET` is left as default, attackers can precompute rainbow tables for all 1,000,000 possible 6-digit OTP codes and bypass SMS security.

---

## 6. Database and PostGIS Audit

### 6.1 Does Startup Fail Without `DATABASE_URL`?
* **NO.** In [`backend/src/core/database/prisma.service.ts#L24-L41`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/database/prisma.service.ts#L24-L41), `onModuleInit()` wraps `this.$connect()` in a `try/catch` block. If connection fails, it sets `isConnected = false` and logs an error, allowing the HTTP server to start.
* However, `/health/live` will pass while `/health/ready` will return HTTP 503 (`database: down`).

### 6.2 PostGIS Extension Necessity and Verification
* **Necessity:** Mandatory for marketplace spatial queries (e.g. finding listings by radius or location coordinates).
* **Verification Code:** In [`backend/src/core/database/prisma.service.ts#L65-L80`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/database/prisma.service.ts#L65-L80):
  ```typescript
  const result = await this.$queryRaw<Array<{ postgis_version: string }>>`
    SELECT PostGIS_Version() as postgis_version;
  `;
  ```
* In [`backend/src/core/health/health.controller.ts#L50,L63`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/health/health.controller.ts#L50-L63), if PostGIS is not enabled in the database, `postgisHealthy` is `false`, and `/health/ready` returns HTTP 503.
* **Action Required:** PostgreSQL on Railway MUST have PostGIS enabled (`CREATE EXTENSION IF NOT EXISTS postgis;`).

### 6.3 Migration Execution: Startup vs. Separate Step
* In [`railway.json#L8`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/railway.json#L8) and [`Dockerfile#L36`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/Dockerfile#L36):
  `startCommand: "node dist/src/main.js"`
* **Finding:** Migrations (`prisma migrate deploy`) are **NOT** executed inside the application container startup command.
* **DevOps Validation:** This is correct practice. Running migrations in `startCommand` during horizontal autoscaling causes deployment concurrency deadlocks on `_prisma_migrations`. Migrations must be executed as a pre-deploy release command or via Railway CLI (`railway run npx prisma migrate deploy`).

---

## 7. Railway Variable Mapping & UNVERIFIED Services

### 7.1 Railway Reference Variable Syntax
Railway supports cross-service variable references using the syntax:
`${{ServiceName.VARIABLE}}`

### 7.2 Service Verification Status
* In the active deployment canvas for project `airy-creativity`, the only visible service is:
  **`one-deal`** (Backend web application)
* **UNVERIFIED SERVICES:**
  - Neither a PostgreSQL service nor a Redis service can be confirmed as provisioned inside the user's Railway canvas.
  - If a PostgreSQL service was created with default naming, the reference is: `${{Postgres.DATABASE_URL}}`
  - If a Redis service was created with default naming, the reference is: `${{Redis.REDIS_URL}}`
  - If external managed services are used (e.g., Neon, Supabase, Upstash), direct connection URI strings must be provided instead of Railway references.

---

## 8. Staging vs. Production Security Configuration

| Configuration Aspect | Staging Environment | Production Environment | Security Blast Radius if Staging Used in Prod |
|---|---|---|---|
| `NODE_ENV` | `staging` or `development` | `production` | **Critical:** In dev mode, OTP codes are logged in plaintext to stdout (`mock-sms.adapter.ts#L46`). |
| `JWT_ACCESS_SECRET` | Any 32+ char random string | High-entropy 64-char hex secret | **Critical:** Anyone knowing the secret can forge access tokens with `role: "ADMIN"` and forge OTP hashes. |
| `DATABASE_URL` | Staging DB with test data | Production isolated PostgreSQL with backups & PostGIS | **Catastrophic:** Overwriting or leaking live customer data. |
| `REDIS_URL` | Single shared Redis instance | Dual Redis (or separated instances with eviction protection) | **High:** Under load, volatile cache eviction can drop BullMQ jobs and async event delivery. |
| `SMS_PROVIDER` | `MOCK` | `SMS_MISR` | **Medium:** In prod, `MockSmsAdapter` refuses to send and returns an error (`mock-sms.adapter.ts#L28-L38`). |
| `ENABLE_V2_PAYMENTS`| `false` | `false` (until V2 release) | None (feature gated). |

---

## 9. Definitive Resolution: The Smallest Safe Set of Environment Variables

To deploy and test the **Deal One staging API** on Railway with full `/health/live` (200), `/health/ready` (200), functional authentication, and database persistence, configure exactly these **5 environment variables**:

```env
NODE_ENV=staging
DATABASE_URL=postgresql://<user>:<password>@<host>:<port>/<dbname>?schema=public
JWT_ACCESS_SECRET=c2e8b23f81e3dc793f18e5b4b1a7d6e5c9f2a4b8e1d7c3b5a9e7f4d2c8b1a3e5
JWT_REFRESH_SECRET=f9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8
REDIS_URL=redis://default:<password>@<host>:<port>
```

### Why this is the absolute minimum safe set:
1. `NODE_ENV=staging`: Activates non-production mode, allowing `MockSmsAdapter` to operate safely without needing paid SMS Misr credentials.
2. `DATABASE_URL`: Enables PostgreSQL connection pool and PostGIS verification so `/health/ready` passes and API entities can be persisted.
3. `JWT_ACCESS_SECRET`: Satisfies the 16-character minimum requirement, signs JWT tokens, and acts as the cryptographic pepper for OTP hashing.
4. `JWT_REFRESH_SECRET`: Satisfies `envSchema` validation without triggering warnings or test failures.
5. `REDIS_URL`: Provides unified connection for both Cache and Queue clients, ensuring `/health/ready` returns HTTP 200 without requiring two separate Redis databases.
*(Note: `PORT` is omitted from the list because Railway automatically injects it into the container runtime).*

