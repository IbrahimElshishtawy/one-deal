# وثيقة المعمارية والمتطلبات — Deal One (Market Space) Backend

> توثيق هندسي مستخرج مباشرة من الكود المصدري الحالي للباك إند (`backend/`).
> آخر تحديث: 2026-11-17

---

## 1. نظرة عامة على النظام (System Overview)

النظام هو الخادم الخلفي لمنصة إعلانات مبوبة وسوق إلكتروني موجّه للسوق المصري (**Deal One / صفقة ون — Market Space**)، مبني بنمط **Modular Monolith** باستخدام:

| الطبقة | التقنية المعتمدة في الكود | المرجع |
| :--- | :--- | :--- |
| **Runtime & Framework** | Node.js 20 (Alpine) + NestJS 10 (TypeScript) + **Fastify** | `package.json`, `src/main.ts`, `Dockerfile` |
| **Database & Geospatial** | PostgreSQL + **PostGIS** (`geometry(Point, 4326)`) عبر **Prisma ORM 5.14** | `prisma/schema.prisma`, `src/core/database/prisma.service.ts` |
| **Caching & Queues** | **Dual-Redis Topology** (`ioredis` + `BullMQ`):<br>1) Redis Cache (`6379`) للكاش و Rate Limiting و OTP Cooldown<br>2) Redis Queue (`6380`) مخصص للطوابير | `src/core/redis/redis.service.ts` |
| **Security & Auth** | Passport JWT (`HS256`)، تشفير كلمات المرور بـ `argon2`، تشفير OTP بـ `SHA-256 + Pepper`، `Helmet`، `CORS` | `src/modules/auth/`, `src/main.ts` |
| **Validation & Docs** | `class-validator` + `class-transformer` للـ DTOs، **Zod** لمتغيرات البيئة، **Swagger / OpenAPI** على `/api/docs` | `src/core/config/env.config.ts`, `src/main.ts` |
| **Phone Normalization** | `libphonenumber-js` مع قصر التسجيل على أرقام الموبايل المصرية (`+20`) | `src/core/identity/phone-normalization.service.ts` |

---

## 2. مكونات النظام (System Components)

### 2.1 طبقة البنية التحتية المشتركة (`src/core/`)

| المكون | المسار | المسؤولية |
| :--- | :--- | :--- |
| **Bootstrap & API Prefix** | `src/main.ts` | تفعيل Fastify، Helmet، CORS، `ValidationPipe` (`whitelist`, `forbidNonWhitelisted`, `transform`)، بادئة `/api/v1` (مع استثناء مسارات `/health/*`)، وتوثيق Swagger على `/api/docs`، وتفعيل `enableShutdownHooks()`. |
| **Env Validation** | `src/core/config/env.config.ts` | التحقق من متغيرات البيئة عند الإقلاع باستخدام **Zod** مع دعم بدائل روابط قواعد البيانات و Redis السحابية. |
| **Database Service** | `src/core/database/prisma.service.ts` | إدارة اتصال Prisma بقاعدة البيانات وفحص الجاهزية (`ping`, `checkPostgisSupport`). |
| **Dual-Redis Service** | `src/core/redis/redis.service.ts` | إدارة عميلين مستقلين (`cacheClient` و `queueClient`) مع `In-Memory Fallback` تلقائي خارج بيئة الإنتاج (`NODE_ENV !== 'production'`). |
| **Phone Normalization** | `src/core/identity/phone-normalization.service.ts` | تنظيف وتحويل أرقام الموبايل المصرية إلى الصيغة القياسية E.164 (`+2010/11/12/15XXXXXXXX`). |
| **Security Audit** | `src/core/security/security-audit.service.ts` | تسجيل أحداث الأمان في جدول `audit_log` مع حجب تلقائي (`[REDACTED]`) للمفاتيح الحساسة (`otp`, `password`, `token`, `secret`...) وضمان عدم تعطيل المعاملة الأساسية عند فشل التسجيل. |
| **Response & Error Standards** | `src/core/interceptors/transform.interceptor.ts`<br>`src/core/filters/http-exception.filter.ts` | توحيد الاستجابات الناجحة في صيغة `{ success: true, data, meta? }`، والأخطاء في صيغة `{ success: false, error: { code, message, details, trace_id } }` مع تمرير `x-trace-id` و `x-request-id`. |
| **Request Tracing & Logging** | `src/core/middleware/request-id.middleware.ts`<br>`src/core/interceptors/logging.interceptor.ts` | توليد/تمرير معرف التتبع لكل طلب وتسجيل زمن التنفيذ. |
| **Rate Limiting Guard** | `src/core/guards/rate-limit.guard.ts` | تطبيق `@RateLimit(limit, ttlSeconds)` بالاعتماد على IP والمسار عبر Redis مع إرجاع ترويسات `X-RateLimit-Limit` و `X-RateLimit-Remaining`. |
| **Health Probes** | `src/core/health/health.controller.ts` | نقاط فحص `/health/live` (Liveness) و `/health/ready` (Readiness: تفحص DB + PostGIS + Redis Cache + Redis Queue + Workers، وتُرجع `503` إذا تعطل أي مكون أساسي). |

