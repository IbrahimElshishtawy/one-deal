// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'DealOne';

  @override
  String get brandNameAr => 'ديل ون';

  @override
  String get brandNameEn => 'DealOne';

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

  @override
  String get activityHubTitle => 'مركز النشاط والتجارة';

  @override
  String get activityHubSubtitle =>
      'أدر سلة التسوق، الحجوزات، طلبات الأسعار، والمفضلة';

  @override
  String get activityHubHeaderTooltip => 'مركز النشاط والتجارة';

  @override
  String get activityTabCart => 'السلة';

  @override
  String get activityTabBookings => 'الحجوزات';

  @override
  String get activityTabRfq => 'عروض الأسعار';

  @override
  String get activityTabFavorites => 'المفضلة';

  @override
  String get activitySearchHint => 'ابحث في نشاطك...';

  @override
  String get activityFilterAll => 'الكل';

  @override
  String activitySummaryCartItems(int count) {
    return '$count في السلة';
  }

  @override
  String activitySummaryBookings(int count) {
    return '$count حجوزات';
  }

  @override
  String activitySummaryRfqs(int count) {
    return '$count طلبات أسعار';
  }

  @override
  String activitySummaryFavorites(int count) {
    return '$count محفوظات';
  }

  @override
  String get activityBackendPendingNotice =>
      'المزامنة الحية مع الخادم لهذا القسم بانتظار دعم الواجهة الخلفية.';

  @override
  String get activityAuthRequiredTitle => 'سجّل الدخول لمزامنة نشاطك';

  @override
  String get activityAuthRequiredMessage =>
      'سجّل الدخول للوصول إلى مفضلتك المتزامنة مع الخادم ونشاط حسابك.';

  @override
  String get activitySignInAction => 'تسجيل الدخول';

  @override
  String get cartTitle => 'سلة التسوق';

  @override
  String get cartEmptyTitle => 'سلة التسوق فارغة';

  @override
  String get cartEmptyMessage =>
      'أضف مواد البناء أو الأجهزة المنزلية أو الأزياء إلى سلتك لإدارة الكميات والتواصل مع البائعين.';

  @override
  String get cartExploreProducts => 'استكشف السوق';

  @override
  String cartSellerLabel(String seller) {
    return 'البائع: $seller';
  }

  @override
  String get cartUnitPriceLabel => 'سعر الوحدة';

  @override
  String get cartQuantityLabel => 'الكمية';

  @override
  String cartSizeLabel(String size) {
    return 'المقاس: $size';
  }

  @override
  String cartColorLabel(String color) {
    return 'اللون: $color';
  }

  @override
  String get cartRemoveItem => 'حذف';

  @override
  String get cartSaveForLater => 'حفظ للاحقاً';

  @override
  String get cartSavedForLaterSuccess => 'تم الحفظ في قائمة المفضلة';

  @override
  String get cartRemovedSuccess => 'تم حذف المنتج من السلة';

  @override
  String get cartAddedSuccess => 'تمت الإضافة إلى سلة التسوق';

  @override
  String get cartRemoveConfirmTitle => 'حذف المنتج';

  @override
  String cartRemoveConfirmMessage(String title) {
    return 'هل أنت متأكد من حذف \"$title\" من سلة التسوق؟';
  }

  @override
  String get cartClearConfirmTitle => 'إفراغ السلة';

  @override
  String get cartClearConfirmMessage =>
      'هل تريد إزالة جميع المنتجات من سلة التسوق؟';

  @override
  String get cartClearAction => 'إفراغ السلة';

  @override
  String get cartSubtotalLabel => 'المجموع الفرعي';

  @override
  String get cartTotalLabel => 'الإجمالي التقديري';

  @override
  String cartItemsCountLabel(int count) {
    return '$count منتجات';
  }

  @override
  String get cartCheckoutAction => 'متابعة / التواصل مع البائعين';

  @override
  String get cartV1CommerceNotice =>
      'تعمل النسخة الحالية بنظام الإعلانات المجانية والتواصل المباشر بدون دفع إلكتروني داخل التطبيق. تواصل مع البائع لإتمام الصفقة.';

  @override
  String get cartSelectVariantTitle => 'اختر المواصفات';

  @override
  String get cartSelectSize => 'اختر المقاس';

  @override
  String get cartSelectColor => 'اختر اللون';

  @override
  String get cartAddToCartAction => 'أضف إلى السلة';

  @override
  String get cartQuantityMinError => 'يجب أن تكون الكمية 1 على الأقل';

  @override
  String get bookingsTitle => 'الحجوزات والمواعيد';

  @override
  String get bookingsEmptyTitle => 'لا توجد حجوزات أو مواعيد بعد';

  @override
  String get bookingsEmptyMessage =>
      'ستظهر هنا معاينات العقارات، فحوصات السيارات، وحجوزات الخدمات عند جدولتها.';

  @override
  String get bookingsFilterRealEstate => 'العقارات';

  @override
  String get bookingsFilterCars => 'السيارات والصيانة';

  @override
  String get bookingsFilterServices => 'الخدمات والهندسة';

  @override
  String get bookingsTypePropertyViewing => 'معاينة عقار';

  @override
  String get bookingsTypePropertyInspection => 'فحص عقار';

  @override
  String get bookingsTypeAgentContact => 'طلب تواصل مع وكيل';

  @override
  String get bookingsTypeVehicleInspection => 'فحص سيارة';

  @override
  String get bookingsTypeMaintenance => 'حجز صيانة';

  @override
  String get bookingsTypeServiceCenter => 'مركز خدمة';

  @override
  String get bookingsTypePlumbing => 'خدمة سباكة';

  @override
  String get bookingsTypeElectricity => 'خدمة كهرباء';

  @override
  String get bookingsTypeAc => 'خدمة تكييف';

  @override
  String get bookingsTypeConstruction => 'خدمة مقاولات';

  @override
  String get bookingsTypeEngineering => 'استشارة هندسية';

  @override
  String get bookingsProviderLabel => 'مقدم الخدمة';

  @override
  String get bookingsDateLabel => 'التاريخ';

  @override
  String get bookingsTimeLabel => 'الوقت';

  @override
  String get bookingsAddressLabel => 'العنوان';

  @override
  String bookingsReferenceLabel(String reference) {
    return 'مرجع #$reference';
  }

  @override
  String get bookingsStatusPending => 'قيد الانتظار';

  @override
  String get bookingsStatusConfirmed => 'مؤكد';

  @override
  String get bookingsStatusRejected => 'مرفوض';

  @override
  String get bookingsStatusCancelled => 'ملغي';

  @override
  String get bookingsStatusCompleted => 'مكتمل';

  @override
  String get bookingsStatusUnknown => 'غير معروف';

  @override
  String get bookingsCancelAction => 'إلغاء الحجز';

  @override
  String get bookingsCancelConfirmTitle => 'إلغاء الحجز';

  @override
  String get bookingsCancelConfirmMessage =>
      'هل أنت متأكد من رغبتك في إلغاء هذا الحجز؟';

  @override
  String get bookingsContactProviderAction => 'التواصل مع مقدم الخدمة';

  @override
  String get bookingsViewListingAction => 'عرض الإعلان';

  @override
  String get bookingsCreateTitle => 'جدولة موعد';

  @override
  String get bookingsSelectDateHint => 'اختر تاريخ الموعد';

  @override
  String get bookingsSelectTimeHint => 'اختر الوقت المتاح';

  @override
  String get bookingsAddressHint => 'أدخل عنوان الخدمة أو المعاينة';

  @override
  String get bookingsNotesHint => 'أضف وصف الطلب أو ملاحظاتك';

  @override
  String get bookingsSubmitAction => 'إرسال الطلب';

  @override
  String get bookingsValidationDateRequired => 'يرجى اختيار التاريخ';

  @override
  String get bookingsValidationTimeRequired => 'يرجى اختيار الوقت';

  @override
  String get bookingsValidationAddressRequired => 'يرجى إدخال العنوان';

  @override
  String get bookingsBackendUnavailableNotice =>
      'إرسال الحجز عبر الإنترنت بانتظار دعم الخادم. يمكنك التواصل مع البائع مباشرة من صفحة الإعلان.';

  @override
  String get rfqTitle => 'طلبات عروض الأسعار';

  @override
  String get rfqEmptyTitle => 'لا توجد طلبات عروض أسعار بعد';

  @override
  String get rfqEmptyMessage =>
      'قدّم طلبات كميات مواد البناء وقارن عروض الأسعار من الموردين هنا.';

  @override
  String get rfqCreateAction => 'طلب عرض سعر جديد';

  @override
  String get rfqCreateTitle => 'إنشاء طلب عرض سعر';

  @override
  String get rfqRequestTitleLabel => 'عنوان المشروع / الطلب';

  @override
  String get rfqRequestTitleHint => 'مثال: توريد كهرباء وأسمنت لفيلا';

  @override
  String get rfqMaterialsLabel => 'المنتجات / المواد المطلوبة';

  @override
  String get rfqMaterialsHint => 'مثال: أسمنت بورتلاندي، حديد تسليح 12 مم';

  @override
  String get rfqQuantityLabel => 'الكمية والوحدة';

  @override
  String get rfqQuantityHint => 'مثال: 50 طن / 200 قطعة';

  @override
  String get rfqDescriptionLabel => 'وصف المشروع';

  @override
  String get rfqDescriptionHint => 'حدد المواصفات الفنية والجدول الزمني';

  @override
  String get rfqDeliveryLocationLabel => 'موقع التسليم';

  @override
  String get rfqDeliveryLocationHint => 'المحافظة، المدينة، عنوان الموقع';

  @override
  String get rfqAttachmentsNote =>
      'إرفاق الصور سيتوفر فور تفعيل رفع مرفقات عروض الأسعار على الخادم.';

  @override
  String get rfqSubmitAction => 'إرسال طلب عرض السعر';

  @override
  String rfqReferenceLabel(String reference) {
    return 'طلب #$reference';
  }

  @override
  String rfqSubmittedDateLabel(String date) {
    return 'تاريخ التقديم: $date';
  }

  @override
  String rfqItemsCountLabel(int count) {
    return '$count بنود مطلوبة';
  }

  @override
  String rfqQuotationsCountLabel(int count) {
    return '$count عروض مستلمة';
  }

  @override
  String rfqLastUpdatedLabel(String date) {
    return 'آخر تحديث: $date';
  }

  @override
  String get rfqStatusDraft => 'مسودة';

  @override
  String get rfqStatusSubmitted => 'تم التقديم';

  @override
  String get rfqStatusUnderReview => 'قيد المراجعة';

  @override
  String get rfqStatusQuoted => 'تم التسعير';

  @override
  String get rfqStatusAccepted => 'مقبول';

  @override
  String get rfqStatusRejected => 'مرفوض';

  @override
  String get rfqStatusClosed => 'مغلق';

  @override
  String get rfqViewQuotationsAction => 'مقارنة العروض';

  @override
  String get rfqNoQuotationsYet => 'لم يتم استلام عروض أسعار من الموردين بعد.';

  @override
  String get rfqAcceptQuotationAction => 'قبول';

  @override
  String get rfqRejectQuotationAction => 'رفض';

  @override
  String get rfqValidationTitleRequired => 'يرجى إدخال عنوان الطلب';

  @override
  String get rfqValidationMaterialsRequired => 'يرجى تحديد المنتجات أو المواد';

  @override
  String get rfqValidationQuantityRequired => 'يرجى تحديد الكميات';

  @override
  String get rfqValidationLocationRequired => 'يرجى تحديد موقع التسليم';

  @override
  String get rfqBackendUnavailableNotice =>
      'إرسال طلبات الأسعار ومقارنة العروض بانتظار دعم واجهة الخادم.';

  @override
  String get favoritesTitle => 'المفضلة';

  @override
  String get favoritesEmptyTitle => 'لا توجد إعلانات محفوظة بعد';

  @override
  String get favoritesEmptyMessage =>
      'اضغط على أيقونة القلب في أي إعلان لحفظه والرجوع إليه هنا.';

  @override
  String get favoritesSearchEmptyTitle => 'لا توجد نتائج مطابقة';

  @override
  String get favoritesSearchEmptyMessage => 'جرّب مسح البحث أو اختيار قسم آخر.';

  @override
  String get favoritesExploreAction => 'تصفح الإعلانات';

  @override
  String get favoritesRemoveAction => 'إزالة من المفضلة';

  @override
  String get favoritesOpenListingAction => 'عرض التفاصيل';

  @override
  String get favoritesGoToSectionAction => 'الانتقال للقسم';

  @override
  String get favoritesRemovedSuccess => 'تمت الإزالة من المفضلة';

  @override
  String get favoritesSectorRealEstate => 'العقارات والأراضي';

  @override
  String get favoritesSectorCars => 'السيارات والصيانة';

  @override
  String get favoritesSectorServices => 'الخدمات والهندسة';

  @override
  String get favoritesSectorBuildingMaterials => 'مواد البناء والكهرباء';

  @override
  String get favoritesSectorAppliances => 'الأجهزة المنزلية والديكور';

  @override
  String get favoritesSectorFashion => 'الأزياء والإكسسوارات';

  @override
  String get actionRequestViewing => 'طلب معاينة';

  @override
  String get actionBookInspection => 'حجز فحص';

  @override
  String get actionBookService => 'حجز خدمة';

  @override
  String get actionRequestQuotation => 'طلب عرض سعر';

  @override
  String get actionContactSeller => 'تواصل مع البائع';
}
