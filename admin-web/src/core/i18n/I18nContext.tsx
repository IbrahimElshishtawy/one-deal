import React, { createContext, useContext, useEffect, useState } from 'react';

export type Locale = 'ar' | 'en';

const dictionaries = {
  en: {
    brand: 'Deal One Admin',
    brandSub: 'Enterprise Operations Console',
    nav: {
      overview: 'Overview',
      users: 'Users & Accounts',
      listings: 'Listings',
      categories: 'Categories & Attributes',
      reports: 'Reports & Moderation',
      verification: 'Verification',
      messaging: 'Messaging Oversight',
      notifications: 'Notifications',
      cms: 'CMS Content',
      analytics: 'Analytics',
      admins: 'Admin Accounts',
      roles: 'Roles & Permissions',
      auditLogs: 'Audit Logs',
      systemHealth: 'System Health',
      featureFlags: 'Feature Flags',
      settings: 'Platform Settings',
      security: 'My Security & Sessions',
    },
    common: {
      search: 'Search...',
      refresh: 'Refresh',
      actions: 'Actions',
      status: 'Status',
      createdAt: 'Created At',
      updatedAt: 'Updated At',
      save: 'Save',
      cancel: 'Cancel',
      confirm: 'Confirm',
      create: 'Create',
      edit: 'Edit',
      delete: 'Delete',
      view: 'View Details',
      exportCsv: 'Export CSV',
      exportJson: 'Export JSON',
      loading: 'Loading data...',
      emptyTitle: 'No matching records found',
      emptyDesc: 'Try adjusting your filters or search criteria.',
      errorTitle: 'Unable to load data',
      retry: 'Retry',
      prev: 'Previous',
      next: 'Next',
      page: 'Page',
      of: 'of',
      total: 'Total',
      reason: 'Reason',
      notes: 'Notes',
      reasonRequired: 'Please provide a reason for this action',
      logout: 'Sign Out',
      darkMode: 'Dark Mode',
      lightMode: 'Light Mode',
      language: 'العربية',
      all: 'All',
      active: 'Active',
      inactive: 'Inactive',
      pending: 'Pending',
      approved: 'Approved',
      rejected: 'Rejected',
      published: 'Published',
      hidden: 'Hidden',
      archived: 'Archived',
      suspended: 'Suspended',
      banned: 'Banned',
      open: 'Open',
      resolved: 'Resolved',
      dismissed: 'Dismissed',
      escalated: 'Escalated',
      noPermission: 'You do not have permission to access this module.',
    },
    auth: {
      title: 'Deal One Enterprise Admin',
      subtitle: 'Sign in with your corporate staff credentials',
      email: 'Work Email',
      password: 'Password',
      signIn: 'Sign In',
      forgotPassword: 'Forgot Password?',
      mfaTitle: 'Two-Factor Verification',
      mfaSubtitle: 'Enter the 6-digit authenticator code or recovery code',
      mfaCode: 'Verification Code',
      verifyMfa: 'Verify & Continue',
      backToLogin: 'Back to Sign In',
      resetTitle: 'Reset Admin Password',
      sendReset: 'Send Reset Instructions',
      resetToken: 'Reset Token',
      newPassword: 'New Password',
      completeReset: 'Reset Password',
    },
  },
  ar: {
    brand: 'إدارة صفقة ون',
    brandSub: 'منظومة التحكم والتشغيل المؤسسية',
    nav: {
      overview: 'نظرة عامة',
      users: 'المستخدمون والحسابات',
      listings: 'الإعلانات',
      categories: 'الأقسام والخصائص',
      reports: 'البلاغات والمراجعة',
      verification: 'طلبات التوثيق',
      messaging: 'شكاوى المحادثات',
      notifications: 'حملات الإشعارات',
      cms: 'إدارة المحتوى CMS',
      analytics: 'التحليلات والتقارير',
      admins: 'حسابات الإدارة',
      roles: 'الأدوار والصلاحيات',
      auditLogs: 'سجلات التدقيق',
      systemHealth: 'صحة النظام',
      featureFlags: 'أعلام الميزات',
      settings: 'إعدادات المنصة',
      security: 'الأمان والجلسات',
    },
    common: {
      search: 'بحث...',
      refresh: 'تحديث',
      actions: 'الإجراءات',
      status: 'الحالة',
      createdAt: 'تاريخ الإنشاء',
      updatedAt: 'آخر تحديث',
      save: 'حفظ',
      cancel: 'إلغاء',
      confirm: 'تأكيد',
      create: 'إنشاء',
      edit: 'تعديل',
      delete: 'حذف',
      view: 'عرض التفاصيل',
      exportCsv: 'تصدير CSV',
      exportJson: 'تصدير JSON',
      loading: 'جاري تحميل البيانات...',
      emptyTitle: 'لا توجد نتائج مطابقة',
      emptyDesc: 'جرّب تعديل معايير البحث أو الفلترة.',
      errorTitle: 'تعذر تحميل البيانات',
      retry: 'إعادة المحاولة',
      prev: 'السابق',
      next: 'التالي',
      page: 'صفحة',
      of: 'من',
      total: 'الإجمالي',
      reason: 'السبب',
      notes: 'ملاحظات',
      reasonRequired: 'يرجى كتابة سبب هذا الإجراء',
      logout: 'تسجيل الخروج',
      darkMode: 'الوضع الليلي',
      lightMode: 'الوضع النهاري',
      language: 'English',
      all: 'الكل',
      active: 'نشط',
      inactive: 'غير نشط',
      pending: 'قيد الانتظار',
      approved: 'معتمد',
      rejected: 'مرفوض',
      published: 'منشور',
      hidden: 'مخفي',
      archived: 'مؤرشف',
      suspended: 'معلق',
      banned: 'محظور',
      open: 'مفتوح',
      resolved: 'تم الحل',
      dismissed: 'مرفوض',
      escalated: 'مصعّد',
      noPermission: 'ليس لديك صلاحية للوصول إلى هذه الوحدة.',
    },
    auth: {
      title: 'لوحة إدارة صفقة ون',
      subtitle: 'تسجيل الدخول باستخدام حساب الموظف المعتمد',
      email: 'البريد الإلكتروني الوظيفي',
      password: 'كلمة المرور',
      signIn: 'تسجيل الدخول',
      forgotPassword: 'نسيت كلمة المرور؟',
      mfaTitle: 'التحقق الثنائي MFA',
      mfaSubtitle: 'أدخل رمز المصادقة المكون من 6 أرقام أو رمز الاسترداد',
      mfaCode: 'رمز التحقق',
      verifyMfa: 'تحقق ومتابعة',
      backToLogin: 'العودة لتسجيل الدخول',
      resetTitle: 'استعادة كلمة مرور المسؤول',
      sendReset: 'إرسال تعليمات الاستعادة',
      resetToken: 'رمز الاستعادة',
      newPassword: 'كلمة المرور الجديدة',
      completeReset: 'تحديث كلمة المرور',
    },
  },
} as const;

