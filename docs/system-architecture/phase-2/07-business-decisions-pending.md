# 07 — Business, Legal & Operational Decisions Pending

These items were intentionally **NOT guessed or hardcoded** in Phase 2 and require explicit owner sign-off.

| ID | Decision Area | Current Implementation | Options | Impact | Recommended Option | Blocks Prod Launch? |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| `BIZ-001` | KYC Document Retention Periods | Env defaults: Rejected `90d`, Withdrawn `30d`, Expired `180d`, Superseded `90d`, Approved `0` (keep) | Keep defaults / Customize per Egyptian KYC & commercial law | Legal compliance & R2 storage cost | Legal sign-off on exact env values before enabling retention purge | **YES (Before Purge)** |
| `BIZ-002` | Malware / AV Scanner Launch Policy | `scanDocumentBoundary()` returns `SCANNER_NOT_CONFIGURED`; R2 ranged-GET magic-byte check is active | (A) Launch with ranged-GET magic bytes + private R2; (B) Provision ClamAV / R2 Security Scan first | Risk of malicious PDF/image payloads reaching admin review | (B) Provision ClamAV sidecar or R2 Security Scan | **DECISION REQUIRED** |
| `BIZ-003` | Four-Eyes Review Enablement | `ENABLE_FOUR_EYES_VERIFICATION_REVIEW=false` | `true` (2 admins required) vs `false` (1 admin) | Fraud prevention vs review turnaround time | `true` once >=2 verification officers are staffed | **NO** |
| `BIZ-004` | `operations_manager` Document Access | Has `verification.approve` without `verification.documents.read` | (A) Remove `verification.approve`; (B) Grant audited `verification.documents.read` | Prevents blind approval | (A) Remove `verification.approve` from `operations_manager` | **NO** |
| `BIZ-005` | Mandatory Staff MFA | Optional per staff user; not guard-enforced | Enforce `@RequireMfa()` for privileged roles vs optional | Admin account takeover risk | Enforce MFA for `super_admin`, `verification_officer`, `platform_admin` | **RECOMMENDED** |
| `BIZ-006` | Verification Validity & Grace Period | `VERIFICATION_VALIDITY_DAYS=365`, reminder `30d`, no grace period | Keep 365d / add grace period before revoking listing creation | Seller UX vs compliance | 365d + 30d reminder | **NO** |
| `BIZ-007` | 2nd Managed Redis Instance on Railway | App supports `REDIS_CACHE_URL` + `REDIS_QUEUE_URL`; Railway falls back to single `REDIS_URL` | Provision 2nd Redis vs accept shared Redis risk | BullMQ job/lock safety under cache memory pressure | Provision 2nd Redis (`noeviction` + AOF) | **YES (At Scale)** |
| `BIZ-008` | Database RPO / RTO & Backup Drills | Managed by Railway PostgreSQL | Define daily snapshots + PITR + restore drill cadence | Disaster recovery readiness | Daily automated snapshots + quarterly restore test | **RECOMMENDED** |
| `BIZ-009` | Chat Push Notification Policy | Every chat message enqueues `PUSH_NOTIFICATION` via Outbox to recipient | Keep always-on vs add user mute/online-presence suppression | Notification noise vs offline delivery | Keep outbox push; add per-conversation mute later | **NO** |
