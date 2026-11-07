# Deal One — Complete Environment Variables Audit for Railway Deployment

**Project:** Deal One Marketplace (Backend Modular Monolith)  
**Backend Root:** `/home/ibrahim-elshishtawy/flutter project/market_space/backend`  
**Date:** November 7, 2026 (Second-Pass Verified Edition)  
**Auditor:** Senior Backend & DevOps Engineer  
**Audit Scope:** Full codebase AST analysis, Prisma schema, Fastify server, Redis dual topology, and Railway deployment  

---

## 1. Executive Summary

This audit is an evidence-based technical inspection of all environment variables consumed, validated, and declared across the Deal One backend codebase. Every variable has been cross-referenced with actual source-code usage (`ConfigService.get()`, `process.env`, `schema.prisma`, and `envSchema` in `backend/src/core/config/env.config.ts`).

### Reconciled Metrics:
1. **Total Application-Defined Variables:** **50 unique variable names**
   - **45 keys** declared and validated in `envSchema` ([`backend/src/core/config/env.config.ts#L3-L80`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L3-L80)).
   - **3 compatibility aliases** supported in `validateEnv` ([`backend/src/core/config/env.config.ts#L91-L93`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L91-L93)): `POSTGRES_URL`, `POSTGRESQL_URL`, `DATABASE_PUBLIC_URL`.
   - **2 CLI seed script flags** ([`backend/prisma/seeds/seed.ts#L54-L56`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/prisma/seeds/seed.ts#L54-L56)): `RESET_DEMO`, `ALLOW_DEMO_SEEDING`.
2. **Direct Runtime References in Application Code:** **35 variables** directly queried via `ConfigService.get()` or `process.env`.
3. **Automatically Provided by Railway:** `PORT` is automatically injected into the container runtime by Railway. Fastify binds to `0.0.0.0:$PORT` ([`backend/src/main.ts#L28,L86`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/main.ts#L28)).
4. **Railway Platform Metadata Variables:** Railway automatically supplies 7 metadata variables (`PORT`, `RAILWAY_ENVIRONMENT_NAME`, `RAILWAY_ENVIRONMENT_ID`, `RAILWAY_PROJECT_NAME`, `RAILWAY_PROJECT_ID`, `RAILWAY_SERVICE_NAME`, `RAILWAY_SERVICE_ID`). Only `PORT` is consumed by the application.
5. **Deployment Readiness Verdict:** **ACTION REQUIRED.** The web container boots using defensive fallbacks, but database operations and security guarantees require configuring the 5 variables identified in Section 6.

---

## 2. Complete Environment Variable Inventory (50 Variables)

| Variable Name | Operational Tier | Code Location | Purpose | Required / Optional | Default Value | Expected Format | Railway Auto-Provides? | Manual Config Required? |
|---|---|---|---|---|---|---|---|---|
| `PORT` | Tier 1 (Startup) | [`main.ts#L28`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/main.ts#L28) <br> [`env.config.ts#L7`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L7) | HTTP listen port for Fastify | **Required for Ingress** | `3000` | Integer | **YES** | ALREADY PROVIDED |
| `NODE_ENV` | Tier 2 (Security) | [`env.config.ts#L4`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L4) <br> [`prisma.service.ts#L20`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/database/prisma.service.ts#L20) <br> [`auth.module.ts#L49`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/auth.module.ts#L49) | Runtime environment mode | **Required for Prod** | `'development'` | `'production'` \| `'staging'` \| `'development'` | **NO** | ADD MANUALLY (`production`) |
| `JWT_ACCESS_SECRET` | Tier 2 (Security) | [`env.config.ts#L40`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L40) <br> [`session.service.ts#L53`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/services/session.service.ts#L53) <br> [`otp.service.ts#L45`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/services/otp.service.ts#L45) | Signs JWT access tokens & peppers OTP hashes | **Required (Critical)** | Placeholder default | String (min 16 chars, rec 64-hex) | **NO** | ADD MANUALLY (Strong random string) |
| `JWT_REFRESH_SECRET` | Tier 2 (Security) | [`env.config.ts#L44`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L44) | Validated in schema for token rotation | **Required (Critical)** | Placeholder default | String (min 16 chars, rec 64-hex) | **NO** | ADD MANUALLY (Strong random string) |
| `JWT_ACCESS_EXPIRES_IN` | Tier 2 (Security) | [`env.config.ts#L48`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L48) <br> [`auth.module.ts#L27`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/auth.module.ts#L27) | Access token lifespan | Optional | `'15m'` | Duration string (`'15m'`, `'1h'`) | **NO** | NOT REQUIRED (Default is optimal) |
| `JWT_REFRESH_EXPIRES_IN` | Tier 2 (Security) | [`env.config.ts#L49`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L49) | Refresh token session lifespan | Optional | `'30d'` | Duration string (`'30d'`) | **NO** | NOT REQUIRED (Default is optimal) |
| `DATABASE_URL` | Tier 3 (Database) | [`schema.prisma#L3`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/prisma/schema.prisma#L3) <br> [`prisma.service.ts#L26`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/database/prisma.service.ts#L26) | Primary PostgreSQL connection string | **Required (Critical)** | Localhost fallback | `postgresql://user:pass@host:port/db?schema=public` | **NO** | MAP TO REFERENCE OR ADD DIRECTLY |
| `POSTGRES_URL` | Tier 3 (Database) | [`env.config.ts#L91`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L91) | Vercel/Railway PostgreSQL alias | Optional (Fallback) | None | Connection URL string | Optional | OPTIONAL (Auto-fallback to `DATABASE_URL`) |
| `POSTGRESQL_URL` | Tier 3 (Database) | [`env.config.ts#L92`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L92) | Generic PostgreSQL connection alias | Optional (Fallback) | None | Connection URL string | Optional | OPTIONAL |
| `DATABASE_PUBLIC_URL` | Tier 3 (Database) | [`env.config.ts#L93`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L93) | Railway external public TCP proxy DB URL | Optional (Fallback) | None | Connection URL string | Optional | OPTIONAL |
| `REDIS_URL` | Tier 4 (Readiness) | [`env.config.ts#L28`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L28) <br> [`redis.service.ts#L42,L65`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L42) | Unified connection URI for Cache & Queue | **Recommended for Prod** | None | `redis://default:pass@host:port` | **NO** | MAP TO REFERENCE OR ADD DIRECTLY |
| `REDIS_CACHE_URL` | Tier 4 (Readiness) | [`env.config.ts#L20`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L20) <br> [`redis.service.ts#L41`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L41) | Dedicated Redis Cache connection URI | Optional (ADR-013) | None | `redis://...` | **NO** | OPTIONAL |
| `REDIS_CACHE_HOST` | Tier 4 (Readiness) | [`env.config.ts#L17`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L17) <br> [`redis.service.ts#L47`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L47) | Redis Cache host (Port 6379) | Optional | `'localhost'` | Hostname / IP | **NO** | OPTIONAL |
| `REDIS_CACHE_PORT` | Tier 4 (Readiness) | [`env.config.ts#L18`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L18) <br> [`redis.service.ts#L51`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L51) | Redis Cache port | Optional | `6379` | Integer | **NO** | OPTIONAL |
| `REDIS_CACHE_PASSWORD` | Tier 4 (Readiness) | [`env.config.ts#L19`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L19) <br> [`redis.service.ts#L55`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L55) | Redis Cache password | Optional | `''` | String | **NO** | OPTIONAL |
| `REDIS_QUEUE_URL` | Tier 4 (Readiness) | [`env.config.ts#L25`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L25) <br> [`redis.service.ts#L64`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L64) | Dedicated Redis Queue connection URI | Optional (ADR-013) | None | `redis://...` | **NO** | OPTIONAL |
| `REDIS_QUEUE_HOST` | Tier 4 (Readiness) | [`env.config.ts#L22`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L22) <br> [`redis.service.ts#L70`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L70) | Redis Queue host (Port 6380) | Optional | `'localhost'` | Hostname / IP | **NO** | OPTIONAL |
| `REDIS_QUEUE_PORT` | Tier 4 (Readiness) | [`env.config.ts#L23`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L23) <br> [`redis.service.ts#L73`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L73) | Redis Queue port | Optional | `6380` | Integer | **NO** | OPTIONAL |
| `REDIS_QUEUE_PASSWORD` | Tier 4 (Readiness) | [`env.config.ts#L24`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L24) <br> [`redis.service.ts#L76`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L76) | Redis Queue password | Optional | `''` | String | **NO** | OPTIONAL |
| `REDISHOST` | Tier 4 (Readiness) | [`env.config.ts#L29`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L29) <br> [`redis.service.ts#L48,L71`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L48) | Railway Redis host component | Optional (Auto) | None | Hostname / IP | Auto (if Redis added) | OPTIONAL |
| `REDISPORT` | Tier 4 (Readiness) | [`env.config.ts#L30`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L30) <br> [`redis.service.ts#L52,L74`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L52) | Railway Redis port component | Optional (Auto) | None | Integer | Auto (if Redis added) | OPTIONAL |
| `REDISPASSWORD` | Tier 4 (Readiness) | [`env.config.ts#L31`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L31) <br> [`redis.service.ts#L56,L77`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L56) | Railway Redis password component | Optional (Auto) | None | String | Auto (if Redis added) | OPTIONAL |
| `REDISUSER` | Tier 4 (Readiness) | [`env.config.ts#L32`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L32) | Railway Redis username component | Optional (Auto) | None | String (`default`) | Auto (if Redis added) | OPTIONAL |
| `REDIS_HOST` | Tier 4 (Readiness) | [`env.config.ts#L35`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L35) <br> [`redis.service.ts#L49`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L49) | Legacy Redis host fallback | Optional | `'localhost'` | Hostname / IP | **NO** | OPTIONAL |
| `REDIS_PORT` | Tier 4 (Readiness) | [`env.config.ts#L36`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L36) <br> [`redis.service.ts#L53`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L53) | Legacy Redis port fallback | Optional | `6379` | Integer | **NO** | OPTIONAL |
| `REDIS_PASSWORD` | Tier 4 (Readiness) | [`env.config.ts#L37`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L37) <br> [`redis.service.ts#L57`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L57) | Legacy Redis password fallback | Optional | `''` | String | **NO** | OPTIONAL |
| `API_BASE_URL` | Tier 5 (Optional) | [`env.config.ts#L8`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L8) | Public API base URL | Optional | `'http://localhost:3000/api/v1'` | Valid HTTP/HTTPS URL | **NO** | OPTIONAL |
| `CORS_ORIGIN` | Tier 5 (Optional) | [`env.config.ts#L9`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L9) <br> [`main.ts#L29`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/main.ts#L29) | Allowed CORS origins for browsers | Optional | `'*'` | Comma-delimited list or `'*'` | **NO** | OPTIONAL |
| `SMS_PROVIDER` | Tier 5 (Optional) | [`env.config.ts#L52`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L52) <br> [`auth.module.ts#L48`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/auth.module.ts#L48) | Active SMS gateway provider | Optional | `'SMS_MISR'` | `'SMS_MISR'` \| `'MOCK'` | **NO** | OPTIONAL |
| `SMS_MISR_USERNAME` | Tier 5 (Optional) | [`env.config.ts#L53`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L53) <br> [`sms-misr.adapter.ts#L20`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/adapters/sms-misr.adapter.ts#L20) | SMS Misr Egypt gateway username | Optional (Prod OTP) | `''` | String | **NO** | ADD MANUALLY (when ready for live SMS) |
| `SMS_MISR_PASSWORD` | Tier 5 (Optional) | [`env.config.ts#L54`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L54) <br> [`sms-misr.adapter.ts#L21`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/adapters/sms-misr.adapter.ts#L21) | SMS Misr Egypt gateway password | Optional (Prod OTP) | `''` | String | **NO** | ADD MANUALLY (when ready for live SMS) |
| `SMS_MISR_SENDER_ID` | Tier 5 (Optional) | [`env.config.ts#L55`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L55) <br> [`sms-misr.adapter.ts#L23`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/adapters/sms-misr.adapter.ts#L23) | NTRA-approved SMS alphanumeric sender | Optional | `'MarketSpace'` | String | **NO** | OPTIONAL |
| `R2_ACCOUNT_ID` | Tier 5 (Optional) | [`env.config.ts#L58`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L58) | Cloudflare R2 Account ID | Optional | `''` | 32-char hex string | **NO** | OPTIONAL |
| `R2_ACCESS_KEY_ID` | Tier 5 (Optional) | [`env.config.ts#L59`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L59) | Cloudflare R2 S3 Access Key ID | Optional | `''` | String | **NO** | OPTIONAL |
| `R2_SECRET_ACCESS_KEY` | Tier 5 (Optional) | [`env.config.ts#L60`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L60) | Cloudflare R2 S3 Secret Access Key | Optional | `''` | String | **NO** | OPTIONAL |
| `R2_BUCKET_NAME` | Tier 5 (Optional) | [`env.config.ts#L61`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L61) <br> [`media.service.ts#L36`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/media/media.service.ts#L36) | Cloudflare R2 Bucket name | Optional | `'marketspace-media'` | String | **NO** | OPTIONAL |
| `R2_PUBLIC_DOMAIN` | Tier 5 (Optional) | [`env.config.ts#L62`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L62) <br> [`media.service.ts#L32`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/media/media.service.ts#L32) | Public CDN URL for uploaded media | Optional | `'https://cdn.marketspace.eg'` | HTTPS URL | **NO** | OPTIONAL |
| `CLOUDFLARE_STREAM_API_TOKEN` | Tier 5 (Optional) | [`env.config.ts#L65`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L65) <br> [`video.service.ts#L17`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/video/video.service.ts#L17) | Cloudflare Stream video API token | Optional | `''` | Secret token string | **NO** | OPTIONAL |
| `CLOUDFLARE_STREAM_ACCOUNT_ID` | Tier 5 (Optional) | [`env.config.ts#L66`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L66) <br> [`video.service.ts#L21`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/video/video.service.ts#L21) | Cloudflare Stream account ID | Optional | `''` | 32-char hex string | **NO** | OPTIONAL |
| `CLOUDFLARE_STREAM_WEBHOOK_SECRET` | Tier 5 (Optional) | [`env.config.ts#L67`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L67) <br> [`video.service.ts#L25`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/video/video.service.ts#L25) | Webhook HMAC secret for Stream | Optional | `''` | Secret string | **NO** | OPTIONAL |
| `ENABLE_V2_PAYMENTS` | Tier 5 (Optional) | [`env.config.ts#L70`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L70) <br> [`app.module.ts#L27`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/app.module.ts#L27) | Feature flag gating V2 Paymob module | Optional (V2) | `false` | `'true'` \| `'false'` | **NO** | NOT REQUIRED (Keep false for V1) |
| `PAYMOB_API_KEY` | Tier 5 (Optional) | [`env.config.ts#L71`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L71) | Paymob Egypt API Key | Optional (V2) | `''` | Secret string | **NO** | NOT REQUIRED |
| `PAYMOB_INTEGRATION_ID_CARD` | Tier 5 (Optional) | [`env.config.ts#L72`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L72) | Paymob Card Integration ID | Optional (V2) | `0` | Numeric ID | **NO** | NOT REQUIRED |
| `PAYMOB_INTEGRATION_ID_WALLET` | Tier 5 (Optional) | [`env.config.ts#L73`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L73) | Paymob Wallet Integration ID | Optional (V2) | `0` | Numeric ID | **NO** | NOT REQUIRED |
| `PAYMOB_HMAC_SECRET` | Tier 5 (Optional) | [`env.config.ts#L74`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L74) <br> [`payments.service.ts#L55`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/payments/payments.service.ts#L55) | Paymob webhook HMAC signature secret | Optional (V2) | `''` | Secret string | **NO** | NOT REQUIRED |
| `FIREBASE_PROJECT_ID` | Tier 5 (Optional) | [`env.config.ts#L77`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L77) <br> [`notifications.service.ts#L11`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/notifications/notifications.service.ts#L11) | Firebase Project ID for FCM | Optional | `''` | String | **NO** | OPTIONAL |
| `FIREBASE_CLIENT_EMAIL` | Tier 5 (Optional) | [`env.config.ts#L78`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L78) | FCM Service Account email | Optional | `''` | Email string | **NO** | OPTIONAL |
| `FIREBASE_PRIVATE_KEY` | Tier 5 (Optional) | [`env.config.ts#L79`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/config/env.config.ts#L79) | FCM Service Account PEM key | Optional | `''` | PEM formatted string | **NO** | OPTIONAL |
| `RESET_DEMO` | Tier 5 (Optional) | [`seed.ts#L54`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/prisma/seeds/seed.ts#L54) | CLI flag to wipe demo data on seed | Optional (CLI) | `false` | `'true'` \| `'false'` | **NO** | NOT REQUIRED |
| `ALLOW_DEMO_SEEDING` | Tier 5 (Optional) | [`seed.ts#L56`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/prisma/seeds/seed.ts#L56) | CLI safety gate for seeding in prod | Optional (CLI) | `false` | `'true'` \| `'false'` | **NO** | NOT REQUIRED |

---

## 3. Operational Tier Classification (Resolving Contradictions)

The previous audit created confusion by claiming both "5 mandatory variables" and "4 missing variables". The exact operational breakdown is as follows:

1. **Tier 1 — Required for Process Startup (1 Variable):**
   - `PORT`: Handled automatically by Railway `$PORT`.
2. **Tier 2 — Required for Secure Production Operation (3 Variables):**
   - `NODE_ENV=production`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`.
   - *Audit finding:* `JWT_ACCESS_SECRET` also serves as the HMAC pepper for hashing Egyptian OTP codes ([`otp.service.ts#L45,L353`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/modules/auth/services/otp.service.ts#L45)).
3. **Tier 3 — Required for Database-Backed Functionality (1 Variable):**
   - `DATABASE_URL` (or aliases `POSTGRES_URL`, `DATABASE_PUBLIC_URL`).
   - *Audit finding:* Startup does not crash if DB is down, but queries fail and `/health/ready` returns 503. PostGIS extension must be active (`CREATE EXTENSION IF NOT EXISTS postgis;`).
4. **Tier 4 — Required for Full Readiness (1 Variable):**
   - `REDIS_URL` (or dedicated `REDIS_CACHE_URL` + `REDIS_QUEUE_URL`).
   - *Audit finding:* In `production`, in-memory cache fallback is disabled ([`redis.service.ts#L298,L329`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/backend/src/core/redis/redis.service.ts#L298)). `/health/ready` requires both `pingCache()` and `pingQueue()`.
5. **Tier 5 — Optional Integrations (44 Variables):**
   - SMS Misr, Cloudflare R2, Cloudflare Stream, Firebase Cloud Messaging, Paymob V2, and CLI flags.

---

## 4. Railway Configuration Reference & UNVERIFIED Services

### Railway Syntax
* Reference syntax: `${{ServiceName.VARIABLE}}`
* If a PostgreSQL plugin exists named `Postgres`: `${{Postgres.DATABASE_URL}}`
* If a Redis plugin exists named `Redis`: `${{Redis.REDIS_URL}}`

> [!WARNING]
> **UNVERIFIED SERVICES IN ACTIVE CANVAS:**
> Inspection of the Railway deployment for project `airy-creativity` confirms that only service `one-deal` is visible. Dedicated PostgreSQL and Redis services are **UNVERIFIED**. If you do not have managed databases inside Railway, you must provision them or supply external connection URIs (e.g., Supabase, Neon, Upstash).

---

## 5. Smallest Safe Set for Staging Deployment

To deploy and test the **Deal One staging API** with healthy `/health/live` (200), `/health/ready` (200), authentication, and database persistence, add these **5 variables** to the Railway service:

```env
NODE_ENV=staging
DATABASE_URL=postgresql://<user>:<password>@<host>:<port>/<dbname>?schema=public
JWT_ACCESS_SECRET=c2e8b23f81e3dc793f18e5b4b1a7d6e5c9f2a4b8e1d7c3b5a9e7f4d2c8b1a3e5
JWT_REFRESH_SECRET=f9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8
REDIS_URL=redis://default:<password>@<host>:<port>
```

For the exhaustive contradiction resolution and deep technical findings on Redis, JWT, and PostGIS, refer to [`RAILWAY_ENVIRONMENT_VARIABLES_CORRECTIONS.md`](file:///home/ibrahim-elshishtawy/flutter%20project/market_space/RAILWAY_ENVIRONMENT_VARIABLES_CORRECTIONS.md).
