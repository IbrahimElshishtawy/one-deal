# Deal One — Final Staging Configuration & Deployment Runbook

**Target:** Deal One Backend (NestJS / Fastify / Prisma)  
**Deployment Target:** Railway Staging (`one-deal` service in project `airy-creativity`)  
**Date:** November 7, 2026  
**Auditor / DevOps Specialist:** Senior DevOps & Railway Specialist  
**Status:** Verification Complete — Ready for Configuration  

---

## 1. NODE_ENV — Critical Verification & Findings

### 1.1 Exact Zod Enum in Code
In [`backend/src/core/config/env.config.ts#L4-L6`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L4-L6):
```typescript
NODE_ENV: z
  .enum(['development', 'test', 'production'])
  .default('development'),
```

> [!CAUTION]
> **`NODE_ENV=staging` IS NOT ACCEPTED BY THE SCHEMA.**  
> The Zod schema strictly validates against `['development', 'test', 'production']`. Setting `NODE_ENV=staging` causes Zod validation to fail (`Invalid enum value. Expected 'development' | 'test' | 'production', received 'staging'`). In strict validation, this throws an uncaught error and crashes the container.

### 1.2 Under Which Exact Condition is `MockSmsAdapter` Selected?
In [`backend/src/modules/auth/auth.module.ts#L48-L71`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/auth.module.ts#L48-L71):
```typescript
const provider = configService.get<string>('SMS_PROVIDER', 'SMS_MISR');
const nodeEnv = configService.get<string>('NODE_ENV', 'development');
const isTestEnv = process.env.NODE_ENV === 'test' || nodeEnv === 'test';

if (isTestEnv) {
  return mockSms;
}

if (
  provider === 'SMS_MISR' &&
  smsMisr.isConfigured() &&
  !smsMisr.isPlaceholder()
) {
  return smsMisr;
}

if (nodeEnv === 'production') {
  // In production, fallback to SmsMisr which will fail safely if unconfigured
  return smsMisr;
}

// In local development with placeholder or mock config, use MockSmsAdapter
return mockSms;
```

And in [`backend/src/modules/auth/adapters/mock-sms.adapter.ts#L25-L48`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/adapters/mock-sms.adapter.ts#L25-L48):
* If `NODE_ENV === 'production'`, `MockSmsAdapter` throws a security error and refuses to deliver OTPs.
* If `NODE_ENV === 'development'`, `MockSmsAdapter` logs the plain-text 6-digit OTP code directly to standard output:
  ```text
  📱 [DEV SMS SIMULATION] Dispatched OTP code to +2010XXXXXXXX: [ 123456 ]
  ```

### 1.3 Can OTP Testing Work Without SMS Misr Credentials?
**YES.**  
When `NODE_ENV=development` and SMS Misr credentials are not provided:
1. `auth.module.ts` automatically selects `MockSmsAdapter`.
2. When a test user requests an OTP via `/api/v1/auth/otp/request`, `MockSmsAdapter.sendOtp` returns `{ success: true }`.
3. The generated OTP code is printed directly into the **Railway Deployment Logs** for the `one-deal` service.
4. You can copy the 6-digit code from the Railway log console and pass it to `/api/v1/auth/otp/verify` to log in and receive an access token.

### 1.4 Safest Existing Configuration for Temporary Railway Staging
The safest and only valid configuration for staging without SMS Misr credentials is:
```env
NODE_ENV=development
```

---

## 2. JWT Configuration & Security Requirements

### 2.1 Validation Constraints
* **Minimum Length:** Exactly **16 characters** enforced by Zod (`.min(16)`) in [`env.config.ts#L42,L46`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L42) and verified at runtime in [`session.service.ts#L54-L58`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/services/session.service.ts#L54-L58).
* **Must They Be Different?**  
  The Zod schema does not enforce `JWT_ACCESS_SECRET !== JWT_REFRESH_SECRET`. However, cryptographic best practices require them to be independent.
* **Do Default Values Generate Warnings?**  
  Yes. If invalid or short strings are passed, `validateEnv` outputs a warning in non-test environments.
* **Critical Finding — OTP Pepper:**  
  [`otp.service.ts#L44-L47,L350-L355`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/services/otp.service.ts#L44-L47) consumes `JWT_ACCESS_SECRET` as the HMAC pepper for hashing OTPs stored in PostgreSQL (`SHA256(code + JWT_ACCESS_SECRET)`). If `JWT_ACCESS_SECRET` is changed while an OTP challenge is pending, the challenge becomes invalid.

### 2.2 Secure JWT Secret Generation
Generate two independent 64-character hexadecimal secrets using `openssl`:

```bash
# Generate JWT_ACCESS_SECRET
openssl rand -hex 32

# Generate JWT_REFRESH_SECRET
openssl rand -hex 32
```

---

## 3. Redis Architecture & Health Verification

### 3.1 Single `REDIS_URL` Initialization
In [`backend/src/core/redis/redis.service.ts#L41-L44,L64-L67`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L41-L44):
* `resolveCacheTarget()` falls back to `this.configService.get<string>('REDIS_URL')`.
* `resolveQueueTarget()` falls back to `this.configService.get<string>('REDIS_URL')`.

When `REDIS_URL` is set, `RedisService.onModuleInit()` connects both the Cache client (Port 6379 semantics) and the Queue client (Port 6380 semantics) to that single Redis connection string.

### 3.2 Health Check Impact
In [`backend/src/core/health/health.controller.ts#L44-L64`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/health/health.controller.ts#L44-L64):
* `pingCache()`: Executes `cacheClient.ping()` (returns `true`).
* `pingQueue()`: Executes `queueClient.ping()` (returns `true`).
* `/health/ready`: Returns `HTTP 200 OK` with:
  ```json
  {
    "status": "healthy",
    "checks": {
      "database": "up",
      "postgis": "up (3.4 USE_GEOS=1 ...)",
      "redis_cache": "up",
      "redis_queue": "up",
      "workers": "active"
    }
  }
  ```

### 3.3 Is a Single Redis Instance Acceptable for Staging?
**YES.**  
For temporary staging, a single Redis instance is fully acceptable. Memory pressure in staging is minimal, so volatile LRU cache evictions will not interfere with BullMQ queues. In high-volume production, separate Redis instances (ADR-013) remain mandatory.

---

## 4. Database & PostGIS Requirements

### 4.1 PostgreSQL & PostGIS Verification
* **PostgreSQL Version:** PostgreSQL 14 or higher.
* **PostGIS Extension:** Mandatory. In [`backend/src/core/database/prisma.service.ts#L70-L72`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/database/prisma.service.ts#L70-L72), the application verifies PostGIS by executing:
  ```sql
  SELECT PostGIS_Version() as postgis_version;
  ```
  If PostGIS is missing, `/health/ready` reports `postgis: down` and returns HTTP 503.
* **Enabling PostGIS:**  
  Connect to the database as superuser/owner and execute:
  ```sql
  CREATE EXTENSION IF NOT EXISTS postgis;
  ```

### 4.2 Migration Execution Context (`prisma migrate deploy`)

> [!IMPORTANT]
> **Railway CLI Execution Context:**  
> `railway run <cmd>` does **not** run inside the remote production container. It runs the command **locally on your machine**, but injects the remote Railway service's environment variables.

#### Prerequisites for Running Migrations from Local Machine:
1. Railway CLI installed: `npm i -g @railway/cli` or `curl -fsSL https://railway.com/install.sh | sh`.
2. Authenticated: `railway login`.
3. Linked to the project:
   ```bash
   cd "/home/ibrahim-elshishtawy/flutter project/market_space"
   railway link
   # Select project: airy-creativity
   # Select environment: production (or staging)
   # Select service: one-deal
   ```
4. If using `DATABASE_PUBLIC_URL` (external TCP proxy domain provided by Railway PostgreSQL):
   ```bash
   cd backend
   DATABASE_URL="<DATABASE_PUBLIC_URL>" npx prisma migrate deploy
   ```
5. If using Railway private networking with `railway run`:
   ```bash
   cd backend
   railway run npx prisma migrate deploy
   ```

---

## 5. Minimal Staging Environment Variables

Configure exactly these **5 environment variables** in Railway under `one-deal` > **Variables**:

| Variable Name | Staging Value | Purpose |
|---|---|---|
| **`NODE_ENV`** | `development` | Enables safe mock SMS logging and accepted Zod enum |
| **`DATABASE_URL`** | `postgresql://<user>:<password>@<host>:<port>/<dbname>?schema=public` | PostgreSQL connection string with PostGIS enabled |
| **`JWT_ACCESS_SECRET`** | *(64-character random hex from `openssl rand -hex 32`)* | Signs JWT access tokens & peppers OTP hashes |
| **`JWT_REFRESH_SECRET`** | *(64-character random hex from `openssl rand -hex 32`)* | Validates session schema |
| **`REDIS_URL`** | `redis://default:<password>@<host>:<port>` | Unified Redis for Cache & BullMQ Queue |

*(Note: `PORT` is automatically managed and injected by Railway; do not set it manually).*

---

## 6. Remaining Blockers & Next Actions

1. **Database Provisioning:**  
   Ensure a PostgreSQL service is provisioned in the Railway project canvas (or external managed DB) and PostGIS is enabled (`CREATE EXTENSION IF NOT EXISTS postgis;`).
2. **Redis Provisioning:**  
   Ensure a Redis service is provisioned in Railway (or external Upstash/Aiven) to provide `REDIS_URL`.
3. **Set Variables in Railway:**  
   In Railway Dashboard > `one-deal` > **Variables**, paste the 5 variables above.
4. **Deploy & Apply Migrations:**  
   Trigger deployment, then run `npx prisma migrate deploy` against the database to create the schema tables.
5. **Verify Endpoints:**  
   - `GET /health/live` -> `200 OK`
   - `GET /health/ready` -> `200 OK`
   - `POST /api/v1/auth/otp/request` -> Check Railway logs for simulated OTP code.