---

### 2.2 وحدات الأعمال (`src/modules/`)

يحتوي التطبيق الجذري (`src/app.module.ts`) على **15 وحدة أعمال** (14 مفعلة دائماً + وحدة المدفوعات مشروطة بـ `ENABLE_V2_PAYMENTS=true`):

| الوحدة | البادئة / المسارات (`@Controller`) | المسؤولية الأساسية |
| :--- | :--- | :--- |
| **AuthModule** | `/api/v1/auth/*` | إرسال/إعادة إرسال/التحقق من OTP، الدخول بكلمة مرور، تدوير Refresh Token، تسجيل الخروج، استعراض وإنهاء الجلسات، بيانات المستخدم الحالي `/auth/me`. |
| **UsersModule** | `/api/v1/users/me` | عرض وتحديث الملف الشخصي (`fullName`, `avatarUrl`, `preferredLanguage`) والحذف الناعم للحساب (`DELETE /users/me`). |
| **AccountsModule** | `/api/v1/accounts/*` | إنشاء حسابات تجارية/فردية، تبديل الحسابات (`my-accounts`)، عرض البروفايل العام، إدارة الفروع (`branches`)، إدارة أعضاء الفريق (`members`). |
| **LocationsModule** | `/api/v1/locations/*` | استعراض المحافظات والمدن النشطة (`governorates`) والمناطق/الأحياء حسب المدينة (`cities/:cityId/areas`). |
| **CategoriesModule** | `/api/v1/categories/*`<br>`/api/v1/admin/categories/*` | شجرة التصنيفات، تفاصيل القسم، الحقول الديناميكية للقسم (`:slug/fields`)، وإدارة الأقسام والحقول للمشرف العام. |
| **ListingsModule** | `/api/v1/listings/*` | إنشاء/تعديل/حذف ناعم للإعلانات، تغذية الإعلانات بـ cursor pagination، تفاصيل الإعلان، تغيير حالة التوافر/النشر، إرسال للمراجعة، وكشف بيانات الاتصال (`contact` / `reveal-contact`). |
| **SearchModule** | `/api/v1/search` | محرك البحث بالكلمات العربية (مع تطبيع اللهجة المصرية)، الفلترة بالخصائص الديناميكية JSONB، والبحث الجغرافي بنصف قطر PostGIS. |
| **MediaModule** | `/api/v1/media/*` | إصدار روابط رفع مباشر للصور (`upload-url`, `upload-urls`, `presigned-url`) وتأكيد الرفع وربطه بالإعلان (`confirm-upload`, `confirm`). |
| **VideoModule** | `/api/v1/media/video/*`<br>`/api/v1/video-feed` | طلب رمز رفع مباشر لـ Cloudflare Stream (بحد أقصى 30 ثانية)، استقبال Webhook التشفير، وتغذية الريلز العمودية (`video-feed`). |
| **FavoritesModule** | `/api/v1/favorites/*`<br>`/api/v1/listings/*/favorite*` | استعراض المفضلة، الإضافة، الحذف، والتبديل (Toggle). |
| **ChatModule** | `/api/v1/conversations/*` | بدء/جلب المحادثة المرتبطة بإعلان، قائمة المحادثات، جلب الرسائل مع تعليمها كمقروءة، وإرسال الرسائل. |
| **QuotasModule** | `/api/v1/quotas/my-usage` | متابعة استهلاك الحصة اليومية لكشف جهات الاتصال بتوقيت القاهرة (`Africa/Cairo`). |
| **ModerationModule** | `/api/v1/reports`<br>`/api/v1/admin/moderation/*`<br>`/api/v1/admin/audit-logs` | تقديم البلاغات، طابور مراجعة الإعلانات والبت فيها، طابور البلاغات والبت فيها، وعرض سجلات التدقيق الأمني. |
| **NotificationsModule** | `/api/v1/notifications/device-token` | تسجيل رموز أجهزة FCM (`android` / `ios`) وإرسال إشعارات الدفع. |
| **PaymentsModule** *(V2 Feature-Flagged)* | `/api/v1/payments/*` | عرض باقات الترويج، بدء الدفع (`checkout`)، واستقبال Paymob Webhook. مفعلة فقط عند `ENABLE_V2_PAYMENTS=true`. |

