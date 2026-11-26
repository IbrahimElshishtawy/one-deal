# 05 — Admin Review Workflow

## RBAC Integration

All admin endpoints under `/api/v1/admin/seller-applications` are guarded by `AdminJwtAuthGuard` + `PermissionsGuard`:

| Permission | Scope |
| --- | --- |
| `verification.read` | List applications, filter queue, view application detail, completeness, history, and requirements |
| `verification.documents.read` | Audited short-lived signed URL access to private verification documents |
| `verification.approve` | Start review, review documents, approve applications, reinstate suspended sellers |
| `verification.reject` | Start review, review documents, request corrections, reject applications, suspend or expire sellers |
| `verification.requirements.manage` | Create, update (versioned), and deactivate configurable verification requirements |

## Review & Decision Workflow

1. **Queue Filtering**: Admins filter applications by `status`, `sellerType` (`INDIVIDUAL`, `BUSINESS`, `SERVICE_PROVIDER`), `businessType`, `marketplaceSection` (any of the 6 Deal One categories), and text search `q`.
2. **Application Inspection**: `GET /api/v1/admin/seller-applications/:id` returns seller info (with sensitive IDs masked), applicable requirements, completeness evaluation (missing fields, missing/rejected/expired documents), all document versions with review history, and chronological status history.
3. **Start Review**: `POST /:id/review` transitions `PENDING → UNDER_REVIEW`, assigns `assignedToStaffId`, records history, and notifies the user.
4. **Individual Document Review**: `POST /:id/documents/:documentId/review` records an immutable `SellerDocumentReview` (`APPROVED`, `REJECTED`, or `CORRECTION_REQUIRED`) with `adminId`, `decision`, `reason`, `notes`, and `reviewedAt`.
5. **Correction Request**: `POST /:id/request-correction` transitions `UNDER_REVIEW → NEEDS_CORRECTION`, marks affected documents as `REJECTED`, stores `correctionFields` and `correctionReason`, and notifies the user.
6. **Transactional Approval**: `POST /:id/approve` executes inside a single Prisma `$transaction`:
   - Verifies non-self-approval (`assertNotSelfAction`).
   - Validates state transition and full dynamic completeness (blocks approval if any required field/document is missing, rejected, or expired).
   - Uses optimistic concurrency (`updateMany` with `where: { id, status: currentStatus }`) to prevent duplicate decisions.
   - Marks current `UPLOADED` documents as `VERIFIED`.
   - Creates or activates the user's seller `Account` (`verificationStatus = 'approved'`, `isActive = true`) and `AccountMember(role='owner')`.
   - Updates `User.sellerStatus = 'APPROVED'` while preserving all buyer permissions.
   - Writes `SellerApplicationHistory`, `ModerationLog`, and `AuditLog` (`SELLER_APPLICATION_APPROVED`, `SELLER_PERMISSIONS_GRANTED`).
   - Invalidates Redis membership cache and dispatches `SELLER_APPLICATION_APPROVED` notification.

## Safeguards Enforced

- **No self-approval**: Staff cannot review, approve, reject, suspend, or expire their own application (`403 SELF_APPROVAL_FORBIDDEN`).
- **No incomplete approvals**: Missing, rejected, or expired required documents return `400 INCOMPLETE_SELLER_APPLICATION`.
- **No duplicate decisions**: Optimistic status locking returns `409 DUPLICATE_APPROVAL` on concurrent or repeated approvals.
- **No unauthorized document access**: Staff lacking `verification.documents.read` receive `403 Forbidden`.
