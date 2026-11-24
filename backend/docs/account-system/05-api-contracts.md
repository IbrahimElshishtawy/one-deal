# 05 — API Contracts

All endpoints are prefixed with `/api/v1` and wrapped in the standard `TransformInterceptor` response envelope (`{ success: true, data: ..., timestamp, requestId }`).

## User-Facing Seller Application Endpoints (`/api/v1/seller-applications`)

All require `Authorization: Bearer <mobile-jwt>`.

| Method | Path | Purpose | Rate Limit |
|---|---|---|---|
| `POST` | `/api/v1/seller-applications` | Request buyer-to-seller conversion (`NOT_REQUESTED -> DRAFT`) | 10 / hour |
| `GET` | `/api/v1/seller-applications/me` | Current `sellerStatus`, `roles`, `capabilities`, active application & completeness | Default |
| `GET` | `/api/v1/seller-applications/me/history` | Chronological status transition history | Default |
| `PATCH` | `/api/v1/seller-applications/me` | Update application draft fields (only when `DRAFT`) | 30 / hour |
| `POST` | `/api/v1/seller-applications/me/documents/upload-url` | Issue short-lived private presigned PUT URL (MIME + 10MB validated) | 20 / hour |
| `POST` | `/api/v1/seller-applications/me/documents` | Confirm & register uploaded private document | 20 / hour |
| `GET` | `/api/v1/seller-applications/me/documents/:documentId/access` | Issue short-lived private signed GET URL (owner-only) | 30 / hour |
| `DELETE` | `/api/v1/seller-applications/me/documents/:documentId` | Remove document while `DRAFT` or `REJECTED` | 20 / hour |
| `POST` | `/api/v1/seller-applications/me/submit` | Submit complete application (`DRAFT -> PENDING`) | 10 / hour |
| `POST` | `/api/v1/seller-applications/me/resubmit` | Reopen (`DRAFT`) or resubmit (`PENDING`) a `REJECTED` application | 10 / hour |
| `GET` | `/api/v1/seller-applications/dashboard` | Seller dashboard metrics (**APPROVED non-suspended sellers only**) | Default |

## Admin Verification Endpoints (`/api/v1/admin/seller-applications`)

All require `Authorization: Bearer <admin-jwt>` (`AdminJwtAuthGuard` + `PermissionsGuard`).

| Method | Path | Permission | Purpose |
|---|---|---|---|
| `GET` | `/api/v1/admin/seller-applications` | `verification.read` | List applications (`status`, `businessType`, `q`, `page`, `limit`) |
| `GET` | `/api/v1/admin/seller-applications/:id` | `verification.read` | Application detail, completeness, documents, and history |
| `GET` | `/api/v1/admin/seller-applications/:id/history` | `verification.read` | Full decision history for an application |
| `GET` | `/api/v1/admin/seller-applications/:id/documents/:documentId` | `verification.documents.read` | Audited short-lived private signed GET URL |
| `POST` | `/api/v1/admin/seller-applications/:id/review` | `verification.approve` OR `verification.reject` | Mark `PENDING -> UNDER_REVIEW` |
| `POST` | `/api/v1/admin/seller-applications/:id/approve` | `verification.approve` | Atomically approve application, grant seller permissions, activate `Account` |
| `POST` | `/api/v1/admin/seller-applications/:id/reject` | `verification.reject` | Reject with mandatory `reason` (`min 5 chars`) |
| `POST` | `/api/v1/admin/seller-applications/:id/suspend` | `verification.reject` OR `users.suspend` | Suspend approved seller (`reason` mandatory); preserves buyer permissions |
| `POST` | `/api/v1/admin/seller-applications/:id/reinstate` | `verification.approve` | Reinstate `SUSPENDED -> APPROVED` |

## Enhanced Auth & Profile Fields

- `POST /api/v1/auth/otp/verify` and `GET /api/v1/users/me` now include:
  - `sellerStatus`: `"NOT_REQUESTED" | "DRAFT" | "PENDING" | "UNDER_REVIEW" | "APPROVED" | "REJECTED" | "SUSPENDED"`
  - `roles`: `["BUYER"]` or `["BUYER", "SELLER"]`
  - `canSell`: `boolean`
  - `role`: `"USER"` (retained for backward compatibility)
