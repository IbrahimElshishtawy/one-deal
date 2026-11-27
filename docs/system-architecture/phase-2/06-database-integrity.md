# 06 — Database Integrity & Migration #16 (Workstream F)

## F1. Payment Webhook Atomic Idempotency (`DB-001`)

- **File:** `backend/src/modules/payments/payments.service.ts`
- **Fix:** Replaced non-atomic `tx.payment.update` with `tx.payment.updateMany({ where: { id: payment.id, status: PaymentStatus.PENDING }, data: { status: PaymentStatus.SUCCESS, ... } })`. If `count === 0`, transaction aborts early without re-applying `promotedUntil` or emitting duplicate `PAYMENT_SUCCEEDED` outbox events. `PaymentsModule` remains disabled by default (`ENABLE_V2_PAYMENTS=false`).

## F2. Migration #16 (`20261127000002_add_message_idempotency_and_suspended_uniqueness`)

- **File:** `backend/prisma/migrations/20261127000002_add_message_idempotency_and_suspended_uniqueness/migration.sql`
- **Changes (Strictly Additive / Safe):**
  1. `ALTER TABLE "messages" ADD COLUMN IF NOT EXISTS "client_message_id" VARCHAR(100);`
  2. `CREATE UNIQUE INDEX IF NOT EXISTS "uq_messages_sender_conversation_client_id" ON "messages" ("conversation_id", "sender_user_id", "client_message_id");`
  3. Recreated partial unique index `uq_seller_applications_active_user_type` including `'SUSPENDED'`.
- **Reinstatement Safety:** `reinstateSeller()` transitions `SUSPENDED -> APPROVED` in-place on the same `SellerApplication` row, so including `'SUSPENDED'` in the partial unique index prevents a suspended user from opening a second conflicting live application while preserving reinstatement.
- **Rollback Considerations:** Dropping `uq_messages_sender_conversation_client_id` or reverting the partial index requires zero data loss; older app versions safely ignore the nullable `client_message_id` column.
- **Production Safety:** Executed locally only (`16/16` applied); NOT run against Production.
