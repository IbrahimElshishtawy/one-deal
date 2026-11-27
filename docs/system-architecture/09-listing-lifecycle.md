# 09 — Listing / Advertisement Lifecycle

## Overview

Deal One implements an **Orthogonal 3-Axis Listing State Machine** (`backend/src/modules/listings/listings-state-machine.ts`) decoupling **Moderation**, **Publication**, and **Availability**.

**Public Visibility Rule:** A listing appears in public buyer search/home feeds **if and only if**:
`moderationStatus == 'approved' AND publicationStatus == 'published' AND availabilityStatus == 'available'`.

---

## A. Three Orthogonal State Machines

```mermaid
stateDiagram-v2
    state "Axis 1: Moderation Status (Admin / Auto-Approve)" as Mod {
        [*] --> draft
        draft --> pending : Seller submits (POST /:id/submit)
        pending --> approved : Admin approves (or AUTO_APPROVE_LISTINGS=true)
        pending --> rejected : Admin rejects with reason
        approved --> pending : Significant edit re-triggers review
        approved --> rejected : Post-moderation takedown
        rejected --> pending : Seller edits & resubmits
    }

    state "Axis 2: Publication Status (Visibility)" as Pub {
        [*] --> unpublished
        unpublished --> published : Publish (requires moderation=approved & available)
        unpublished --> archived : Archive
        published --> hidden : Seller pauses / Admin hides
        published --> expired : ListingExpiryProcessor (expiresAt <= now)
        published --> archived : Archive
        hidden --> published : Resume / Restore
        hidden --> archived : Archive
        expired --> published : Renew / Republish
        expired --> archived : Archive
        archived --> [*] : Terminal state
    }

    state "Axis 3: Availability Status (Inventory / Deal State)" as Avail {
        [*] --> available
        available --> reserved : Mark reserved
        available --> sold : Mark sold
        available --> rented : Mark rented
        available --> out_of_stock : Out of stock
        available --> discontinued : Discontinue
        reserved --> available : Release
        reserved --> sold : Complete sale
        reserved --> rented : Complete rental
        sold --> available : Relist
        rented --> available : Relist
        out_of_stock --> available : Restock
        discontinued --> available : Reactivate
    }
```

---

## B. Role & Seller Verification Gate Impact on Listings

```mermaid
flowchart LR
    Guest["Guest / Buyer\n(NOT_REQUESTED)"] -->|"Read Published\n(GET /listings, /search)"| PublicFeed["Public Feed & Detail"]
    Unverified["Unverified / Pending / Suspended / Expired Seller"] -->|"POST /listings"| Guard["SellerAuthorizationGuard\n+ AccountTenantGuard"]
    Guard -->|"403 Forbidden"| Blocked["Blocked: Approved Seller Required"]
    Verified["Approved Seller\n(IDENTITY_VERIFIED or BUSINESS_VERIFIED)"] -->|"POST /listings\nPUT/PATCH /:id\nPOST /:id/submit"| Guard2["SellerAuthorizationGuard\n+ DailyQuota Check"]
    Guard2 -->|"Allowed"| ListingDB[("Listing + ListingMedia")]
    Admin["Admin / Content Moderator\n(listings.approve / reject / hide / delete)"] -->|"AdminListingsController\n/admin/listings/*"| ListingDB
```

### Key Listing Invariants Verified in Code
- **Seller Gate:** `POST /api/v1/listings`, `PUT/PATCH /api/v1/listings/:id`, `DELETE /api/v1/listings/:id`, and `POST /api/v1/listings/:id/submit` require an active, approved seller (`SellerAuthorizationGuard`) and valid `AccountMember` permission (`owner`, `manager`, or `lister`).
- **Feed Cache Invalidation:** Creating, editing, moderating, or changing seller verification status bumps Redis version keys `listings:feed:ver` and `home:feed:ver`.
- **Soft Delete:** Deleting a listing sets `deletedAt` while preserving historical conversations, reports, and bookings.
