# 06 — Database ERDs by Domain

All entities, keys, cardinalities, unique constraints, and indexes below are derived directly from `backend/prisma/schema.prisma` and Migrations #1–#15.

---

## Domain 1: Accounts, Users, Authentication & Locations

```mermaid
erDiagram
    Governorate ||--o{ City : contains
    City ||--o{ Area : contains
    User ||--o{ UserSession : has
    User ||--o{ UserDevice : registers
    User ||--o{ Account : owns
    User ||--o{ AccountMember : joins
    Account ||--o{ AccountMember : has_members
    Account ||--o{ Branch : operates
    Account ||--o{ ServiceArea : covers
    Area ||--o{ Branch : locates
    Area ||--o{ ServiceArea : defines

    User {
        uuid id PK
        varchar phone UK
        varchar email UK
        varchar password_hash
        varchar full_name
        varchar role
        varchar seller_status
        timestamptz seller_approved_at
        timestamptz seller_suspended_at
        boolean is_active
        timestamptz deleted_at
    }

    UserSession {
        uuid id PK
        uuid user_id FK
        uuid family_id
        varchar refresh_token_hash
        boolean is_revoked
        timestamptz expires_at
    }

    UserDevice {
        uuid id PK
        uuid user_id FK
        text fcm_token
        varchar platform
    }

    Otp {
        uuid id PK
        varchar phone
        varchar purpose
        varchar code_hash
        smallint attempts
        boolean is_consumed
        timestamptz expires_at
    }

    Account {
        uuid id PK
        uuid owner_user_id FK
        varchar account_type
        varchar seller_type
        varchar display_name
        varchar slug UK
        varchar verification_status
        varchar verification_tier
        timestamptz verification_approved_at
        timestamptz verification_expires_at
        timestamptz verification_suspended_at
        uuid verification_reviewed_by_staff_id FK
        boolean is_active
    }

    AccountMember {
        uuid id PK
        uuid account_id FK
        uuid user_id FK
        varchar role
    }

    Branch {
        uuid id PK
        uuid account_id FK
        uuid area_id FK
        varchar name
        geometry location
        boolean is_main
    }

    ServiceArea {
        uuid id PK
        uuid account_id FK
        uuid area_id FK
        int radius_km
    }

    Governorate {
        uuid id PK
        varchar slug UK
    }

    City {
        uuid id PK
        uuid governorate_id FK
        varchar slug UK
    }

    Area {
        uuid id PK
        uuid city_id FK
        varchar slug UK
    }
```

**Key Constraints & Indexes:**
- `AccountMember`: `UNIQUE (account_id, user_id)` (`uq_account_user`)
- `UserDevice`: `UNIQUE (user_id, fcm_token)` (`uq_user_device_token`)
- `ServiceArea`: `UNIQUE (account_id, area_id)` (`uq_service_area`)
- `Branch`: GiST spatial index `idx_branches_location`
- `Account`: `chk_account_verification_status` (`not_submitted`, `pending`, `approved`, `rejected`, `needs_changes`, `suspended`, `expired`), `chk_accounts_seller_type`, `chk_accounts_verification_tier`, index on `(verification_expires_at)`

---

## Domain 2: Seller Verification System

