-- Non-destructive migration: Seller Verification & Identity Review System Enhancements
-- Preserves all existing users, accounts, listings, seller applications, documents, and history.

-- 1. Extend seller_applications with seller types, marketplace sections, service provider / representative metadata,
--    correction tracking, expiration lifecycle, soft delete, and encrypted PII storage width.
ALTER TABLE "seller_applications"
  ALTER COLUMN "national_id_number" TYPE TEXT,
  ALTER COLUMN "tax_id_number" TYPE TEXT;

ALTER TABLE "seller_applications"
  ADD COLUMN IF NOT EXISTS "seller_type" VARCHAR(30) NOT NULL DEFAULT 'INDIVIDUAL',
  ADD COLUMN IF NOT EXISTS "marketplace_sections" JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS "authorized_representative_name" VARCHAR(150),
  ADD COLUMN IF NOT EXISTS "authorized_representative_id" TEXT,
  ADD COLUMN IF NOT EXISTS "service_category" VARCHAR(120),
  ADD COLUMN IF NOT EXISTS "years_of_experience" INTEGER,
  ADD COLUMN IF NOT EXISTS "qualifications" TEXT,
  ADD COLUMN IF NOT EXISTS "professional_license_number" VARCHAR(100),
  ADD COLUMN IF NOT EXISTS "portfolio_url" VARCHAR(500),
  ADD COLUMN IF NOT EXISTS "correction_fields" JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS "correction_reason" TEXT,
  ADD COLUMN IF NOT EXISTS "correction_requested_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "verification_expires_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "expired_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "deleted_at" TIMESTAMPTZ;

-- Backfill seller_type from existing business_type for any pre-existing applications
UPDATE "seller_applications"
SET "seller_type" = CASE
  WHEN "business_type" IN ('company', 'factory', 'office', 'store') THEN 'BUSINESS'
  ELSE 'INDIVIDUAL'
END
WHERE "seller_type" = 'INDIVIDUAL' AND "business_type" <> 'individual';

-- Update status CHECK constraint to include NEEDS_CORRECTION and EXPIRED
ALTER TABLE "seller_applications"
  DROP CONSTRAINT IF EXISTS "chk_seller_applications_status";

ALTER TABLE "seller_applications"
  ADD CONSTRAINT "chk_seller_applications_status" CHECK (
    "status" IN ('DRAFT', 'PENDING', 'UNDER_REVIEW', 'NEEDS_CORRECTION', 'APPROVED', 'REJECTED', 'SUSPENDED', 'EXPIRED')
  );

ALTER TABLE "seller_applications"
  DROP CONSTRAINT IF EXISTS "chk_seller_applications_seller_type";

ALTER TABLE "seller_applications"
  ADD CONSTRAINT "chk_seller_applications_seller_type" CHECK (
    "seller_type" IN ('INDIVIDUAL', 'BUSINESS', 'SERVICE_PROVIDER')
  );

-- Update active-application uniqueness index to cover NEEDS_CORRECTION as an active in-flight status
DROP INDEX IF EXISTS "uq_seller_applications_active_user";

CREATE UNIQUE INDEX IF NOT EXISTS "uq_seller_applications_active_user"
  ON "seller_applications" ("user_id")
  WHERE "is_active" = true AND "deleted_at" IS NULL AND "status" IN ('DRAFT', 'PENDING', 'UNDER_REVIEW', 'NEEDS_CORRECTION', 'APPROVED');

CREATE INDEX IF NOT EXISTS "seller_applications_seller_type_status_idx"
  ON "seller_applications" ("seller_type", "status");

CREATE INDEX IF NOT EXISTS "seller_applications_verification_expires_at_idx"
  ON "seller_applications" ("verification_expires_at");

