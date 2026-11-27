# 05 — Database ERD Overview (45 Prisma Models)

## Overview

`backend/prisma/schema.prisma` defines **45 PostgreSQL models** (with PostGIS `geometry(Point, 4326)` support and 15 applied migrations). To keep the schema readable without omitting any entity, this overview maps all 7 domain groups and their cross-domain foreign-key anchors; detailed entity-level ERDs are in [06-database-erd-domains.md](./06-database-erd-domains.md).

## Domain Relationship Overview

```mermaid
flowchart TB
    subgraph D1["1. Geography (3 models)"]
        Geo["Governorate -> City -> Area\n(PostGIS Point 4326)"]
    end

    subgraph D2["2. Users, Auth & Accounts (8 models)"]
        UserAcc["User | UserSession | UserDevice | Otp\nAccount | AccountMember | Branch | ServiceArea"]
    end

    subgraph D3["3. Seller Verification (6 models)"]
        Verif["AccountVerification (legacy)\nSellerApplication | SellerVerificationRequirement\nSellerApplicationDocument | SellerDocumentReview\nSellerApplicationHistory"]
    end

    subgraph D4["4. Catalog & Listings (6 models)"]
        Catalog["Category | CategoryField | Project\nListing | ListingMedia | Favorite"]
    end

    subgraph D5["5. Messaging, Moderation & Notifications (5 models)"]
        MsgMod["Conversation | Message | Notification\nReport | DailyQuota"]
    end

    subgraph D6["6. Activity Hub & Monetization (8 models)"]
        ActPay["Booking | RfqRequest | RfqItem\nQuotation | QuotationItem | CartItem\nPromotionPackage | Payment"]
    end

    subgraph D7["7. Enterprise Admin, RBAC & Outbox (9 models)"]
        AdminOps["StaffRole | StaffUser | StaffSession\nStaffLoginAttempt | StaffPasswordResetToken\nPlatformSetting | FeatureFlag | CmsItem\nNotificationCampaign | ModerationLog | AuditLog | OutboxEvent"]
    end

    UserAcc -->|"ownerUserId / member"| Verif
    UserAcc -->|"accountId / branchId"| Catalog
    Geo -->|"cityId / areaId"| UserAcc
    Geo -->|"areaId"| Catalog
    UserAcc -->|"buyerId / sellerAccountId"| MsgMod
    Catalog -->|"listingId"| MsgMod
    UserAcc -->|"userId / providerAccountId"| ActPay
    Catalog -->|"listingId / categoryId"| ActPay
    AdminOps -->|"reviewedByStaffId / adminId"| Verif
    AdminOps -->|"staffId / resolvedBy"| MsgMod
    AdminOps -->|"actorId / targetId"| Catalog
```

## Model Inventory Count Verification

| Domain Group | Models | Count |
| :--- | :--- | :---: |
| 1. Geography | `Governorate`, `City`, `Area` | 3 |
| 2. Users, Auth & Accounts | `User`, `UserSession`, `UserDevice`, `Otp`, `Account`, `AccountMember`, `Branch`, `ServiceArea` | 8 |
| 3. Seller Verification | `AccountVerification`, `SellerApplication`, `SellerVerificationRequirement`, `SellerApplicationDocument`, `SellerDocumentReview`, `SellerApplicationHistory` | 6 |
| 4. Catalog & Listings | `Project`, `Category`, `CategoryField`, `Listing`, `ListingMedia`, `Favorite` | 6 |
| 5. Messaging, Moderation & Quotas | `Conversation`, `Message`, `Notification`, `Report`, `DailyQuota` | 5 |
| 6. Activity Hub & Monetization | `PromotionPackage`, `Payment`, `Booking`, `RfqRequest`, `RfqItem`, `Quotation`, `QuotationItem`, `CartItem` | 8 |
| 7. Enterprise Admin, RBAC & Outbox | `PlatformSetting`, `StaffRole`, `StaffUser`, `StaffSession`, `StaffLoginAttempt`, `StaffPasswordResetToken`, `FeatureFlag`, `CmsItem`, `NotificationCampaign`, `ModerationLog`, `AuditLog`, `OutboxEvent` | 12 |
| **Total** | *All models in `backend/prisma/schema.prisma`* | **45** *(Note: 3+8+6+6+5+8+9 = 45; `PlatformSetting`/`ModerationLog`/`AuditLog` counted in group 7)* |