---

### 2.3 معالجات الخلفية (`src/workers/`)

يتم تشغيل المهام المجدولة عبر `WorkerService` (`OnModuleInit` / `OnModuleDestroy`):

| المعالج | الدورية الحالية | الوظيفة |
| :--- | :--- | :--- |
| **ListingExpiryProcessor** | كل **30 دقيقة** | البحث عن الإعلانات ذات `publicationStatus = 'published'` و `expiresAt <= now` وتحويلها إلى `expired`. |
| **PaymentReconciliationProcessor** | كل **15 دقيقة** | فحص المعاملات المعلقة (`pending`) الأقدم من 60 دقيقة وتحويلها إلى `failed`. |
| **MediaCleanupProcessor** | كل **6 ساعات** | حذف سجلات `ListingMedia` التي بقيت بحالة `processingStatus = 'pending'` لأكثر من 24 ساعة. |
| **NotificationProcessor** | عند الطلب (`enqueueNotification`) | إرسال إشعارات الدفع بشكل غير متزامن دون تعطيل المسارات المتزامنة. |

---

### 2.4 نموذج البيانات والفهرسة (`prisma/schema.prisma`)

يضم المخطط **29 جدولاً** موزعة على 10 وحدات منطقية:
1. **الجغرافيا (3):** `Governorate`, `City`, `Area` (`centroid` من نوع `geometry(Point, 4326)` مع فهرس `GIST`).
2. **الهوية والجلسات (4):** `User`, `UserSession` (`familyId`, `refreshTokenHash`, `isRevoked`), `UserDevice`, `Otp`.
3. **الحسابات متعددة المستأجرين (6):** `Account`, `AccountMember`, `AccountVerification`, `Branch` (`location` بـ `GIST`), `ServiceArea`, `Project`.
4. **التصنيفات (2):** `Category`, `CategoryField`.
5. **الإعلانات والوسائط (2):** `Listing` (`physical_location` و `display_location` بـ `GIST`، و `attributes` JSONB بـ `GIN`، وفهرس مركب `idx_listings_search`)، و `ListingMedia`.
6. **التفاعل والبلاغات (2):** `Favorite`, `Report`.
7. **الدردشة (2):** `Conversation`, `Message`.
8. **الإشعارات والحصص والإعدادات (3):** `Notification`, `DailyQuota`, `PlatformSetting`.
9. **الموظفون والرقابة والتدقيق (4):** `StaffRole`, `StaffUser`, `ModerationLog`, `AuditLog`.
10. **الأحداث الموثوقة (1):** `OutboxEvent` (Transactional Outbox).

