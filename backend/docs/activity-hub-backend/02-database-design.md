# 02 — Database Design & Prisma Schema

## Migration
- **Migration:** `prisma/migrations/20261121213256_add_activity_hub_domains/migration.sql`
- **Status:** Non-destructive additive migration (creates 5 new tables and adds `favorites_listing_id_idx`).

## Tables & Models

### 1. `favorites` (`Favorite`)
- Existing table preserved; added `@@index([listingId])` (`favorites_listing_id_idx`).
- Unique constraint: `uq_user_favorite` on `(user_id, listing_id)`.

### 2. `bookings` (`Booking`)
- Fields: `id`, `reference` (unique), `user_id`, `listing_id` (nullable), `provider_account_id`, `category_id` (nullable), `booking_type`, `scheduled_date` (`DATE`), `scheduled_time`, `scheduled_at` (`TIMESTAMPTZ`), `location`, `notes`, `status`, `cancellation_reason`, `cancelled_by_user_id`, `confirmed_at`, `completed_at`, `cancelled_at`, `created_at`, `updated_at`.
- Indexes: `(user_id, status, scheduled_at DESC)`, `(provider_account_id, status, scheduled_at)`, `(listing_id, scheduled_at)`, `(category_id)`.

### 3. `rfq_requests` (`RfqRequest`) & `rfq_items` (`RfqItem`)
- `rfq_requests`: `id`, `reference` (unique), `user_id`, `category_id`, `title`, `description`, `delivery_location`, `required_by_date`, `supporting_images` (`JSONB`), `additional_notes`, `status`, `accepted_quotation_id`, `cancellation_reason`, `expires_at`, `created_at`, `updated_at`.
- `rfq_items`: `id`, `rfq_id` (cascade delete), `listing_id` (set null), `name`, `specification`, `quantity` (`DECIMAL(12,3)`), `unit`, `sort_order`.

### 4. `quotations` (`Quotation`) & `quotation_items` (`QuotationItem`)
- `quotations`: `id`, `rfq_id`, `supplier_account_id`, `submitted_by_user_id`, `subtotal_amount`, `delivery_fee`, `total_amount`, `currency`, `estimated_delivery_days`, `valid_until`, `notes`, `status`, `created_at`, `updated_at`.
- Unique constraint: `uq_rfq_supplier_quotation` on `(rfq_id, supplier_account_id)` prevents duplicate quotations from the same supplier account.
- `quotation_items`: `id`, `quotation_id` (cascade delete), `rfq_item_id` (set null), `name`, `quantity`, `unit`, `unit_price`, `line_total`, `notes`.

### 5. `cart_items` (`CartItem`)
- Fields: `id`, `user_id`, `listing_id`, `quantity`, `variant_key` (default `'default'`), `variant_attributes` (`JSONB`), `unit_price_snapshot` (`DECIMAL(14,2)`), `currency`, `notes`, `created_at`, `updated_at`.
- Unique constraint: `uq_cart_user_listing_variant` on `(user_id, listing_id, variant_key)`.
