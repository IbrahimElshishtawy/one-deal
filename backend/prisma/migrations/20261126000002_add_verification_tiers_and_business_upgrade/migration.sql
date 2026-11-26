-- Non-destructive, reversible migration: Seller Identity & Business Verification Tiers + Individual-to-Business Upgrade
-- Preserves all existing accounts, users, listings, conversations, and verification submissions.

-- 1. Extend accounts with seller_type, verification_tier, and verification review metadata
ALTER TABLE "accounts"
  ADD COLUMN IF NOT EXISTS "seller_type" VARCHAR(30) NOT NULL DEFAULT 'INDIVIDUAL',
  ADD COLUMN IF NOT EXISTS "verification_tier" VARCHAR(30) NOT NULL DEFAULT 'NONE',
  ADD COLUMN IF NOT EXISTS "verification_approved_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "verification_reviewed_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "verification_reviewed_by_staff_id" UUID;

ALTER TABLE "accounts"
  DROP CONSTRAINT IF EXISTS "accounts_verification_reviewed_by_staff_id_fkey";

ALTER TABLE "accounts"
  ADD CONSTRAINT "accounts_verification_reviewed_by_staff_id_fkey"
    FOREIGN KEY ("verification_reviewed_by_staff_id")
    REFERENCES "staff_users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "accounts"
  DROP CONSTRAINT IF EXISTS "chk_accounts_seller_type";

ALTER TABLE "accounts"
  ADD CONSTRAINT "chk_accounts_seller_type" CHECK (
    "seller_type" IN ('INDIVIDUAL', 'BUSINESS', 'SERVICE_PROVIDER')
  );

ALTER TABLE "accounts"
  DROP CONSTRAINT IF EXISTS "chk_accounts_verification_tier";

ALTER TABLE "accounts"
  ADD CONSTRAINT "chk_accounts_verification_tier" CHECK (
    "verification_tier" IN ('NONE', 'IDENTITY_VERIFIED', 'BUSINESS_VERIFIED')
  );

CREATE INDEX IF NOT EXISTS "accounts_verification_status_tier_active_idx"
  ON "accounts" ("verification_status", "verification_tier", "is_active");

-- 2. Extend seller_applications with application_type (INITIAL vs BUSINESS_UPGRADE) and derived_verification_tier
ALTER TABLE "seller_applications"
  ADD COLUMN IF NOT EXISTS "application_type" VARCHAR(30) NOT NULL DEFAULT 'INITIAL',
  ADD COLUMN IF NOT EXISTS "derived_verification_tier" VARCHAR(30);

ALTER TABLE "seller_applications"
  DROP CONSTRAINT IF EXISTS "chk_seller_applications_application_type";

ALTER TABLE "seller_applications"
  ADD CONSTRAINT "chk_seller_applications_application_type" CHECK (
    "application_type" IN ('INITIAL', 'BUSINESS_UPGRADE')
  );

ALTER TABLE "seller_applications"
  DROP CONSTRAINT IF EXISTS "chk_seller_applications_derived_tier";

ALTER TABLE "seller_applications"
  ADD CONSTRAINT "chk_seller_applications_derived_tier" CHECK (
    "derived_verification_tier" IS NULL OR
    "derived_verification_tier" IN ('NONE', 'IDENTITY_VERIFIED', 'BUSINESS_VERIFIED')
  );

-- Allow one active INITIAL application AND one active BUSINESS_UPGRADE application per user
DROP INDEX IF EXISTS "uq_seller_applications_active_user";

CREATE UNIQUE INDEX IF NOT EXISTS "uq_seller_applications_active_user_type"
  ON "seller_applications" ("user_id", "application_type")
  WHERE "is_active" = true AND "deleted_at" IS NULL AND "status" IN ('DRAFT', 'PENDING', 'UNDER_REVIEW', 'NEEDS_CORRECTION', 'APPROVED');

CREATE INDEX IF NOT EXISTS "seller_applications_user_type_active_idx"
  ON "seller_applications" ("user_id", "application_type", "is_active");

-- 3. Extend seller_application_history with account_id, previous_tier, and new_tier for full decision auditability
ALTER TABLE "seller_application_history"
  ADD COLUMN IF NOT EXISTS "account_id" UUID,
  ADD COLUMN IF NOT EXISTS "previous_tier" VARCHAR(30),
  ADD COLUMN IF NOT EXISTS "new_tier" VARCHAR(30);

