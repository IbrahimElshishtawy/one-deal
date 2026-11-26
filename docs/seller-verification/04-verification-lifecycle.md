# 04 — Verification Lifecycle & State Machine

## Application Statuses

All statuses are defined in `SellerApplicationStatus` (`backend/src/core/enums/domain.enums.ts`) and enforced at both the service layer and PostgreSQL `chk_seller_applications_status` constraint:

- `NOT_REQUESTED` (initial user state, no application)
- `DRAFT`
- `PENDING`
- `UNDER_REVIEW`
- `NEEDS_CORRECTION`
- `APPROVED`
- `REJECTED`
- `SUSPENDED`
- `EXPIRED`

## Authoritative Transition Matrix

Centralized in `SELLER_APPLICATION_TRANSITIONS` (`backend/src/modules/accounts/seller-application-state-machine.ts`):

| From Status | Allowed Target Statuses | Trigger |
| --- | --- | --- |
| `NOT_REQUESTED` | `DRAFT` | Buyer creates application |
| `DRAFT` | `PENDING` | Buyer submits complete application |
| `PENDING` | `UNDER_REVIEW`, `APPROVED`, `REJECTED` | Admin starts review or adjudicates |
| `UNDER_REVIEW` | `NEEDS_CORRECTION`, `APPROVED`, `REJECTED` | Admin requests correction, approves, or rejects |
| `NEEDS_CORRECTION` | `PENDING` | User resubmits after fixing affected fields/documents |
| `REJECTED` | `DRAFT`, `PENDING` | User reopens or resubmits (subject to max resubmission policy) |
| `APPROVED` | `SUSPENDED`, `EXPIRED` | Admin suspends seller or verification expires |
| `SUSPENDED` | `APPROVED` | Admin reinstates seller |
| `EXPIRED` | `DRAFT`, `PENDING` | User renews expired verification |

Invalid transitions (e.g., `DRAFT → APPROVED`, `REJECTED → APPROVED`, `NEEDS_CORRECTION → APPROVED`) throw `400 INVALID_SELLER_STATUS_TRANSITION`.

## Correction Flow (`NEEDS_CORRECTION`)

1. Admin transitions `UNDER_REVIEW → NEEDS_CORRECTION` via `POST /api/v1/admin/seller-applications/:id/request-correction` with `reason`, `affectedFields`, and `rejectedDocumentIds`.
2. Selected documents are marked `REJECTED` and logged in `seller_document_reviews`.
3. User retrieves pending corrections via `GET /api/v1/seller-applications/me/corrections`.
4. User may update **only** fields listed in `correctionFields` and replace **only** documents in `REJECTED` status.
5. User resubmits via `POST /api/v1/seller-applications/me/resubmit`, transitioning `NEEDS_CORRECTION → PENDING`.

## Expiration Policy (`EXPIRED`)

- Approved applications receive `verificationExpiresAt` (configurable on approval, default 365 days).
- Expiration can be triggered by an admin (`POST /api/v1/admin/seller-applications/:id/expire`) or via the batch policy method `SellerApplicationService.expireOverdueVerifications()`.
- On expiration:
  - `SellerApplication.status = 'EXPIRED'`, `expiredAt = now()`.
  - `User.sellerStatus = 'EXPIRED'`.
  - Owned seller `Account` records are deactivated (`isActive = false`), immediately blocking new listings, listing edits, and seller dashboard access via `SellerAuthorizationGuard`.
  - All buyer permissions, existing listings, and audit history are preserved intact.
  - A `SELLER_VERIFICATION_EXPIRED` in-app notification is generated.
