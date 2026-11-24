-- Non-destructive migration: Buyer-to-Seller Account Conversion & Mandatory Seller Verification System
-- Preserves all existing user IDs, accounts, listings, favorites, and conversations.

-- 1. Extend users table with seller lifecycle tracking (all new users default to NOT_REQUESTED = BUYER)
ALTER TABLE "users"
  ADD COLUMN IF NOT EXISTS "seller_status" VARCHAR(25) NOT NULL DEFAULT 'NOT_REQUESTED',
  ADD COLUMN IF NOT EXISTS "seller_approved_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "seller_suspended_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "seller_suspension_reason" TEXT;

CREATE INDEX IF NOT EXISTS "users_seller_status_idx" ON "users" ("seller_status");

-- Backfill existing sellers who already own an active approved account with existing listings
-- so existing seller/listing relationships remain intact without disruption.
UPDATE "users" u
SET
  "seller_status" = 'APPROVED',
  "seller_approved_at" = COALESCE(u."seller_approved_at", u."created_at")
WHERE u."seller_status" = 'NOT_REQUESTED'
  AND EXISTS (
    SELECT 1
    FROM "accounts" a
    INNER JOIN "listings" l ON l."account_id" = a."id"
    WHERE a."owner_user_id" = u."id"
      AND a."is_active" = true
      AND a."deleted_at" IS NULL
      AND a."verification_status" = 'approved'
  );

-- 2. Seller Applications table
CREATE TABLE IF NOT EXISTS "seller_applications" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "account_id" UUID,
  "status" VARCHAR(25) NOT NULL DEFAULT 'DRAFT',
  "business_type" VARCHAR(20) NOT NULL DEFAULT 'individual',
  "business_name" VARCHAR(150),
  "business_description" TEXT,
  "national_id_number" VARCHAR(50),
  "tax_id_number" VARCHAR(50),
  "commercial_register_number" VARCHAR(100),
  "contact_phone" VARCHAR(20),
  "contact_email" VARCHAR(255),
  "city_id" INTEGER,
  "address" TEXT,
  "submitted_at" TIMESTAMPTZ,
  "reviewed_at" TIMESTAMPTZ,
  "reviewed_by_staff_id" UUID,
  "assigned_to_staff_id" UUID,
  "rejection_reason" TEXT,
  "suspension_reason" TEXT,
  "admin_notes" TEXT,
  "resubmission_count" INTEGER NOT NULL DEFAULT 0,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT "seller_applications_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "chk_seller_applications_status" CHECK (
    "status" IN ('DRAFT', 'PENDING', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'SUSPENDED')
  ),
  CONSTRAINT "chk_seller_applications_business_type" CHECK (
    "business_type" IN ('individual', 'company', 'factory', 'office', 'store')
  ),
  CONSTRAINT "seller_applications_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT "seller_applications_account_id_fkey"
    FOREIGN KEY ("account_id") REFERENCES "accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT "seller_applications_reviewed_by_staff_id_fkey"
    FOREIGN KEY ("reviewed_by_staff_id") REFERENCES "staff_users"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT "seller_applications_assigned_to_staff_id_fkey"
    FOREIGN KEY ("assigned_to_staff_id") REFERENCES "staff_users"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "seller_applications_user_id_is_active_idx"
  ON "seller_applications" ("user_id", "is_active");
CREATE INDEX IF NOT EXISTS "seller_applications_status_submitted_at_idx"
  ON "seller_applications" ("status", "submitted_at");
CREATE INDEX IF NOT EXISTS "seller_applications_assigned_to_staff_id_status_idx"
  ON "seller_applications" ("assigned_to_staff_id", "status");

-- Prevent duplicate active seller applications per user at the database level
CREATE UNIQUE INDEX IF NOT EXISTS "uq_seller_applications_active_user"
  ON "seller_applications" ("user_id")
  WHERE "is_active" = true AND "status" IN ('DRAFT', 'PENDING', 'UNDER_REVIEW', 'APPROVED');

-- 3. Seller Application Documents table (private storage only; never public listing media)
CREATE TABLE IF NOT EXISTS "seller_application_documents" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "application_id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "document_type" VARCHAR(50) NOT NULL,
  "storage_key" VARCHAR(500) NOT NULL,
  "original_file_name" VARCHAR(255) NOT NULL,
  "mime_type" VARCHAR(100) NOT NULL,
  "file_size_bytes" INTEGER NOT NULL,
  "checksum_sha256" VARCHAR(64),
  "status" VARCHAR(20) NOT NULL DEFAULT 'UPLOADED',
  "uploaded_at" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT "seller_application_documents_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "seller_application_documents_storage_key_key" UNIQUE ("storage_key"),
  CONSTRAINT "chk_seller_app_doc_size" CHECK ("file_size_bytes" > 0 AND "file_size_bytes" <= 10485760),
  CONSTRAINT "seller_application_documents_application_id_fkey"
    FOREIGN KEY ("application_id") REFERENCES "seller_applications"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "seller_application_documents_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "seller_application_documents_application_id_document_type_idx"
  ON "seller_application_documents" ("application_id", "document_type");
CREATE INDEX IF NOT EXISTS "seller_application_documents_user_id_idx"
  ON "seller_application_documents" ("user_id");

-- 4. Seller Application History (immutable decision & status transition ledger)
CREATE TABLE IF NOT EXISTS "seller_application_history" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "application_id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "admin_id" UUID,
  "actor_type" VARCHAR(20) NOT NULL,
  "previous_status" VARCHAR(25) NOT NULL,
  "new_status" VARCHAR(25) NOT NULL,
  "reason" TEXT,
  "metadata" JSONB DEFAULT '{}',
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT "seller_application_history_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "seller_application_history_application_id_fkey"
    FOREIGN KEY ("application_id") REFERENCES "seller_applications"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "seller_application_history_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT "seller_application_history_admin_id_fkey"
    FOREIGN KEY ("admin_id") REFERENCES "staff_users"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "seller_application_history_application_id_created_at_idx"
  ON "seller_application_history" ("application_id", "created_at" DESC);
CREATE INDEX IF NOT EXISTS "seller_application_history_user_id_created_at_idx"
  ON "seller_application_history" ("user_id", "created_at" DESC);
CREATE INDEX IF NOT EXISTS "seller_application_history_admin_id_created_at_idx"
  ON "seller_application_history" ("admin_id", "created_at" DESC);