---

## 3. المستخدمون والأدوار والصلاحيات (Users, Actors & RBAC)

يعمل النظام بنموذج صلاحيات ثنائي المستوى: **مستوى المنصة (Platform Roles)** و**مستوى الحساب التجاري/الفردي (Multi-Tenant Account RBAC)**.

### 3.1 الفاعلون على مستوى المنصة (`UserRole` في `domain.enums.ts` و `JwtStrategy`)

| الدور | الوصف | الصلاحيات المؤكدة في الكود (`RolesGuard` & Controllers) |
| :--- | :--- | :--- |
| **زائر غير مسجل (Guest)** | مستخدم بدون JWT Token | تصفح الإعلانات المنشورة (`GET /listings`, `GET /listings/:id`)، البحث (`GET /search`)، مشاهدة تغذية الفيديو (`GET /video-feed`)، تصفح الأقسام والمحافظات والبروفايل العام للحسابات وباقات الترويج، وفحص `/health/*`. |
| **`USER`** | مستخدم مسجل برقم موبايل مصري موثق | إدارة ملفه الشخصي وجلساته، إنشاء حسابات، إنشاء/تعديل/حذف إعلاناته، رفع الوسائط والفيديو، إضافة المفضلة، الدردشة، كشف جهات الاتصال (ضمن الحصة)، تقديم بلاغات، عرض حصته اليومية، تسجيل FCM Token، وبدء الدفع لإعلاناته. |
| **`MODERATOR`** | مشرف محتوى | بالإضافة لصلاحيات المستخدم: الوصول إلى طابور الإعلانات المعلقة (`GET /admin/moderation/listings`)، اعتماد أو رفض الإعلانات (`POST /admin/moderation/listings/:id/decision`)، عرض طابور البلاغات (`GET /admin/moderation/queue`)، والبت في البلاغات (`PATCH /admin/moderation/reports/:id`). |
| **`SUPER_ADMIN`** | مدير النظام الأعلى | جميع صلاحيات `MODERATOR` + إنشاء التصنيفات وحقولها الديناميكية (`POST /admin/categories`, `POST /admin/categories/:id/fields`) + استعراض سجلات التدقيق الأمني (`GET /admin/audit-logs`) + تعديل/حذف/تغيير حالة أي إعلان متجاوزاً فحص الملكية في `ListingsService`. |

> **ملاحظة من الكود:** توجد أيضاً جداول `StaffUser` و `StaffRole` في `schema.prisma` للربط مع `ModerationLog`, `AccountVerification`, `Report`, `PlatformSetting`، بينما يعتمد التحقق في Controllers حالياً على `JwtAuthGuard` + `RolesGuard` مع قيم `UserRole` (`USER`, `MODERATOR`, `SUPER_ADMIN`).

---

### 3.2 أنواع الحسابات وأدوار الأعضاء (`AccountType` & `AccountMemberRole`)

* **أنواع الحسابات (`AccountType`):** `individual` (فرد)، `company` (شركة)، `factory` (مصنع)، `office` (مكتب)، `store` (متجر).
* **آلية سياق الحساب (`AccountTenantGuard`):** يمرر العميل ترويسة `X-Account-ID` (UUID)؛ يتحقق الحارس من عضوية المستخدم في الحساب (مع كاش Redis لمدة 5 دقائق: `account:membership:{userId}:{accountId}`) ويحقن `AccountContext` بالصلاحيات التالية:

