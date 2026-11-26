-- Non-destructive, additive migration: Seller Verification System Hardening
-- Adds:
--   1. Account verification expiration & suspension metadata + 'expired' verification_status
--   2. SellerApplication requirements versioning/snapshot, withdrawal tracking, optimistic version lock,
--      four-eyes first reviewer tracking, renewal reminder tracking, encrypted commercial_register_number (TEXT)
--   3. SellerApplicationDocument review metadata & retention/purge lifecycle fields
--   4. SellerApplicationHistory explicit action field
-- Preserves all existing accounts, users, listings, branches, members, conversations, and verification records.

-- 1. Extend accounts
ALTER TABLE "accounts"
  ADD COLUMN IF NOT EXISTS "verification_expires_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "verification_suspended_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "verification_suspension_reason" TEXT;

ALTER TABLE "accounts"
  DROP CONSTRAINT IF EXISTS "chk_account_verification_status";

ALTER TABLE "accounts"
  ADD CONSTRAINT "chk_account_verification_status" CHECK (
    "verification_status" IN (
      'not_submitted',
      'pending',
      'approved',
      'rejected',
      'needs_changes',
      'suspended',
      'expired'
    )
  );

CREATE INDEX IF NOT EXISTS "accounts_verification_expires_at_idx"
  ON "accounts" ("verification_expires_at");

-- 2. Extend seller_applications
ALTER TABLE "seller_applications"
  ALTER COLUMN "commercial_register_number" TYPE TEXT;

ALTER TABLE "seller_applications"
  ADD COLUMN IF NOT EXISTS "requirements_version" INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS "requirements_snapshot" JSONB,
  ADD COLUMN IF NOT EXISTS "withdrawn_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "withdrawal_reason" TEXT,
  ADD COLUMN IF NOT EXISTS "version" INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS "first_reviewed_by_staff_id" UUID,
  ADD COLUMN IF NOT EXISTS "first_reviewed_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "renewal_reminder_sent_at" TIMESTAMPTZ;

ALTER TABLE "seller_applications"
  DROP CONSTRAINT IF EXISTS "chk_seller_applications_status";

ALTER TABLE "seller_applications"
  ADD CONSTRAINT "chk_seller_applications_status" CHECK (
    "status" IN (
      'DRAFT',
      'PENDING',
      'UNDER_REVIEW',
      'NEEDS_CORRECTION',
      'APPROVED',
      'REJECTED',
      'WITHDRAWN',
      'SUSPENDED',
      'EXPIRED'
    )
  );

ALTER TABLE "seller_applications"
  DROP CONSTRAINT IF EXISTS "chk_seller_applications_application_type";

ALTER TABLE "seller_applications"
  ADD CONSTRAINT "chk_seller_applications_application_type" CHECK (
    "application_type" IN ('INITIAL', 'BUSINESS_UPGRADE', 'RENEWAL')
  );

-- 3. Extend seller_application_documents
ALTER TABLE "seller_application_documents"
  ADD COLUMN IF NOT EXISTS "reviewed_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "reviewed_by_staff_id" UUID,
  ADD COLUMN IF NOT EXISTS "retention_expires_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "purged_at" TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS "seller_application_documents_retention_idx"
  ON "seller_application_documents" ("retention_expires_at", "purged_at");

-- 4. Extend seller_application_history
ALTER TABLE "seller_application_history"
  ADD COLUMN IF NOT EXISTS "action" VARCHAR(60);

-- 5. Backfill Account.verification_expires_at from active approved SellerApplication where missing
UPDATE "accounts" a
SET "verification_expires_at" = sa."verification_expires_at"
FROM "seller_applications" sa
WHERE sa."account_id" = a."id"
  AND sa."status" = 'APPROVED'
  AND sa."is_active" = true
  AND sa."deleted_at" IS NULL
  AND sa."verification_expires_at" IS NOT NULL
  AND a."verification_expires_at" IS NULL;
