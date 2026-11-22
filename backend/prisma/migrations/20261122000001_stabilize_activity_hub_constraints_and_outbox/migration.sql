-- Additive stabilization migration for Activity Hub constraints, expiry indexes, and Outbox retry/recovery

-- 1. Outbox retry, backoff, and stale-lock recovery columns
ALTER TABLE "outbox_events"
  ADD COLUMN IF NOT EXISTS "retry_count" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "max_retries" INTEGER NOT NULL DEFAULT 5,
  ADD COLUMN IF NOT EXISTS "next_retry_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "locked_at" TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS "outbox_events_status_next_retry_at_created_at_idx"
  ON "outbox_events"("status", "next_retry_at", "created_at");

-- 2. Quotation status reason column & expiry scan indexes
ALTER TABLE "quotations"
  ADD COLUMN IF NOT EXISTS "status_reason" TEXT;

CREATE INDEX IF NOT EXISTS "rfq_requests_status_expires_at_idx"
  ON "rfq_requests"("status", "expires_at");

CREATE INDEX IF NOT EXISTS "quotations_status_valid_until_idx"
  ON "quotations"("status", "valid_until");

-- 3. Referential integrity foreign keys (additive, ON DELETE SET NULL)
ALTER TABLE "bookings"
  ADD CONSTRAINT "bookings_cancelled_by_user_id_fkey"
  FOREIGN KEY ("cancelled_by_user_id") REFERENCES "users"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;

CREATE UNIQUE INDEX IF NOT EXISTS "rfq_requests_accepted_quotation_id_key"
  ON "rfq_requests"("accepted_quotation_id");

ALTER TABLE "rfq_requests"
  ADD CONSTRAINT "rfq_requests_accepted_quotation_id_fkey"
  FOREIGN KEY ("accepted_quotation_id") REFERENCES "quotations"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;

-- 4. DB-level concurrency guards (partial unique indexes)
CREATE UNIQUE INDEX IF NOT EXISTS "uq_bookings_provider_confirmed_slot"
  ON "bookings"("provider_account_id", "scheduled_at")
  WHERE "status" = 'CONFIRMED';

CREATE UNIQUE INDEX IF NOT EXISTS "uq_quotations_rfq_single_accepted"
  ON "quotations"("rfq_id")
  WHERE "status" = 'ACCEPTED';