export type TranslationDict = typeof dictionaries.en;

interface I18nContextValue {
  locale: Locale;
  dir: 'rtl' | 'ltr';
  setLocale: (loc: Locale) => void;
  toggleLocale: () => void;
  t: (typeof dictionaries)[Locale];
}

const I18nContext = createContext<I18nContextValue | null>(null);

export function I18nProvider({ children }: { children: React.ReactNode }) {
  const [locale, setLocaleState] = useState<Locale>(() => {
    const saved = localStorage.getItem('dealone_admin_locale');
    return saved === 'en' ? 'en' : 'ar';
  });

  const dir: 'rtl' | 'ltr' = locale === 'ar' ? 'rtl' : 'ltr';

  useEffect(() => {
    localStorage.setItem('dealone_admin_locale', locale);
    document.documentElement.lang = locale;
    document.documentElement.dir = dir;
  }, [locale, dir]);

  const setLocale = (loc: Locale) => setLocaleState(loc);
  const toggleLocale = () => setLocaleState((p) => (p === 'ar' ? 'en' : 'ar'));

  return (
    <I18nContext.Provider
      value={{
        locale,
        dir,
        setLocale,
        toggleLocale,
        t: dictionaries[locale],
      }}
    >
      {children}
    </I18nContext.Provider>
  );
}

export function useI18n() {
  const ctx = useContext(I18nContext);
  if (!ctx) throw new Error('useI18n must be used inside I18nProvider');
  return ctx;
}
