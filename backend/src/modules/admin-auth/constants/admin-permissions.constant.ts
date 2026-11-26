export interface PermissionCatalogItem {
  key: string;
  module: string;
  labelEn: string;
  labelAr: string;
  descriptionEn: string;
  descriptionAr: string;
  isSensitive?: boolean;
}

export const ADMIN_PERMISSION_CATALOG: PermissionCatalogItem[] = [
  // Overview & Analytics
  {
    key: 'analytics.read',
    module: 'analytics',
    labelEn: 'Read Dashboard & Analytics',
    labelAr: 'قراءة التحليلات ولوحة المعلومات',
    descriptionEn: 'View KPI overview, charts, and aggregated analytics',
    descriptionAr: 'عرض مؤشرات الأداء والرسوم البيانية والتحليلات المجمعة',
  },
  {
    key: 'analytics.export',
    module: 'analytics',
    labelEn: 'Export Analytics Reports',
    labelAr: 'تصدير تقارير التحليلات',
    descriptionEn: 'Export aggregated analytics CSV/JSON reports',
    descriptionAr: 'تصدير تقارير التحليلات بصيغة CSV/JSON',
    isSensitive: true,
  },

  // Users & Seller Accounts
  {
    key: 'users.read',
    module: 'users',
    labelEn: 'Read Users & Accounts',
    labelAr: 'عرض المستخدمين والحسابات',
    descriptionEn: 'View marketplace users and seller accounts',
    descriptionAr: 'استعراض حسابات المستخدمين والتجار',
  },
  {
    key: 'users.update',
    module: 'users',
    labelEn: 'Update Users & Add Notes',
    labelAr: 'تعديل المستخدمين وإضافة الملاحظات',
    descriptionEn:
      'Edit user metadata, seller account status, and add internal notes',
    descriptionAr: 'تعديل بيانات المستخدم وحالة الحساب وإضافة ملاحظات داخلية',
  },
  {
    key: 'users.suspend',
    module: 'users',
    labelEn: 'Suspend / Unsuspend Users',
    labelAr: 'تعليق ورفع تعليق المستخدمين',
    descriptionEn:
      'Temporarily suspend or unsuspend marketplace users and revoke sessions',
    descriptionAr: 'تعليق حساب المستخدم مؤقتاً أو رفع التعليق وإبطال الجلسات',
    isSensitive: true,
  },
  {
    key: 'users.ban',
    module: 'users',
    labelEn: 'Ban / Unban Users',
    labelAr: 'حظر وفك حظر المستخدمين',
    descriptionEn: 'Permanently ban or unban marketplace users',
    descriptionAr: 'حظر المستخدم نهائياً أو فك الحظر',
    isSensitive: true,
  },

  // Listings
  {
    key: 'listings.read',
    module: 'listings',
    labelEn: 'Read Listings',
    labelAr: 'عرض الإعلانات',
    descriptionEn:
      'View all listings regardless of moderation or publication status',
    descriptionAr: 'استعراض كافة الإعلانات بجميع حالاتها',
  },
  {
    key: 'listings.approve',
    module: 'listings',
    labelEn: 'Approve & Restore Listings',
    labelAr: 'اعتماد واستعادة الإعلانات',
    descriptionEn:
      'Approve pending listings and restore hidden/archived listings',
    descriptionAr: 'الموافقة على الإعلانات قيد المراجعة واستعادة المخفية',
  },
  {
    key: 'listings.reject',
    module: 'listings',
    labelEn: 'Reject & Request Listing Changes',
    labelAr: 'رفض الإعلانات وطلب التعديل',
    descriptionEn:
      'Reject non-compliant listings or request modifications from owners',
    descriptionAr: 'رفض الإعلانات المخالفة أو طلب تعديلات من الناشر',
  },
  {
    key: 'listings.hide',
    module: 'listings',
    labelEn: 'Hide / Archive Listings',
    labelAr: 'إخفاء وأرشفة الإعلانات',
    descriptionEn: 'Hide or archive published listings from marketplace search',
    descriptionAr: 'إخفاء أو أرشفة الإعلانات من الظهور في التطبيق',
  },
  {
    key: 'listings.delete',
    module: 'listings',
    labelEn: 'Delete Listings',
    labelAr: 'حذف الإعلانات',
    descriptionEn: 'Soft-delete listings from the platform',
    descriptionAr: 'حذف الإعلانات بشكل منطقي من المنصة',
    isSensitive: true,
  },

  // Categories
  {
    key: 'categories.read',
    module: 'categories',
    labelEn: 'Read Categories & Attributes',
    labelAr: 'عرض الأقسام والخصائص',
    descriptionEn:
      'View active and inactive categories, subcategories, and dynamic fields',
    descriptionAr: 'عرض الأقسام الرئيسية والفرعية والحقول الديناميكية',
  },
  {
    key: 'categories.create',
    module: 'categories',
    labelEn: 'Create Categories',
    labelAr: 'إنشاء الأقسام',
    descriptionEn: 'Create new root categories and subcategories',
    descriptionAr: 'إنشاء أقسام رئيسية وفرعية جديدة',
  },
  {
    key: 'categories.update',
    module: 'categories',
    labelEn: 'Update Categories & Fields',
    labelAr: 'تعديل الأقسام والخصائص',
    descriptionEn:
      'Edit categories, reorder display order, and configure dynamic attributes',
    descriptionAr: 'تعديل الأقسام وإعادة الترتيب وضبط الحقول الديناميكية',
  },
  {
    key: 'categories.delete',
    module: 'categories',
    labelEn: 'Deactivate / Delete Categories',
    labelAr: 'حذف وتعطيل الأقسام',
    descriptionEn: 'Deactivate or remove unused categories and fields',
    descriptionAr: 'تعطيل أو حذف الأقسام والحقول غير المستخدمة',
    isSensitive: true,
  },

  // Reports & Moderation
  {
    key: 'reports.read',
    module: 'reports',
    labelEn: 'Read Reports & Moderation Logs',
    labelAr: 'عرض البلاغات وسجل المراجعة',
    descriptionEn: 'View abuse reports queue and moderation log history',
    descriptionAr: 'استعراض قائمة البلاغات وسجل قرارات المراجعة',
  },
  {
    key: 'reports.assign',
    module: 'reports',
    labelEn: 'Assign & Prioritize Reports',
    labelAr: 'إسناد وتحديد أولوية البلاغات',
    descriptionEn: 'Assign reports to moderators and update priority levels',
    descriptionAr: 'توزيع البلاغات على المراجعين وتحديد الأولوية',
  },
  {
    key: 'reports.resolve',
    module: 'reports',
    labelEn: 'Resolve / Dismiss / Escalate Reports',
    labelAr: 'حسم وتصعيد البلاغات',
    descriptionEn: 'Resolve, dismiss, escalate reports, and add internal notes',
    descriptionAr: 'حل البلاغات أو رفضها أو تصعيدها وإضافة ملاحظات',
  },

  // Verification
  {
    key: 'verification.read',
    module: 'verification',
    labelEn: 'Read Verification Requests',
    labelAr: 'عرض طلبات التوثيق',
    descriptionEn: 'View seller account verification queue and metadata',
    descriptionAr: 'عرض طلبات توثيق الحسابات وحالتها',
  },
  {
    key: 'verification.documents.read',
    module: 'verification',
    labelEn: 'View Sensitive Verification Documents',
    labelAr: 'الاطلاع على مستندات التوثيق الحساسة',
    descriptionEn:
      'Audited access to view identity and commercial registration files',
    descriptionAr: 'صلاحية مسجلة للاطلاع على ملفات الهوية والسجل التجاري',
    isSensitive: true,
  },
  {
    key: 'verification.approve',
    module: 'verification',
    labelEn: 'Approve & Assign Verifications',
    labelAr: 'اعتماد وتوزيع التوثيق',
    descriptionEn: 'Approve verification submissions and assign reviewers',
    descriptionAr: 'اعتماد طلبات التوثيق وإسناد المراجعين',
  },
  {
    key: 'verification.reject',
    module: 'verification',
    labelEn: 'Reject / Request Verification Resubmission',
    labelAr: 'رفض أو طلب إعادة تقديم التوثيق',
    descriptionEn:
      'Reject verification requests or request document resubmission',
    descriptionAr: 'رفض طلبات التوثيق أو طلب استكمال المستندات',
  },
  {
    key: 'verification.requirements.manage',
    module: 'verification',
    labelEn: 'Manage Seller Verification Requirements',
    labelAr: 'إدارة متطلبات توثيق البائعين',
    descriptionEn:
      'Create, update, version, and deactivate configurable seller verification document requirements',
    descriptionAr: 'إنشاء وتعديل وإصدار وتعطيل متطلبات مستندات توثيق البائعين',
    isSensitive: true,
  },

  // Messaging Oversight
  {
    key: 'messaging.complaints.read',
    module: 'messaging',
    labelEn: 'Read Messaging Complaints',
    labelAr: 'عرض شكاوى المحادثات',
    descriptionEn:
      'View conversation complaints and technical delivery summaries',
    descriptionAr: 'عرض شكاوى المحادثات وحالة التسليم التقنية',
  },
  {
    key: 'chat.oversight.read',
    module: 'messaging',
    labelEn: 'Audited Conversation Inspection',
    labelAr: 'فحص محتوى المحادثات المبلغ عنها',
    descriptionEn:
      'Audited limited access to messages in complained conversations',
    descriptionAr: 'وصول مقيد ومسجل لرسائل المحادثات المرتبطة بشكاوى',
    isSensitive: true,
  },
  {
    key: 'messaging.support.resolve',
    module: 'messaging',
    labelEn: 'Resolve & Escalate Messaging Cases',
    labelAr: 'حل وتصعيد شكاوى المحادثات',
    descriptionEn:
      'Update conversation status or escalate messaging support cases',
    descriptionAr: 'تحديث حالة المحادثة أو تصعيد تذكرة الدعم',
  },

  // Notifications
  {
    key: 'notifications.read',
    module: 'notifications',
    labelEn: 'Read Notification Campaigns',
    labelAr: 'عرض حملات الإشعارات',
    descriptionEn:
      'View campaigns, audience estimates, and delivery statistics',
    descriptionAr: 'عرض حملات الإشعارات وإحصائيات التسليم',
  },
  {
    key: 'notifications.create',
    module: 'notifications',
    labelEn: 'Create & Schedule Campaigns',
    labelAr: 'إنشاء وجدولة الحملات',
    descriptionEn: 'Create notification campaigns and schedule delivery',
    descriptionAr: 'إنشاء حملات إشعارات وجدولتها',
  },
  {
    key: 'notifications.approve',
    module: 'notifications',
    labelEn: 'Approve Notification Campaigns',
    labelAr: 'اعتماد حملات الإشعارات',
    descriptionEn: 'Approve pending notification campaigns for sending',
    descriptionAr: 'اعتماد حملات الإشعارات قبل الإرسال',
  },
  {
    key: 'notifications.send',
    module: 'notifications',
    labelEn: 'Send Notification Campaigns',
    labelAr: 'إرسال حملات الإشعارات',
    descriptionEn: 'Dispatch approved push and in-app notification campaigns',
    descriptionAr: 'إطلاق حملات الإشعارات المعتمدة للمستخدمين',
    isSensitive: true,
  },

  // CMS
  {
    key: 'cms.read',
    module: 'cms',
    labelEn: 'Read CMS Content',
    labelAr: 'عرض محتوى CMS',
    descriptionEn: 'View banners, static pages, FAQs, and revision history',
    descriptionAr:
      'عرض البنرات والصفحات الثابتة والأسئلة الشائعة وسجل التعديلات',
  },
  {
    key: 'cms.manage',
    module: 'cms',
    labelEn: 'Manage & Publish CMS Content',
    labelAr: 'إدارة ونشر محتوى CMS',
    descriptionEn:
      'Create, edit, schedule, publish, unpublish, and archive CMS content',
    descriptionAr: 'إنشاء وتعديل وجدولة ونشر وأرشفة محتوى التطبيق',
  },

  // Admin Accounts
  {
    key: 'admins.read',
    module: 'admins',
    labelEn: 'Read Admin Accounts',
    labelAr: 'عرض حسابات الإدارة',
    descriptionEn: 'View staff user accounts, statuses, and admin activity',
    descriptionAr: 'استعراض حسابات الموظفين وحالاتهم ونشاطهم',
  },
  {
    key: 'admins.create',
    module: 'admins',
    labelEn: 'Invite / Create Admin Accounts',
    labelAr: 'إنشاء ودعوة حسابات الإدارة',
    descriptionEn: 'Create or invite new administrative staff accounts',
    descriptionAr: 'إنشاء ودعوة موظفين جدد للوحة الإدارة',
    isSensitive: true,
  },
  {
    key: 'admins.update',
    module: 'admins',
    labelEn: 'Manage Admin Accounts & Sessions',
    labelAr: 'تعديل حسابات الإدارة والجلسات',
    descriptionEn:
      'Suspend, disable, activate admins, assign roles, revoke sessions, reset MFA',
    descriptionAr: 'تعليق وتفعيل وتعديل الموظفين وإبطال الجلسات وإعادة ضبط MFA',
    isSensitive: true,
  },

  // Roles & Permissions
  {
    key: 'roles.read',
    module: 'roles',
    labelEn: 'Read Roles & Permissions',
    labelAr: 'عرض الأدوار والصلاحيات',
    descriptionEn:
      'View staff roles, permission catalog, and effective permissions',
    descriptionAr: 'استعراض الأدوار ودليل الصلاحيات والصلاحيات الفعلية',
  },
  {
    key: 'roles.create',
    module: 'roles',
    labelEn: 'Create & Clone Roles',
    labelAr: 'إنشاء واستنساخ الأدوار',
    descriptionEn: 'Create or clone administrative roles',
    descriptionAr: 'إنشاء أدوار جديدة أو استنساخ الأدوار القائمة',
    isSensitive: true,
  },
  {
    key: 'roles.update',
    module: 'roles',
    labelEn: 'Update Role Permissions',
    labelAr: 'تعديل صلاحيات الأدوار',
    descriptionEn: 'Modify role metadata and assigned granular permissions',
    descriptionAr: 'تعديل بيانات الأدوار والصلاحيات المرتبطة بها',
    isSensitive: true,
  },
  {
    key: 'roles.delete',
    module: 'roles',
    labelEn: 'Delete Custom Roles',
    labelAr: 'حذف الأدوار المخصصة',
    descriptionEn: 'Delete non-system custom roles with zero active assignees',
    descriptionAr: 'حذف الأدوار المخصصة غير المرتبطة بموظفين',
    isSensitive: true,
  },

  // Audit, System Health, Feature Flags & Settings
  {
    key: 'audit_logs.read',
    module: 'audit_logs',
    labelEn: 'Read Audit Logs',
    labelAr: 'عرض سجلات التدقيق',
    descriptionEn: 'Inspect immutable security and administrative audit logs',
    descriptionAr: 'مراجعة سجل التدقيق الأمني والتشغيلي غير القابل للتعديل',
  },
  {
    key: 'audit_logs.export',
    module: 'audit_logs',
    labelEn: 'Export Audit Logs',
    labelAr: 'تصدير سجلات التدقيق',
    descriptionEn: 'Export filtered audit logs with audited tracking',
    descriptionAr: 'تصدير سجلات التدقيق مع توثيق عملية التصدير',
    isSensitive: true,
  },
  {
    key: 'system_health.read',
    module: 'system_health',
    labelEn: 'Read System Health',
    labelAr: 'مراقبة صحة النظام',
    descriptionEn:
      'View PostgreSQL, PostGIS, Redis, storage, and outbox health telemetry',
    descriptionAr: 'عرض حالة قواعد البيانات وRedis والتخزين والطوابير',
  },
  {
    key: 'feature_flags.read',
    module: 'feature_flags',
    labelEn: 'Read Feature Flags',
    labelAr: 'عرض أعلام الميزات',
    descriptionEn: 'View feature flags and change history',
    descriptionAr: 'عرض إعدادات Feature Flags وسجل تغييراتها',
  },
  {
    key: 'feature_flags.manage',
    module: 'feature_flags',
    labelEn: 'Manage Feature Flags',
    labelAr: 'إدارة أعلام الميزات',
    descriptionEn:
      'Create, toggle, update environment, and delete feature flags',
    descriptionAr: 'إنشاء وتفعيل وتعطيل وتعديل Feature Flags',
    isSensitive: true,
  },
  {
    key: 'settings.read',
    module: 'settings',
    labelEn: 'Read Platform Settings',
    labelAr: 'عرض إعدادات المنصة',
    descriptionEn:
      'View operational platform settings (no infrastructure secrets)',
    descriptionAr: 'عرض إعدادات التشغيل العامة للمنصة',
  },
  {
    key: 'settings.update',
    module: 'settings',
    labelEn: 'Update Platform Settings',
    labelAr: 'تعديل إعدادات المنصة',
    descriptionEn:
      'Modify listing limits, moderation rules, maintenance, and language settings',
    descriptionAr: 'تعديل حدود الإعلانات وقواعد المراجعة والصيانة واللغات',
    isSensitive: true,
  },
];