-- 2. Configurable Seller Verification Requirements Engine table
CREATE TABLE IF NOT EXISTS "seller_verification_requirements" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "seller_type" VARCHAR(30) NOT NULL,
  "marketplace_section" VARCHAR(60),
  "document_type" VARCHAR(50) NOT NULL,
  "display_name" VARCHAR(150) NOT NULL,
  "display_name_ar" VARCHAR(150),
  "description" TEXT,
  "is_required" BOOLEAN NOT NULL DEFAULT true,
  "accepted_mime_types" JSONB NOT NULL DEFAULT '["application/pdf","image/jpeg","image/png","image/webp"]'::jsonb,
  "max_file_size_bytes" INTEGER NOT NULL DEFAULT 10485760,
  "requires_expiration" BOOLEAN NOT NULL DEFAULT false,
  "verification_rules" JSONB NOT NULL DEFAULT '{}'::jsonb,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "version" INTEGER NOT NULL DEFAULT 1,
  "sort_order" INTEGER NOT NULL DEFAULT 0,
  "created_by_staff_id" UUID,
  "updated_by_staff_id" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "deleted_at" TIMESTAMPTZ,

  CONSTRAINT "seller_verification_requirements_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "chk_svr_seller_type" CHECK (
    "seller_type" IN ('INDIVIDUAL', 'BUSINESS', 'SERVICE_PROVIDER', 'ALL')
  ),
  CONSTRAINT "chk_svr_max_file_size" CHECK (
    "max_file_size_bytes" > 0 AND "max_file_size_bytes" <= 26214400
  )
);

CREATE INDEX IF NOT EXISTS "seller_verification_requirements_type_section_active_idx"
  ON "seller_verification_requirements" ("seller_type", "marketplace_section", "is_active");

CREATE INDEX IF NOT EXISTS "seller_verification_requirements_doc_type_active_idx"
  ON "seller_verification_requirements" ("document_type", "is_active");

-- 3. Extend seller_application_documents with versioning, expiration, requirement link, rejection reason, and soft delete
ALTER TABLE "seller_application_documents"
  ADD COLUMN IF NOT EXISTS "requirement_id" UUID,
  ADD COLUMN IF NOT EXISTS "version" INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS "is_current" BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS "replaced_by_document_id" UUID,
  ADD COLUMN IF NOT EXISTS "expires_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "rejection_reason" TEXT,
  ADD COLUMN IF NOT EXISTS "deleted_at" TIMESTAMPTZ;

ALTER TABLE "seller_application_documents"
  DROP CONSTRAINT IF EXISTS "seller_application_documents_requirement_id_fkey";

ALTER TABLE "seller_application_documents"
  ADD CONSTRAINT "seller_application_documents_requirement_id_fkey"
    FOREIGN KEY ("requirement_id") REFERENCES "seller_verification_requirements"("id") ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX IF NOT EXISTS "seller_application_documents_app_doc_current_idx"
  ON "seller_application_documents" ("application_id", "document_type", "is_current");

CREATE INDEX IF NOT EXISTS "seller_application_documents_expires_at_idx"
  ON "seller_application_documents" ("expires_at");

-- 4. Individual Document Review Ledger table
CREATE TABLE IF NOT EXISTS "seller_document_reviews" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "application_id" UUID NOT NULL,
  "document_id" UUID NOT NULL,
  "admin_id" UUID,
  "decision" VARCHAR(30) NOT NULL,
  "reason" TEXT,
  "notes" TEXT,
  "reviewed_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT "seller_document_reviews_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "chk_sdr_decision" CHECK (
    "decision" IN ('APPROVED', 'REJECTED', 'CORRECTION_REQUIRED')
  ),
  CONSTRAINT "seller_document_reviews_application_id_fkey"
    FOREIGN KEY ("application_id") REFERENCES "seller_applications"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "seller_document_reviews_document_id_fkey"
    FOREIGN KEY ("document_id") REFERENCES "seller_application_documents"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "seller_document_reviews_admin_id_fkey"
    FOREIGN KEY ("admin_id") REFERENCES "staff_users"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "seller_document_reviews_app_reviewed_at_idx"
  ON "seller_document_reviews" ("application_id", "reviewed_at" DESC);

CREATE INDEX IF NOT EXISTS "seller_document_reviews_doc_reviewed_at_idx"
  ON "seller_document_reviews" ("document_id", "reviewed_at" DESC);

CREATE INDEX IF NOT EXISTS "seller_document_reviews_admin_reviewed_at_idx"
  ON "seller_document_reviews" ("admin_id", "reviewed_at" DESC);
