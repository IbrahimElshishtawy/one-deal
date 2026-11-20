import pypandoc, os, textwrap

md = r"""# Deal One
# Enterprise Admin System Specification
## وثيقة تحليل وتصميم وتنفيذ نظام الإدارة المركزي

**Document type:** Product Requirements + Business Analysis + System Architecture + RBAC Specification  
**Project:** Deal One Marketplace  
**Target:** Enterprise Admin Web Platform  
**Version:** 1.0  
**Status:** Baseline specification — requires reconciliation with the existing backend before implementation  
**Primary language:** Arabic, with English technical identifiers  
**Frontend direction:** Independent Web Admin Application  
**Backend direction:** Existing Deal One NestJS/Fastify API and PostgreSQL database

---

# 1. الغرض من الوثيقة

هذه الوثيقة تحدد بالتفصيل نظام الإدارة المركزي الخاص بمنصة Deal One. وهي مرجع لفريق تحليل الأعمال، وتصميم الواجهات، وتطوير Backend وFrontend، والأمن، والاختبار، والتشغيل.

الهدف ليس إنشاء صفحات إدارية شكلية، بل بناء نظام تشغيل وتحكم يستطيع فريق Deal One من خلاله إدارة المنصة ومستخدميها وإعلاناتها ومحتواها وبلاغاتها وإعداداتها، مع ضمان أن كل عملية:

1. لها هدف تجاري واضح.
2. لها مستخدم مسؤول عنها.
3. لها صلاحية محددة.
4. لها مدخلات ومخرجات معروفة.
5. يتم التحقق منها داخل Backend.
6. يتم تسجيلها في Audit Log عندما تكون عملية إدارية مؤثرة.
7. يمكن اختبارها ومراجعتها.
8. لا تكسر تطبيق Flutter أو عقود API الحالية.

## 1.1 ما الذي لا تعنيه هذه الوثيقة؟

- لا تفترض أن كل Endpoint المقترح موجود بالفعل.
- لا تعتبر أسماء الجداول المقترحة قراراً نهائياً قبل مراجعة Prisma Schema.
- لا تسمح بتغيير قاعدة الإنتاج أو حذف بياناتها أثناء مرحلة الاكتشاف.
- لا تفترض أن وجود صفحة في الواجهة يعني أن الوظيفة مكتملة.
- لا تسمح للـ Admin Web بالاتصال المباشر بقاعدة البيانات.
- لا تستبدل نظام المصادقة الحالي قبل فحصه وتوثيق سبب التغيير.

---

# 2. ملخص المنصة وسياق العمل

Deal One منصة Marketplace تربط بين أصحاب الإعلانات والباحثين عن المنتجات أو العقارات أو الخدمات. نطاق الأقسام الحالي يشمل:

- العقارات.
- مواد البناء والكهرباء.
- الخدمات المنزلية والهندسية.
- الأجهزة والديكور.
- السيارات.
- الملابس والإكسسوارات.

## 2.1 نموذج العمل الحالي

وفق نطاق V1 المعتمد للمشروع:

- نشر الإعلانات مجاني.
- لا يوجد Checkout أو Orders أو دفع إلكتروني للمشتريات في V1.
- التواصل بين المستخدمين يتم من خلال وسائل التواصل التي يدعمها التطبيق، ومنها المحادثات إذا كانت مفعلة في النسخة الحالية.
- لا يتم احتساب عمولة بيع أو حجز غير موجودة فعلياً في المنتج.
- يمكن مستقبلاً إضافة الاشتراكات والإعلانات المميزة والحدود المدفوعة، ثم التجارة والدفع أو عمولات الخدمات وفق قرارات منتج منفصلة.

**قاعدة:** لا تظهر لوحة الإدارة إيرادات أو طلبات شراء أو مدفوعات باعتبارها حقائق إذا لم تكن هذه الوظائف موجودة ومتصلة فعلياً بالـ Backend.

## 2.2 الهدف من لوحة الإدارة

توفير مصدر تحكم واحد للموظفين المخولين من أجل:

- متابعة صحة المنصة ونشاطها.
- إدارة حسابات المستخدمين.
- مراجعة الإعلانات.
- إدارة البلاغات والمحتوى المخالف.
- إدارة التوثيق.
- إدارة الأقسام والخصائص والفلاتر.
- التواصل التشغيلي والإشعارات.
- إدارة المحتوى الثابت والصفحات والبنرات.
- تحليل نشاط المنصة.
- إدارة موظفي الإدارة وأدوارهم.
- مراجعة السجل الأمني والتشغيلي.
- مراقبة الخدمات والإعدادات.

---

# 3. المبادئ المعمارية الأساسية

## 3.1 التطبيقات والخدمات

| الجزء | المسؤولية |
|---|---|
| Flutter Mobile App | تجربة المستخدم النهائي |
| Admin Web | واجهة الموظفين والإدارة |
| Existing NestJS Backend | منطق الأعمال والتحقق من الصلاحيات وتنفيذ العمليات |
| PostgreSQL | البيانات الأساسية والعلاقات |
| Prisma | الوصول المنظم لقاعدة البيانات |
| Redis | Cache / Rate Limits / Queues عند وجودها |
| Object Storage / R2 | الصور والملفات عند اعتماد التخزين الحالي |
| Cloudflare / WAF | حماية وحركة المرور حسب الإعداد الحالي |
| Monitoring | تتبع الأخطاء والأداء والخدمات |

## 3.2 قاعدة مصدر الحقيقة

Backend هو مصدر الحقيقة (Source of Truth). لا يجوز للواجهة أن تقرر أن المستخدم موثق أو الإعلان مقبول أو الموظف يمتلك صلاحية بمجرد تغيير حالة محلية.

أي قرار مؤثر يجب أن يمر بالترتيب:

1. Admin Web يرسل طلباً موثقاً.
2. Backend يتحقق من الجلسة.
3. Backend يتحقق من Permission.
4. Backend يتحقق من Business Rules.
5. Backend يتحقق من حالة الكيان الحالية.
6. Backend ينفذ العملية بأمان، وباستخدام Transaction عند الحاجة.
7. Backend يسجل Audit Event.
8. Backend يعيد نتيجة موحدة.
9. Admin Web يحدث البيانات المعروضة ويظهر النتيجة.

## 3.3 Modular Monolith

الاختيار المبدئي هو الاستمرار في Modular Monolith داخل NestJS ما دام ذلك مناسباً. لا يتم فصل الخدمات إلى Microservices إلا عند وجود سبب مثبت متعلق بالحمل أو الاستقلال التشغيلي أو حدود الملكية.

## 3.4 استقلال الواجهة

Admin Web مشروع مستقل عن Flutter، لكنه يستهلك API الحالية. يفضل استخدام Next.js + TypeScript، مع API Client مركزي وعقود OpenAPI مولدة أو متوافقة مع Swagger الحالي.

## 3.5 حماية الإنتاج

- عدم تشغيل migrations مدمرة.
- عدم استخدام reset أو drop على Production.
- لا يتم تنفيذ Bulk Actions قبل مراجعة الأثر وعدد السجلات.
- لا يتم تغيير صلاحيات Super Admin دون ضوابط.
- لا يتم تصدير بيانات حساسة إلا بتصريح وسجل تدقيق.
- لا يتم نشر وظائف تعتمد على Mock Data.

---

# 4. خريطة النظام وكيف تخدم الوحدات بعضها

```text
                    ┌──────────────────────────┐
                    │       Admin Web          │
                    │ Login / Dashboard / UI   │
                    └────────────┬─────────────┘
                                 │ HTTPS API
                    ┌────────────▼─────────────┐
                    │     Admin API Layer      │
                    │ Auth / RBAC / Validation │
                    └────────────┬─────────────┘
                                 │
      ┌──────────────────────────┼──────────────────────────┐
      │                          │                          │
┌─────▼─────┐              ┌─────▼─────┐              ┌─────▼─────┐
│ Users     │              │ Listings  │              │ Reports   │
│ Accounts  │◄────────────►│ Content   │◄────────────►│ Moderation│
└─────┬─────┘              └─────┬─────┘              └─────┬─────┘
      │                          │                          │
      └──────────────────────────┼──────────────────────────┘
                                 │
       ┌─────────────────────────┼──────────────────────────┐
       │                         │                          │
┌──────▼─────┐            ┌──────▼──────┐             ┌──────▼─────┐
│Verification│            │ Categories  │             │ Messaging  │
│ Identity   │            │ Filters     │             │ Complaints │
└────────────┘            └──────────────┘             └────────────┘

       ┌─────────────────────────┼──────────────────────────┐
       │                         │                          │
┌──────▼──────┐           ┌──────▼──────┐             ┌──────▼─────┐
│ Notifications│          │ CMS          │             │ Analytics  │
│ Campaigns    │          │ App Content  │             │ Reporting  │
└──────────────┘           └──────────────┘             └────────────┘

                                 │
                    ┌────────────▼─────────────┐
                    │ Audit / Security / Health│
                    │ Roles / Settings / Flags │
                    └────────────┬─────────────┘
                                 │
                    ┌────────────▼─────────────┐
                    │ PostgreSQL / Redis / R2  │
                    └──────────────────────────┘
```

## 4.1 علاقات التشغيل الأساسية

| الوحدة | تعتمد على | تخدم |
|---|---|---|
| Authentication | Admin identities, sessions | كل وحدات الإدارة |
| RBAC | Roles, permissions | كل العمليات |
| Users | User records, status | Listings, Reports, Verification, Support |
| Listings | Users, Categories, media | Search experience, Moderation, Analytics |
| Categories | Category tree, attributes | Listing creation, search filters |
| Reports | Users, listings, report reasons | Moderation, Audit, Support |
| Verification | User identity/submissions | Trust indicators, User profile |
| Notifications | Users, segments, templates | User communication |
| CMS | App content, media | Flutter app display |
| Analytics | Events and operational data | Management decisions |
| Audit Logs | Actor + action + target | Security and accountability |
| System Health | Service telemetry | Operations and incident response |

---

# 5. تصنيف البيانات والحسابات

يجب فصل ثلاث فئات مختلفة:

1. **Marketplace User:** مستخدم التطبيق العادي الذي ينشر إعلاناً أو يبحث أو يتواصل.
2. **Admin Identity:** موظف أو مسؤول يدخل لوحة الإدارة.
3. **Service Identity:** حساب تقني تستخدمه خدمة أو مهمة آلية، وليس شخصاً يسجل الدخول يدوياً.

لا يتم إعطاء حساب تقني صلاحيات بشرية واسعة، ولا يتم استخدام حساب موظف مشترك بين أكثر من شخص.

## 5.1 بيانات Marketplace User التي قد يراها الأدمن

بحسب صلاحية الموظف والغرض التشغيلي:

- User ID.
- الاسم الظاهر.
- رقم الهاتف أو البريد وفق سياسة الخصوصية.
- حالة الحساب.
- تاريخ التسجيل.
- حالة التوثيق.
- عدد الإعلانات.
- حالة الإعلانات.
- البلاغات المرتبطة بالحساب.
- بيانات الدعم اللازمة لحل مشكلة.
- آخر نشاط عام إذا كان متاحاً ومسموحاً.

لا تعرض كلمات المرور أو OTP أو Tokens أو أسرار المصادقة أو بيانات لا يحتاجها الموظف. لا تعرض مستندات الهوية إلا لموظف التوثيق المخول ولغرض واضح.

## 5.2 بيانات Admin Identity

- Admin ID.
- الاسم.
- بريد العمل.
- حالة الحساب.
- الأدوار.
- الصلاحيات الفعلية.
- MFA status.
- آخر دخول.
- الجلسات النشطة.
- تاريخ الإنشاء.
- منشئ الحساب.
- سجل تغييرات الأدوار.
- تاريخ انتهاء الحساب إن كان مؤقتاً.

---

# 6. الهيكل العام للوحة الإدارة

## 6.1 القائمة الجانبية

1. Overview
2. Users
3. Listings
4. Categories & Attributes
5. Reports & Moderation
6. Verification
7. Messaging Oversight
8. Notifications
9. CMS
10. Analytics & Reports
11. Admin Accounts
12. Roles & Permissions
13. Audit Logs
14. System Health
15. Feature Flags
16. Platform Settings

يجب أن تظهر عناصر القائمة وفق صلاحيات الموظف. إخفاء العنصر في الواجهة تحسين تجربة فقط، ولا يغني عن التحقق من Backend.

## 6.2 العناصر العامة في كل صفحة

- Page title and description.
- Breadcrumb.
- Search عند الحاجة.
- Filters.
- Server-side sorting.
- Pagination.
- Loading state.
- Empty state.
- Error state.
- Permission-aware actions.
- Confirmation dialog للعمليات المؤثرة.
- Toast أو Feedback واضح.
- Export عند وجود Permission وسياسة تسمح.
- سجل آخر تحديث عند الحاجة.

---

# 7. تفاصيل وحدات النظام

# 7.1 Admin Authentication & Session Management

## الوظيفة

السماح لموظفي Deal One المصرح لهم بالدخول إلى لوحة الإدارة بشكل آمن، وإدارة جلساتهم.

## المدخلات

- بريد أو معرف دخول معتمد.
- كلمة مرور.
- MFA challenge عند تفعيله.
- بيانات الجهاز والجلسة.
- رمز استعادة وفق آلية آمنة.

## المخرجات

- جلسة موثقة.
- بيانات Admin profile الضرورية.
- الأدوار والصلاحيات الفعلية.
- انتهاء الجلسة أو رفض الدخول مع سبب آمن.

## عناصر التحكم

- Login.
- Logout.
- Logout all sessions.
- MFA enrollment and verification.
- Password reset.
- Session revocation.
- View active sessions.
- Lockout/rate-limit handling.

## من يرى ماذا؟

الموظف يرى ملفه وجلساته. مسؤول إدارة الحسابات يرى حالة حسابات الموظفين حسب صلاحياته. لا يرى أي موظف كلمات مرور أو MFA secrets.

## التأثير

حماية جميع الوحدات. أي خلل في هذه الوحدة قد يسمح بوصول غير مصرح إلى بيانات المستخدمين والإعلانات والإعدادات.

## قواعد أساسية

- حساب منفصل لكل موظف.
- MFA إلزامي على الأقل للأدوار الحساسة، ويفضل لجميع الحسابات الإدارية.
- Cookies: HttpOnly, Secure, SameSite وفق تصميم الجلسة.
- لا تخزن Refresh Token في localStorage.
- Rate limiting لمحاولات الدخول.
- إبطال الجلسات عند تعطيل الحساب أو سحب صلاحيات مؤثرة.
- عدم كشف هل البريد موجود أم لا في رسائل استعادة كلمة المرور.
- إعادة مصادقة للعمليات عالية الخطورة.
- تسجيل نجاح وفشل محاولات الدخول.

## صلاحيات مقترحة

- `admin_auth.login`
- `admin_auth.logout`
- `admin_auth.sessions.read`
- `admin_auth.sessions.revoke`
- `admin_auth.mfa.manage`
- `admin_auth.password.change`

---

# 7.2 Overview Dashboard

## الوظيفة

تقديم صورة تشغيلية مختصرة عن حالة المنصة، وليس مجرد أرقام تجميلية.

## ما تعرضه

### Marketplace KPIs

- إجمالي المستخدمين.
- المستخدمون الجدد خلال فترة محددة.
- المستخدمون النشطون وفق تعريف موثق.
- إجمالي الإعلانات.
- الإعلانات المنشورة.
- الإعلانات قيد المراجعة.
- الإعلانات المرفوضة.
- الإعلانات المنتهية.
- البلاغات المفتوحة.
- طلبات التوثيق المعلقة.
- عدد المحادثات أو النشاط المتاح فعلياً.

### الرسوم البيانية

- نمو التسجيلات حسب اليوم/الأسبوع/الشهر.
- إنشاء الإعلانات حسب الفترة.
- توزيع الإعلانات حسب القسم.
- توزيع النشاط حسب المدينة إذا كانت البيانات تسمح.
- معدل قبول ورفض الإعلانات.
- حجم البلاغات حسب السبب والحالة.

### Operational Widgets

- Queue backlog إذا كان نظام Queue موجوداً.
- API error rate.
- Database/Redis health.
- Latest admin actions.
- Pending moderation tasks.
- Failed notifications.

## المدخلات

Aggregated queries أو analytics tables/events موثوقة، مع نطاق زمني ومنطقة زمنية محددين.

## المخرجات

KPIs ورسوم ومهام تتطلب تدخلاً.

## عناصر التحكم

- Date range.
- Section filter.
- City filter.
- Refresh.
- Drill-down إلى قائمة السجلات التي كوّنت الرقم.
- Export للتقارير المسموح بها.

## من يرى ماذا؟

- Super Admin: جميع المؤشرات.
- Platform Admin: مؤشرات المنصة.
- Operations Manager: مؤشرات التشغيل.
- Moderator: مؤشرات المراجعة والبلاغات المسموح بها.
- Analyst: مؤشرات وتحليلات دون صلاحيات تغيير بيانات.
- Support: مؤشرات دعم محدودة.

## التأثير

يساعد الإدارة في اكتشاف التكدس والمشكلات واتخاذ القرارات. يجب ألا يؤدي تحميل الصفحة إلى قراءة ملايين السجلات دفعة واحدة.

## قواعد البيانات والأداء

- Server-side aggregation.
- Indexes مدروسة.
- Cache للبيانات المتكررة.
- تعريف دقيق لكل KPI.
- عدم خلط المستخدمين المسجلين بالمستخدمين النشطين.
- عدم اختلاق Revenue أو Orders في V1.
- إظهار وقت آخر تحديث ومصدر المؤشر.

## الصلاحيات

- `dashboard.overview.read`
- `dashboard.operational.read`
- `dashboard.financial.read` (مستقبلي، لا يستخدم قبل وجود بيانات مالية حقيقية)

---

# 7.3 Users Management

## الوظيفة

إدارة حسابات مستخدمي Marketplace وحالاتهم، ومساعدة فرق التشغيل والدعم على فهم المشكلات المرتبطة بهم.

## القائمة

- User ID.
- Display name.
- Contact identifier وفق الصلاحية.
- Account status.
- Verification status.
- Registration date.
- Listings count.
- Reports count.
- Last activity إذا كان متاحاً.
- Risk flags إذا كانت مبنية على قواعد موثقة.

## صفحة تفاصيل المستخدم

### A. Profile

- البيانات الأساسية.
- حالة الحساب.
- تاريخ التسجيل.
- وسائل التواصل المتاحة.
- حالة التوثيق.

### B. Listings

- جميع إعلانات المستخدم.
- حالة كل إعلان.
- تاريخ النشر والتعديل.
- سبب الرفض إن وجد.
- روابط التفاصيل.

### C. Reports

- البلاغات المرتبطة بالمستخدم.
- هل هو مبلغ أم مبلغ عنه؟
- الحالة والقرار.
- البلاغات السابقة ذات الصلة.

### D. Verification

- حالة التوثيق.
- الطلبات.
- القرار.
- سبب الرفض.
- المستندات فقط لموظفي التوثيق المخولين.

### E. Admin Actions

- تعليق الحساب.
- رفع التعليق.
- حظر الحساب وفق سياسة واضحة.
- إضافة ملاحظة داخلية.
- عرض سجل الإجراءات.

## المدخلات

User ID، سبب الإجراء، مدة التعليق إن كانت السياسة تسمح، الحالة المطلوبة، ومعلومات المراجعة.

## المخرجات

تغيير حالة الحساب، تسجيل الإجراء، إبطال جلسات المستخدم عند الحاجة، وتحديث أثره على التطبيق.

## حالات الحساب

يجب اعتماد State Machine من Backend، مع تعريف واضح لكل حالة. أمثلة مرشحة:

- Active.
- Temporarily Suspended.
- Restricted.
- Banned.
- Deactivated.
- Pending Deletion إذا كان ذلك مدعوماً.

لا يتم إنشاء الحالات أو الانتقال بينها من الواجهة وحدها.

## عناصر التحكم

- Search.
- Filters.
- Sorting.
- Pagination.
- View details.
- Suspend.
- Unsuspend.
- Ban.
- Unban وفق السياسة.
- Add internal note.
- Export إذا كان مصرحاً.

## التأثير على المشروع

- منع المستخدم الموقوف من تنفيذ العمليات التي تمنعها السياسة.
- التعامل مع إعلاناته وفق سياسة التعليق/الحظر.
- إبطال الجلسات أو Tokens عند الحاجة.
- إظهار رسالة مناسبة في Flutter.
- حفظ سبب الإجراء وتاريخه ومنفذه.
- لا يتم حذف بيانات المستخدم لمجرد حظره.

## الصلاحيات

- `users.read`
- `users.read_contact`
- `users.read_sensitive`
- `users.update`
- `users.suspend`
- `users.unsuspend`
- `users.ban`
- `users.unban`
- `users.add_note`
- `users.export`

يجب فصل `users.read_sensitive` عن `users.read`.

---

# 7.4 Listings Management

## الوظيفة

إدارة دورة حياة الإعلان ومراجعة محتواه وضمان توافقه مع سياسات Deal One.

## القائمة

- Listing ID.
- Title.
- Owner.
- Category/Subcategory.
- Price.
- City/Location.
- Status.
- Created at.
- Updated at.
- Moderation state.

## تفاصيل الإعلان

- العنوان والوصف.
- السعر والعملة.
- القسم والتصنيف.
- الخصائص الديناميكية.
- الموقع.
- الصور والفيديو.
- بيانات الناشر.
- تاريخ الإنشاء والتعديلات.
- سجل المراجعات.
- البلاغات.
- سبب الرفض أو الإخفاء.

## دورة الحياة المقترحة

Draft → Submitted → Pending Review → Approved/Published → Hidden/Rejected/Expired/Archived

هذه الحالات مجرد نموذج مقترح؛ يجب مطابقتها مع Listing Status الموجودة فعلياً في Backend.

## عناصر التحكم

- Approve.
- Reject with reason.
- Request changes.
- Hide/unhide.
- Archive وفق السياسة.
- View owner.
- View reports.
- Bulk review وفق حدود آمنة.
- Search/filter/sort.
- Feature/promote فقط إذا كانت خاصية الترويج موجودة فعلياً.

## المدخلات

Listing ID، القرار، سبب القرار، ملاحظات المراجع، وأي بيانات تعديل مسموح بها.

## المخرجات

تغيير حالة الإعلان، إخطار صاحبه إذا كانت الخدمة موجودة، تحديث ظهوره في التطبيق، وتسجيل القرار.

## قواعد

- لا يمكن الموافقة على إعلان محذوف أو في حالة غير مناسبة.
- لا يمكن قبول إعلان دون استيفاء قواعد القسم.
- يجب منع المراجعين من اعتماد إعلانهم أو إعلان مرتبط بتضارب مصالح إذا كانت السياسة تتطلب ذلك.
- يجب حفظ تاريخ وسبب الرفض.
- لا يتم تعديل محتوى المستخدم بصمت.
- Bulk actions تحتاج preview وعدد العناصر وتأكيداً.
- العمليات المتزامنة يجب أن تمنع تضارب قرار مراجع مع آخر.

## التأثير

مباشر على نتائج البحث وتجربة المستخدم وثقة السوق. يجب أن تنعكس الحالة من خلال API المستخدمة في Flutter، وليس عن طريق تعديل منفصل في لوحة الإدارة.

## الصلاحيات

- `listings.read`
- `listings.read_owner`
- `listings.approve`
- `listings.reject`
- `listings.request_changes`
- `listings.hide`
- `listings.restore`
- `listings.archive`
- `listings.delete`
- `listings.feature`
- `listings.bulk_moderate`
- `listings.export`

الحذف الدائم صلاحية شديدة الحساسية، والأصل استخدام الإخفاء أو الأرشفة وفق سياسة الاحتفاظ.

---

# 7.5 Categories, Subcategories & Attributes

## الوظيفة

إدارة الهيكل الذي يصنف الإعلانات، ويحدد خصائصها وفلاتر البحث التي تظهر للمستخدم.

## مثال

العقارات:
- شقق.
- فيلات.
- أراضٍ.
- تجاري.

خصائص محتملة:
- المساحة.
- عدد الغرف.
- عدد الحمامات.
- نوع العرض.
- التشطيب.

السيارات:
- الماركة.
- الموديل.
- سنة الصنع.
- ناقل الحركة.
- الوقود.
- المسافة المقطوعة.

## ما تديره الوحدة

- Category.
- Subcategory.
- Arabic/English names.
- Slug.
- Description.
- Icon/Image.
- Display order.
- Active/Inactive status.
- Dynamic attributes.
- Attribute types.
- Required/Optional.
- Validation rules.
- Filter visibility.
- Search behavior.

## عناصر التحكم

- Create category.
- Edit.
- Reorder.
- Activate/deactivate.
- Create subcategory.
- Configure attributes.
- Preview listing form.
- Preview search filters.

## التأثير

أي تغيير في Attributes قد يؤثر على:
- إنشاء إعلان Flutter.
- تعديل الإعلان.
- التحقق من بيانات الإعلانات القديمة.
- فلاتر البحث.
- نتائج البحث.
- التحليلات.

لذلك يجب عدم حذف Attribute مستخدم في إعلانات منشورة دون خطة ترحيل وتوافق.

## الصلاحيات

- `categories.read`
- `categories.create`
- `categories.update`
- `categories.reorder`
- `categories.activate`
- `categories.deactivate`
- `categories.attributes.manage`
- `categories.delete`

---

# 7.6 Reports & Moderation

## الوظيفة

إدارة البلاغات التي يقدمها المستخدمون عن حسابات أو إعلانات أو محتوى مخالف.

## أنواع البلاغات

- Scam/Fraud.
- Misleading information.
- Duplicate listing.
- Prohibited content.
- Inappropriate images.
- Harassment/abuse.
- Wrong category.
- Incorrect price.
- Other.

هذه الأسباب يجب أن تطابق Report Reasons المعتمدة في Backend.

## قائمة البلاغات

- Report ID.
- Reporter.
- Target type.
- Target ID.
- Reason.
- Description.
- Submitted at.
- Status.
- Priority.
- Assigned moderator.

## دورة العمل

Submitted → Triaged → Assigned → Under Review → Resolved / Rejected / Escalated

## عناصر التحكم

- Assign to moderator.
- Change priority.
- Open target.
- Add internal note.
- Request more information إذا كانت العملية مدعومة.
- Resolve.
- Reject as invalid.
- Escalate.
- Reopen وفق السياسة.

## نتائج معالجة البلاغ

- لا يوجد انتهاك.
- تحذير.
- تعديل/إخفاء إعلان.
- تعليق حساب.
- حظر وفق السياسة.
- إحالة للمسؤول الأعلى.

البلاغ لا يعني تلقائياً أن المستخدم مذنب. يجب مراجعة الأدلة وتوثيق القرار.

## التكامل

- Users: لمعرفة سجل الطرفين.
- Listings: لاتخاذ قرار على الإعلان.
- Notifications: لإبلاغ الأطراف بالقرارات المناسبة.
- Audit: لحفظ القرار.
- Analytics: لقياس أسباب البلاغات والأنماط.

## الصلاحيات

- `reports.read`
- `reports.assign`
- `reports.priority.update`
- `reports.note.add`
- `reports.resolve`
- `reports.reject`
- `reports.escalate`
- `reports.reopen`

---

# 7.7 Verification Management

## الوظيفة

مراجعة طلبات توثيق الحسابات، وإدارة قرار منح أو رفض علامة التوثيق.

## ما تستقبله

- User ID.
- بيانات الطلب.
- نوع التوثيق.
- بيانات التحقق المطلوبة.
- الملفات/المستندات إذا كانت موجودة.
- تاريخ التقديم.
- حالة الطلب.

## ما تعرضه

- بيانات مقدم الطلب الضرورية.
- نوع التوثيق.
- المستندات المسموح للمراجع برؤيتها.
- سجل الطلبات.
- نتيجة التحقق.
- ملاحظات المراجع.

## عناصر التحكم

- Open request.
- Assign reviewer.
- Approve.
- Reject with reason.
- Request resubmission.
- Mark pending.
- Expire/revoke verification وفق سياسة واضحة.

## قواعد مهمة

- `account.verified=true` لا يجب أن يتغير من الواجهة مباشرة.
- يجب تحديد معنى التوثيق: ماذا تم التحقق منه؟ وبأي دليل؟ ولمدة كم؟
- لا يجوز منح علامة التوثيق بمجرد رفع مستند.
- الوصول إلى المستندات الحساسة مقصور على دور التوثيق.
- روابط الملفات تكون مؤقتة ومحمية عند الحاجة.
- يجب تسجيل من فتح المستند ومن اتخذ القرار.
- يجب تحديد سياسة الاحتفاظ بالمستندات وحذفها.

## الصلاحيات

- `verification.read`
- `verification.documents.read`
- `verification.assign`
- `verification.approve`
- `verification.reject`
- `verification.request_resubmission`
- `verification.revoke`

---

# 7.8 Messaging Oversight & Support

## الوظيفة

إدارة شكاوى التواصل ومشكلات المحادثات، وليس التجسس العام على رسائل المستخدمين.

## ما يمكن إدارته

- البلاغات المرتبطة بمحادثة.
- معرف المحادثة.
- الأطراف المرتبطة.
- حالة المشكلة.
- بيانات تقنية ضرورية لتشخيص الأعطال.
- مؤشرات فشل الإرسال.
- حالة الدعم.

## الوصول إلى محتوى الرسائل

الأصل ألا يكون لكل موظف دعم وصول مفتوح لمحتوى الرسائل. إذا تطلب بلاغ محدد مراجعة المحتوى:

1. يوجد سبب واضح.
2. يوجد Permission مستقل.
3. الوصول محدود بالمحادثة ذات الصلة.
4. يتم تسجيل من فتح المحتوى ووقت الوصول والسبب.
5. لا يتم عرض المحتوى في Analytics أو Overview.
6. تخضع العملية لسياسة الخصوصية والقوانين المعمول بها.

## عناصر التحكم

- View complaint.
- Link to related report.
- Assign ticket.
- Add internal note.
- Escalate.
- Resolve support case.
- View permitted technical status.

## الصلاحيات

- `messaging.complaints.read`
- `messaging.technical.read`
- `messaging.content.read_limited`
- `support.assign`
- `support.note.add`
- `support.resolve`

---

# 7.9 Notifications Management

## الوظيفة

إنشاء وإدارة الإشعارات التي تصل إلى مستخدمي التطبيق.

## أنواع الإشعارات

- Transactional: مرتبطة بحدث حقيقي مثل قرار مراجعة إعلان.
- Operational: صيانة أو تحديث أو تنبيه تشغيلي.
- Campaign: رسالة تسويقية أو تعريفية لمجموعة مسموح بها.

## عناصر التحكم

- Create campaign.
- Select audience.
- Arabic/English content.
- Preview.
- Schedule.
- Send test.
- Submit for approval.
- Send.
- Pause/cancel إذا كان مدعوماً.
- View delivery statistics.

## تقسيم الجمهور

- All users إذا كانت السياسة تسمح.
- Users by category/activity/region وفق بيانات وموافقات مناسبة.
- Verified users.
- New users.
- Specific user segment.

لا يجوز استهداف المستخدمين ببيانات حساسة أو استخدام معلومات لا يوجد أساس مشروع لمعالجتها.

## ضوابط الإرسال

- Preview لحجم الجمهور.
- Rate limits.
- Idempotency لمنع التكرار.
- Approval workflow للحملات العامة.
- سجل المحتوى والمرسل والموافق.
- Failed delivery handling.
- Unsubscribe/preferences حسب نوع الرسالة والمتطلبات القانونية.

## الصلاحيات

- `notifications.read`
- `notifications.create`
- `notifications.schedule`
- `notifications.send`
- `notifications.approve`
- `notifications.cancel`
- `notifications.analytics.read`

---

# 7.10 CMS & App Content Management

## الوظيفة

إدارة المحتوى العام الذي يظهر في تطبيق Flutter دون الحاجة إلى إصدار تطبيق جديد لكل تعديل محتوى.

## أنواع المحتوى

- Home banners.
- Promotional sections.
- Featured categories.
- Static pages.
- About Us.
- Terms and Conditions.
- Privacy Policy.
- FAQ.
- Contact information.
- Social links.
- Help content.

## عناصر التحكم

- Create.
- Edit.
- Preview.
- Publish.
- Schedule.
- Unpublish.
- Archive.
- Upload media.
- Set Arabic/English versions.
- Set display order.
- Define active dates.

## قواعد النشر

- Draft لا يظهر للمستخدم.
- Published يظهر حسب شروط العرض.
- Scheduled يظهر في موعد محدد.
- Archived لا يظهر.
- يجب التحقق من صلاحية الصور والروابط.
- يجب توفير Preview قبل النشر.
- يجب حفظ نسخة سابقة أو Revision History للمحتوى المهم.

## التأثير على Flutter

يستهلك Flutter المحتوى المنشور من API أو CMS endpoint. يجب توفير fallback مناسب عند فشل التحميل، وعدم الاعتماد على أن كل محتوى سيكون متاحاً دائماً.

## الصلاحيات

- `cms.read`
- `cms.create`
- `cms.update`
- `cms.publish`
- `cms.schedule`
- `cms.unpublish`
- `cms.archive`
- `cms.media.manage`

---

# 7.11 Analytics & Reports

## الوظيفة

توفير بيانات تساعد الإدارة على فهم استخدام السوق، واتخاذ قرارات مبنية على بيانات.

## التقارير

### Users
- Registrations by period.
- Active users وفق تعريف النشاط.
- Retention إذا توفرت Events مناسبة.
- Geographic distribution.

### Listings
- Listings created.
- Published/Rejected/Expired.
- Category distribution.
- Average time to review.
- Listing status transitions.

### Moderation
- Reports by reason.
- Open vs resolved.
- Average resolution time.
- Decisions by period.
- Workload per moderator.

### Verification
- Pending requests.
- Approval/rejection rate.
- Review duration.

### Notifications
- Sent.
- Delivered.
- Failed.
- Opened/clicked فقط إذا كان مزود الخدمة يدعم القياس وبما يتوافق مع الخصوصية.

## عناصر التحكم

- Date range.
- Timezone.
- Group by day/week/month.
- Filter by category/city/status.
- Export.
- Drill-down.
- Saved reports إذا تم تنفيذها.

## قواعد

- تعريف كل Metric.
- توضيح مصدر البيانات.
- إظهار آخر تحديث.
- لا تعتبر API request أو page view مستخدماً نشطاً تلقائياً.
- لا يتم عرض Revenue في V1 دون مصدر مالي حقيقي.
- لا يتم تحميل raw events بالكامل على الواجهة.
- التصدير يخضع لصلاحيات مستقلة.

## الصلاحيات

- `analytics.read`
- `analytics.export`
- `analytics.sensitive.read`
- `reports.business.read`

---

# 7.12 Admin Accounts Management

## الوظيفة

إنشاء وإدارة حسابات الموظفين الذين يستخدمون Admin Web.

هذه الحسابات ليست حسابات مستخدمي Marketplace.

## إنشاء الحساب

الحقول المقترحة:

- Full name.
- Work email.
- Employee/Staff ID إذا كان النظام يحتاجه.
- Department.
- Job title.
- Role assignment.
- Account expiry إذا كان مؤقتاً.
- Invitation status.

لا يتم تعيين كلمة مرور افتراضية معروفة لجميع الموظفين. يتم إرسال دعوة آمنة أو اتباع آلية إعداد حساب معتمدة.

## حالات حساب الإدارة

- Invited.
- Active.
- Temporarily Locked.
- Suspended.
- Disabled.
- Expired.

## عناصر التحكم

- Invite admin.
- Resend invitation.
- Assign/revoke role.
- Disable account.
- Suspend account.
- Revoke sessions.
- Reset MFA وفق إجراءات آمنة.
- View admin activity.
- Set expiry.
- View access history.

## قواعد

- حساب منفصل لكل شخص.
- لا توجد حسابات مشتركة.
- لا يمكن لأي موظف منح نفسه صلاحيات أعلى.
- إنشاء Super Admin عملية مقيدة.
- آخر Super Admin لا يمكن حذفه أو تعطيله دون آلية طوارئ معتمدة.
- عند مغادرة موظف، يتم تعطيل الحساب وإبطال الجلسات فوراً.
- يجب تسجيل كل تغيير في حساب إداري.

## الصلاحيات

- `admins.read`
- `admins.invite`
- `admins.update`
- `admins.disable`
- `admins.suspend`
- `admins.sessions.revoke`
- `admins.roles.assign`
- `admins.mfa.reset`
- `admins.activity.read`

---

# 7.13 Roles & Permissions

## الوظيفة

تعريف ما يمكن لكل موظف رؤيته وتنفيذه.

## نموذج RBAC

Admin User → Role Assignment → Role → Permissions

يمكن للموظف امتلاك أكثر من Role إذا كان التصميم يسمح، ويجب تحديد كيفية دمج الصلاحيات ومنع التعارضات.

## أنواع الصلاحيات

- Read.
- Create.
- Update.
- Delete/Archive.
- Approve.
- Reject.
- Export.
- Assign.
- Resolve.
- Sensitive Read.
- Manage Settings.

## عناصر التحكم

- Create role.
- Edit role.
- Clone role.
- Assign permissions.
- Assign role to admin.
- Revoke role.
- Preview effective permissions.
- View role change history.

## ضوابط

- Least Privilege.
- Deny by default.
- Backend enforcement.
- منع privilege escalation.
- منع حذف آخر Super Admin.
- تأكيد العمليات الحساسة.
- مراجعة دورية للصلاحيات.
- صلاحيات مؤقتة عند الحاجة.
- فصل المهام المتعارضة (Separation of Duties) عند الحاجة.

## الصلاحيات

- `roles.read`
- `roles.create`
- `roles.update`
- `roles.delete`
- `roles.permissions.manage`
- `roles.assign`

---

# 7.14 Audit Logs

## الوظيفة

سجل مركزي غير قابل للتعديل من المستخدمين الإداريين العاديين، يوضح من فعل ماذا ومتى وعلى أي كيان.

## الحقول المقترحة

- Event ID.
- Actor Admin ID.
- Action.
- Target type.
- Target ID.
- Timestamp.
- Outcome.
- Reason.
- Request/correlation ID.
- IP/device metadata عند الحاجة.
- Before/after diff مع إخفاء البيانات الحساسة.

## الأحداث

- Login success/failure.
- MFA changes.
- Role changes.
- Permission changes.
- User suspension/ban.
- Listing approval/rejection.
- Verification decisions.
- Notification campaign send.
- CMS publish.
- Sensitive record access.
- Export operations.
- Settings changes.

## عناصر التحكم

- Search.
- Filter by actor.
- Filter by action.
- Filter by target.
- Date range.
- View event details.
- Export وفق صلاحية.
- Correlate related events.

## قواعد

- Append-only logical design.
- لا تخزن Passwords أو OTP أو Tokens أو أسرار.
- لا تسمح بتعديل أو حذف السجل من Admin UI.
- حدّد سياسة retention.
- احمِ السجل من العبث، ويمكن استخدام تخزين منفصل أو immutable storage حسب الحاجة.
- سجل فشل العملية الحساسة أيضاً.
- لا تعتبر تسجيل Audit بديلاً عن مراقبة التطبيق أو سجلات البنية التحتية.

## الصلاحيات

- `audit_logs.read`
- `audit_logs.export`
- `audit_logs.sensitive.read`

---

# 7.15 System Health & Operations

## الوظيفة

إظهار حالة المكونات التقنية ومساعدة فريق التشغيل على اكتشاف الأعطال.

## ما يمكن عرضه

- Backend health.
- Database connectivity.
- Redis connectivity.
- Queue health إذا كانت موجودة.
- Storage availability.
- API latency.
- Error rate.
- Failed jobs.
- Deployment version.
- Last successful backup status إذا كان متاحاً من مصدر موثوق.

## عناصر التحكم

في البداية يفضل أن تكون Read-only، مثل:
- View status.
- View incidents.
- View metrics.
- View logs وفق صلاحية.
- Acknowledge alert.

عمليات restart أو migration أو تغيير secrets لا تضاف إلى Admin Web إلا إذا وُجدت حاجة تشغيلية واضحة وضوابط أمنية منفصلة.

## الصلاحيات

- `system_health.read`
- `system_health.logs.read`
- `system_health.alerts.acknowledge`
- `system_health.operations.manage` (صلاحية شديدة التقييد إن تم اعتمادها)

---

# 7.16 Feature Flags

## الوظيفة

تشغيل أو إيقاف وظائف معينة بشكل تدريجي دون إصدار نسخة جديدة، إذا كانت التطبيقات مصممة لاستهلاك هذه العلامات.

## أمثلة

- New listing form.
- New category experience.
- Feature rollout.
- Temporary maintenance behavior.

## عناصر التحكم

- Create flag.
- Enable/disable.
- Target environment.
- Audience/percentage rollout إذا تم تنفيذه.
- Start/end time.
- Change history.
- Kill switch وفق ضوابط.

## قواعد

- لا تستخدم Feature Flag لإخفاء خلل أمني.
- لا تجعل التغيير يكسر Flutter القديم.
- حدد Default behavior إذا لم تصل قيمة Flag.
- سجل كل تغيير.
- لا يتم تشغيل Flag في Production دون اختبار وتأكيد.

## الصلاحيات

- `feature_flags.read`
- `feature_flags.create`
- `feature_flags.update`
- `feature_flags.activate`
- `feature_flags.deactivate`

---

# 7.17 Platform Settings

## الوظيفة

إدارة إعدادات الأعمال العامة التي يجب أن تكون قابلة للتغيير من لوحة الإدارة.

## أمثلة

- حدود نشر الإعلانات.
- إعدادات مراجعة الإعلانات.
- إعدادات الصيانة.
- إعدادات اللغات.
- إعدادات ظهور الأقسام.
- إعدادات رفع الملفات ضمن الحدود المعتمدة.
- إعدادات التواصل والدعم.
- إعدادات السياسات العامة.

## عناصر التحكم

- View.
- Edit.
- Validate.
- Preview impact.
- Save.
- Publish/apply.
- Rollback إذا كان مدعوماً.

## قواعد

- فصل الإعدادات التشغيلية عن Secrets.
- لا يتم عرض API keys أو database URLs.
- التغييرات الحساسة تحتاج إعادة مصادقة أو موافقة إضافية.
- حفظ القيمة القديمة والجديدة.
- تحديد من يحق له التغيير.
- إعدادات لها تأثير على Flutter يجب أن تكون متوافقة مع الإصدارات السابقة.

## الصلاحيات

- `settings.read`
- `settings.update`
- `settings.sensitive.update`
- `settings.rollback`

---

# 8. حسابات الموظفين المقترحة والصلاحيات التفصيلية

هذه هي نقطة البداية المقترحة. الأدوار ليست بالضرورة حسابات فردية؛ يمكن إنشاء عدة موظفين تحت الدور نفسه. يجب أن يكون لكل موظف حساب منفصل.

## 8.1 Super Admin

**العدد المقترح:** 1 إلى 2 حسابات موثوقة، وليس حساباً مشتركاً.

### يرى

- Overview بالكامل.
- جميع المستخدمين والإعلانات.
- البلاغات والتوثيق.
- الأقسام والفلاتر.
- الإشعارات وCMS.
- التحليلات.
- جميع حسابات الإدارة.
- الأدوار والصلاحيات.
- Audit Logs.
- System Health.
- Settings وFeature Flags.

### يستطيع

- إدارة الأدوار والصلاحيات.
- إنشاء وتعطيل حسابات الإدارة.
- إدارة إعدادات المنصة.
- اعتماد العمليات الحساسة.
- مراجعة السجلات.
- إدارة وحدات المنصة كلها.

### قيود

- كل إجراء يسجل.
- MFA إلزامي.
- إعادة مصادقة للعمليات الحرجة.
- لا يتم استخدام الحساب اليومي العام كحساب طوارئ.
- يفضل وجود Break-glass procedure موثق.

## 8.2 Platform Admin

**العدد المقترح:** 1 إلى 3.

### يرى

- Overview.
- Users.
- Listings.
- Categories.
- Reports.
- Verification status.
- Notifications.
- CMS.
- Analytics.
- Admin activity حسب السياسة.

### يستطيع

- إدارة بيانات المنصة التشغيلية.
- إدارة المستخدمين والإعلانات وفق السياسات.
- إدارة المحتوى.
- الإشراف على فرق التشغيل.

### لا يستطيع افتراضياً

- تعديل صلاحيات Super Admin.
- تغيير أسرار البنية التحتية.
- الوصول المفتوح إلى مستندات الهوية.
- تعديل أو حذف Audit Logs.

## 8.3 Operations Manager

**العدد المقترح:** 1 إلى 2.

### يرى

- مؤشرات التشغيل.
- قوائم الإعلانات والبلاغات.
- مهام المراجعين.
- حالة الطوابير.
- تقارير الأداء التشغيلي.

### يستطيع

- توزيع مهام المراجعة.
- إعادة إسناد البلاغات.
- متابعة SLA.
- تصعيد الحالات.
- مراجعة مؤشرات التشغيل.

### لا يستطيع

- إدارة أسرار النظام.
- تعديل RBAC.
- الوصول غير المقيد للمستندات الحساسة.

## 8.4 Content Moderator

**العدد المقترح:** حسب حجم البلاغات والإعلانات.

### يرى

- الإعلانات المطلوب مراجعتها.
- تفاصيل المحتوى والصور.
- البلاغات المسندة إليه أو المتاحة وفق سياسة التوزيع.
- سجل المراجعة الضروري.
- بيانات صاحب الإعلان الضرورية للمراجعة.

### يستطيع

- Approve.
- Reject.
- Request changes.
- Hide ضمن السياسة.
- إضافة ملاحظات داخلية.
- حل البلاغات المسندة إليه ضمن حدود دوره.

### لا يستطيع

- إدارة الأدوار.
- إنشاء أدمن.
- تصدير جميع المستخدمين.
- الوصول إلى مستندات التوثيق.
- تعديل إعدادات المنصة.
- حذف سجلات التدقيق.

## 8.5 Verification Officer

**العدد المقترح:** حسب عدد طلبات التوثيق.

### يرى

- طلبات التوثيق.
- بيانات التحقق الضرورية.
- المستندات المسموح بها.
- سجل قرارات التوثيق.

### يستطيع

- مراجعة الطلب.
- طلب إعادة التقديم.
- قبول أو رفض الطلب.
- إضافة سبب القرار.

### لا يستطيع

- إدارة الإعلانات بشكل عام.
- تغيير الأدوار.
- الوصول إلى كل محادثات المستخدمين.
- تصدير مستندات التوثيق بالجملة.

## 8.6 Customer Support

**العدد المقترح:** حسب حجم الدعم.

### يرى

- ملف المستخدم الأساسي.
- حالة الحساب.
- حالة الإعلانات.
- البلاغات المرتبطة.
- حالة طلبات الدعم.
- بيانات التواصل اللازمة.

### يستطيع

- إضافة ملاحظة دعم.
- إنشاء/تحديث تذكرة إذا كانت وحدة Tickets موجودة.
- تصعيد الحالة.
- متابعة نتيجة البلاغ.
- إرشاد المستخدم إلى الإجراء المطلوب.

### لا يستطيع

- Ban أو Delete دون صلاحية خاصة.
- الموافقة على توثيق.
- الوصول المفتوح إلى رسائل المحادثات.
- تعديل صلاحيات الموظفين.
- الاطلاع على مستندات حساسة.

## 8.7 Marketing Manager

**العدد المقترح:** 1 إلى 2.

### يرى

- بيانات أداء المحتوى.
- الأقسام المسموح بها.
- الحملات.
- نتائج الإشعارات.
- البنرات والمحتوى.

### يستطيع

- إنشاء حملة.
- تحرير المحتوى.
- تجهيز إشعار.
- جدولة حملة.
- طلب موافقة أو إرسال ضمن حدود الصلاحية.

### لا يستطيع

- حظر مستخدم.
- اعتماد توثيق.
- تعديل RBAC.
- الوصول إلى مستندات الهوية.
- إرسال حملة عامة إذا كانت تحتاج موافقة ولم يحصل عليها.

## 8.8 Analyst

**العدد المقترح:** 1 إلى 3.

### يرى

- Analytics.
- Aggregated Reports.
- مؤشرات الأقسام والمدن.
- اتجاهات الاستخدام.
- تقارير المراجعة.

### يستطيع

- إنشاء تقارير.
- تطبيق Filters.
- تصدير بيانات مجمعة عند السماح.

### لا يستطيع

- تعديل بيانات المستخدمين.
- الموافقة على الإعلانات.
- تغيير إعدادات النظام.
- عرض بيانات شخصية غير لازمة.
- الوصول إلى مستندات أو محتوى محادثات.

## 8.9 Security Auditor

**العدد المقترح:** 1 أو أكثر حسب سياسة الشركة.

### يرى

- Audit Logs.
- Admin Login Events.
- Role/Permission Changes.
- Sensitive Actions.
- Security alerts.
- سياسات الوصول.

### يستطيع

- البحث والمراجعة.
- تصدير سجل تدقيق وفق تصريح.
- إضافة ملاحظة مراجعة.
- تصعيد حادث أمني.

### لا يستطيع

- تعديل السجلات.
- تنفيذ إجراءات المستخدمين بشكل افتراضي.
- تعديل صلاحياته.
- حذف الأدلة.

---

# 9. مصفوفة الصلاحيات

الرموز:

- **F** = Full access داخل حدود سياسة الوحدة.
- **R** = Read.
- **W** = Write/Update.
- **A** = Approve/Reject.
- **L** = Limited access.
- **—** = لا يوجد وصول افتراضي.
- **C** = Create/Manage.

| الوحدة | Super Admin | Platform Admin | Operations | Moderator | Verification | Support | Marketing | Analyst | Auditor |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Overview | F | R | R | L | L | L | L | R | L |
| Users | F | W | R | L | L | L | — | — | R* |
| Listings | F | W | W | A | — | R | — | R* | R* |
| Categories | F | W | R | R | — | — | R | R | R* |
| Reports | F | W | W | A | — | L | — | R* | R* |
| Verification | F | R | L | — | A | L | — | — | R* |
| Messaging complaints | F | L | L | L | — | L | — | — | R* |
| Notifications | F | W | L | — | — | — | C | R* | R* |
| CMS | F | W | R | — | — | — | C | R* | R* |
| Analytics | F | R | R | L | L | L | R | R | R* |
| Admin accounts | F | L | — | — | — | — | — | — | R* |
| Roles/Permissions | F | — | — | — | — | — | — | — | R* |
| Audit Logs | F | R | L | L | L | — | — | — | R |
| System Health | F | L | R | — | — | — | — | — | R* |
| Feature Flags | F | L | — | — | — | — | — | — | R* |
| Platform Settings | F | W | L | — | — | — | L | — | R* |

`R*` يعني قراءة محدودة أو منقحة، لا تعني الوصول لكل البيانات الخام أو الشخصية.

هذه المصفوفة نقطة انطلاق. يجب تحويلها إلى Permissions دقيقة لكل عملية، ثم مراجعتها أمنياً واعتمادها من مالك المنتج.

---

# 10. مصفوفة التحكم في البيانات

| البيانات | Support | Moderator | Verification | Analyst | Auditor | Super Admin |
|---|---|---|---|---|---|---|
| الاسم الظاهر | نعم | نعم عند الحاجة | نعم | مجمع/مخفي | عند الحاجة | حسب الصلاحية |
| رقم الهاتف | محدود | لا افتراضياً | حسب الحاجة | لا | لا افتراضياً | حسب الصلاحية |
| البريد | محدود | لا افتراضياً | حسب الحاجة | لا | لا افتراضياً | حسب الصلاحية |
| الإعلانات | نعم | نعم | لا افتراضياً | مجمع | سجل القرار | نعم |
| بلاغات المستخدم | محدود | نعم | لا | مجمع | سجل التدقيق | نعم |
| مستندات الهوية | لا | لا | نعم | لا | بيانات الوصول فقط | وصول استثنائي مسجل |
| محتوى المحادثات | لا افتراضياً | لا افتراضياً | لا | لا | لا | وصول استثنائي وفق سياسة |
| Tokens/Passwords | ممنوع | ممنوع | ممنوع | ممنوع | ممنوع | ممنوع |
| Audit Logs | لا | محدود | محدود | محدود | نعم | نعم |

---

# 11. الصلاحيات التقنية المقترحة

يجب أن تكون الصلاحيات granular وليست مجرد أسماء Roles.

## Authentication

- `admin_auth.login`
- `admin_auth.logout`
- `admin_auth.sessions.read`
- `admin_auth.sessions.revoke`
- `admin_auth.mfa.manage`

## Users

- `users.read`
- `users.read_contact`
- `users.read_sensitive`
- `users.update`
- `users.suspend`
- `users.unsuspend`
- `users.ban`
- `users.unban`
- `users.add_note`
- `users.export`

## Listings

- `listings.read`
- `listings.read_owner`
- `listings.approve`
- `listings.reject`
- `listings.request_changes`
- `listings.hide`
- `listings.restore`
- `listings.archive`
- `listings.delete`
- `listings.bulk_moderate`
- `listings.export`

## Categories

- `categories.read`
- `categories.create`
- `categories.update`
- `categories.reorder`
- `categories.activate`
- `categories.deactivate`
- `categories.attributes.manage`

## Reports

- `reports.read`
- `reports.assign`
- `reports.note.add`
- `reports.resolve`
- `reports.reject`
- `reports.escalate`
- `reports.reopen`

## Verification

- `verification.read`
- `verification.documents.read`
- `verification.assign`
- `verification.approve`
- `verification.reject`
- `verification.request_resubmission`
- `verification.revoke`

## Notifications

- `notifications.read`
- `notifications.create`
- `notifications.schedule`
- `notifications.send`
- `notifications.approve`
- `notifications.cancel`
- `notifications.analytics.read`

## CMS

- `cms.read`
- `cms.create`
- `cms.update`
- `cms.publish`
- `cms.schedule`
- `cms.unpublish`
- `cms.archive`
- `cms.media.manage`

## Analytics

- `analytics.read`
- `analytics.export`
- `analytics.sensitive.read`

## Admin Accounts & RBAC

- `admins.read`
- `admins.invite`
- `admins.update`
- `admins.disable`
- `admins.suspend`
- `admins.sessions.revoke`
- `admins.roles.assign`
- `admins.activity.read`
- `roles.read`
- `roles.create`
- `roles.update`
- `roles.delete`
- `roles.permissions.manage`

## Audit & System

- `audit_logs.read`
- `audit_logs.export`
- `system_health.read`
- `system_health.logs.read`
- `system_health.alerts.acknowledge`
- `feature_flags.read`
- `feature_flags.update`
- `settings.read`
- `settings.update`
- `settings.sensitive.update`

---

# 12. دورة العمل بين الوحدات (End-to-End Workflows)

## 12.1 نشر ومراجعة إعلان

1. المستخدم ينشئ إعلاناً من Flutter.
2. Flutter يرسل البيانات إلى Backend.
3. Backend يتحقق من البيانات والقسم والصلاحيات.
4. الإعلان يدخل الحالة المناسبة للمراجعة وفق سياسة النشر.
5. Overview يحدث مؤشرات المراجعة.
6. Listings تعرض الإعلان للمراجع.
7. Moderator يراجع البيانات والصور.
8. Backend يتحقق من `listings.approve` أو `listings.reject`.
9. Backend يغير الحالة ويسجل القرار.
10. Audit يسجل الموظف والقرار والسبب.
11. Notifications ترسل نتيجة للمستخدم إذا كانت الخدمة مفعلة.
12. Flutter يعرض الحالة الجديدة من API.
13. Analytics يسجل الانتقال.

## 12.2 بلاغ على إعلان

1. المستخدم يرسل بلاغاً.
2. Backend يتحقق من Report Reason والبيانات.
3. البلاغ يظهر في Reports.
4. Operations يوزعه أو يتم إسناده آلياً.
5. Moderator يفتح البلاغ والإعلان المرتبط.
6. يراجع الأدلة وسجل الإعلان.
7. يتخذ قراراً ضمن صلاحياته.
8. Backend ينفذ الإجراء على الإعلان أو الحساب عند الحاجة.
9. Audit يسجل القرار.
10. Notification تخطر الأطراف وفق السياسة.
11. Analytics تحدث مؤشرات البلاغات.

## 12.3 توثيق حساب

1. المستخدم يقدم طلب توثيق.
2. Backend يحفظ الطلب والمستندات بأمان.
3. Verification تعرض الطلب.
4. يتم إسناده لمراجع.
5. المراجع يفحص المستندات.
6. يوافق أو يرفض أو يطلب استكمالاً.
7. Backend يتحقق من Permission ومن صلاحية الحالة الحالية.
8. Backend يحدث حالة التوثيق.
9. يتم تسجيل القرار.
10. Flutter يعرض حالة التوثيق الجديدة.

## 12.4 إنشاء موظف إداري

1. Super Admin أو المسؤول المخول يفتح Admin Accounts.
2. يدخل بيانات الموظف.
3. يختار Role مع Preview للصلاحيات.
4. Backend يتحقق من `admins.invite`.
5. يتم إرسال دعوة آمنة.
6. الموظف ينشئ بيانات الدخول وMFA.
7. الحساب يصبح Active بعد إتمام شروط التفعيل.
8. Audit يسجل الدعوة والتفعيل وتعيين الدور.

## 12.5 إرسال إشعار جماعي

1. Marketing ينشئ Campaign.
2. يحدد الجمهور والمحتوى واللغة.
3. النظام يعرض العدد المتوقع للمستلمين.
4. يتم فحص المحتوى والحدود.
5. إذا تطلبت السياسة موافقة، يراجعها موظف مخول.
6. Backend ينشئ Job آمنة وIdempotent.
7. Queue ترسل الإشعارات بمعدل مضبوط.
8. Dashboard تعرض الإرسال والفشل.
9. Audit يسجل من أنشأ ومن وافق ومن أرسل.

---

# 13. نموذج حالات العمليات

كل وحدة تحتاج State Machine واضحة في Backend.

## 13.1 Account

مثال مرشح:

`ACTIVE → SUSPENDED → ACTIVE`

`ACTIVE → BANNED`

`ACTIVE → DEACTIVATED`

الانتقالات المسموحة وأثرها على الجلسات والإعلانات يجب تعريفها مركزياً.

## 13.2 Listing

مثال مرشح:

`DRAFT → PENDING_REVIEW → PUBLISHED`

`PENDING_REVIEW → REJECTED`

`PUBLISHED → HIDDEN`

`PUBLISHED → EXPIRED`

`HIDDEN → PUBLISHED` بعد مراجعة مخولة.

## 13.3 Report

`SUBMITTED → ASSIGNED → UNDER_REVIEW → RESOLVED`

أو:

`SUBMITTED → REJECTED`

`UNDER_REVIEW → ESCALATED`

## 13.4 Verification

`SUBMITTED → UNDER_REVIEW → APPROVED`

`UNDER_REVIEW → REJECTED`

`UNDER_REVIEW → NEEDS_RESUBMISSION`

هذه الحالات أمثلة تصميمية، وليست وصفاً للحالات الموجودة فعلياً. يجب توحيدها مع الـ Enums وBusiness Rules الحالية.

---

# 14. API Integration Specification

Base URL الحالية التي قدمها مالك المشروع:

`https://one-deal-cjjt-production.up.railway.app/api/v1`

يجب التحقق من أن الخدمة مستقرة وأن الـ API contract الحالي يطابق هذه البيئة قبل الربط.

## 14.1 Endpoint Groups المقترحة

| Group | أمثلة مسارات مقترحة |
|---|---|
| Overview | `GET /admin/overview` |
| Users | `GET /admin/users`, `GET /admin/users/:id` |
| User actions | `PATCH /admin/users/:id/status` |
| Listings | `GET /admin/listings`, `GET /admin/listings/:id` |
| Listing decisions | `POST /admin/listings/:id/approve` |
| Reports | `GET /admin/reports`, `POST /admin/reports/:id/resolve` |
| Categories | `GET /admin/categories`, `POST /admin/categories` |
| Verification | `GET /admin/verification`, `POST /admin/verification/:id/approve` |
| Notifications | `GET /admin/notifications`, `POST /admin/notifications` |
| CMS | `GET /admin/cms`, `POST /admin/cms` |
| Analytics | `GET /admin/analytics` |
| Admin accounts | `GET /admin/admins`, `POST /admin/admins/invitations` |
| Roles | `GET /admin/roles`, `POST /admin/roles` |
| Permissions | `GET /admin/permissions` |
| Audit | `GET /admin/audit-logs` |
| Health | `GET /admin/system/health` |

**هذه مسارات مقترحة فقط.** قبل إنشائها يجب مراجعة Controllers وSwagger والـ existing routes. إذا كانت الوظيفة موجودة بمسار مختلف، يستخدم المسار الموجود أو يتم تطويره دون تكرار.

## 14.2 Contract Requirements

كل API يجب أن توثق:

- Method.
- Path.
- Authentication requirement.
- Permission requirement.
- Query parameters.
- Request DTO.
- Response DTO.
- Error cases.
- Pagination.
- Rate limits.
- Audit requirements.
- Side effects.
- Idempotency requirements.

## 14.3 Pagination

يجب أن تكون Server-side، مع حدود للـ page size. لا يتم تحميل جميع المستخدمين أو الإعلانات إلى المتصفح.

## 14.4 Error Handling

توحيد عرض أخطاء:
- Unauthorized.
- Forbidden.
- Not found.
- Validation error.
- Conflict.
- Rate limited.
- Internal server error.

لا تعرض Stack traces أو Secrets أو تفاصيل قاعدة البيانات للمستخدم.

---

# 15. Database Design — قواعد قبل إضافة الجداول

يتم فحص Prisma Schema أولاً. الجداول التالية مرشحة وليست إلزامية:

- AdminUser.
- AdminRole.
- AdminPermission.
- AdminRolePermission.
- AdminUserRole.
- AdminSession.
- AdminMfaMethod.
- AdminAuditLog.
- AdminLoginAttempt.
- ModerationAssignment.
- AdminInvitation.
- FeatureFlag.
- NotificationCampaign.
- CmsContent / CmsRevision.

قد توجد نماذج مشابهة بالفعل. لا تضف نسخة ثانية منها.

## 15.1 متطلبات عامة

- Primary keys واضحة.
- Foreign keys عند الحاجة.
- Unique constraints.
- Indexes مبنية على الاستعلامات.
- CreatedAt/UpdatedAt.
- Actor metadata للعمليات الإدارية.
- Soft deletion حيث يلزم.
- Transactions للعمليات المركبة.
- Retention policies للبيانات الحساسة.
- Migration review قبل الإنتاج.

## 15.2 Data ownership

- User data يظل تابعاً لوحدة Users.
- Listing data يظل تابعاً لوحدة Listings.
- Admin identity مستقلة عن Marketplace User عند الحاجة.
- Audit events لا تكون قابلة للتعديل من موظفي الإدارة.
- لا يتم نسخ مستندات الهوية أو بيانات المستخدمين في جداول غير لازمة.

---

# 16. Frontend Architecture

الاقتراح المبدئي: Next.js + TypeScript + Tailwind + shadcn/ui.

```text
deal-one-admin/
├── src/
│   ├── app/
│   │   ├── (auth)/
│   │   └── (dashboard)/
│   ├── features/
│   │   ├── authentication/
│   │   ├── overview/
│   │   ├── users/
│   │   ├── listings/
│   │   ├── moderation/
│   │   ├── categories/
│   │   ├── verification/
│   │   ├── notifications/
│   │   ├── cms/
│   │   ├── analytics/
│   │   ├── admins/
│   │   ├── roles/
│   │   ├── audit-logs/
│   │   └── system-health/
│   ├── components/
│   ├── core/
│   │   ├── api/
│   │   ├── auth/
│   │   ├── permissions/
│   │   ├── errors/
│   │   ├── security/
│   │   ├── query/
│   │   └── i18n/
│   ├── hooks/
│   ├── schemas/
│   ├── types/
│   └── styles/
├── tests/
├── e2e/
└── docs/
```

## 16.1 API Client

مركزي ويحتوي على:
- Typed requests.
- Secure session handling.
- Error normalization.
- Timeout.
- Cancellation.
- Query serialization.
- Pagination helpers.
- Contract validation حسب الحاجة.

## 16.2 State Management

- TanStack Query لبيانات Backend وCache.
- React local state لتفاعلات الواجهة المحلية.
- لا تكرر Server State داخل Global Store دون سبب.
- تحديث Cache بعد عمليات الموافقة أو الرفض أو الحظر.

## 16.3 Design System

- Design tokens.
- RTL/LTR.
- Dark/Light.
- Typography واضحة.
- Responsive breakpoints.
- Accessible contrast.
- Consistent form controls.
- Tables and filters.
- Empty/loading/error states.

---

# 17. تأثير التغييرات على Flutter

أي تغيير إداري قد يؤثر على تطبيق Flutter، ولذلك يجب فحص الآثار التالية:

| التغيير | أثره على Flutter |
|---|---|
| تعليق حساب | منع العمليات غير المسموحة وإظهار حالة مفهومة |
| حظر حساب | منع الدخول/النشر وفق سياسة Backend |
| اعتماد إعلان | تحديث حالة الإعلان وظهوره |
| رفض إعلان | إظهار سبب الرفض للمستخدم إذا كانت السياسة تسمح |
| تغيير Category | تحديث نموذج إنشاء الإعلان والفلاتر |
| تغيير Attribute | توافق بيانات الإعلانات القديمة والجديدة |
| توثيق الحساب | تحديث علامة وحالة التوثيق |
| نشر Banner | ظهور المحتوى الجديد |
| Feature Flag | تغيير سلوك الميزة وفق التوافق |
| Maintenance | عرض رسالة صيانة أو منع عمليات محددة |

لا يجوز تغيير Response contract مستخدم في Flutter دون:
- تحليل كل المستهلكين.
- الحفاظ على backward compatibility أو versioning.
- اختبارات contract.
- اختبار التطبيق المتأثر.

---

# 18. Security & Privacy Requirements

## 18.1 Authorization

- Deny by default.
- Backend guard على كل عملية.
- Permission مستقل للبيانات الحساسة.
- Scope محدود للموظف عند الحاجة.
- منع privilege escalation.
- فصل المهام المتعارضة.

## 18.2 Sessions

- Secure HttpOnly cookies أو تصميم جلسة موثق.
- CSRF protection إذا كانت Cookies تستخدم للمصادقة.
- Session expiry.
- Session revocation.
- Rotation.
- MFA.
- Re-authentication للعمليات الحساسة.

## 18.3 Sensitive Data

لا يتم تخزين أو عرض:
- Passwords.
- OTP values.
- Access/refresh tokens.
- API secrets.
- Database credentials.
- Private keys.
- MFA recovery secrets بصورتها القابلة للقراءة.

## 18.4 Audit

كل عملية حساسة تسجل:
- Actor.
- Action.
- Target.
- Time.
- Outcome.
- Reason.
- Request ID.
- Relevant diff مع تنقيح البيانات.

## 18.5 Data minimization

كل موظف يرى أقل قدر من البيانات يكفي لإنجاز مهمته.

---

# 19. Non-functional Requirements

## Performance

- Server-side pagination.
- Indexed filtering.
- Aggregated analytics.
- Query timeouts.
- Cache where useful.
- Lazy loading.
- Avoid N+1 queries.
- Background processing for large tasks.

## Reliability

- Graceful error states.
- Retry only safe/idempotent requests.
- Transaction safety.
- Queue retry/dead-letter strategy إذا كان النظام يستخدم queues.
- Backup and restore procedures.
- Rollback plan.

## Scalability

الهدف التصميمي دعم نمو المنصة إلى ملايين الإعلانات، لكن القابلية الفعلية يجب إثباتها بـ Load Tests وQuery Profiling وقياس الموارد.

## Accessibility

- Keyboard navigation.
- Visible focus.
- Accessible labels.
- Contrast.
- Screen-reader-friendly controls.

## Localization

- Arabic RTL.
- English LTR.
- Localized dates/numbers.
- Currency formatting.
- Translation fallback.

---

# 20. Testing Strategy

## Unit Tests

- Permission evaluation.
- DTO validation.
- Business rules.
- State transitions.
- Utility functions.

## Integration Tests

- Admin authentication.
- RBAC guards.
- Listing approval/rejection.
- User suspension.
- Report resolution.
- Verification decisions.
- Audit creation.
- Notification campaign creation.

## API Contract Tests

- Request schema.
- Response schema.
- Error contract.
- Pagination.
- Backward compatibility مع Flutter.

## E2E Tests

- Admin login.
- MFA.
- Moderator reviews listing.
- Support views permitted user data.
- Verification Officer approves a request.
- Marketing creates campaign.
- Super Admin creates role.
- Unauthorized employee is denied.
- Disabled admin loses access.

## Security Tests

- IDOR.
- Privilege escalation.
- CSRF.
- XSS.
- Brute force.
- Session fixation/reuse.
- Unauthorized export.
- Sensitive data leakage.

## Load Tests

- Large paginated lists.
- Filter combinations.
- Dashboard aggregations.
- Concurrent moderation.
- Bulk notification jobs.
- Audit queries.

---

# 21. خطة التنفيذ ومخرجات كل مرحلة

| Phase | العمل | المخرجات | شرط الإغلاق |
|---|---|---|---|
| 00 | Backend Discovery | Audit + API Matrix | فهم الموجود والناقص |
| 01 | Frontend Foundation | Next.js skeleton + design system | Build/Lint/Tests PASS |
| 02 | Authentication + RBAC | Secure admin access | Permission tests PASS |
| 03 | Core Operations | Overview, Users, Listings, Categories, Reports | Real API + E2E |
| 04 | Trust & Communication | Verification, Notifications, CMS, Support | Workflows tested |
| 05 | Analytics | Reports and aggregates | Metrics validated |
| 06 | System Control | Audit, Health, Flags, Settings | Security review |
| 07 | QA | Full test report | No critical unresolved defects |
| 08 | Production | Deployment + Monitoring | GO decision |

## 21.1 Phase 00 إلزامية

لا يبدأ Agent بكتابة جميع الواجهات قبل:
- فحص Backend.
- فحص قاعدة البيانات.
- فحص Swagger.
- فحص Authentication.
- فحص حالة Production.
- إعداد Gap Analysis.
- تحديد تأثير التعديلات على Flutter.

---

# 22. Definition of Done

لا تعتبر أي وحدة مكتملة إلا إذا تحقق التالي:

1. Business purpose موثق.
2. Data inputs/outputs موثقة.
3. API contract محدد.
4. Backend authorization مطبق.
5. UI تعمل ببيانات حقيقية.
6. Loading/empty/error states موجودة.
7. Validation موجودة.
8. Audit logging موجود للعمليات المؤثرة.
9. Unit tests ناجحة.
10. Integration tests ناجحة.
11. E2E tests مناسبة ناجحة.
12. Flutter compatibility تم فحصها إذا تأثرت.
13. Responsive وRTL/LTR تم اختبارهما.
14. لا توجد Secrets في الواجهة أو المستودع.
15. Documentation محدثة.

---

# 23. المخاطر والقرارات التي تحتاج اعتماداً

| القرار/المخاطرة | المطلوب قبل التنفيذ |
|---|---|
| معنى `account.verified` | تحديد نوع التوثيق ومعاييره ومصدره |
| صلاحيات قراءة الهاتف والبريد | اعتماد سياسة خصوصية |
| الوصول للمحادثات | تحديد سياسة الوصول والتدقيق |
| حالات حظر المستخدم | تعريف أثر كل حالة على التطبيق |
| Listing lifecycle | توحيد الحالات مع Backend |
| Category attributes | خطة توافق للإعلانات القديمة |
| Admin identity | مراجعة نظام الحسابات الحالي |
| MFA | تحديد مزود وآلية الاستعادة |
| Notification approval | تحديد من ينشئ ومن يعتمد ومن يرسل |
| Audit retention | سياسة الاحتفاظ والحماية |
| Data export | تحديد البيانات والموظفين المصرح لهم |
| Analytics definitions | تعريف رسمي لكل مؤشر |
| Production stability | إثبات استقرار Backend قبل ربط الإدارة |
| Data residency/retention | مراجعة المتطلبات القانونية والتشغيلية |

---

# 24. قائمة المخرجات المطلوبة من فريق التنفيذ

## Documentation

- Backend Discovery Report.
- Existing API Inventory.
- Admin Feature Gap Analysis.
- Admin Architecture.
- RBAC Matrix.
- Data Access Matrix.
- Workflow Diagrams.
- API Contracts.
- Database Changes.
- Security Threat Model.
- Test Plan.
- Deployment Runbook.
- Rollback Plan.
- User/Admin Operating Guide.

## Source Code

- Independent Admin Web application.
- Admin API modules أو extensions المطلوبة فقط.
- RBAC implementation.
- Audit logging.
- Tests.
- CI checks.
- Environment example.
- Deployment configuration.

## Reports

كل Phase يجب أن ينتج:
- What was implemented.
- Files changed.
- APIs added/changed.
- Database migrations.
- Tests executed and exact results.
- Security findings.
- Known limitations.
- GO/NO-GO.

---

# 25. تعليمات مباشرة للـ AI Agent

تعامل مع هذه الوثيقة كـ Product/System Specification مرجعية.

ابدأ بـ Phase 00 فقط.

1. اقرأ الوثيقة بالكامل.
2. اقرأ وثائق Backend الحالية.
3. افحص جميع Modules وControllers وServices وPrisma models.
4. قارن كل Feature بما هو موجود بالفعل.
5. لا تنشئ تكراراً.
6. لا تعدل Production.
7. لا تحذف أو تستبدل وظائف.
8. لا تعتبر المسارات المقترحة مسارات موجودة.
9. لا تستخدم Mock Data كدليل على التنفيذ.
10. جهز تقريراً مفصلاً بالملفات والأدلة والاختبارات.
11. حدد القرارات التي تحتاج موافقة مالك المشروع.
12. توقف بعد Phase 00 وانتظر مراجعة التقرير قبل بدء التنفيذ.

**معيار النجاح:** أن تصبح هذه الوثيقة قابلة للتحويل إلى مهام تنفيذ دقيقة، وأن يكون كل قرار متعلق بالبيانات أو الصلاحيات أو تأثير Flutter أو Production مبنياً على فحص حقيقي للمشروع.

---

# 26. الخلاصة التنفيذية

Deal One Admin ليست مجرد صفحة تحكم، بل طبقة تشغيل وإدارة وحوكمة للمنصة.

العلاقات الأساسية:

- Authentication يحدد من يدخل.
- RBAC يحدد ما الذي يمكنه فعله.
- Users يدير الحسابات.
- Listings يدير المحتوى التجاري.
- Categories تنظم البيانات ونماذج النشر والبحث.
- Moderation يعالج المخالفات والبلاغات.
- Verification يدعم الثقة.
- Notifications وCMS يديران التواصل والمحتوى.
- Analytics تساعد الإدارة على اتخاذ القرار.
- Audit Logs تحفظ المساءلة.
- System Health يراقب الخدمات.
- Settings وFeature Flags يتحكمان في سلوك المنصة.

كل هذه الوحدات تعتمد على Backend واحد موثوق، وعقود API واضحة، وصلاحيات مركزية، وسجلات قابلة للمراجعة.

**الخطوة الأولى المعتمدة: Backend Discovery — ثم اعتماد Gap Analysis قبل أي تنفيذ واسع.**
"""

out = "/mnt/data/Deal_One_Enterprise_Admin_System_Specification.md"
pypandoc.convert_text(md, "md", format="md", outputfile=out, extra_args=["--standalone"])
print(out, os.path.getsize(out))
