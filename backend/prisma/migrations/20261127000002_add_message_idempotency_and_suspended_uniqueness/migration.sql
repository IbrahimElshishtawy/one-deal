-- Additive, backward-compatible migration:
-- 1. Message client_message_id + unique constraint scoped to (conversation_id, sender_user_id, client_message_id)
--    for safe retry idempotency (PostgreSQL treats NULLs as distinct, preserving legacy messages).
-- 2. Extend uq_seller_applications_active_user_type partial unique index to include 'SUSPENDED'
--    so a suspended seller cannot concurrently create a conflicting second live application of the same type
--    while preserving single-row reinstatement (SUSPENDED -> APPROVED).

ALTER TABLE "messages"
  ADD COLUMN IF NOT EXISTS "client_message_id" VARCHAR(100);

CREATE UNIQUE INDEX IF NOT EXISTS "uq_messages_sender_conversation_client_id"
  ON "messages" ("conversation_id", "sender_user_id", "client_message_id");

DROP INDEX IF EXISTS "uq_seller_applications_active_user_type";

CREATE UNIQUE INDEX IF NOT EXISTS "uq_seller_applications_active_user_type"
  ON "seller_applications" ("user_id", "application_type")
  WHERE "is_active" = true
    AND "deleted_at" IS NULL
    AND "status" IN ('DRAFT', 'PENDING', 'UNDER_REVIEW', 'NEEDS_CORRECTION', 'APPROVED', 'SUSPENDED');