| دور العضو داخل الحساب | الصلاحيات المحسوبة في `AccountTenantGuard` | التحقق المطبق فعلياً في `AccountsService` |
| :--- | :--- | :--- |
| **`owner`** | `*`, `account:manage`, `team:manage`, `listings:manage`, `chat:respond` | يملك كامل الصلاحيات: دعوة/إزالة أعضاء (بما فيهم المدراء)، إضافة/تعديل/حذف الفروع، إدارة إعلانات الحساب والرد في الدردشة. لا يمكن إزالة المالك. |
| **`manager`** | `team:view`, `listings:manage`, `chat:respond` | يمكنه دعوة أعضاء، إزالة غير الملاك وغير المدراء (`lister`, `responder`)، وتعديل وحذف الفروع (`updateBranch`, `deleteBranch`). *(ملاحظة: `createBranch` تفحص `['owner', 'admin']` حالياً).* |
| **`lister`** | `listings:create`, `listings:edit` | مخصص لإنشاء وتعديل الإعلانات ضمن الحساب. |
| **`responder`** | `chat:respond` | مخصص للرد على محادثات العملاء. |

---

## 4. منطق العمل الأساسي (Business Logic)

### 4.1 المصادقة بالهاتف المصري وحماية OTP (`OtpService`, `PhoneNormalizationService`)
1. **توحيد الرقم:** يقبل فقط أرقام الموبايل المصرية (`010`, `011`, `012`, `015`) بصيغ مختلفة (`010...`, `002010...`, `+2010...`) ويحولها إلى E.164 (`+2010XXXXXXXX`). يرفض الأرضي (مثل `02`, `03`) والأرقام الأجنبية.
2. **منع الإغراق (Anti-SMS Bombing):**
   * حد أقصى **10 طلبات كل 15 دقيقة** لكل IP.
   * حد أقصى **3 طلبات كل 15 دقيقة** لكل رقم هاتف.
   * فترة انتظار (**Cooldown**) إلزامية **60 ثانية** بين طلبات الإرسال لنفس الرقم.
3. **أمان الرمز:**
   * توليد 6 أرقام عشوائية (`crypto.randomInt`) وتخزينها مشفرة بـ `SHA-256 + Pepper` في جدول `otps` بصلاحية **3 دقائق**.
   * إبطال أي رموز سابقة غير مستهلكة لنفس الرقم والغرض (`purpose`) عند طلب رمز جديد.
   * قفل الرمز بعد **5 محاولات فاشلة**، والمقارنة باستخدام `crypto.timingSafeEqual`.
   * استهلاك ذري (`updateMany` بشرط `isConsumed: false`) لمنع السباق المتزامن (Race Condition).
4. **التسجيل الأول التلقائي:** عند نجاح التحقق لمستخدم غير موجود، يتم إنشاء `User` + `Account` من نوع `individual` (بحالة `approved` فوراً) + `AccountMember` بدور `owner` داخل Transaction واحد.

### 4.2 إدارة الجلسات وتدوير الرموز (`SessionService`)
* يصدر النظام Access Token قصير العمر (**15 دقيقة**) و Refresh Token عشوائي (40 bytes hex) صالح لمدة **30 يوماً** يُحفظ هاش `SHA-256` له في `user_sessions` مرتبطاً بـ `familyId`.
* **تدوير الرمز واكتشاف الاختراق (Reuse Detection):**
  * عند تحديث التوكن (`rotateRefreshToken`)، يتم إبطال الجلسة القديمة ذرياً وإنشاء جلسة جديدة بنفس `familyId`.
  * إذا ورد طلب بـ Refresh Token سبق إبطاله (`isRevoked = true`)، يعتبر النظام ذلك محاولة سرقة/إعادة استخدام ويقوم فوراً بإلغاء **جميع جلسات نفس الـ `familyId`** للمستخدم وتسجيل تنبيه أمني عالي الخطورة `REFRESH_TOKEN_REUSE_DETECTED`.

### 4.3 دورة حياة الإعلان ثلاثية الأبعاد (`listings-state-machine.ts` & `ListingsService`)
تم فصل دورة حياة الإعلان إلى **3 محاور متعامدة مستقلة (Orthogonal Axes)**:

