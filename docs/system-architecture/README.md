# Deal One — Full System Architecture & Engineering Diagrams

> **Platform:** Deal One Multi-Vertical Egyptian Marketplace (Real Estate, Building Materials & Electricity, Home & Engineering Services, Home Appliances & Decor, Cars, Fashion)
> **Repository Root:** `market_space/` (`backend/`, `deal one app/`, `admin-web/`, `docs/`)
> **Architecture Style:** Modular Monolith Backend (NestJS + Fastify + Prisma + PostgreSQL/PostGIS + Dual Redis + BullMQ) + Flutter Riverpod Mobile App + React/Vite Enterprise Admin Dashboard
> **Ground-Truth Policy:** Every module, entity, endpoint, worker, and integration in these diagrams reflects the **actual verified codebase**. Unimplemented or feature-flagged capabilities are explicitly labeled **Planned / Future** or **Feature-Flagged**.

---

## Documentation Index

| Diagram | Purpose | Source Files | Status |
| :--- | :--- | :--- | :--- |
| [01-system-context.md](./01-system-context.md) | High-level system actors, external gateways, and data boundaries | `backend/src/app.module.ts`, `backend/src/core/config/env.config.ts`, `deal one app/`, `admin-web/` | Verified |
| [02-c4-container.md](./02-c4-container.md) | Deployable containers, runtime protocols, dual-Redis split, and storage tiers | `docker-compose.yml`, `railway.json`, `backend/Dockerfile`, `admin-web/package.json` | Verified |
| [03-backend-architecture.md](./03-backend-architecture.md) | Complete NestJS Modular Monolith map (Core vs. 25 Business Modules, Guards, Workers) | `backend/src/app.module.ts`, `backend/src/modules/**`, `backend/src/workers/**` | Verified |
| [04-flutter-architecture.md](./04-flutter-architecture.md) | Actual Flutter app structure, Riverpod, Dio interceptors, routing, and feature layering | `deal one app/lib/main.dart`, `deal one app/lib/core/**`, `deal one app/lib/features/**` | Verified |
| [05-database-erd-overview.md](./05-database-erd-overview.md) | High-level ERD overview connecting all 45 Prisma models across 7 domain groups | `backend/prisma/schema.prisma` | Verified |
| [06-database-erd-domains.md](./06-database-erd-domains.md) | Detailed per-domain ERDs (Accounts/Auth, Seller Verification, Listings/Categories, Chat/Notifications, Activity Hub/Payments, Admin RBAC/Ops) | `backend/prisma/schema.prisma`, `backend/prisma/migrations/**` | Verified |
| [07-authentication-flow.md](./07-authentication-flow.md) | End-to-end sequences for OTP Register/Login, Password Auth, Refresh Rotation, Logout, Admin MFA, and RBAC | `backend/src/modules/auth/**`, `backend/src/modules/admin-auth/**` | Verified |
| [08-seller-verification-lifecycle.md](./08-seller-verification-lifecycle.md) | Authoritative 10-state Seller Verification machine, Four-Eyes review, Business Upgrade, Withdraw, Renewal, and Expiration | `backend/src/modules/accounts/seller-application-state-machine.ts`, `seller-application.service.ts` | Verified |
| [09-listing-lifecycle.md](./09-listing-lifecycle.md) | Orthogonal 3-Axis Listing State Machine (`Moderation × Publication × Availability`) and seller verification gates | `backend/src/modules/listings/listings-state-machine.ts`, `listings.controller.ts` | Verified |
| [10-messaging-notifications.md](./10-messaging-notifications.md) | REST-based Conversation/Messaging flow, FCM Push Notifications, In-App Notifications, and Admin Chat Oversight | `backend/src/modules/chat/**`, `backend/src/modules/notifications/**` | Verified |
| [11-background-workers.md](./11-background-workers.md) | BullMQ `marketspace-maintenance` queue, 8 repeatable jobs, Redis distributed lock fallback, and failure/retry behavior | `backend/src/workers/**` | Verified |
| [12-security-data-flow.md](./12-security-data-flow.md) | Sensitive PII flow (National ID, Tax ID, CR, KYC Docs, JWTs), AES-256-GCM key ring rotation, R2 SigV4, and Malware Scanner boundary | `sensitive-data-crypto.service.ts`, `private-document-storage.service.ts`, `session.service.ts` | Verified |
| [13-deployment-architecture.md](./13-deployment-architecture.md) | Current Production (Railway), Local Development (Docker Compose), Health Checks, Migrations, and Planned Infrastructure | `railway.json`, `docker-compose.yml`, `backend/Dockerfile`, `backend/scripts/migrate-deploy.js` | Verified |
| [14-api-integration-map.md](./14-api-integration-map.md) | API route groups, 38 controllers, auth guards, and Flutter feature bindings | `backend/src/modules/**/*.controller.ts`, `deal one app/lib/core/network/api_endpoints.dart` | Verified |
| [15-roles-permissions.md](./15-roles-permissions.md) | Marketplace User/Account roles, 9 Staff RBAC roles, and 44 granular admin permissions extracted from Guards & Catalog | `admin-permissions.constant.ts`, `seller-authorization.guard.ts`, `account-tenant.guard.ts` | Verified |