```mermaid
erDiagram
    User ||--o{ SellerApplication : submits
    Account ||--o{ SellerApplication : upgrades_or_verifies
    Account ||--o{ AccountVerification : legacy_verifications
    StaffUser ||--o{ SellerApplication : reviews_or_assigned
    SellerApplication ||--o{ SellerApplicationDocument : attaches
    SellerApplication ||--o{ SellerDocumentReview : receives
    SellerApplication ||--o{ SellerApplicationHistory : logs
    SellerVerificationRequirement ||--o{ SellerApplicationDocument : governs
    SellerApplicationDocument ||--o{ SellerDocumentReview : reviewed_by
    StaffUser ||--o{ SellerDocumentReview : decides
    StaffUser ||--o{ SellerApplicationHistory : records

    SellerApplication {
        uuid id PK
        uuid user_id FK
        uuid account_id FK
        varchar application_type
        varchar status
        varchar seller_type
        varchar business_type
        varchar derived_verification_tier
        jsonb marketplace_sections
        int requirements_version
        jsonb requirements_snapshot
        text national_id_number
        text tax_id_number
        text commercial_register_number
        text authorized_representative_id
        uuid first_reviewed_by_staff_id
        timestamptz first_reviewed_at
        uuid reviewed_by_staff_id FK
        timestamptz verification_expires_at
        timestamptz renewal_reminder_sent_at
        timestamptz withdrawn_at
        int version
        boolean is_active
    }

    SellerVerificationRequirement {
        uuid id PK
        varchar seller_type
        varchar marketplace_section
        varchar document_type
        boolean is_required
        jsonb accepted_mime_types
        int max_file_size_bytes
        boolean requires_expiration
        int version
        boolean is_active
    }

    SellerApplicationDocument {
        uuid id PK
        uuid application_id FK
        uuid user_id FK
        uuid requirement_id FK
        varchar document_type
        varchar storage_key UK
        varchar status
        int version
        boolean is_current
        uuid replaced_by_document_id
        timestamptz expires_at
        timestamptz reviewed_at
        uuid reviewed_by_staff_id
        timestamptz retention_expires_at
        timestamptz purged_at
    }

    SellerDocumentReview {
        uuid id PK
        uuid application_id FK
        uuid document_id FK
        uuid admin_id FK
        varchar decision
        text reason
        timestamptz reviewed_at
    }

    SellerApplicationHistory {
        uuid id PK
        uuid application_id FK
        uuid account_id
        uuid user_id FK
        uuid admin_id FK
        varchar actor_type
        varchar action
        varchar previous_status
        varchar new_status
        varchar previous_tier
        varchar new_tier
        timestamptz created_at
    }
```

**Key Constraints & Indexes:**
- Partial Unique Index `uq_seller_applications_active_user_type` on `(user_id, application_type)` where `is_active = true AND deleted_at IS NULL AND status IN ('DRAFT','PENDING','UNDER_REVIEW','NEEDS_CORRECTION','APPROVED')`.
- `SellerApplicationDocument`: `UNIQUE (storage_key)`, index on `(retention_expires_at, purged_at)` for retention cleanup worker.

---

## Domain 3: Listings, Categories, Media & Projects

```mermaid
erDiagram
    Category ||--o{ Category : parent_of
    Category ||--o{ CategoryField : defines
    Category ||--o{ Listing : categorizes
    Account ||--o{ Project : develops
    Account ||--o{ Listing : owns
    Branch ||--o{ Listing : located_at
    Project ||--o{ Listing : groups
    Area ||--o{ Listing : area_of
    Listing ||--o{ ListingMedia : has_media
    Listing ||--o{ Favorite : favorited_by
    User ||--o{ Favorite : saves

    Category {
        uuid id PK
        uuid parent_id FK
        varchar slug UK
        varchar name_ar
        varchar name_en
        boolean is_active
    }

    CategoryField {
        uuid id PK
        uuid category_id FK
        varchar field_key
        varchar field_type
        boolean is_required
        boolean is_filterable
    }

    Project {
        uuid id PK
        uuid account_id FK
        varchar name
        varchar slug UK
    }

    Listing {
        uuid id PK
        uuid account_id FK
        uuid branch_id FK
        uuid project_id FK
        uuid category_id FK
        uuid area_id FK
        varchar listing_kind
        varchar title
        decimal price
        varchar moderation_status
        varchar publication_status
        varchar availability_status
        jsonb attributes
        timestamptz expires_at
        timestamptz deleted_at
    }

    ListingMedia {
        uuid id PK
        uuid listing_id FK
        varchar media_type
        varchar url
        varchar processing_status
        int sort_order
    }

    Favorite {
        uuid id PK
        uuid user_id FK
        uuid listing_id FK
    }
```

---

## Domain 4: Messaging, Notifications, Reports & Quotas

