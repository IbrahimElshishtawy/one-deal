# 10 — Business, Legal & Operational Decisions Required

These items are **NOT engineering bugs** — they require explicit sign-off from Product, Legal/Compliance, or Infrastructure owners before production rollout.

| Decision ID | Topic | Current Default / State | Options / Questions to Decide | Linked Finding |
| :--- | :--- | :--- | :--- | :--- |
| `BIZ-001` | **Legal Document Retention Periods** | Rejected: `90d`, Withdrawn: `30d`, Expired: `180d`, Superseded: `90d`, Approved: `0` (keep indefinitely) | Confirm Egyptian commercial/KYC legal retention requirements for each document category before enabling automated R2 purge in production. | Retention Policy |
| `BIZ-002` | **Malware / Antivirus Scanning Policy** | `SCANNER_NOT_CONFIGURED` (boundary only) | Decide: (a) launch with MIME + extension + server ranged-GET magic-byte + private R2 isolation, OR (b) block KYC uploads until ClamAV / Cloudflare R2 Security Scan is provisioned. | `SEC-001` / Malware |
| `BIZ-003` | **Four-Eyes Verification Review at Launch** | `ENABLE_FOUR_EYES_VERIFICATION_REVIEW=false` | Confirm whether launch admin staffing supports mandatory two-person review (`true`) or single-officer review (`false`). | Verification Governance |
| `BIZ-004` | **`operations_manager` Verification Permissions** | Has `verification.approve` WITHOUT `verification.documents.read` | Should `operations_manager` lose `verification.approve` (strict separation) or be granted audited `verification.documents.read`? | `RBAC-002` |
| `BIZ-005` | **Mandatory Staff MFA Rollout** | Optional per staff user; not enforced by guard | Should MFA be mandatory (`@RequireMfa()`) for `super_admin`, `verification_officer`, and `platform_admin` in production? | `RBAC-001` |
| `BIZ-006` | **Verification Validity & Reminder Window** | `VERIFICATION_VALIDITY_DAYS=365`, `VERIFICATION_RENEWAL_REMINDER_DAYS=30` | Confirm annual expiration period (365 days) and whether expired sellers should have a grace period before badge/listing-creation revocation. | Expiration / Renewal |
| `BIZ-007` | **Dedicated Dual-Redis Provisioning** | Single `REDIS_URL` fallback supported | Approve provisioning a 2nd managed Redis instance on Railway so Cache (`allkeys-lru`) and BullMQ Queue (`noeviction` + AOF) are isolated. | `INF-001` |
| `BIZ-008` | **Database RPO / RTO & Backup Policy** | Managed by Railway platform | Define target RPO/RTO and schedule periodic backup restore drills. | `DB-003` |
