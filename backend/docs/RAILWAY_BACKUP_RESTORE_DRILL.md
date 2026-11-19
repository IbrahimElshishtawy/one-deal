# Deal One — Railway Database Backup & Restore Drill Report (Phase Six)

**Date:** 2026-11-19  
**Railway Backup & Restore Drill Status:** **BLOCKED** (Railway Postgres PITR is NOT enabled — `0` storage buckets exist; volume backup schedule is not exposed via read-only MCP; no isolated Railway staging database exists for a cloud restore drill)  
**Isolated Local Docker PostGIS Backup/Restore Drill Status:** **PASS** (Clearly separated from Railway cloud verification below)

---

## 1. Read-Only Railway PostgreSQL Inspection (`airy-creativity`)

From `describe-environment`, `describe-service`, and `get-service-metrics` on `Postgres` (`a6a0fc2b-4ae2-4391-abf8-073e91a98886`):

| Parameter | Observed Railway State | Risk / Gap |
|---|---|---|
| **Service / Image** | `Postgres` (`postgis/postgis:16-3.4-alpine`), region `iad`, 1 replica | Single point of failure (`haTemplateCode: postgres-ha` not enabled) |
| **Volume** | `postgres-volume` (`7ca84c2a-1f84-4eb8-871c-7adf118870e5`), **500 MB** (`0.1655 GB` currently used) | Tight disk headroom for growth/WAL |
| **Railway PITR (pgBackRest WAL Archiving)** | **NOT ENABLED** (`Buckets (0): none` in `describe-environment`; Railway PITR archives WAL to a Railway storage bucket) | **Zero point-in-time recovery** currently configured |
| **Scheduled Volume Backups** | **UNVERIFIED / BLOCKED** (Not visible via Railway MCP; requires Railway Dashboard → `Postgres` → **Backups** tab or `railway postgres` CLI) | Cannot assume backups are enabled |
| **Backup Frequency / Retention / Encryption** | **UNVERIFIED / BLOCKED** | Must be confirmed and configured by project owner |
| **RPO / RTO (Railway Production)** | **UNKNOWN / UNVERIFIED** | Cannot be claimed until a real Railway backup & restore drill succeeds |

---

## 2. Isolated Local Docker Backup & Restore Drill (Non-Railway Reference Only)

Executed on 2026-11-19 against local `marketspace-postgres` (`postgis/postgis:16-3.4-alpine`) into a temporary isolated database `marketspace_restore_drill` (which was dropped immediately after verification):

| Metric | Measured Local Value |
|---|---|
| **Backup Timestamp** | `2026-11-19T02:00:50+02:00` |
| **Backup Method** | `pg_dump --no-owner --no-acl \| gzip` |
| **Compressed Backup Size** | `173,311 bytes` (`~169.2 KB`) |
| **Dump Duration** | `411 ms` |
| **Restore Duration (Local RTO)** | `1,979 ms` (`~1.98 s`) |
| **PostGIS Verification (`PostGIS_Version()`)** | `3.4 USE_GEOS=1 USE_PROJ=1 USE_STATS=1` |
| **Prisma Migrations (`finished_at IS NOT NULL`)** | `8 / 8` |
| **Public Schema Tables** | `37` |
| **Record Counts Verified** | `users = 36`, `listings = 340` |
| **Local Repo Scripts Audited** | `../scripts/backup-db.sh` and `../scripts/restore-db.sh` exist (`../backups/marketspace_backup_20261105_184019.sql.gz` from Nov 5, 2026 is a stale local backup, NOT a Railway production backup) |

> **Important:** A local Docker restore drill proves SQL/PostGIS dump-restore mechanics work on `postgis/postgis:16-3.4-alpine`, but does **NOT** verify Railway production backups.

---

## 3. Mandatory Owner Actions to Unblock Railway Backup & Restore Verification

1. **Enable Automated Backups & PITR on Railway `Postgres` (`a6a0fc2b-4ae2-4391-abf8-073e91a98886`):**
   - Open Railway Dashboard → `airy-creativity` → `production` → `Postgres` → **Backups** tab (or run `railway postgres pitr` via Railway CLI).
   - Enable **Scheduled Volume Backups** (minimum: Daily, retention ≥ 14–30 days).
   - Enable **PostgreSQL PITR** (WAL archiving to encrypted Railway storage bucket via `pgBackRest`, ~4-week restore window) if supported by your Railway plan tier.
   - Increase `postgres-volume` size beyond `500 MB` (recommended ≥ `5–10 GB` for production headroom).
2. **Execute Isolated Restore Drill into Railway Staging Database (NEVER Overwrite Production):**
   - Take an on-demand backup of `Postgres` and record its exact UTC timestamp.
   - Restore the backup into an isolated `staging-postgres` service (Railway PITR restores into a new service by default; for volume backups, restore into a separate staging Postgres instance).
   - Run verification checks against `$STAGING_DATABASE_URL`:
     ```bash
     psql "$STAGING_DATABASE_URL" -c "SELECT PostGIS_Version();"
     psql "$STAGING_DATABASE_URL" -c "SELECT count(*) FROM _prisma_migrations WHERE finished_at IS NOT NULL;"
     psql "$STAGING_DATABASE_URL" -c "SELECT count(*) AS users FROM users; SELECT count(*) AS listings FROM listings;"
     ```
   - Point `staging-api` at the restored database and verify `GET /health/ready` (`200`) and `GET /api/v1/listings?limit=5` (`200`).
3. **Record Verified Evidence:** Document actual Backup Timestamp, Restore Timestamp, Database Size, Restore Duration (actual RTO), Achieved RPO, and Smoke Test Results in this file before moving to production release.
