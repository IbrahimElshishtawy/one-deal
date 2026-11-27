# 13 — Deployment & Infrastructure Architecture

## Overview

This diagram strictly separates **Current Production (Railway)**, **Local Development (Docker Compose)**, and **Planned Infrastructure**, verified directly against `railway.json`, `Dockerfile`, `backend/Dockerfile`, `docker-compose.yml`, and `backend/scripts/migrate-deploy.js`.

## Deployment Diagram

```mermaid
flowchart TB
    subgraph Clients["End-User & Staff Clients"]
        Mobile["Flutter Mobile App\n(Android / iOS)\nBase URL: API_BASE_URL"]
        AdminWeb["Admin Web Dashboard\n(React / Vite Build)\nCORS_ORIGIN Allowlist"]
    end

    subgraph Prod["Current Production Environment (Railway)"]
        RailEdge["Railway HTTPS Edge\n(TLS Termination)"]
        PreDeploy["Railway Pre-Deploy Hook:\nnode scripts/migrate-deploy.js\n(Single-connection Prisma migrate deploy\n+ Catalog Redis cache invalidation)"]
        RailAPI["Railway Backend Service\n(Dockerfile -> node dist/src/main.js)\nHealthcheck: GET /health/live (120s timeout)\nWorkers In-Process (ENABLE_WORKERS=true)"]
        RailPG[("Railway Managed PostgreSQL\n+ PostGIS")]
        RailRedis[("Railway Managed Redis\n(REDIS_URL / Cache + Queue)")]
    end

    subgraph CloudExt["External Cloud Services"]
        R2[("Cloudflare R2\nPublic + Private Buckets")]
        Stream["Cloudflare Stream"]
        Gateways["Resend | FCM | SMS Misr | WhatsApp | Sentry"]
    end

    subgraph LocalDev["Local Development (docker-compose.yml)"]
        Nginx["Nginx 1.25 (:80/:443)"]
        LocalAPI["NestJS API Container (:3000)"]
        LocalPG[("PostGIS 16-3.4 (:5432)")]
        LocalRC[("Redis Cache (:6379, LRU 256MB)")]
        LocalRQ[("Redis Queue (:6380, AOF noeviction 512MB)")]
    end

    subgraph Planned["Planned / Future Infrastructure (NOT YET IN PRODUCTION)"]
        DedicatedWorkers["Dedicated Worker Replica\n(ENABLE_WORKERS=true, API pods false)"]
        PgBouncer["PgBouncer Connection Pooling\n(Env hook ready: PGBOUNCER_ENABLED)"]
        ClamAV["Malware / AV Scanning Service\n(ClamAV or R2 Security Scan)"]
        WSGateway["Real-Time WebSocket Tier"]
    end

    Mobile -->|"HTTPS"| RailEdge
    AdminWeb -->|"HTTPS"| RailEdge
    RailEdge --> RailAPI
    PreDeploy -.->|"Runs before startCommand"| RailPG
    RailAPI --> RailPG
    RailAPI --> RailRedis
    RailAPI --> R2
    RailAPI --> Stream
    RailAPI --> Gateways

    Nginx --> LocalAPI
    LocalAPI --> LocalPG
    LocalAPI --> LocalRC
    LocalAPI --> LocalRQ
```

## Runtime Health Checks, Migrations & Env Groups

- **Health Endpoints:**
  - `GET /health/live` — Liveness probe configured in `railway.json` (`healthcheckTimeout: 120`) and `docker-compose.yml`.
  - `GET /health/ready` — Readiness probe verifying PostgreSQL, Redis, and Worker status.
  - `GET /metrics` — Prometheus metrics protected by `METRICS_AUTH_TOKEN` (`MetricsAuthGuard`).
- **Safe Migration Execution (`backend/scripts/migrate-deploy.js`):**
  - Enforces `DIRECT_DATABASE_URL` when PgBouncer is used, sets `connection_limit=1`, redacts credentials from logs, applies all 15 Prisma migrations via local Prisma CLI binary, and invalidates catalog Redis cache.
- **Required Production Env Groups (No Secrets Shown):**
  - Core: `NODE_ENV=production`, `DATABASE_URL`, `DIRECT_DATABASE_URL`, `CORS_ORIGIN`, `TRUST_PROXY`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`
  - Admin: `ADMIN_JWT_ACCESS_SECRET`, `ADMIN_MFA_ENCRYPTION_KEY`, `ADMIN_PUBLIC_URL`, `ADMIN_COOKIE_DOMAIN`
  - Verification & Storage: `SELLER_PII_ENCRYPTION_KEYS`, `SELLER_PII_ENCRYPTION_KEY_VERSION`, `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET_NAME`, `R2_PRIVATE_BUCKET_NAME`, `R2_PUBLIC_DOMAIN`, `ENABLE_FOUR_EYES_VERIFICATION_REVIEW`, `VERIFICATION_VALIDITY_DAYS`, `VERIFICATION_DOC_RETENTION_*_DAYS`
  - Gateways: `RESEND_API_KEY`, `FIREBASE_*`, `WHATSAPP_*` / `SMS_MISR_*`, `CLOUDFLARE_STREAM_*`