1. **محور المراجعة (`ModerationStatus`):**
   * `draft` ← `pending`
   * `pending` ← `approved` | `rejected`
   * `approved` ← `pending` | `rejected`
   * `rejected` ← `pending`
2. **محور النشر (`PublicationStatus`):**
   * `unpublished` ← `published` | `archived`
   * `published` ← `hidden` | `expired` | `archived`
   * `hidden` ← `published` | `archived`
   * `expired` ← `published` | `archived`
   * `archived` ← *(حالة نهائية Terminal State)*
3. **محور التوافر (`AvailabilityStatus`):**
   * `available` ← `reserved` | `sold` | `rented` | `out_of_stock` | `discontinued`
   * `reserved` ← `available` | `sold` | `rented`
   * `sold` / `rented` / `out_of_stock` ← `available` | `discontinued`
   * `discontinued` ← `available`

* **قاعدة الظهور للجمهور (`isListingPubliclyVisible`):** لا يظهر الإعلان في البحث العام للمشتري إلا إذا تحقق `(approved × published × available)`، وتستلزم دالة `assertCanPublish` أن يكون الإعلان `approved` وألا يكون `sold` أو `discontinued`.
* **إنشاء الإعلان (`createListing`):** يتحقق من نشاط القسم والمدينة، يتحقق من وجود كافة الحقول الديناميكية الإلزامية (`field.isRequired`)، يفحص ملكية كل `mediaKey` (يجب أن يحتوي على `/{userId}/`)، ويضبط `expiresAt` على **+30 يوماً** وعملة `EGP`.

### 4.4 البحث العربي والفلترة المكانية (`SearchService`, `arabic-normalizer.ts`)
* **تطبيع النص العربي:** إزالة التشكيل والمد (`ـ`)، توحيد الألف (`أ إ آ ٱ` ← `ا`)، التاء المربوطة (`ة` ← `ه`)، الياء (`ى ی` ← `ي`)، الكاف الفارسية (`ک` ← `ك`).
* **توسيع الاستعلام باللهجة المصرية (`generateArabicSearchVariants`):** توليد متغيرات بإضافة أو حذف `ال` التعريف وتبديل الحروف الشائعة بالعامية المصرية (`ذ`←`ز`، `ث`←`س`).
* **الفلترة الهرمية والديناميكية:** عند البحث بقسم أب، يشمل البحث تلقائياً جميع أقسامه الفرعية (`children`)، مع دعم فلترة حقول JSONB داخل `attributes` (مثل الغرف، الحمامات، التشطيب، الماركة، الموديل، السنة، ناقل الحركة، نوع الوقود...).
* **البحث المكاني (PostGIS):** عند تمرير `lat` و `lng`، يتم تنفيذ استعلام `ST_DWithin` على `display_location` بنصف قطر افتراضي **25 كم** وترتيب النتائج حسب الأقرب مسافة عبر `<->` (بحد أقصى 300 نتيجة أولية).

### 4.5 كشف بيانات الاتصال والحصص اليومية (`ListingsService.recordContactAction`, `QuotasService`)
* **حماية ضد سحب الأرقام (Anti-Scraping):** حد أقصى **30 كشفاً في الساعة لكل IP** عبر Redis.
* **منع الكشف الذاتي:** لا يُسمح لصاحب الإعلان بكشف رقم نفسه.
* **الحصة اليومية (`DailyQuota`):** بحد أقصى **5 كشوفات يومياً** (`DAILY_LIMIT = 5`) على مستوى الحساب (`callerAccount.id`)، ويُحسب اليوم بتوقيت القاهرة (`Africa/Cairo`) بحيث يتجدد في منتصف الليل بتوقيت مصر.
* عند النجاح، يُزاد عداد `contactRevealsCount` للإعلان، يُسجل حدث `CONTACT_REVEALED`، ويُرجع رقم الهاتف ورابط WhatsApp (`https://wa.me/...`) والحصة المتبقية.

