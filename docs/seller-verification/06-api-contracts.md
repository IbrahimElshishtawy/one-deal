# 06 — API Contracts

All endpoints are prefixed with `/api/v1` and wrapped in the standard Deal One response envelope `{ success: true, data: ... }` or `{ success: false, error: { code, message } }`.

## User Endpoints (`/api/v1/seller-applications`, Guard: `JwtAuthGuard`)

| Method | Path | Rate Limit | Description |
| --- | --- | --- | --- |
| `GET` | `/seller-applications/requirements` | Default | Get active verification requirements filtered by `sellerType`, `marketplaceSection`, or `marketplaceSections` |
| `POST` | `/seller-applications` | 10/hr | Create a `DRAFT` seller application (`CAN_SUBMIT_SELLER_APPLICATION`) |
| `GET` | `/seller-applications/me` | Default | Get current user's seller status, roles, capabilities, and active application details |
| `GET` | `/seller-applications/me/corrections` | Default | Get active correction requests (reason, affected fields, rejected documents) |
| `GET` | `/seller-applications/me/history` | Default | Get chronological status transition history |
| `PATCH` | `/seller-applications/me` | 30/hr | Update `DRAFT` fields (or only `correctionFields` during `NEEDS_CORRECTION`) |
| `POST` | `/seller-applications/me/documents/upload-url` | 20/hr | Request short-lived private presigned `PUT` URL (`expiresInSeconds: 900`) |
| `POST` | `/seller-applications/me/documents` | 20/hr | Confirm & register uploaded document (validates MIME, size, magic bytes, ownership, expiration) |
| `PUT` | `/seller-applications/me/documents/:documentId/replace` | 20/hr | Replace a document (creates new version, preserves previous version; restricted to `REJECTED` docs during `NEEDS_CORRECTION`) |
| `GET` | `/seller-applications/me/documents/:documentId/access` | 30/hr | Get short-lived private signed `GET` URL for own document (`expiresInSeconds: 300`) |
| `DELETE` | `/seller-applications/me/documents/:documentId` | 20/hr | Soft-delete document from an editable `DRAFT` or `REJECTED` application |
| `POST` | `/seller-applications/me/submit` | 10/hr | Validate completeness and submit application (`DRAFT → PENDING`) |
| `POST` | `/seller-applications/me/resubmit` | 10/hr | Resubmit `NEEDS_CORRECTION → PENDING` or `REJECTED`/`EXPIRED` → `DRAFT`/`PENDING` |
| `GET` | `/seller-applications/dashboard` | Default | Seller dashboard summary (`CAN_ACCESS_SELLER_DASHBOARD`, approved sellers only) |

## Admin Endpoints (`/api/v1/admin/seller-applications`, Guards: `AdminJwtAuthGuard`, `PermissionsGuard`)

| Method | Path | Required Permission(s) | Description |
| --- | --- | --- | --- |
| `GET` | `/admin/seller-applications/requirements` | `verification.read` | List all configurable verification requirements |
| `POST` | `/admin/seller-applications/requirements` | `verification.requirements.manage` OR `settings.update` | Create a new verification requirement |
| `PATCH` | `/admin/seller-applications/requirements/:requirementId` | `verification.requirements.manage` OR `settings.update` | Update requirement (auto-increments `version`) |
| `DELETE` | `/admin/seller-applications/requirements/:requirementId` | `verification.requirements.manage` OR `settings.update` | Soft-delete / deactivate requirement |
| `GET` | `/admin/seller-applications` | `verification.read` | List & filter applications (`status`, `sellerType`, `businessType`, `marketplaceSection`, `q`, `page`, `limit`) |
| `GET` | `/admin/seller-applications/:id` | `verification.read` | Full application detail, completeness report, applicable requirements, document versions & reviews, and history |
| `GET` | `/admin/seller-applications/:id/history` | `verification.read` | Chronological verification status history |
| `GET` | `/admin/seller-applications/:id/documents/:documentId` | `verification.documents.read` | Audited short-lived private signed URL to inspect a verification document |
| `POST` | `/admin/seller-applications/:id/documents/:documentId/review` | `verification.approve` OR `verification.reject` | Accept or reject an individual document (`APPROVED`, `REJECTED`, `CORRECTION_REQUIRED`) |
| `POST` | `/admin/seller-applications/:id/review` | `verification.approve` OR `verification.reject` | Transition `PENDING → UNDER_REVIEW` |
| `POST` | `/admin/seller-applications/:id/request-correction` | `verification.reject` OR `verification.approve` | Transition `UNDER_REVIEW → NEEDS_CORRECTION` with affected fields & rejected document IDs |
| `POST` | `/admin/seller-applications/:id/approve` | `verification.approve` | Transactional approval, seller account activation, permission grant, notification, and audit |
| `POST` | `/admin/seller-applications/:id/reject` | `verification.reject` | Reject application with mandatory reason (min 5 chars) |
| `POST` | `/admin/seller-applications/:id/suspend` | `verification.reject` OR `users.suspend` | Suspend seller privileges immediately while preserving buyer permissions |
| `POST` | `/admin/seller-applications/:id/expire` | `verification.reject` OR `verification.approve` | Expire approved verification (`APPROVED → EXPIRED`) |
| `POST` | `/admin/seller-applications/:id/reinstate` | `verification.approve` | Reinstate suspended seller (`SUSPENDED → APPROVED`) |