```mermaid
erDiagram
    User ||--o{ Conversation : buyer_in
    Account ||--o{ Conversation : seller_in
    Listing ||--o{ Conversation : subject_of
    Conversation ||--o{ Message : contains
    User ||--o{ Message : sends
    User ||--o{ Notification : receives
    User ||--o{ Report : files
    Listing ||--o{ Report : reported_listing
    Account ||--o{ Report : reported_account
    Account ||--o{ DailyQuota : tracks

    Conversation {
        uuid id PK
        uuid listing_id FK
        uuid buyer_user_id FK
        uuid seller_account_id FK
        varchar status
        timestamptz last_message_at
    }

    Message {
        uuid id PK
        uuid conversation_id FK
        uuid sender_user_id FK
        text body
        varchar status
        timestamptz read_at
    }

    Notification {
        uuid id PK
        uuid user_id FK
        varchar type
        varchar title
        text body
        boolean is_read
    }

    Report {
        uuid id PK
        uuid reporter_user_id FK
        uuid listing_id FK
        uuid reported_account_id FK
        varchar reason
        varchar status
    }

    DailyQuota {
        uuid id PK
        uuid account_id FK
        varchar quota_type
        date quota_date
        int used_count
    }
```

---

## Domain 5: Activity Hub (Bookings, RFQ, Quotations, Cart) & Payments

```mermaid
erDiagram
    User ||--o{ Booking : books
    Account ||--o{ Booking : provides
    Listing ||--o{ Booking : booked_service
    User ||--o{ RfqRequest : requests
    Category ||--o{ RfqRequest : for_category
    RfqRequest ||--o{ RfqItem : items
    RfqRequest ||--o{ Quotation : receives
    Account ||--o{ Quotation : submits
    Quotation ||--o{ QuotationItem : quotes
    User ||--o{ CartItem : holds
    Listing ||--o{ CartItem : added_item
    User ||--o{ Payment : pays
    Listing ||--o{ Payment : promotes
    PromotionPackage ||--o{ Payment : selected_plan

    Booking {
        uuid id PK
        uuid user_id FK
        uuid provider_account_id FK
        uuid listing_id FK
        varchar status
        timestamptz scheduled_at
    }

    RfqRequest {
        uuid id PK
        uuid user_id FK
        uuid category_id FK
        varchar status
        timestamptz expires_at
    }

    Quotation {
        uuid id PK
        uuid rfq_id FK
        uuid supplier_account_id FK
        decimal total_price
        varchar status
    }

    CartItem {
        uuid id PK
        uuid user_id FK
        uuid listing_id FK
        int quantity
    }

    Payment {
        uuid id PK
        uuid user_id FK
        uuid listing_id FK
        uuid package_id FK
        decimal amount
        varchar status
        varchar provider_ref
    }
```

---

## Domain 6: Enterprise Admin RBAC, CMS, Campaigns & Outbox

```mermaid
erDiagram
    StaffRole ||--o{ StaffUser : assigned_to
    StaffUser ||--o{ StaffSession : holds
    StaffUser ||--o{ StaffLoginAttempt : logs
    StaffUser ||--o{ StaffPasswordResetToken : requests
    StaffUser ||--o{ ModerationLog : writes

    StaffRole {
        int id PK
        varchar name UK
        jsonb permissions
        boolean is_system
    }

    StaffUser {
        uuid id PK
        int role_id FK
        varchar email UK
        varchar password_hash
        boolean mfa_enabled
        text mfa_secret_encrypted
        varchar status
    }

    StaffSession {
        uuid id PK
        uuid staff_id FK
        varchar refresh_token_hash
        boolean is_revoked
        timestamptz expires_at
    }

    AuditLog {
        uuid id PK
        varchar actor_type
        varchar actor_id
        varchar action
        varchar target_entity
        varchar target_id
        jsonb diff_payload
        timestamptz created_at
    }

    OutboxEvent {
        uuid id PK
        varchar event_type
        varchar aggregate_id
        jsonb payload
        varchar status
        int retry_count
    }

    FeatureFlag {
        uuid id PK
        varchar key UK
        boolean is_enabled
    }

    CmsItem {
        uuid id PK
        varchar slug UK
        varchar type
        varchar status
    }

    NotificationCampaign {
        uuid id PK
        varchar title
        varchar status
        timestamptz scheduled_at
    }

    PlatformSetting {
        varchar key PK
        jsonb value
    }
```