### 4.6 الوسائط والفيديو القصير (`MediaService`, `VideoService`)
* **عزل أصول المستخدمين:** مسار تخزين الصور يضم `/{userId}/`، ويُمنع تأكيد رفع أو ربط أي ملف لا يتضمن معرف المستخدم، كما يتحقق من ملكية/عضوية المستخدم في الحساب قبل ربط الصورة بإعلان.
* **الفيديو القصير (Reels):** إصدار رابط رفع مباشر لـ Cloudflare Stream بمدة قصوى **30 ثانية**، وتحديث `processingStatus` عند استلام Webhook، ولا يعرض `/video-feed` إلا الإعلانات المنشورة ذات الفيديوهات التي حالتها `ready`.

### 4.7 الدردشة الداخلية (`ChatService`)
* تنشأ محادثة واحدة فريدة لكل زوج `(listingId, buyerUserId)` بشرط أن يكون الإعلان منشوراً وألا يكون المشتري هو مالك حساب البائع.
* التحقق الصارم من المشاركة (IDOR Check): يُسمح فقط لـ `buyerUserId` أو `sellerAccount.ownerUserId` بقراءة الرسائل أو الإرسال.
* عند قراءة الرسائل، يتم تعليم رسائل الطرف الآخر تلقائياً بحالة `read` مع تسجيل `readAt`.

### 4.8 الرقابة والبلاغات والتدقيق (`ModerationService`)
* يفتح المستخدم بلاغاً (`status = 'open'`) على إعلان أو حساب.
* قرار المشرف على الإعلان (`approve` / `reject`) يحدّث `moderationStatus` و `publicationStatus` ويسجل في جدولين: `moderation_log` و `audit_log` داخل Transaction واحد.
* قرار المشرف على البلاغ يحدّث البلاغ إلى `resolved` مع ملاحظات الإجراء ويسجل الحدث في `audit_log`.

### 4.9 المدفوعات والترويج V2 (`PaymentsService`)
* توفر الباقات المعرفة بالخادم لمنع التلاعب بالأسعار:
  * `BUMP_UP`: 35 EGP (رفع للمقدمة، 0 أيام)
  * `FEATURED_7_DAYS`: 120 EGP (مميز 7 أيام)
  * `FEATURED_14_DAYS`: 200 EGP (مميز 14 يوماً)
* عند بدء الدفع: يتحقق من ملكية الإعلان، ينشئ سجل دفع بحالة `PENDING` بالسعر الخادمي.
* عند استلام Paymob Webhook: يتحقق من توقيع **HMAC-SHA512** عبر 20 حقلاً من حقول Paymob، ويطبق Idempotency لتجاهل المعاملات المعالجة مسبقاً.

---

## 5. ملخص المتطلبات الوظيفية وغير الوظيفية

### أ) المتطلبات الوظيفية (Functional Requirements)
* **FR-01:** المصادقة عبر OTP للموبايل المصري + كلمة المرور الاختيارية + إدارة تعدد الجلسات.
* **FR-02:** تعدد الحسابات للمستخدم (فردي وتجاري) مع إدارة الفروع وأعضاء الفريق.
* **FR-03:** توفير بيانات مصر الجغرافية (محافظة/مدينة/منطقة) وشجرة التصنيفات بالحقول الديناميكية.
* **FR-04:** دورة حياة الإعلان الكاملة (إنشاء، تعديل، حذف ناعم، تغيير التوافر والنشر، مراجعة، انتهاء صلاحية بعد 30 يوماً).
* **FR-05:** محرك بحث عربي يدعم العامية المصرية، الفلترة بخصائص JSONB، والبحث الجغرافي بنصف القطر.
* **FR-06:** رفع الصور عبر Presigned URLs والفيديوهات القصيرة (30 ثانية) مع خلاصة Reels.
* **FR-07:** المفضلة، الدردشة 1-لـ-1 المرتبطة بالإعلان، وكشف الهاتف/WhatsApp بحصة يومية (5/يوم).
* **FR-08:** نظام البلاغات، طوابير مراجعة الإعلانات والبلاغات، وسجلات التدقيق الأمني.
* **FR-09:** إشعارات الدفع (FCM) ونظام الترويج والمدفوعات V2 عبر Paymob.

