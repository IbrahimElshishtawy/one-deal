# 02 — Database Design & Prisma Schema

## Migrations
- **Initial Migration:** `prisma/migrations/20261121213256_add_activity_hub_domains/migration.sql` (additive: creates 6 new tables — `bookings`, `rfq_requests`, `rfq_items`, `quotations`, `quotation_items`, `cart_items` — and adds `favorites_listing_id_idx`).
- **Stabilization Migration (2026-11-22):** `prisma/migrations/20261122000001_stabilize_activity_hub_constraints_and_outbox/migration.sql` (additive):
  - Adds `outbox_events` retry/recovery columns (`retry_count`, `max_retries`, `next_retry_at`, `locked_at`) and composite index `(status, next_retry_at, created_at)`.
  - Adds `quotations.status_reason` and expiry scan indexes `rfq_requests(status, expires_at)` and `quotations(status, valid_until)`.
  - Adds foreign keys `bookings.cancelled_by_user_id -> users(id)` (`ON DELETE SET NULL`) and `rfq_requests.accepted_quotation_id -> quotations(id)` (`ON DELETE SET NULL`, unique).
  - Adds DB-level partial unique concurrency guards: `uq_bookings_provider_confirmed_slot` (`WHERE status = 'CONFIRMED'`) and `uq_quotations_rfq_single_accepted` (`WHERE status = 'ACCEPTED'`).

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
