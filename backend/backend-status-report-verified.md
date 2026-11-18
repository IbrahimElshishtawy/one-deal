# تقرير حالة الـ Backend الموثّق — مشروع Deal One (Market Space)

> هذا التقرير محدّث وموثّق بنتائج التشغيل والفحص الفعلي على بيئة العمل في `/home/ibrahim-elshishtawy/flutter project/deal one/backend`.
> تاريخ التحقق: `2026-11-18`

---

## 1. الملخص التنفيذي وقياسات التحقق

| المحور | النتيجة الفعلية | أمر التحقق المستخدم |
| :--- | :--- | :--- |
| **البناء (TypeScript / NestJS)** | ناجح (`exit code 0`) | `npm run build` |
| **فحص الكود (ESLint / Prettier)** | **0 errors, 0 warnings** (مع تحذير غير حاجب عن إصدار TypeScript 5.9.3 مقابل `<5.6.0`) | `npx eslint "{src,test}/**/*.ts"` |
| **اختبارات الوحدة (Unit Tests)** | **32 suites passed / 176 tests passed** (`12.096 s`) | `npm test` |
| **اختبارات التكامل والـ E2E** | **5 suites passed / 36 tests passed** (`6.051 s`) | `npm run test:e2e` |
| **حالة الـ Migrations** | **8 migrations found — Database schema is up to date!** (بدون مسح بيانات) | `npx prisma migrate status` |
| **إضافات PostgreSQL** | `pg_trgm` و `postgis` و `pg_stat_statements` مسجلة في `pg_extension` (7 إضافات إجمالاً) | `docker exec marketspace-postgres sh -c 'psql -U "${POSTGRES_USER:-marketspace_app}" -d "${POSTGRES_DB:-marketspace}" -c "SELECT extname FROM pg_extension ORDER BY extname;"'` |
| **`shared_preload_libraries`** | **فارغ (`""`)** على الحاوية الحالية `marketspace-postgres`، لذا استعلام `SELECT count(*) FROM pg_stat_statements;` يرجع `ERROR: pg_stat_statements must be loaded via shared_preload_libraries` (بينما [docker-compose.yml](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/docker-compose.yml) يضبطه) | `docker exec marketspace-postgres sh -c 'psql -U "${POSTGRES_USER:-marketspace_app}" -d "${POSTGRES_DB:-marketspace}" -c "SHOW shared_preload_libraries;"'` |
| **أسرار JWT في `.env`** | قيمتا `JWT_ACCESS_SECRET` و `JWT_REFRESH_SECRET` مختلفتان وطول كل منهما **128 حرف hex** (`64 bytes`) | فحص برمجي via `node -e` على `.env` بدون طباعة القيم |
| **حماية الأسرار (`.gitignore`)** | `.env` و `.env.*` مستبعدة في [.gitignore](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/.gitignore) | قراءة [.gitignore](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/.gitignore) |

---

## 2. البنية التحتية والملفات الأساسية (`src/core/` و `src/main.ts`)

تم التحقق من وجود كافة الملفات التالية فعلياً في مساراتها:

| المكون | الملف المرجعي | المسؤولية |
| :--- | :--- | :--- |
| **Bootstrap & Security** | [main.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/main.ts) | Fastify، `@fastify/helmet`، `@fastify/cors`، `ValidationPipe` (`whitelist`, `forbidNonWhitelisted`, `transform`)، بادئة `/api/v1` (مع استثناء `health/live`, `health/ready`, `health/liveness`, `health/readiness`, `metrics`)، وتوثيق Swagger على `/api/docs`. |
| **Environment Validation** | [env.config.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/core/config/env.config.ts) | التحقق من متغيرات البيئة عبر **Zod** مع دعم بدائل `DATABASE_URL` وروابط Redis السحابية. |
| **Database** | [prisma.service.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/core/database/prisma.service.ts) | اتصال PostgreSQL عبر Prisma Client 5.14 مع دعم PostGIS و PgBouncer. |
| **Dual-Redis** | [redis.service.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/core/redis/redis.service.ts) | عميلان منفصلان (`cacheClient` و `queueClient`) مع Memory Fallback خارج الإنتاج. |
| **Phone Normalization** | [phone-normalization.service.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/core/identity/phone-normalization.service.ts) | توحيد أرقام الموبايل المصرية (`+2010/11/12/15...`) عبر `libphonenumber-js`. |
| **Security Audit** | [security-audit.service.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/core/security/security-audit.service.ts) | تسجيل أحداث التدقيق في `audit_log` مع تنقية المفاتيح الحساسة تلقائياً. |
| **Filters & Interceptors** | [http-exception.filter.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/core/filters/http-exception.filter.ts)<br>[transform.interceptor.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/core/interceptors/transform.interceptor.ts)<br>[logging.interceptor.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/core/interceptors/logging.interceptor.ts) | توحيد استجابات النجاح (`{ success: true, data, meta? }`) والأخطاء (`{ success: false, error: ... }`) وتسجيل زمن التنفيذ. |
| **Request Tracing Middleware** | [request-id.middleware.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/core/middleware/request-id.middleware.ts) | توليد وتمرير معرفات التتبع `x-trace-id` و `x-request-id` لكل طلب في `AppModule`. |
| **Rate Limiting** | [rate-limit.guard.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/core/guards/rate-limit.guard.ts) | تحديد المعدل عبر Redis (`userId` للمصادقين و`IP` للزوار) مع ترويسات `X-RateLimit-*`. |
| **Health & Metrics** | [health.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/core/health/health.controller.ts)<br>[metrics.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/core/metrics/metrics.controller.ts) | فحص الجاهزية `/health/live`, `/health/liveness`, `/health/ready`, `/health/readiness` و `/metrics` بصيغة Prometheus. |