### ب) المتطلبات غير الوظيفية (Non-Functional Requirements)
* **الأمان:** مقاومة هجمات التخمين والسباق على OTP و Refresh Tokens، عزل ملكية الملفات والحسابات (IDOR Protection)، تنقية السجلات الأمنية، التحقق الصارم من المدخلات (`forbidNonWhitelisted`).
* **الأداء:** Fastify، فصل Redis Cache عن Redis Queue، فهارس `GIST` و `GIN`، و Cursor Pagination في قوائم الإعلانات والفيديو.
* **الاعتمادية:** جاهزية Probes تفحص كامل الاعتماديات، تراجع Redis للذاكرة في التطوير/الاختبار، ومعالجات خلفية للتنظيف والانتهاء والتسوية.
* **التوطين:** حصر V1 في أرقام مصر (`+20`)، العملة `EGP`، توقيت `Africa/Cairo`، والواجهات ثنائية اللغة (عربي/إنجليزي).

---

## 6. التحسينات المطبقة للإنتاج (Production Hardening Applied)

تمت معالجة الفجوات السابقة وتجهيز النظام لحمل 5,000 مستخدم متزامن عبر:
1. **الأمان وعزل CGNAT:** تحديث `RateLimitGuard` و`recordContactAction` لتقييد الطلبات حسب `userId` للمصادقين وحسب `IP` للزوار فقط، تعطيل Swagger في الإنتاج افتراضياً (`NODE_ENV=production`)، وتوحيد أدوار `AccountsService` عبر `AccountMemberRole.OWNER` و`AccountMemberRole.MANAGER`.
2. **الأداء وتعدد النسخ (Multi-Replica):** إضافة دعم PgBouncer (`PGBOUNCER_ENABLED`, `DATABASE_CONNECTION_LIMIT`)، تشغيل Workers عبر BullMQ repeatable jobs أو Redis Distributed Locks (`ENABLE_WORKERS` لفصل نسخة Workers)، كاش Redis TTL للتصنيفات والمواقع وتغذية الإعلانات، بث الدردشة الفوري عبر SSE + Redis Pub/Sub (`/api/v1/conversations/stream`)، فهارس `pg_trgm` على `search_normalized_text` وفهارس تعبير JSONB، وطابور `audit-logs` الاختياري في `SecurityAuditService`.
3. **الاعتمادية والمراقبة:** إضافة `MetricsModule` (`/metrics` بصيغة Prometheus لحساب p50/p95/p99 والأخطاء)، ملفات Prometheus/Grafana/Alerts في `infra/`، تشغيل `OutboxPublisherProcessor` لمعالجة `outbox_events`، واختبار حمل `load-tests/k6-5000-online.js`.
4. **اكتمال النماذج والمحولات الخارجية:** إضافة `PromotionPackage` و`Payment` إلى `prisma/schema.prisma` والـ migrations، تفعيل توقيع AWS SigV4 لـ Cloudflare R2، التحقق من توقيع Cloudflare Stream API/Webhook، حفظ `UserDevice` وإرسال FCM HTTP v1، إتمام Paymob checkout وتفعيل ترقية الإعلانات، وضبط `createListing` ليبدأ بحالة `pending` (مع خيار `AUTO_APPROVE_LISTINGS`).
5. **التشغيل والاختبارات:** إضافة `docker-compose.yml`، خط CI/CD في `.github/workflows/ci-cd.yml`، واختبارات تزامن `Promise.all` لـ OTP وتدوير التوكن.
