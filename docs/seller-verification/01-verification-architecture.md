# 01 — Seller Verification Architecture

## Overview

The Deal One Seller Verification & Identity Review System is built directly inside the existing NestJS `AccountsModule` (`backend/src/modules/accounts/`), extending the unified Buyer-to-Seller account conversion system without duplicating authentication, user management, or account models.

Every user starts as a `BUYER` (`User.sellerStatus = 'NOT_REQUESTED'`). Seller privileges (`canCreateListing`, `canManageListing`, `canAccessSellerDashboard`) remain strictly disabled server-side until an authorized admin approves a complete `SellerApplication`.

## Modular Component Architecture

| Component | Location | Responsibility |
| --- | --- | --- |
| `SellerApplicationController` | `backend/src/modules/accounts/controllers/seller-application.controller.ts` | User-facing APIs: requirements lookup, application creation/editing, document upload/replacement/deletion/access, submission, corrections, history, seller dashboard |
| `AdminSellerApplicationsController` | `backend/src/modules/accounts/controllers/admin-seller-applications.controller.ts` | Admin RBAC-protected APIs: requirements CRUD, filtered application queue, detail & completeness inspection, individual document reviews, correction requests, approve/reject/suspend/expire/reinstate |
| `SellerApplicationService` | `backend/src/modules/accounts/services/seller-application.service.ts` | Core transactional business logic, workflow orchestration, cache invalidation, audit logging, and notification dispatch |
| `SellerVerificationRequirementsService` | `backend/src/modules/accounts/services/seller-verification-requirements.service.ts` | Configurable database-backed verification requirements engine across seller types and Deal One marketplace sections |
| `PrivateDocumentStorageService` | `backend/src/modules/accounts/services/private-document-storage.service.ts` | Private R2/S3 bucket isolation, MIME & size enforcement, magic-byte file content signature verification, path-traversal prevention, short-lived AWS SigV4 presigned URLs |
| `SensitiveDataCryptoService` | `backend/src/modules/accounts/services/sensitive-data-crypto.service.ts` | AES-256-GCM encryption at rest and API response masking for sensitive identity numbers (`nationalIdNumber`, `taxIdNumber`, `authorizedRepresentativeId`) |
| `SellerAuthorizationGuard` | `backend/src/modules/accounts/guards/seller-authorization.guard.ts` | Centralized server-side capability enforcement on all seller-only endpoints (`ListingsController`, seller dashboard) |
| `seller-application-state-machine.ts` | `backend/src/modules/accounts/seller-application-state-machine.ts` | Authoritative status transition matrix and seller/business type resolvers |

## Cross-Module Integrations

- **Auth & Identity (`AuthModule`)**: Reuses `JwtAuthGuard`, `CurrentUser`, and the single `User` identity record. No duplicate user table or auth flow.
- **Admin RBAC (`AdminAuthModule`)**: Uses `AdminJwtAuthGuard`, `PermissionsGuard`, and granular permissions (`verification.read`, `verification.documents.read`, `verification.approve`, `verification.reject`, `verification.requirements.manage`).
- **Notifications (`NotificationsModule`)**: Persists in-app notifications in `Notification` and dispatches push notifications via `NotificationsService` for all 7 lifecycle events.
- **Audit Trail (`SecurityAuditService` & `AuditLog` / `ModerationLog`)**: Immutable audit ledger with automatic redaction of sensitive keys (national IDs, signed URLs, tokens, document contents).
- **Redis (`RedisService`)**: Invalidates `account:membership:<userId>:<accountId>` cache immediately on approval, suspension, expiration, or reinstatement.
