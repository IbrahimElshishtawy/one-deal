# Deal One Backend — Database Backup & Recovery Verification

**Date:** 2026-11-19  
**Status:** **BLOCKED (Requires Project Owner Railway Dashboard Access & Restore Drill)**

---

## 1. Current Observed Infrastructure

Read-only inspection of Railway project `airy-creativity` (`036ef563-b1f9-4d6e-b901-802946a28e0a`):
- **Production Database Service:** `Postgres` (`a6a0fc2b-4ae2-4391-abf8-073e91a98886`) in environment `production`.
- **Migration Safety Verified Locally:** `scripts/migrate-deploy.js` verified against PostgreSQL 16.4 + PostGIS 3.4.3 (8/8 Prisma migrations applied, advisory lock `84920173` acquired/released, zero destructive operations).
- **Backup Configuration Visibility:** Railway's managed PostgreSQL backup schedule, retention policy, encryption-at-rest, and Point-In-Time Recovery (PITR) settings are managed in the Railway Dashboard / Pro plan and are **not exposed via read-only MCP endpoints**. Furthermore, no staging database exists on Railway to execute a non-destructive restore drill.

---

## 2. Unverified Items (Marked BLOCKED)

| Requirement | Status |
|---|---|
| Automated backup frequency (e.g., daily snapshots) | **BLOCKED** — Must be verified in Railway Postgres → Backups tab |
| Backup retention window & storage region | **BLOCKED** — Must be verified by project owner |
| Encryption at rest & in transit | **BLOCKED** — Verify Railway managed Postgres TLS & volume encryption |
| Point-In-Time Recovery (PITR) / RPO & RTO | **BLOCKED** — Confirm plan tier and document target RPO/RTO |
| Actual restore test into separate staging DB | **BLOCKED** — Requires staging Postgres instance |

---

## 3. Exact Owner Verification & Restore Drill Instructions

1. Open Railway Dashboard → Project `airy-creativity` → Service `Postgres` → **Backups** tab.
2. Enable **Scheduled Backups** (minimum: Daily, ≥7–30 day retention; enable PITR if on Pro plan) and record RPO/RTO.
3. Trigger a manual snapshot of `Postgres`.
4. Provision a **separate staging PostgreSQL/PostGIS** database (NEVER restore over production).
5. Restore the snapshot into the staging database and verify:
   ```bash
   psql "$STAGING_DATABASE_URL" -c "SELECT PostGIS_Version();"
   psql "$STAGING_DATABASE_URL" -c "SELECT count(*) FROM listings; SELECT count(*) FROM users;"
   ```
6. Record the restore duration (actual RTO) and mark this document VERIFIED once the staging restore succeeds.