-- 4. Safe, conservative backfill of accounts.seller_type
-- First derive from approved seller_applications where linked
UPDATE "accounts" a
SET "seller_type" = sa."seller_type"
FROM "seller_applications" sa
WHERE sa."account_id" = a."id"
  AND sa."status" = 'APPROVED'
  AND sa."deleted_at" IS NULL;

-- Fallback for accounts without a linked application: infer seller_type from account_type
UPDATE "accounts" a
SET "seller_type" = CASE
  WHEN a."account_type" IN ('company', 'factory', 'office', 'store') THEN 'BUSINESS'
  ELSE 'INDIVIDUAL'
END
WHERE NOT EXISTS (
  SELECT 1 FROM "seller_applications" sa
  WHERE sa."account_id" = a."id"
    AND sa."status" = 'APPROVED'
    AND sa."deleted_at" IS NULL
);

-- 5. Safe, evidence-based backfill of accounts.verification_tier
-- NEVER grant BUSINESS_VERIFIED without verified/uploaded commercial_register AND tax_card.
UPDATE "accounts" a
SET
  "verification_tier" = 'BUSINESS_VERIFIED',
  "verification_approved_at" = COALESCE(a."verification_approved_at", sa."reviewed_at", a."updated_at"),
  "verification_reviewed_at" = COALESCE(a."verification_reviewed_at", sa."reviewed_at"),
  "verification_reviewed_by_staff_id" = COALESCE(a."verification_reviewed_by_staff_id", sa."reviewed_by_staff_id")
FROM "seller_applications" sa
WHERE sa."account_id" = a."id"
  AND sa."status" = 'APPROVED'
  AND sa."seller_type" = 'BUSINESS'
  AND sa."deleted_at" IS NULL
  AND a."verification_status" = 'approved'
  AND a."is_active" = true
  AND a."deleted_at" IS NULL
  AND EXISTS (
    SELECT 1 FROM "seller_application_documents" d1
    WHERE d1."application_id" = sa."id"
      AND d1."document_type" = 'commercial_register'
      AND d1."status" IN ('VERIFIED', 'UPLOADED')
      AND d1."is_current" = true
      AND d1."deleted_at" IS NULL
  )
  AND EXISTS (
    SELECT 1 FROM "seller_application_documents" d2
    WHERE d2."application_id" = sa."id"
      AND d2."document_type" = 'tax_card'
      AND d2."status" IN ('VERIFIED', 'UPLOADED')
      AND d2."is_current" = true
      AND d2."deleted_at" IS NULL
  );

-- Map previously approved INDIVIDUAL / SERVICE_PROVIDER accounts to IDENTITY_VERIFIED
-- ONLY when their approved document history proves identity verification (national_id_front + national_id_back).
UPDATE "accounts" a
SET
  "verification_tier" = 'IDENTITY_VERIFIED',
  "verification_approved_at" = COALESCE(a."verification_approved_at", sa."reviewed_at", a."updated_at"),
  "verification_reviewed_at" = COALESCE(a."verification_reviewed_at", sa."reviewed_at"),
  "verification_reviewed_by_staff_id" = COALESCE(a."verification_reviewed_by_staff_id", sa."reviewed_by_staff_id")
FROM "seller_applications" sa
WHERE sa."account_id" = a."id"
  AND sa."status" = 'APPROVED'
  AND sa."seller_type" IN ('INDIVIDUAL', 'SERVICE_PROVIDER')
  AND sa."deleted_at" IS NULL
  AND a."verification_status" = 'approved'
  AND a."verification_tier" = 'NONE'
  AND a."is_active" = true
  AND a."deleted_at" IS NULL
  AND EXISTS (
    SELECT 1 FROM "seller_application_documents" d1
    WHERE d1."application_id" = sa."id"
      AND d1."document_type" = 'national_id_front'
      AND d1."status" IN ('VERIFIED', 'UPLOADED')
      AND d1."is_current" = true
      AND d1."deleted_at" IS NULL
  )
  AND EXISTS (
    SELECT 1 FROM "seller_application_documents" d2
    WHERE d2."application_id" = sa."id"
      AND d2."document_type" = 'national_id_back'
      AND d2."status" IN ('VERIFIED', 'UPLOADED')
      AND d2."is_current" = true
      AND d2."deleted_at" IS NULL
  );

-- Ambiguous legacy accounts without verified supporting documents remain at verification_tier = 'NONE' until reviewed.