export const ADMIN_PERMISSIONS = ADMIN_PERMISSION_CATALOG.map(
  (p) => p.key,
) as readonly string[];

export const ADMIN_PERMISSION_SET = new Set<string>(ADMIN_PERMISSIONS);

export interface SeedRoleSpec {
  name: string;
  description: string;
  isSystem: boolean;
  permissions: string[];
}

export const INITIAL_ADMIN_ROLES: SeedRoleSpec[] = [
  {
    name: 'super_admin',
    description:
      'Super Admin — Full platform governance, RBAC, security, and emergency controls',
    isSystem: true,
    permissions: [...ADMIN_PERMISSIONS],
  },
  {
    name: 'platform_admin',
    description:
      'Platform Admin — Operational platform administration without Super Admin RBAC override',
    isSystem: true,
    permissions: [
      'analytics.read',
      'users.read',
      'users.update',
      'users.suspend',
      'users.ban',
      'listings.read',
      'listings.approve',
      'listings.reject',
      'listings.hide',
      'listings.delete',
      'categories.read',
      'categories.create',
      'categories.update',
      'categories.delete',
      'reports.read',
      'reports.assign',
      'reports.resolve',
      'verification.read',
      'messaging.complaints.read',
      'messaging.support.resolve',
      'notifications.read',
      'notifications.create',
      'notifications.approve',
      'notifications.send',
      'cms.read',
      'cms.manage',
      'admins.read',
      'audit_logs.read',
      'system_health.read',
      'feature_flags.read',
      'settings.read',
      'settings.update',
    ],
  },
  {
    name: 'operations_manager',
    description:
      'Operations Manager — Oversees moderation queues, assignments, categories, and operational SLA',
    isSystem: true,
    permissions: [
      'analytics.read',
      'users.read',
      'users.update',
      'users.suspend',
      'listings.read',
      'listings.approve',
      'listings.reject',
      'listings.hide',
      'categories.read',
      'categories.create',
      'categories.update',
      'reports.read',
      'reports.assign',
      'reports.resolve',
      'verification.read',
      'verification.approve',
      'messaging.complaints.read',
      'messaging.support.resolve',
      'notifications.read',
      'notifications.create',
      'cms.read',
      'audit_logs.read',
      'system_health.read',
      'settings.read',
    ],
  },
  {
    name: 'content_moderator',
    description:
      'Content Moderator — Reviews listings, handles assigned reports, and enforces listing policy',
    isSystem: true,
    permissions: [
      'analytics.read',
      'users.read',
      'listings.read',
      'listings.approve',
      'listings.reject',
      'listings.hide',
      'categories.read',
      'reports.read',
      'reports.resolve',
      'messaging.complaints.read',
      'audit_logs.read',
    ],
  },
  {
    name: 'verification_officer',
    description:
      'Verification Officer — Reviews KYC & commercial documents and approves/rejects account verification',
    isSystem: true,
    permissions: [
      'analytics.read',
      'users.read',
      'verification.read',
      'verification.documents.read',
      'verification.approve',
      'verification.reject',
      'audit_logs.read',
    ],
  },
  {
    name: 'customer_support',
    description:
      'Customer Support — Assists marketplace users, triages messaging complaints, adds internal notes',
    isSystem: true,
    permissions: [
      'analytics.read',
      'users.read',
      'users.update',
      'listings.read',
      'reports.read',
      'reports.assign',
      'verification.read',
      'messaging.complaints.read',
      'chat.oversight.read',
      'messaging.support.resolve',
      'notifications.read',
    ],
  },
  {
    name: 'marketing_manager',
    description:
      'Marketing Manager — Manages CMS banners/pages and notification campaigns',
    isSystem: true,
    permissions: [
      'analytics.read',
      'categories.read',
      'listings.read',
      'notifications.read',
      'notifications.create',
      'notifications.send',
      'cms.read',
      'cms.manage',
      'settings.read',
    ],
  },
  {
    name: 'analyst',
    description:
      'Analyst — Read-only access to platform analytics, listings, categories, and exports',
    isSystem: true,
    permissions: [
      'analytics.read',
      'analytics.export',
      'users.read',
      'listings.read',
      'categories.read',
      'reports.read',
      'notifications.read',
      'cms.read',
    ],
  },
  {
    name: 'security_auditor',
    description:
      'Security Auditor — Read-only audit trail, login history, RBAC inspection, and system health review',
    isSystem: true,
    permissions: [
      'analytics.read',
      'users.read',
      'listings.read',
      'reports.read',
      'verification.read',
      'admins.read',
      'roles.read',
      'audit_logs.read',
      'audit_logs.export',
      'system_health.read',
      'feature_flags.read',
      'settings.read',
    ],
  },
];