---

## Verified Discrepancies Between Code and Legacy Docs

| Area | Legacy Comment / Doc Claim | Actual Code Reality |
| :--- | :--- | :--- |
| **Database Table Count** | `domain.enums.ts` header references a "28-table Modular Monolith architecture". | `backend/prisma/schema.prisma` currently defines **45 Prisma models** across 15 migrations (including Activity Hub: Bookings, RFQs, Quotations, Cart; Enterprise Admin RBAC; Seller Verification v2). |
| **Real-Time Chat** | Earlier SRS/design drafts mention WebSockets / real-time chat. | `backend/src/modules/chat/` implements **REST-only** endpoints (`/api/v1/conversations`, `/api/v1/conversations/:id/messages`) paired with **FCM Push Notifications** and client refresh/polling. No WebSocket gateway exists yet. |
| **Payments (Paymob)** | Listed as a core marketplace module. | `PaymentsModule` is **feature-flagged off by default** (`ENABLE_V2_PAYMENTS=false` in `app.module.ts` & `env.config.ts`). |
| **Malware Scanning** | Verification blueprint references document scanning. | `PrivateDocumentStorageService.scanDocumentBoundary()` is an integration boundary returning `SCANNER_NOT_CONFIGURED` until an external AV engine (e.g., ClamAV / Cloudflare R2 Security Scan) is provisioned. |
| **Flutter Feature Layering** | Master prompt specifies uniform Clean Architecture across all features. | Core transactional features (`auth`, `activity_hub`, `seller_verification`) implement 4 layers (`application/data/domain/presentation`); domain features (`listings`, `accounts`, `conversations`, `search`) implement 3 layers (`data/domain/presentation`); 5 vertical category hubs (`cars_maintenance`, `fashion_accessories`, `appliances_decor`, `construction_electrical`, `services_engineering`) are presentation shells reusing shared `listings`/`search` repositories. |

---

## Open Questions / Architecture Gaps

1. **Unconfirmed R2 Orphan Uploads:** `requestDocumentUploadUrl()` does not persist a `PENDING_UPLOAD` row in PostgreSQL; unconfirmed direct-to-R2 uploads require a Cloudflare R2 bucket lifecycle rule or future `PENDING_UPLOAD` tracking.
2. **Malware Scanning Rollout:** Business decision required on provisioning ClamAV or Cloudflare R2 Security Scan before scaling KYC document intake.
3. **Real-Time Messaging:** WebSocket/SSE gateway for live chat typing/delivery receipts remains in **Planned / Future**.
4. **Legal Retention Periods:** Default `VERIFICATION_DOC_RETENTION_*_DAYS` values are configurable via env vars and require Egyptian legal/compliance sign-off.
