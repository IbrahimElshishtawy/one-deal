# 08 — Seller Verification Lifecycle

## Overview

Derived directly from `backend/src/modules/accounts/seller-application-state-machine.ts`, `verification-tier.helper.ts`, and `seller-application.service.ts`.

Deal One keeps **Seller Classification** (`INDIVIDUAL`, `BUSINESS`, `SERVICE_PROVIDER`) strictly separate from **Server-Derived Verification Tier** (`NONE`, `IDENTITY_VERIFIED`, `BUSINESS_VERIFIED`).

---

## A. Authoritative State Machine (10 Actual States)

```mermaid
stateDiagram-v2
    [*] --> NOT_REQUESTED
    NOT_REQUESTED --> DRAFT : Seller creates application\n(POST /seller-applications)

    DRAFT --> PENDING : Seller submits complete app\n(locks requirementsSnapshot)
    DRAFT --> WITHDRAWN : Seller withdraws\n(POST /me/withdraw)

    PENDING --> UNDER_REVIEW : Admin claims review\n(sets firstReviewedByStaffId)
    PENDING --> APPROVED : Admin approves\n(blocked if Four-Eyes enabled)
    PENDING --> REJECTED : Admin rejects (reason required)
    PENDING --> WITHDRAWN : Seller withdraws\n(POST /me/withdraw)

    UNDER_REVIEW --> NEEDS_CORRECTION : Admin requests targeted fixes
    UNDER_REVIEW --> APPROVED : Admin approves\n(Four-Eyes: 2nd admin if enabled)
    UNDER_REVIEW --> REJECTED : Admin rejects (reason required)

    NEEDS_CORRECTION --> PENDING : Seller fixes & resubmits
    NEEDS_CORRECTION --> WITHDRAWN : Seller withdraws

    REJECTED --> DRAFT : Seller reopens draft
    REJECTED --> PENDING : Seller resubmits directly

    WITHDRAWN --> DRAFT : Seller starts new draft
    WITHDRAWN --> PENDING : Seller resubmits

    APPROVED --> SUSPENDED : Admin suspends\n(badge & seller perms revoked)
    APPROVED --> EXPIRED : Worker/Admin expires\n(verificationExpiresAt <= now)

    SUSPENDED --> APPROVED : Admin reinstates

    EXPIRED --> DRAFT : Seller starts renewal\n(POST /me/renew, same Account)
    EXPIRED --> PENDING : Seller submits renewal directly
```

### Account & Badge Impact Mapping

| `SellerApplication.status` | `Account.verificationStatus` | `Account.verificationTier` | Public Badge | Listing Creation |
| :--- | :--- | :--- | :--- | :---: |
| `NOT_REQUESTED` / `DRAFT` / `WITHDRAWN` | `not_submitted` | `NONE` | `null` | Blocked |
| `PENDING` / `UNDER_REVIEW` | `pending` | `NONE` | `null` | Blocked |
| `NEEDS_CORRECTION` | `needs_changes` | `NONE` | `null` | Blocked |
| `REJECTED` | `rejected` | `NONE` | `null` | Blocked |
| `APPROVED` (Individual / Service Provider) | `approved` | `IDENTITY_VERIFIED` | **هوية موثقة** | Allowed |
| `APPROVED` (Business) | `approved` | `BUSINESS_VERIFIED` | **شركة / مكتب موثق** | Allowed |
| `SUSPENDED` | `suspended` | `NONE` | `null` (Revoked) | Blocked *(buyer perms kept)* |
| `EXPIRED` | `expired` | `NONE` | `null` (Revoked) | Blocked *(buyer perms kept)* |

*Business Upgrade Invariant: While a `BUSINESS_UPGRADE` application is `DRAFT`, `PENDING`, `UNDER_REVIEW`, `NEEDS_CORRECTION`, `REJECTED`, or `WITHDRAWN`, the seller's existing `Account`, `IDENTITY_VERIFIED` badge, listings, branches, members, and conversations remain completely untouched.*

---

## B. Sequence: Submission, Four-Eyes Review & Approval

```mermaid
sequenceDiagram
    actor Seller
    participant API as SellerApplicationController
    participant Storage as PrivateDocumentStorage
    participant R2 as Cloudflare R2 (Private)
    actor Admin1 as Reviewer Admin
    actor Admin2 as Approver Admin
    participant DB as PostgreSQL
    participant Redis as Redis Cache

    Seller->>API: POST /seller-applications (encrypted PII)
    API->>DB: Create DRAFT + History

    Seller->>API: POST /me/documents/upload-url
    API->>Storage: Validate MIME, size, ext, compatibility
    Storage-->>Seller: SigV4 Presigned PUT URL (15m)
    Seller->>R2: Direct PUT file
    Seller->>API: POST /me/documents (confirm + magic bytes)
    API->>Storage: SigV4 HEAD check (exists, size, content-type)
    API->>DB: Save versioned SellerApplicationDocument

    Seller->>API: POST /me/submit
    API->>DB: Lock requirementsSnapshot + DRAFT -> PENDING + History + AuditLog

    Admin1->>API: POST /admin/seller-applications/:id/review
    API->>DB: PENDING -> UNDER_REVIEW + set firstReviewedByStaffId

    Admin2->>API: POST /admin/seller-applications/:id/approve
    Note over API,DB: Self-approval ALWAYS blocked.<br/>If ENABLE_FOUR_EYES=true: Admin2 != firstReviewedByStaffId enforced atomically.
    API->>DB: Transaction: APPROVED, deriveVerificationTier, update/create Account + verificationExpiresAt, mark docs VERIFIED, History, AuditLog
    API->>Redis: DEL membership + INCR listings:feed:ver & home:feed:ver + SCAN del profiles
```

---

## C. Sequence: Expiration & Same-Account Renewal

```mermaid
sequenceDiagram
    participant Worker as SellerVerificationMaintenanceProcessor
    participant DB as PostgreSQL
    participant Redis as Redis Cache
    actor Seller
    participant API as SellerApplicationController

    Worker->>DB: Hourly scan: APPROVED & verificationExpiresAt <= now
    Worker->>DB: Atomic APPROVED -> EXPIRED, Account -> expired / NONE, schedule doc retention
    Worker->>Redis: Invalidate account, profile & feed caches
    Worker-->>Seller: Push: SELLER_VERIFICATION_EXPIRED

    Seller->>API: POST /api/v1/seller-applications/me/renew
    API->>DB: EXPIRED -> DRAFT (same accountId preserved; valid non-expired docs kept; expired docs marked isCurrent=false)
    Note over Seller,DB: Existing listings, branches, members & conversations remain intact.<br/>Badge stays NONE until Admin approves renewed submission.
```
