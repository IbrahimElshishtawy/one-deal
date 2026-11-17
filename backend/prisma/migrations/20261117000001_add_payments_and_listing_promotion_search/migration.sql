-- AlterTable: Add search_normalized_text and promoted_until to listings
ALTER TABLE "listings"
  ADD COLUMN IF NOT EXISTS "search_normalized_text" TEXT,
  ADD COLUMN IF NOT EXISTS "promoted_until" TIMESTAMPTZ;

-- CreateTable: promotion_packages
CREATE TABLE IF NOT EXISTS "promotion_packages" (
  "id" VARCHAR(50) NOT NULL,
  "name_ar" VARCHAR(150) NOT NULL,
  "name_en" VARCHAR(150) NOT NULL,
  "type" VARCHAR(30) NOT NULL,
  "price_egp" DECIMAL(10, 2) NOT NULL,
  "duration_days" INTEGER NOT NULL DEFAULT 0,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "promotion_packages_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "promotion_packages_is_active_price_egp_idx"
  ON "promotion_packages" ("is_active", "price_egp");

-- CreateTable: payments
CREATE TABLE IF NOT EXISTS "payments" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "listing_id" UUID NOT NULL,
  "package_id" VARCHAR(50) NOT NULL,
  "amount_egp" DECIMAL(10, 2) NOT NULL,
  "status" VARCHAR(20) NOT NULL DEFAULT 'pending',
  "gateway_transaction_id" VARCHAR(120),
  "raw_response" JSONB,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "payments_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "payments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT "payments_listing_id_fkey" FOREIGN KEY ("listing_id") REFERENCES "listings"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT "payments_package_id_fkey" FOREIGN KEY ("package_id") REFERENCES "promotion_packages"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "payments_gateway_transaction_id_key"
  ON "payments" ("gateway_transaction_id");

CREATE INDEX IF NOT EXISTS "payments_user_id_created_at_idx"
  ON "payments" ("user_id", "created_at" DESC);

CREATE INDEX IF NOT EXISTS "payments_listing_id_status_idx"
  ON "payments" ("listing_id", "status");

CREATE INDEX IF NOT EXISTS "payments_status_created_at_idx"
  ON "payments" ("status", "created_at");

-- Seed default V2 promotion packages idempotently
INSERT INTO "promotion_packages" ("id", "name_ar", "name_en", "type", "price_egp", "duration_days", "is_active")
VALUES
  ('BUMP_UP', 'رفع الإعلان إلى المقدمة', 'Bump to Top', 'bump_up', 35.00, 0, true),
  ('FEATURED_7_DAYS', 'إعلان مميز لمدة 7 أيام', 'Featured Ad (7 Days)', 'featured_7_days', 120.00, 7, true),
  ('FEATURED_14_DAYS', 'إعلان مميز لمدة 14 يوماً', 'Featured Ad (14 Days)', 'featured_14_days', 200.00, 14, true)
ON CONFLICT ("id") DO NOTHING;
