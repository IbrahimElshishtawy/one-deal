# 03 — Seller Permissions Matrix

Centralized enforcement via `SellerAuthorizationGuard` (`src/modules/accounts/guards/seller-authorization.guard.ts`) and `@RequireSellerCapability(...)` (`src/modules/accounts/decorators/require-seller-capability.decorator.ts`), plus defense-in-depth checks in `ListingsService` and `AccountTenantGuard`.

## Capability Matrix by Seller Status

| Operation / Endpoint | `NOT_REQUESTED` (BUYER) | `DRAFT` | `PENDING` / `UNDER_REVIEW` | `REJECTED` | `APPROVED` | `SUSPENDED` |
|---|---|---|---|---|---|---|
| Browse / Search Listings (`GET /listings`, `GET /listings/:id`) | Allowed | Allowed | Allowed | Allowed | Allowed | Allowed |
| Contact Seller (`POST /listings/:id/contact`) | Allowed | Allowed | Allowed | Allowed | Allowed | Allowed |
| Favorites (`GET/POST/DELETE /favorites`) | Allowed | Allowed | Allowed | Allowed | Allowed | Allowed |
| Cart / Purchase (`GET/POST/PATCH/DELETE /cart/*`) | Allowed | Allowed | Allowed | Allowed | Allowed | Allowed |
| Bookings as Buyer (`POST /bookings`, `GET /bookings`) | Allowed | Allowed | Allowed | Allowed | Allowed | Allowed |
| Create/Manage Buyer RFQs (`POST /rfqs`, `GET /rfqs`) | Allowed | Allowed | Allowed | Allowed | Allowed | Allowed |
| Chat Conversations (`GET/POST /chat/*`) | Allowed | Allowed | Allowed | Allowed | Allowed | Allowed |
| Request / Update / Submit Seller Application | Allowed | Allowed | Blocked (`409`/`400`) | Resubmit | Blocked (`403`) | Blocked (`403`) |
| View Own Application Status & History | Allowed | Allowed | Allowed | Allowed | Allowed | Allowed |
| **Create Listing** (`POST /listings`) | **403** | **403** | **403** | **403** | **Allowed** | **403** |
| **Update / Delete / Availability / Submit / Publish Listing** | **403** | **403** | **403** | **403** | **Owner Only** | **403** |
| **Promote Listing** (`POST /payments/checkout`) | **403** | **403** | **403** | **403** | **Owner Only** | **403** |
| **Listing Video Upload** (`POST /media/video/upload-token`) | **403** | **403** | **403** | **403** | **Allowed** | **403** |
| **Seller Dashboard** (`GET /seller-applications/dashboard`) | **403** | **403** | **403** | **403** | **Allowed** | **403** |
| **Create Commercial Account / Branches / Team / Service Areas** | **403** | **403** | **403** | **403** | **Allowed** | **403** |
| **Submit Supplier RFQ Quotation** (`POST /rfqs/:id/quotations`) | **403** | **403** | **403** | **403** | **Allowed** | **403** |

## Guard Capability Definitions

- `canCreateListing`: Authenticated + active user (`isActive=true`, `deletedAt=null`, `moderationStatus='active'`) + `sellerStatus === 'APPROVED'` + active non-deleted `Account` with `verificationStatus === 'approved'`.
- `canManageListing`: Authorized staff/admin OR approved non-suspended seller who owns (or holds `owner`/`manager`/`lister` role on) the target listing's approved active `Account`.
- `canAccessSellerDashboard`: Authenticated + active user + `sellerStatus === 'APPROVED'`.
- `canSubmitSellerApplication`: Authenticated + active user + `sellerStatus` is neither `APPROVED` nor `SUSPENDED`.
