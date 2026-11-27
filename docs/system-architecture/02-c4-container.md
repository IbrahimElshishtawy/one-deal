# 02 — C4 Container Diagram

## Overview

This C4 Level-2 Container Diagram details every deployable container in the Deal One platform, its technology stack, and the exact communication protocols verified in `docker-compose.yml`, `railway.json`, `backend/Dockerfile`, `admin-web/package.json`, and `deal one app/pubspec.yaml`.

## Diagram

```mermaid
flowchart LR
    subgraph MobileTier["Mobile Client Tier"]
        Flutter["Flutter Mobile App\n[Dart / Flutter / Riverpod / GoRouter / Dio]\nLocal Secure Storage + SharedPreferences"]
    end

    subgraph WebTier["Admin Web Tier"]
        AdminSPA["Admin Web Dashboard\n[React 18 / Vite / TypeScript / TanStack Query]\nServed on :5173 (dev) / Static Build"]
    end

    subgraph EdgeTier["Edge / Reverse Proxy Tier"]
        Proxy["Railway HTTPS Edge (Prod)\nor Nginx 1.25 Reverse Proxy (Docker Local)\n[TLS Termination + HTTP/2]"]
    end

    subgraph AppTier["Backend Runtime Container (Node.js)"]
        NestAPI["Backend API Process\n[NestJS 10 + Fastify Adapter + Prisma 5]\nREST /api/v1/* | /health/* | /metrics | /api/docs"]
        BullWorker["In-Process Maintenance Workers\n[BullMQ Worker + Redis Lock Fallback]\nControlled by ENABLE_WORKERS=true|false"]
    end

    subgraph PersistenceTier["Persistence & Caching Containers"]
        Postgres[("PostgreSQL 16 + PostGIS 3.4\n[TCP :5432 | pg_stat_statements]\nPrimary Relational & Geospatial Store")]
        RedisCache[("Redis Cache Instance\n[TCP :6379 | allkeys-lru | 256MB]\nFeeds, Profiles, Rate Limits, OTP/Email Tokens")]
        RedisQueue[("Redis Queue Instance\n[TCP :6380 | AOF everysec | noeviction]\nBullMQ Repeatable Jobs & Distributed Locks")]
    end

    subgraph CloudStorage["Object & Media Cloud Tier"]
        R2Pub[("Cloudflare R2 Public Bucket\n[S3-Compatible HTTPS + CDN]")]
        R2Priv[("Cloudflare R2 Private Bucket\n[S3-Compatible HTTPS + SigV4 Only]")]
        CFStream[("Cloudflare Stream\n[HTTPS REST + HMAC Webhook]")]
    end

    Flutter -->|"HTTPS JSON (REST + JWT)"| Proxy
    AdminSPA -->|"HTTPS JSON (REST + Admin JWT + Cookie)"| Proxy
    Proxy -->|"HTTP :3000 (Fastify)"| NestAPI

    NestAPI -->|"Prisma Connection Pool (TCP :5432)"| Postgres
    NestAPI -->|"ioredis (TCP :6379)"| RedisCache
    NestAPI -->|"ioredis / BullMQ (TCP :6380)"| RedisQueue

    BullWorker -->|"Prisma (TCP :5432)"| Postgres
    BullWorker -->|"ioredis Invalidation (TCP :6379)"| RedisCache
    BullWorker -->|"BullMQ Poll / Locks (TCP :6380)"| RedisQueue

    NestAPI -->|"SigV4 Presigned PUT/GET/HEAD"| R2Priv
    BullWorker -->|"SigV4 DELETE (Retention Purge)"| R2Priv
    NestAPI -->|"Presigned PUT URLs"| R2Pub
    NestAPI -->|"Direct Upload API & Webhook Verify"| CFStream
    Flutter -.->|"Direct HTTPS PUT/GET (Presigned)"| R2Pub
    Flutter -.->|"Direct HTTPS PUT/GET (Presigned)"| R2Priv
    AdminSPA -.->|"Direct HTTPS GET (Audited Presigned)"| R2Priv
```

## Key Container Decisions

1. **Dual-Redis Isolation:** Cache (`6379`, `allkeys-lru`) is separated from Queue (`6380`, `noeviction` + AOF persistence) so cache eviction pressure never drops BullMQ jobs or distributed locks. (In managed single-Redis Railway setups, `REDIS_URL` fallback is supported transparently via `env.config.ts`.)
2. **Worker Isolation Toggle (`ENABLE_WORKERS`):** Workers run in-process by default for simple single-container deployments, and can be split into dedicated worker replicas by setting `ENABLE_WORKERS=false` on API replicas and `ENABLE_WORKERS=true` on worker replicas.
3. **Direct-to-R2 Binary Transfers:** Large images and KYC documents never stream through Fastify memory; the API issues short-lived SigV4 presigned URLs and validates uploads via magic-byte headers and R2 `HEAD` checks.
