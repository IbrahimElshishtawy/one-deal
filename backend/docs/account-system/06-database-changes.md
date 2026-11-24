# 06 — Database Changes & Migration Safety

## Migration

- **File**: `prisma/migrations/20261124000001_add_seller_verification_system/migration.sql`
- **Type**: Strictly additive and non-destructive.
- **Preserved Entities**: All existing `users`, `accounts`, `account_members`, `listings`, `favorites`, `conversations`, `bookings`, `rfq_requests`, `cart_items`, and `audit_log` rows and foreign keys remain intact.

## Schema Changes

### 1. Extended `users` Table
Added columns:
- `seller_status VARCHAR(25) NOT NULL DEFAULT 'NOT_REQUESTED'`
- `seller_approved_at TIMESTAMPTZ`
- `seller_suspended_at TIMESTAMPTZ`
- `seller_suspension_reason TEXT`
- Index: `users_seller_status_idx (seller_status)`

**Safe Backfill**: Pre-existing users who already owned an active, non-deleted, `approved` `accounts` row with at least one existing listing were backfilled to `seller_status = 'APPROVED'` so existing seller/listing relationships remain valid. All new registrations default strictly to `NOT_REQUESTED` (`BUYER`).

### 2. New Table: `seller_applications`
Stores buyer-to-seller conversion applications with status lifecycle, business metadata, reviewer assignment, review timestamps, rejection/suspension reasons, and resubmission count.
- Check constraints: `chk_seller_applications_status`, `chk_seller_applications_business_type`
- Partial unique index preventing duplicate active applications at the DB level:
  ```sql
  CREATE UNIQUE INDEX uq_seller_applications_active_user
    ON seller_applications (user_id)
    WHERE is_active = true AND status IN ('DRAFT', 'PENDING', 'UNDER_REVIEW', 'APPROVED');
  ```
- Indexes: `(user_id, is_active)`, `(status, submitted_at)`, `(assigned_to_staff_id, status)`.

### 3. New Table: `seller_application_documents`
Stores private verification document metadata (`document_type`, `storage_key` UNIQUE, `original_file_name`, `mime_type`, `file_size_bytes`, `checksum_sha256`, `status`, `uploaded_at`).
- Check constraint: `chk_seller_app_doc_size (file_size_bytes > 0 AND file_size_bytes <= 10485760)`.
- Indexes: `(application_id, document_type)`, `(user_id)`.

### 4. New Table: `seller_application_history`
Immutable decision and status transition ledger storing `application_id`, `user_id`, `admin_id`, `actor_type`, `previous_status`, `new_status`, `reason`, `metadata`, `created_at`.
- Indexes: `(application_id, created_at DESC)`, `(user_id, created_at DESC)`, `(admin_id, created_at DESC)`.