---

## 3. قاعدة البيانات والـ Migrations ([schema.prisma](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/prisma/schema.prisma))

يضم المخطط **31 نموذجاً (`model`)** (تم التحقق عبر `grep -n "^model " prisma/schema.prisma | wc -l`):
1. **الجغرافيا (3):** `Governorate`, `City`, `Area` (`geometry(Point, 4326)` + فهرس `Gist`).
2. **الهوية والجلسات (4):** `User`, `UserSession`, `UserDevice`, `Otp`.
3. **الحسابات متعددة المستأجرين (6):** `Account`, `AccountMember`, `AccountVerification`, `Branch`, `ServiceArea`, `Project`.
4. **التصنيفات (2):** `Category`, `CategoryField`.
5. **الإعلانات والوسائط (2):** `Listing`, `ListingMedia`.
6. **التفاعل والبلاغات (2):** `Favorite`, `Report`.
7. **الدردشة (2):** `Conversation`, `Message`.
8. **الإشعارات والحصص والإعدادات (3):** `Notification`, `DailyQuota`, `PlatformSetting`.
9. **الموظفون والرقابة والتدقيق (4):** `StaffRole`, `StaffUser`, `ModerationLog`, `AuditLog`.
10. **الأحداث الموثوقة (1):** `OutboxEvent`.
11. **الترويج والمدفوعات V2 (2):** `PromotionPackage`, `Payment`.

> **حالة نموذج `Project`:** موجود في `prisma/schema.prisma` (سطر `251`) ولا يوجد له Controller حالياً، ومصنّف **كمؤجل** لحين الاحتياج إليه في المرحلة القادمة.

### حالة الـ Migrations (تم التحقق بـ `npx prisma migrate status`):
جميع الـ **8 migrations** مطبقة بنجاح (`Database schema is up to date!`):
1. `20261102232252_init_database_foundation`
2. `20261102232759_`
3. `20261102233251_add_gist_gin_spatial_indexes`
4. `20261103001630_add_geometry_defaults`
5. `20261103155808_phase03_auth_family_and_otp_purpose`
6. `20261104230259_add_demo_marker_and_indexes`
7. [20261117000001_add_payments_and_listing_promotion_search](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/prisma/migrations/20261117000001_add_payments_and_listing_promotion_search/migration.sql)
8. [20261117000002_add_trgm_jsonb_indexes_and_pg_stat_statements](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/prisma/migrations/20261117000002_add_trgm_jsonb_indexes_and_pg_stat_statements/migration.sql)

---

## 4. المصادقة وإدارة كلمات المرور ([auth.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/auth/auth.controller.ts))

كل المسارات التالية محققة فعلياً تحت `/api/v1/auth`:
- **OTP:** `POST /auth/otp/send`, `POST /auth/otp/resend`, `POST /auth/otp/verify`
- **الدخول بكلمة المرور:** `POST /auth/login` *(مع alias: `POST /auth/password/login` لنفس `loginWithPassword`)*
- **إدارة كلمات المرور:**
  - `POST /auth/password/set` (`JwtAuthGuard` — للمستخدم المسجّل بـ OTP دون كلمة مرور)
  - `POST /auth/password/change` (`JwtAuthGuard` — يتحقق من الكلمة الحالية ويلغي باقي الجلسات عبر `sid`)
  - `POST /auth/password/forgot` (`RateLimitGuard` — يرسل OTP بغرض `PASSWORD_RESET` ويرجع `200 OK` دائماً لمنع كشف الأرقام)
  - `POST /auth/password/reset` (`RateLimitGuard` — يتحقق من OTP `PASSWORD_RESET` ويهش بـ `argon2` ويلغي كل الجلسات)
