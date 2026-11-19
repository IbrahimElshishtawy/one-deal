// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ديل ون';

  @override
  String get brandNameAr => 'ديل ون';

  @override
  String get brandNameEn => 'DEAL ONE';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get close => 'إغلاق';

  @override
  String get copy => 'نسخ';

  @override
  String copiedItem(String label) {
    return 'تم نسخ $label';
  }

  @override
  String get networkError => 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.';

  @override
  String get serverError => 'حدث خطأ في الخادم. يرجى المحاولة لاحقاً.';

  @override
  String get timeoutError => 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.';

  @override
  String get unauthorizedError =>
      'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجدداً.';

  @override
  String get unknownError => 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';

  @override
  String get emptyStateMessage => 'لا توجد بيانات متاحة حالياً.';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get initializationFailed => 'فشل تهيئة التطبيق.';

  @override
  String get pageNotFound => 'الصفحة غير موجودة.';

  @override
  String get backToHome => 'العودة للرئيسية';

  @override
  String get timeRemainingText => 'الوقت المتبقي';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingCreateAccount => 'إنشاء حساب';

  @override
  String get onboardingBrowseGuest => 'تصفح كزائر';

  @override
  String get onboardingSlide1Title => 'عالم من العقارات والسيارات بين يديك';

  @override
  String get onboardingSlide1Description =>
      'اكتشف أحدث العروض لبيع وشراء العقارات، السيارات، وخدمات الصيانة وقطع الغيار بكل سهولة.';

  @override
  String get onboardingSlide2Title => 'تشطيبات وخدمات منزلية بالقرب منك';

  @override
  String get onboardingSlide2Description =>
      'تواصل مع المكاتب الهندسية واطلب مواد البناء والمستلزمات الكهربائية من أقرب الموردين والفنيين لمنطقتك.';

  @override
  String get onboardingSlide3Title => 'أناقتك وديكور منزلك بتواصل مباشر';

  @override
  String get onboardingSlide3Description =>
      'تصفح أحدث صيحات الملابس، قطع الديكور والأجهزة المنزلية، وتواصل مباشرة مع البائعين لإتمام صفقاتك بكل سهولة وأمان.';

  @override
  String get authBrowseAsGuest => 'تصفح كزائر';

  @override
  String get authOrContinueWith => 'أو المتابعة عبر';

  @override
  String get authProviderEmail => 'البريد الإلكتروني';

  @override
  String get authProviderApple => 'حساب آبل';

  @override
  String get authLegalPrefix => 'بالمتابعة، فإنك توافق على ';

  @override
  String get authLegalTerms => 'شروط الخدمة';

  @override
  String get authLegalAnd => ' و';

  @override
  String get authLegalPrivacy => 'سياسة الخصوصية';

  @override
  String get authLegalSuffix => '.';

  @override
  String get signUpTitle => 'أنشئ حسابك في Deal One';

  @override
  String get signUpSubtitle => 'ابحث عن عقارك، سيارتك، وصفقاتك في مكان واحد.';

  @override
  String get signUpNameHint => 'اكتب اسمك هنا';

  @override
  String get signUpPhoneHint => '01XXXXXXXXX';

  @override
  String get signUpWhatsappNote => 'سيتم إرسال رمز التحقق عبر الواتساب';

  @override
  String get signUpSubmitButton => 'إرسال رمز التحقق';

  @override
  String get signUpAlreadyHaveAccount => 'لديك حساب بالفعل؟ ';

  @override
  String get signUpGoToLogin => 'تسجيل الدخول';

  @override
  String get loginTitle => 'أهلاً بك مجدداً';

  @override
  String get loginSubtitle =>
      'أدخل رقم الواتساب للمتابعة واستكشاف\nالعقارات والمشتريات';

  @override
  String get loginSubmitButton => 'تسجيل الدخول';

  @override
  String get loginNoAccount => 'ليس لديك حساب؟ ';

  @override
  String get loginCreateAccountNow => 'إنشاء حساب الآن';

  @override
  String get otpTitle => 'أدخل رمز التحقق';

  @override
  String otpSubtitle(int length, String phone) {
    return 'أدخل الرمز المكون من $length أرقام المرسل إلى\n[$phone] عبر الواتساب';
  }

  @override
  String get otpChangePhone => 'تغيير الرقم';

  @override
  String get otpVerifyButton => 'تأكيد الرمز';

  @override
  String get otpRetryButton => 'إعادة المحاولة';

  @override
  String otpRetryWithCooldown(String cooldown) {
    return 'إعادة المحاولة ($cooldown)';
  }

  @override
  String get otpResendingLabel => 'جاري إرسال رمز جديد...';

  @override
  String get otpDidNotReceive => 'ألم تستلم الرمز؟ ';

  @override
  String get otpResendAgain => 'إرسال مجدداً';

  @override
  String otpResendCountdown(String cooldown) {
    return 'إرسال مجدداً $cooldown';
  }

  @override
  String get otpSendingLabel => 'جاري الإرسال...';

  @override
  String otpExpiryRemaining(String time) {
    return 'صلاحية الرمز المتبقية: $time';
  }

  @override
  String get otpWhatsappHelp => 'لم يصلك الرمز عبر واتساب؟';

  @override
  String get otpSupportPrompt => 'تواجه مشكلة في تسجيل الدخول؟ تواصل مع الدعم';

  @override
  String otpResendInCooldown(String cooldown) {
    return 'إرسال رمز جديد خلال $cooldown';
  }

  @override
  String get otpRequestNewCode => 'طلب رمز تحقق جديد';

  @override
  String get otpResentSuccess => 'تم إرسال رمز تحقق جديد بنجاح';

  @override
  String otpWaitCooldownSms(String cooldown) {
    return 'يرجى انتظار $cooldown قبل إعادة الإرسال عبر SMS';
  }

  @override
  String otpWaitCooldownNewCode(String cooldown) {
    return 'يرجى انتظار $cooldown قبل طلب رمز جديد';
  }

  @override
  String otpSemanticsLabel(int length) {
    return 'حقل إدخال رمز التحقق المكون من $length أرقام';
  }

  @override
  String get otpNoActiveSessionTitle => 'لا توجد جلسة تحقق نشطة';

  @override
  String get otpNoActiveSessionSubtitle =>
      'يرجى إدخال رقم هاتفك أولاً لاستلام رمز التحقق.';

  @override
  String get otpBackToLogin => 'العودة لتسجيل الدخول';

  @override
  String get otpRemainingAttemptsOne =>
      'متبقي لك محاولة واحدة (1) فقط قبل القفل المؤقت';

  @override
  String get otpRemainingAttemptsTwo =>
      'متبقي لك محاولتان (2) فقط قبل القفل المؤقت';

  @override
  String otpRemainingAttemptsMany(int count) {
    return 'متبقي لك $count محاولات فقط قبل القفل المؤقت';
  }

  @override
  String get otpExpiredTitle => 'انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد';

  @override
  String get otpExpiredBody =>
      'انقضت مهلة الأمان المحددة لحماية حسابك ومعاملاتك العقارية. يمكنك إنشاء رمز جديد فوري ومتابعة توثيق العملية.';

  @override
  String get whatsappFailureTitle => 'تعذر الإرسال عبر واتساب';

  @override
  String get whatsappFailureDefaultSubtitle =>
      'عذراً، هذا الرقم غير مسجل على تطبيق واتساب. يرجى استخدام طريقة أخرى';

  @override
  String get whatsappFailureSendEmail => 'إرسال رسالة عبر البريد الإلكتروني';

  @override
  String get whatsappFailureResendSms => 'إعادة الإرسال عبر رسالة SMS';

  @override
  String get whatsappFailureEditPhone => 'تعديل الرقم';

  @override
  String get whatsappFailureNeedHelp => 'تحتاج مساعدة في تسجيل الدخول؟';

  @override
  String get emailFallbackTitle => 'التحقق بالبريد الإلكتروني';

  @override
  String get emailFallbackSubtitle =>
      'أدخل بريدك الإلكتروني للتحقق من إمكانية إرسال رمز بديل.';

  @override
  String get emailFallbackLabel => 'البريد الإلكتروني';

  @override
  String get emailFallbackSubmit => 'التحقق من البريد الإلكتروني';

  @override
  String get emailFallbackUnsupported =>
      'إرسال رمز التحقق عبر البريد الإلكتروني غير متاح حالياً من الخادم. يرجى إتمام التحقق عبر رسالة SMS على رقم الموبايل المصري (+20).';

  @override
  String get supportTitle => 'الدعم الفني - ديل ون';

  @override
  String get supportSubtitle =>
      'إذا واجهت صعوبة متكررة في استلام رمز التحقق، يمكنك التواصل مع فريق الدعم أو نسخ بيانات التواصل أدناه:';

  @override
  String get supportEmailTitle => 'البريد الإلكتروني للدعم';

  @override
  String get supportHotlineTitle => 'خدمة العملاء';

  @override
  String providerUnavailableTitle(String provider) {
    return 'التسجيل عبر $provider غير مفعل حالياً';
  }

  @override
  String get providerUnavailableBody =>
      'يدعم نظام ديل ون حالياً التسجيل والتحقق الآمن عبر رقم الهاتف المصري ورمز التحقق (OTP). يرجى إدخال رقم هاتفك للمتابعة.';

  @override
  String get providerUnavailableButton => 'فهمت، المتابعة برقم الهاتف';

  @override
  String get successTitle => 'تم التحقق بنجاح!';

  @override
  String get successSubtitleDefault =>
      'أصبح حسابك جاهزاً الآن للاستخدام والبحث عن\nعقارك ومشترياتك.';

  @override
  String successSubtitleWithName(String name) {
    return 'أهلاً بك، $name\nأصبح حسابك جاهزاً الآن للاستخدام والبحث عن عقارك ومشترياتك.';
  }

  @override
  String get successContinueButton => 'المتابعة لتسجيل الدخول';

  @override
  String get validationNameRequired => 'من فضلك أدخل الاسم الكامل';

  @override
  String get validationNameTooShort =>
      'الاسم الكامل يجب أن يكون حرفين على الأقل';

  @override
  String get validationNameTooLong => 'الاسم الكامل طويل جداً';

  @override
  String get validationNameLetters => 'يرجى إدخال اسم صحيح يحتوي على حروف';

  @override
  String get validationPhoneRequired => 'من فضلك أدخل رقم الهاتف';

  @override
  String get validationPhoneInvalid =>
      'أدخل رقم موبايل مصري صحيح (مثال: 01012345678)';

  @override
  String get validationEmailRequired => 'من فضلك أدخل البريد الإلكتروني';

  @override
  String get validationEmailInvalid => 'صيغة البريد الإلكتروني غير صحيحة';

  @override
  String get validationOtpRequired => 'من فضلك أدخل رمز التحقق';

  @override
  String validationOtpIncomplete(int length) {
    return 'يرجى إدخال رمز التحقق المكون من $length أرقام';
  }

  @override
  String get validationOtpDigitsOnly => 'رمز التحقق يجب أن يحتوي على أرقام فقط';

  @override
  String get authErrorNetwork =>
      'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.';

  @override
  String get authErrorTimeout =>
      'انتهت مهلة الاتصال بالخادم. يرجى المحاولة مرة أخرى.';

  @override
  String get authErrorUnexpectedResponse =>
      'تم استلام استجابة غير متوقعة من الخادم. يرجى المحاولة لاحقاً.';

  @override
  String get authErrorWhatsappUnavailable =>
      'عذراً، هذا الرقم غير مسجل على تطبيق واتساب. يرجى استخدام طريقة أخرى.';

  @override
  String get authErrorOtpDeliveryFailed =>
      'تعذر إرسال رمز التحقق حالياً. يرجى التأكد من الرقم أو المحاولة لاحقاً.';

  @override
  String get authErrorMaxAttempts =>
      'تم تجاوز الحد الأقصى للمحاولات (5 محاولات). يرجى طلب رمز تحقق جديد.';

  @override
  String get authErrorOtpExpired =>
      'انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد';

  @override
  String get authErrorOtpInvalid =>
      'رمز التحقق غير صحيح، يرجى التأكد وإعادة المحاولة';

  @override
  String get authErrorInvalidRefreshToken =>
      'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get authErrorRateLimited =>
      'تم إرسال عدة طلبات مؤخراً. يرجى انتظار انتهاء العداد قبل طلب رمز جديد.';

  @override
  String get authErrorAccountNotFound =>
      'لم يتم العثور على حساب مرتبط بهذا الرقم.';

  @override
  String get authErrorExistingAccount =>
      'رقم الهاتف مسجل مسبقاً. يمكنك تسجيل الدخول مباشرة.';

  @override
  String get authErrorInvalidPhone =>
      'أدخل رقم موبايل مصري صحيح (مثال: 01012345678)';

  @override
  String get authErrorValidation =>
      'يرجى مراجعة البيانات المدخلة والمحاولة مرة أخرى';

  @override
  String get authErrorAccountSuspended =>
      'هذا الحساب غير مصرح له بالدخول حالياً. تواصل مع الدعم الفني.';

  @override
  String get authErrorUnauthorized =>
      'انتهت صلاحية الجلسة أو بيانات التحقق غير صالحة. حاول مرة أخرى.';

  @override
  String get authErrorServer =>
      'حدث خطأ غير متوقع في الخادم. يرجى المحاولة لاحقاً.';

  @override
  String get legalTermsTitle => 'شروط الاستخدام';

  @override
  String get legalPrivacyTitle => 'سياسة الخصوصية';

  @override
  String get legalTermsSection1Title => '1. استخدام منصة ديل ون';

  @override
  String get legalTermsSection1Body =>
      'تلتزم عند استخدام منصة ديل ون بنشر إعلانات حقيقية ومطابقة للقوانين المعمول بها في جمهورية مصر العربية، وعدم انتحال شخصية أو تقديم معلومات مضللة.';

  @override
  String get legalTermsSection2Title => '2. الحساب والتحقق برقم الهاتف';

  @override
  String get legalTermsSection2Body =>
      'يتم توثيق الحسابات برقم موبايل مصري فعّال عبر رمز تحقق لمرة واحدة (OTP). أنت مسؤول عن سرية جلسة الدخول وعدم مشاركة رموز التحقق مع أي طرف.';

  @override
  String get legalTermsSection3Title => '3. التعاملات بين المستخدمين';

  @override
  String get legalTermsSection3Body =>
      'ديل ون منصة وساطة وعرض إعلانات بين البائعين والمشترين. يرجى المعاينة الدقيقة والتأكد من مستندات الملكية قبل إتمام أي معاملة مالية.';

  @override
  String get legalPrivacySection1Title => '1. البيانات التي نجمعها';

  @override
  String get legalPrivacySection1Body =>
      'نجمع فقط الاسم الكامل ورقم الهاتف المصري وبيانات الإعلانات التي تضيفها لتفعيل حسابك وتمكين التواصل الموثوق داخل التطبيق.';

  @override
  String get legalPrivacySection2Title => '2. أمان الرموز والجلسات';

  @override
  String get legalPrivacySection2Body =>
      'تُحفظ رموز الجلسة (JWT Access & Refresh Tokens) داخل التخزين المشفر على جهازك ولا تتم مشاركتها مع أي جهات خارجية لأغراض تسويقية.';

  @override
  String get legalPrivacySection3Title => '3. حقوقك في الحساب';

  @override
  String get legalPrivacySection3Body =>
      'يمكنك تعديل اسمك، تسجيل الخروج من جميع الجلسات، أو طلب حذف حسابك في أي وقت عبر إعدادات الحساب أو بالتواصل مع الدعم الفني.';

  @override
  String get profileTitleGuest => 'حسابي';

  @override
  String get profileTitleAuth => 'حسابي والملف الشخصي';

  @override
  String get profileGuestHeadline => 'سجّل الدخول للوصول إلى إعلاناتك والتواصل';

  @override
  String get profileLoginWithPhone => 'تسجيل الدخول برقم الهاتف';

  @override
  String get profileRegisteredUser => 'المستخدم المسجل';

  @override
  String get profileIdAvailable => 'المعرف متوفر';

  @override
  String get profileDailyQuotaTitle => 'حصة التواصل اليومية (توقيت القاهرة)';

  @override
  String profileDailyQuotaRemaining(int remaining, int limit) {
    return 'المتبقي اليوم: $remaining من أصل $limit كشوفات أرقام';
  }

  @override
  String get profileDailyQuotaNote =>
      'تتجدد الحصة تلقائياً عند منتصف ليل كل يوم بتوقيت القاهرة.';

  @override
  String get profileDailyQuotaError => 'تعذر تحميل معلومات الحصة اليومية';

  @override
  String get profileAccountsTitle => 'حسابات البيع والمعارض التابعة';

  @override
  String get profileAccountsEmpty => 'لا توجد حسابات معارض إضافية';

  @override
  String get profileAccountsError => 'تعذر تحميل الحسابات';

  @override
  String get profileVerified => 'موثق';

  @override
  String get profileUnderReview => 'قيد المراجعة';

  @override
  String profileRoleLabel(String role, String status) {
    return 'الصفة: $role • $status';
  }

  @override
  String get profileLogout => 'تسجيل الخروج';

  @override
  String get settingsThemeTitle => 'مظهر التطبيق';

  @override
  String get settingsThemeSystem => 'النظام';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsLanguageTitle => 'لغة التطبيق';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageEnglish => 'English';
}
