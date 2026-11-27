# 04 — Database, Migrations & Payments Audit

## 1. Schema & Constraint Verification (`backend/prisma/schema.prisma`)

- **Total Models:** 48 Prisma models across 15 migrations (all 15 migrations verified in `backend/src/core/database/migrate-deploy.spec.ts:43-69`).
- **Key Unique Constraints Verified:**
  - `User.phone`, `User.email`
  - `Account.slug`
  - `AccountMember (accountId, userId)` (`uq_account_user`)
  - `UserDevice (userId, fcmToken)` (`uq_user_device_token`)
  - `SellerApplicationDocument.storageKey`
  - `Conversation (listingId, buyerUserId)` (`uq_conversation_pair`)
  - `Payment.gatewayTransactionId` (`@unique`, `schema.prisma:1008`)
  - `Booking.reference` (`@unique`, `schema.prisma:1029`)
- **Migration Timing:** `railway.json:8-10` executes `node scripts/migrate-deploy.js` in `preDeployCommand` *before* `startCommand: "node dist/src/main.js"`. `migrate-deploy.js` enforces `connection_limit=1`, prefers `DIRECT_DATABASE_URL`, and rejects PgBouncer transaction-pooled URLs.
- **Migration #15 Backward Compatibility:** Verified strictly additive (`ADD COLUMN IF NOT EXISTS`, `ALTER COLUMN commercial_register_number TYPE TEXT`, extended `CHECK` constraints, supporting indexes `accounts_verification_expires_at_idx` and `seller_application_documents_retention_idx`).

## 2. Verified Findings

### Finding `DB-001` — MEDIUM — Paymob Webhook Update Lacks Atomic `status: PENDING` Guard
- **Status:** VERIFIED
- **Evidence:** `backend/src/modules/payments/payments.service.ts:281-360`
- **Actual Behavior:** `handlePaymobWebhook()` checks `existingPayment.status === PaymentStatus.SUCCESS` *outside* the `$transaction`, then executes `tx.payment.update({ where: { id: payment.id } })` without `status: PaymentStatus.PENDING` in the `WHERE` clause. While `gatewayTransactionId @unique` blocks identical transaction IDs from committing twice, two concurrent webhook deliveries for the same `payment.id` with different gateway IDs (or racing before commit) could both pass the pre-check and apply `promotedUntil` / create duplicate `OutboxEvent` rows.
- **Note:** `PaymentsModule` is currently disabled in production (`ENABLE_V2_PAYMENTS=false`, `app.module.ts:38`). Must be fixed before enabling V2 Payments.
- **Recommended Resolution:** Use atomic `tx.payment.updateMany({ where: { id: payment.id, status: PaymentStatus.PENDING }, data: { status: PaymentStatus.SUCCESS, ... } })` and abort if `count === 0`.
- **Business Decision Required:** No (engineering blocker only when `ENABLE_V2_PAYMENTS=true`).

### Finding `DB-002` — MEDIUM — Partial Unique Index `uq_seller_applications_active_user_type` Excludes `SUSPENDED`
- **Status:** VERIFIED
- **Evidence:** `backend/prisma/migrations/20261126000002_add_verification_tiers_and_business_upgrade/migration.sql:73-75`
- **Actual Behavior:** The partial unique index covers `status IN ('DRAFT', 'PENDING', 'UNDER_REVIEW', 'NEEDS_CORRECTION', 'APPROVED')`. It does NOT cover `'SUSPENDED'`. Duplicate prevention for suspended users relies solely on the application-layer check `user.sellerStatus === SellerApplicationStatus.SUSPENDED` (`seller-application.service.ts:226`).
- **Recommended Resolution:** Include `'SUSPENDED'` in the partial unique index in a future migration for defense-in-depth at the DB layer.
- **Business Decision Required:** No.

### Finding `DB-003` — LOW — Backup & Point-in-Time Recovery (PITR) Runbook Not Verified in Code
- **Status:** NOT VERIFIED
- **Evidence:** `backups/` directory exists at repo root, but automated production PostgreSQL backup / PITR restore procedures are Railway platform configuration outside the repository.
- **Recommended Resolution:** Document Railway PostgreSQL backup retention & tested restore runbook before launch.
- **Business Decision Required:** Yes (RPO/RTO targets).