- **الجلسات والهوية:**
  - `POST /auth/refresh` *(مع alias: `POST /auth/token/refresh` لنفس `refreshToken`)*
  - `POST /auth/logout`, `POST /auth/sessions/terminate-all`, `GET /auth/sessions`, `GET /auth/me`

---

## 5. خريطة الـ APIs المستخرجة فعلياً من الـ Controllers

تم استخراج كل `@Controller` وdecorators المسارات مباشرة من ملفات `src/**/*.controller.ts`:

| الوحدة | الملف | المسارات الفعلية (تحت `/api/v1` عدا `health` و `metrics`) |
| :--- | :--- | :--- |
| **Health** | [health.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/core/health/health.controller.ts) | `GET /health/liveness`, `GET /health/live`, `GET /health/readiness`, `GET /health/ready` |
| **Metrics** | [metrics.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/core/metrics/metrics.controller.ts) | `GET /metrics` |
| **Users** | [users.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/users/users.controller.ts) | `GET /users/me`, `PUT /users/me`, `DELETE /users/me` |
| **Accounts** | [accounts.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/accounts/accounts.controller.ts) | `POST /accounts`, `GET /accounts/my-accounts`, `GET /accounts/:id`, `POST /accounts/:id/branches`, `GET /accounts/:id/branches`, `PUT /accounts/:id/branches/:branchId`, `DELETE /accounts/:id/branches/:branchId`, `GET /accounts/:id/members`, `POST /accounts/:id/members/invite`, `DELETE /accounts/:id/members/:userId`, `GET /accounts/:id/service-areas`, `POST /accounts/:id/service-areas`, `DELETE /accounts/:id/service-areas/:serviceAreaId`, `GET /accounts/:id/verifications`, `POST /accounts/:id/verifications` |
| **Locations** | [locations.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/locations/locations.controller.ts) | `GET /locations/governorates`, `GET /locations/cities/:cityId/areas` |
| **Categories** | [categories.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/categories/categories.controller.ts) | `GET /categories`, `GET /categories/:slug`, `GET /categories/:slug/fields`, `POST /admin/categories`, `POST /admin/categories/:id/fields` |
| **Listings** | [listings.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/listings/listings.controller.ts) | `GET /listings`, `GET /listings/:id`, `POST /listings`, `PUT /listings/:id`, `DELETE /listings/:id`, `PATCH /listings/:id/availability`, `POST /listings/:id/submit`, `PATCH /listings/:id/status`, `POST /listings/:id/contact` *(alias: `POST /listings/:id/reveal-contact`)* |
| **Search** | [search.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/search/search.controller.ts) | `GET /search` |
| **Media** | [media.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/media/media.controller.ts) | `POST /media/images/upload-url` *(aliases: `/media/upload-urls`, `/media/presigned-url`)*, `POST /media/confirm-upload` *(alias: `/media/confirm`)* |
| **Video** | [video.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/video/video.controller.ts) | `POST /media/video/upload-token`, `POST /media/video/webhook`, `GET /video-feed` |
| **Favorites** | [favorites.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/favorites/favorites.controller.ts) | `GET /favorites` *(alias: `GET /listings/favorites`)*, `POST /favorites/:listingId`, `DELETE /favorites/:listingId`, `POST /listings/:listingId/favorite` |
| **Chat** | [chat.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/chat/chat.controller.ts) | `SSE /conversations/stream`, `GET /conversations`, `POST /conversations`, `GET /conversations/:id/messages`, `POST /conversations/:id/messages` |
| **Quotas** | [quotas.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/quotas/quotas.controller.ts) | `GET /quotas/my-usage` |
| **Notifications** | [notifications.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/notifications/notifications.controller.ts) | `GET /notifications`, `PATCH /notifications/read-all`, `PATCH /notifications/:id/read`, `POST /notifications/device-token` |
| **Moderation** | [moderation.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/moderation/moderation.controller.ts) | `POST /reports`, `GET /admin/moderation/listings`, `POST /admin/moderation/listings/:id/decision`, `GET /admin/moderation/queue`, `PATCH /admin/moderation/reports/:id`, `GET /admin/audit-logs`, `GET /admin/moderation/verifications`, `POST /admin/moderation/verifications/:id/decision` |
| **Platform Settings** | [platform-settings.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/platform-settings/platform-settings.controller.ts) | `GET /admin/settings`, `GET /admin/settings/:key`, `PUT /admin/settings/:key` |
| **Staff** | [staff.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/staff/staff.controller.ts) | `GET /admin/staff/roles`, `POST /admin/staff/roles`, `GET /admin/staff`, `POST /admin/staff`, `PATCH /admin/staff/:id` |
| **Payments (V2)** | [payments.controller.ts](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/backend/src/modules/payments/payments.controller.ts) | `GET /payments/packages`, `POST /payments/checkout`, `POST /payments/webhook` *(مفعلّة عند `ENABLE_V2_PAYMENTS=true` فقط)* |

