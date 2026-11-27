# 01 — Repository Inventory

## 1. Git Branch & Working Tree State

- **Active Branch:** `main` (`1722df9`, synced with `origin/main`)
- **Other Local Branches:** `fix/review-findings` (`6c65615`), `staging-validation` (`7e544eb`)
- **Uncommitted Changes:** Only untracked `docs/system-architecture/` (prior documentation pass). Zero uncommitted changes to `backend/`, `deal one app/`, or `admin-web/`.

## 2. Top-Level Structure

- `backend/` — NestJS 10 + Fastify + Prisma 5 + PostgreSQL/PostGIS + ioredis + BullMQ Modular Monolith
- `deal one app/` — Flutter mobile app (Riverpod, GoRouter, Dio, AR/EN localization)
- `admin-web/` — React 18 + Vite + TypeScript + TanStack Query + Tailwind CSS Admin Dashboard
- `docs/` — `docs/backend_blueprint/`, `docs/seller-verification/`, `docs/system-architecture/`
- `docker-compose.yml`, `railway.json`, `Dockerfile`, `backend/Dockerfile`, `nginx/`

## 3. Backend Module Inventory (`backend/src/app.module.ts`)

- **Core Infrastructure:** `ConfigModule` (Zod `env.config.ts`), `PrismaModule`, `RedisModule`, `MetricsModule`, `HealthController`, `WorkerModule` (`@Global`), `RequestIdMiddleware`, `LoggingInterceptor`, `TransformInterceptor`, `HttpExceptionFilter`, `ValidationPipe` (`whitelist: true`, `forbidNonWhitelisted: true`).
- **25 Business Modules:** `AuthModule`, `EmailModule`, `UsersModule`, `AccountsModule`, `CategoriesModule`, `MediaModule`, `ListingsModule`, `HomeModule`, `SearchModule`, `ChatModule`, `VideoModule`, `ModerationModule`, `NotificationsModule`, `LocationsModule`, `FavoritesModule`, `BookingsModule`, `RfqModule`, `CartModule`, `ActivityHubModule`, `QuotasModule`, `PlatformSettingsModule`, `StaffModule`, `AdminAuthModule`, `AdminOperationsModule`, and feature-flagged `PaymentsModule` (`ENABLE_V2_PAYMENTS === 'true'`, `app.module.ts:38,74`).
- **Controllers:** 38 NestJS controllers across `/api/v1/*`, `/health/*`, and `/metrics`.

## 4. Prisma Model Inventory (`backend/prisma/schema.prisma`)

**Actual Count: 48 Prisma Models** across **15 migrations** (`backend/prisma/migrations/`):
1. **Geography (3):** `Governorate`, `City`, `Area`
2. **Users, Auth & Accounts (8):** `User`, `UserSession`, `UserDevice`, `Otp`, `Account`, `AccountMember`, `Branch`, `ServiceArea`
3. **Seller Verification (6):** `AccountVerification`, `SellerApplication`, `SellerVerificationRequirement`, `SellerApplicationDocument`, `SellerDocumentReview`, `SellerApplicationHistory`
4. **Catalog & Listings (6):** `Project`, `Category`, `CategoryField`, `Listing`, `ListingMedia`, `Favorite`
5. **Messaging, Moderation & Quotas (5):** `Conversation`, `Message`, `Notification`, `Report`, `DailyQuota`
6. **Activity Hub & Payments (8):** `PromotionPackage`, `Payment`, `Booking`, `RfqRequest`, `RfqItem`, `Quotation`, `QuotationItem`, `CartItem`
7. **Enterprise Admin, RBAC & Outbox (12):** `PlatformSetting`, `StaffRole`, `StaffUser`, `StaffSession`, `StaffLoginAttempt`, `StaffPasswordResetToken`, `FeatureFlag`, `CmsItem`, `NotificationCampaign`, `ModerationLog`, `AuditLog`, `OutboxEvent`

## 5. Flutter Feature Inventory (`deal one app/lib/features/`)

**22 Feature Directories:**
- **4-layer (`application/data/domain/presentation`):** `auth`, `activity_hub`, `seller_verification`
- **3-layer (`data/domain/presentation`):** `accounts`, `categories`, `conversations`, `favorites`, `listings`, `locations`, `maps`, `media`, `moderation`, `notifications`, `quotas`, `real_estate`, `search`
- **Presentation-only hubs:** `main_hub`, `appliances_decor`, `cars_maintenance`, `construction_electrical`, `fashion_accessories`, `services_engineering`

## 6. Test Inventory

- **Backend:** 53 Jest unit/integration spec files (`backend/src/**/*.spec.ts`) + E2E specs in `backend/test/` (including 3 Seller Verification E2E suites with 21 scenarios).
- **Flutter:** 47 test files (`deal one app/test/**/*_test.dart`).
- **Admin Web:** Vitest configured in `admin-web/package.json`.

## 7. Deployment Inventory

- `railway.json` — Dockerfile build, `preDeployCommand: ["node scripts/migrate-deploy.js"]`, `startCommand: "node dist/src/main.js"`, `healthcheckPath: "/health/live"`.
- `docker-compose.yml` — Nginx (`80/443`), API (`3000`), PostGIS 16-3.4 (`5432`), Redis Cache (`6379`, `allkeys-lru`), Redis Queue (`6380`, AOF `noeviction`).
