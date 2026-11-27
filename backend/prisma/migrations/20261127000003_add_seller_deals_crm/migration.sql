-- Additive, backward-compatible migration for Deal One Seller Center CRM (V1)
-- Note: Deal One V1 does not process payments or orders. SellerDeal records are
-- seller-managed CRM entries explicitly flagged with seller_reported_only = true.

CREATE TABLE IF NOT EXISTS "seller_deals" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "seller_account_id" UUID NOT NULL,
  "created_by_user_id" UUID NOT NULL,
  "listing_id" UUID NOT NULL,
  "customer_user_id" UUID,
  "customer_name" VARCHAR(150) NOT NULL,
  "customer_reference" VARCHAR(150),
  "conversation_id" UUID,
  "initial_price" DECIMAL(14, 2) NOT NULL,
  "agreed_price" DECIMAL(14, 2),
  "currency" VARCHAR(3) NOT NULL DEFAULT 'EGP',
  "status" VARCHAR(30) NOT NULL DEFAULT 'NEW_INQUIRY',
  "seller_reported_only" BOOLEAN NOT NULL DEFAULT true,
  "notes" TEXT,
  "completed_at" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "seller_deals_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "chk_seller_deals_status" CHECK (
    "status" IN ('NEW_INQUIRY', 'CONTACTED', 'NEGOTIATING', 'AGREED', 'COMPLETED', 'CANCELLED')
  ),
  CONSTRAINT "seller_deals_seller_account_id_fkey"
    FOREIGN KEY ("seller_account_id") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "seller_deals_created_by_user_id_fkey"
    FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT "seller_deals_listing_id_fkey"
    FOREIGN KEY ("listing_id") REFERENCES "listings"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_seller_deals_account_status_updated"
  ON "seller_deals" ("seller_account_id", "status", "updated_at" DESC);

CREATE INDEX IF NOT EXISTS "idx_seller_deals_listing"
  ON "seller_deals" ("listing_id");

CREATE INDEX IF NOT EXISTS "idx_seller_deals_creator"
  ON "seller_deals" ("created_by_user_id");
