-- AlterTable
ALTER TABLE "areas" ALTER COLUMN "centroid" SET DEFAULT ST_SetSRID(ST_MakePoint(31.2357, 30.0444), 4326);

-- AlterTable
ALTER TABLE "branches" ALTER COLUMN "location" SET DEFAULT ST_SetSRID(ST_MakePoint(31.2357, 30.0444), 4326);

-- AlterTable
ALTER TABLE "listings" ALTER COLUMN "physical_location" SET DEFAULT ST_SetSRID(ST_MakePoint(31.2357, 30.0444), 4326),
ALTER COLUMN "display_location" SET DEFAULT ST_SetSRID(ST_MakePoint(31.2357, 30.0444), 4326);

-- AlterTable
ALTER TABLE "payments" ALTER COLUMN "id" DROP DEFAULT;

-- CreateTable
CREATE TABLE "bookings" (
    "id" UUID NOT NULL,
    "reference" VARCHAR(30) NOT NULL,
    "user_id" UUID NOT NULL,
    "listing_id" UUID,
    "provider_account_id" UUID NOT NULL,
    "category_id" UUID,
    "booking_type" VARCHAR(40) NOT NULL,
    "scheduled_date" DATE NOT NULL,
    "scheduled_time" VARCHAR(10) NOT NULL,
    "scheduled_at" TIMESTAMPTZ NOT NULL,
    "location" TEXT,
    "notes" TEXT,
    "status" VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    "cancellation_reason" TEXT,
    "cancelled_by_user_id" UUID,
    "confirmed_at" TIMESTAMPTZ,
    "completed_at" TIMESTAMPTZ,
    "cancelled_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bookings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rfq_requests" (
    "id" UUID NOT NULL,
    "reference" VARCHAR(30) NOT NULL,
    "user_id" UUID NOT NULL,
    "category_id" UUID,
    "title" VARCHAR(200) NOT NULL,
    "description" TEXT NOT NULL,
    "delivery_location" TEXT NOT NULL,
    "required_by_date" DATE,
    "supporting_images" JSONB NOT NULL DEFAULT '[]',
    "additional_notes" TEXT,
    "status" VARCHAR(25) NOT NULL DEFAULT 'SUBMITTED',
    "accepted_quotation_id" UUID,
    "cancellation_reason" TEXT,
    "expires_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "rfq_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rfq_items" (
    "id" UUID NOT NULL,
    "rfq_id" UUID NOT NULL,
    "listing_id" UUID,
    "name" VARCHAR(200) NOT NULL,
    "specification" TEXT,
    "quantity" DECIMAL(12,3) NOT NULL,
    "unit" VARCHAR(40) NOT NULL,
    "sort_order" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "rfq_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "quotations" (
    "id" UUID NOT NULL,
    "rfq_id" UUID NOT NULL,
    "supplier_account_id" UUID NOT NULL,
    "submitted_by_user_id" UUID NOT NULL,
    "subtotal_amount" DECIMAL(14,2) NOT NULL,
    "delivery_fee" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "total_amount" DECIMAL(14,2) NOT NULL,
    "currency" VARCHAR(3) NOT NULL DEFAULT 'EGP',
    "estimated_delivery_days" INTEGER NOT NULL,
    "valid_until" TIMESTAMPTZ NOT NULL,
    "notes" TEXT,
    "status" VARCHAR(20) NOT NULL DEFAULT 'SUBMITTED',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "quotations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "quotation_items" (
    "id" UUID NOT NULL,
    "quotation_id" UUID NOT NULL,
    "rfq_item_id" UUID,
    "name" VARCHAR(200) NOT NULL,
    "quantity" DECIMAL(12,3) NOT NULL,
    "unit" VARCHAR(40) NOT NULL,
    "unit_price" DECIMAL(14,2) NOT NULL,
    "line_total" DECIMAL(14,2) NOT NULL,
    "notes" TEXT,

    CONSTRAINT "quotation_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cart_items" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "listing_id" UUID NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "variant_key" VARCHAR(100) NOT NULL DEFAULT 'default',
    "variant_attributes" JSONB NOT NULL DEFAULT '{}',
    "unit_price_snapshot" DECIMAL(14,2) NOT NULL,
    "currency" VARCHAR(3) NOT NULL DEFAULT 'EGP',
    "notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "cart_items_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "bookings_reference_key" ON "bookings"("reference");

-- CreateIndex
CREATE INDEX "bookings_user_id_status_scheduled_at_idx" ON "bookings"("user_id", "status", "scheduled_at" DESC);

-- CreateIndex
CREATE INDEX "bookings_provider_account_id_status_scheduled_at_idx" ON "bookings"("provider_account_id", "status", "scheduled_at");

-- CreateIndex
CREATE INDEX "bookings_listing_id_scheduled_at_idx" ON "bookings"("listing_id", "scheduled_at");

-- CreateIndex
CREATE INDEX "bookings_category_id_idx" ON "bookings"("category_id");

-- CreateIndex
CREATE UNIQUE INDEX "rfq_requests_reference_key" ON "rfq_requests"("reference");

-- CreateIndex
CREATE INDEX "rfq_requests_user_id_status_created_at_idx" ON "rfq_requests"("user_id", "status", "created_at" DESC);

-- CreateIndex
CREATE INDEX "rfq_requests_status_created_at_idx" ON "rfq_requests"("status", "created_at" DESC);

-- CreateIndex
CREATE INDEX "rfq_requests_category_id_idx" ON "rfq_requests"("category_id");

-- CreateIndex
CREATE INDEX "rfq_items_rfq_id_idx" ON "rfq_items"("rfq_id");

-- CreateIndex
CREATE INDEX "quotations_rfq_id_status_idx" ON "quotations"("rfq_id", "status");

-- CreateIndex
CREATE INDEX "quotations_supplier_account_id_created_at_idx" ON "quotations"("supplier_account_id", "created_at" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "quotations_rfq_id_supplier_account_id_key" ON "quotations"("rfq_id", "supplier_account_id");

-- CreateIndex
CREATE INDEX "quotation_items_quotation_id_idx" ON "quotation_items"("quotation_id");

-- CreateIndex
CREATE INDEX "cart_items_user_id_updated_at_idx" ON "cart_items"("user_id", "updated_at" DESC);

-- CreateIndex
CREATE INDEX "cart_items_listing_id_idx" ON "cart_items"("listing_id");

-- CreateIndex
CREATE UNIQUE INDEX "cart_items_user_id_listing_id_variant_key_key" ON "cart_items"("user_id", "listing_id", "variant_key");

-- CreateIndex
CREATE INDEX "favorites_listing_id_idx" ON "favorites"("listing_id");

-- AddForeignKey
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_listing_id_fkey" FOREIGN KEY ("listing_id") REFERENCES "listings"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_provider_account_id_fkey" FOREIGN KEY ("provider_account_id") REFERENCES "accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rfq_requests" ADD CONSTRAINT "rfq_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rfq_requests" ADD CONSTRAINT "rfq_requests_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rfq_items" ADD CONSTRAINT "rfq_items_rfq_id_fkey" FOREIGN KEY ("rfq_id") REFERENCES "rfq_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rfq_items" ADD CONSTRAINT "rfq_items_listing_id_fkey" FOREIGN KEY ("listing_id") REFERENCES "listings"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quotations" ADD CONSTRAINT "quotations_rfq_id_fkey" FOREIGN KEY ("rfq_id") REFERENCES "rfq_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quotations" ADD CONSTRAINT "quotations_supplier_account_id_fkey" FOREIGN KEY ("supplier_account_id") REFERENCES "accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quotations" ADD CONSTRAINT "quotations_submitted_by_user_id_fkey" FOREIGN KEY ("submitted_by_user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quotation_items" ADD CONSTRAINT "quotation_items_quotation_id_fkey" FOREIGN KEY ("quotation_id") REFERENCES "quotations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quotation_items" ADD CONSTRAINT "quotation_items_rfq_item_id_fkey" FOREIGN KEY ("rfq_item_id") REFERENCES "rfq_items"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cart_items" ADD CONSTRAINT "cart_items_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cart_items" ADD CONSTRAINT "cart_items_listing_id_fkey" FOREIGN KEY ("listing_id") REFERENCES "listings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