> **نتيجة مقارنة المسارات مع التقرير:** لا توجد مسارات في التقرير مفقودة من الكود، ولا توجد مسارات في الكود مفقودة من هذا التقرير الموثّق.

---

## 6. مقارنة وتحديث تطبيق Flutter ([api_endpoints.dart](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/deal%20one%20app/lib/core/network/api_endpoints.dart))

- كل الثوابت الموجودة مسبقاً في `ApiEndpoints` تطابق مسارات الـ Backend الفعلية.
- تمت إضافة الثوابت الناقصة للمسارات الجديدة في [api_endpoints.dart](file:///home/ibrahim-elshishtawy/flutter%20project/deal%20one/deal%20one%20app/lib/core/network/api_endpoints.dart) بنفس الأسلوب:
  - **Password:** `setPassword`, `changePassword`, `forgotPassword`, `resetPassword`
  - **Notifications Inbox:** `notifications`, `markAllNotificationsRead`, `markNotificationRead(id)`
  - **Accounts (Service Areas & Verifications):** `accountServiceAreas(id)`, `accountServiceAreaDetail(id, serviceAreaId)`, `accountVerifications(id)`
  - **Admin (Settings, Verifications & Staff):** `adminSettings`, `adminSettingByKey(key)`, `adminModerationVerifications`, `adminModerationVerificationDecision(id)`, `adminStaffRoles`, `adminStaff`, `adminStaffById(id)`

---

## 7. نتائج التحقق

| البند | المتوقع | الفعلي | الحالة (✅/❌) |
| :--- | :--- | :--- | :--- |
| `npm run build` | بناء ناجح بدون أخطاء | نجح (`exit code 0`) | ✅ |
| `npx eslint "{src,test}/**/*.ts"` | 0 errors و 0 warnings | 0 errors و 0 warnings | ✅ |
| `npm test` | 32 suites / 176 tests ناجحة | 32 suites passed / 176 tests passed (`12.096 s`) | ✅ |
| `npm run test:e2e` | 5 suites / 36 tests ناجحة | 5 suites passed / 36 tests passed (`6.051 s`) | ✅ |
| `npx prisma migrate status` | 8 من 8 مطبّقة بدون drift | `8 migrations found — Database schema is up to date!` | ✅ |
| إضافة `pg_trgm` في PostgreSQL | مفعلة في `pg_extension` | موجودة في `pg_extension` | ✅ |
| تحميل `pg_stat_statements` في `shared_preload_libraries` | محمّلة في `shared_preload_libraries` وقابلة للاستعلام | `SHOW shared_preload_libraries;` فارغ على الحاوية الحالية `marketspace-postgres` والاستعلام يفشل بـ `must be loaded via shared_preload_libraries` | ❌ |
| أسرار JWT في `.env` | مختلفة وطول كل منها 128 hex | قيمتان مختلفتان، طول كل منهما 128 hex (`64 bytes`) | ✅ |
| استبعاد `.env` في `.gitignore` | `.env` غير متتبع بـ git | `.env` و `.env.*` مضافة في `.gitignore` | ✅ |
| تطابق مسارات التقرير مع الـ Controllers | وجود كل المسارات والـ aliases | تطابق كامل لكل المسارات والـ aliases | ✅ |
| وجود الـ 13 ملفاً أساسياً + نموذج `Project` مؤجل | جميعها موجودة و`Project` بدون controller | جميع الـ 13 ملفاً موجودة و`model Project` مؤجل في `schema.prisma` | ✅ |
| تحديث ثوابت `api_endpoints.dart` في Flutter | إضافة الثوابت الجديدة فقط بنفس الأسلوب | تمت إضافة 17 ثابتاً/دالة للمسارات الجديدة دون تعديل أي شاشة أو منطق | ✅ |
