# 04 — Admin Verification Workflow

Implemented in `AdminSellerApplicationsController` (`src/modules/accounts/controllers/admin-seller-applications.controller.ts`) and `SellerApplicationService`. Reuses the existing Enterprise Admin RBAC (`AdminJwtAuthGuard`, `PermissionsGuard`, `StaffUser`, `StaffRole`).

## Required RBAC Permissions

| Admin Endpoint | Required Permission(s) |
|---|---|
| `GET /api/v1/admin/seller-applications` | `verification.read` (masks sensitive IDs unless `verification.documents.read`) |
| `GET /api/v1/admin/seller-applications/:id` | `verification.read` |
| `GET /api/v1/admin/seller-applications/:id/history` | `verification.read` |
| `GET /api/v1/admin/seller-applications/:id/documents/:documentId` | `verification.documents.read` |
| `POST /api/v1/admin/seller-applications/:id/review` | `verification.approve` OR `verification.reject` |
| `POST /api/v1/admin/seller-applications/:id/approve` | `verification.approve` |
| `POST /api/v1/admin/seller-applications/:id/reject` | `verification.reject` |
| `POST /api/v1/admin/seller-applications/:id/suspend` | `verification.reject` OR `users.suspend` |
| `POST /api/v1/admin/seller-applications/:id/reinstate` | `verification.approve` |

## Governance & Anti-Abuse Protections

1. **Self-Approval Prevention**: `assertNotSelfAction()` rejects any admin action where `application.userId === staff.id` or `application.user.email === staff.email` (`403 SELF_APPROVAL_FORBIDDEN`).
2. **Unauthorized Approval Prevention**: Regular marketplace user tokens have `permissions = []` in `AdminJwtAuthGuard`, causing `PermissionsGuard` to return `403 Forbidden`.
3. **Duplicate Approval Prevention**: Optimistic concurrency check (`updateMany({ where: { id, status: currentStatus } })`) inside `prisma.$transaction` rejects concurrent or repeated approvals with `409 Conflict` (`DUPLICATE_APPROVAL`).
4. **Incomplete Application Guard**: `approveApplication()` re-validates `evaluateApplicationCompleteness()` server-side before approving (`400 INCOMPLETE_SELLER_APPLICATION`).
5. **Mandatory Reasons**: Rejection (`AdminRejectSellerApplicationDto`) and suspension (`AdminSuspendSellerDto`) enforce a non-empty `reason` (min 5 characters).
6. **Transactional Atomicity**: Approval atomically updates `SellerApplication`, marks documents `VERIFIED`, creates/activates `Account` (`verificationStatus = 'approved'`) + `AccountMember(role = 'owner')`, updates `User.sellerStatus = 'APPROVED'`, records `SellerApplicationHistory`, `ModerationLog`, and `AuditLog` (`SELLER_APPLICATION_APPROVED`, `SELLER_PERMISSIONS_GRANTED`).
7. **Seller-Only Suspension**: `suspendSeller()` sets `User.sellerStatus = 'SUSPENDED'` and `Account.verificationStatus = 'suspended'`, invalidates Redis membership caches immediately, and **preserves `User.isActive = true`** so buyer permissions remain uninterrupted.
