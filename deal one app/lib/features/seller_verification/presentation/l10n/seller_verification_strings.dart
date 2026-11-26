import 'package:flutter/widgets.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';

/// Centralized Arabic (RTL) & English (LTR) localization helper for Seller Verification.
/// Ensures zero hardcoded strings inside widgets.
class SellerVerificationStrings {
  final bool isArabic;

  const SellerVerificationStrings._(this.isArabic);

  factory SellerVerificationStrings.of(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    final isAr = locale != null
        ? locale.languageCode.toLowerCase() == 'ar'
        : Directionality.of(context) == TextDirection.rtl;
    return SellerVerificationStrings._(isAr);
  }

  factory SellerVerificationStrings.fromFlag(bool isArabic) =>
      SellerVerificationStrings._(isArabic);

  // Common
  String get continueLabel => isArabic ? 'متابعة' : 'Continue';
  String get backLabel => isArabic ? 'رجوع' : 'Back';
  String get retryLabel => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get cancelLabel => isArabic ? 'إلغاء' : 'Cancel';
  String get editLabel => isArabic ? 'تعديل' : 'Edit';
  String get requiredTag => isArabic ? 'مطلوب' : 'Required';
  String get optionalTag => isArabic ? 'اختياري' : 'Optional';
  String get loadingLabel => isArabic ? 'جاري التحميل...' : 'Loading...';
  String get refreshLabel => isArabic ? 'تحديث الحالة' : 'Refresh Status';
  String get returnHomeLabel =>
      isArabic ? 'العودة للرئيسية' : 'Return to Home';
  String get contactSupportLabel =>
      isArabic ? 'تواصل مع الدعم' : 'Contact Support';
  String get stepProgressPrefix => isArabic ? 'الخطوة' : 'Step';
  String get ofLabel => isArabic ? 'من' : 'of';

  // Badges
  String get identityVerifiedBadge =>
      isArabic ? 'هوية موثقة' : 'Identity Verified';
  String get businessVerifiedBadge =>
      isArabic ? 'شركة / مكتب موثق' : 'Business Verified';
  String get unverifiedLabel => isArabic ? 'غير موثق' : 'Not Verified';

  // Screen 01: Onboarding Entry
  String get onboardingTitle =>
      isArabic ? 'ابدأ البيع على صفقة ون' : 'Become a Seller on Deal One';
  String get onboardingHeadline => isArabic
      ? 'وثّق حسابك وابدأ نشر إعلاناتك بثقة'
      : 'Verify Your Account & Start Selling with Trust';
  String get onboardingSubtitle => isArabic
      ? 'عملية توثيق سريعة وآمنة تمنح المشترين الثقة الكاملة وتفتح لك أدوات إدارة الإعلانات.'
      : 'A quick, secure verification process that builds buyer trust and unlocks full seller tools.';
  String get benefitsSectionTitle =>
      isArabic ? 'مميزات البائع الموثق' : 'Verified Seller Benefits';
  String get benefitTrustTitle =>
      isArabic ? 'شارة توثيق رسمية' : 'Official Verification Badge';
  String get benefitTrustDesc => isArabic
      ? 'تظهر شارة التوثيق على ملفك الشخصي وجميع إعلاناتك لزيادة ثقة المشترين.'
      : 'Displayed on your profile and every listing to boost buyer confidence.';
  String get benefitVisibilityTitle =>
      isArabic ? 'نشر وإدارة إعلاناتك' : 'Publish & Manage Listings';
  String get benefitVisibilityDesc => isArabic
      ? 'انشر إعلاناتك في جميع أقسام صفقة ون وتابع استفسارات المشترين بسهولة.'
      : 'Publish listings across Deal One categories and manage buyer inquiries seamlessly.';
  String get benefitUpgradeTitle =>
      isArabic ? 'ترقية مرنة للشركات' : 'Seamless Business Upgrade';
  String get benefitUpgradeDesc => isArabic
      ? 'ابدأ كفرد موثق ويمكنك الترقية لاحقاً إلى شركة أو مكتب موثق مع الاحتفاظ بكل إعلاناتك.'
      : 'Start as an individual seller and upgrade to Business Verified later while keeping all listings.';
  String get securityNoticeTitle =>
      isArabic ? 'خصوصية وأمان مستنداتك' : 'Document Privacy & Security';
  String get securityNoticeBody => isArabic
      ? 'تُحفظ مستندات التوثيق في تخزين خاص مشفّر ولا تُعرض أبداً للمشترين أو في الإعلانات العامة.'
      : 'Verification documents are stored in private encrypted storage and are never shown publicly.';
  String get startSellingCta =>
      isArabic ? 'ابدأ التسجيل كبائع' : 'Start Selling';
  String get viewApplicationStatusCta =>
      isArabic ? 'متابعة حالة الطلب' : 'Track Application Status';
  String get existingApplicationTitle =>
      isArabic ? 'لديك طلب توثيق قائم' : 'Existing Verification Application';

  // Screen 02: Seller Type Selection
  String get selectTypeTitle =>
      isArabic ? 'اختر نوع البائع' : 'Choose Seller Type';
  String get selectTypeSubtitle => isArabic
      ? 'اختر التصنيف المناسب لنشاطك لتحديد المستندات المطلوبة بدقة.'
      : 'Select the classification that matches your activity to load exact document requirements.';
  String get individualTitle => isArabic ? 'بائع فردي' : 'Individual Seller';
  String get individualDesc => isArabic
      ? 'للأفراد، الوسطاء العقاريين المستقلين، والبائعين من المنزل. يتطلب صورة البطاقة الشخصية (الأمام والخلف).'
      : 'For individuals, independent brokers, and home-based sellers. Requires National ID (front & back).';
  String get businessTitle =>
      isArabic ? 'شركة / مكتب تجاري' : 'Business / Commercial Office';
  String get businessDesc => isArabic
      ? 'للشركات، المكاتب العقارية، المعارض، المتاجر، والمؤسسات التجارية. يتطلب السجل التجاري والبطاقة الضريبية.'
      : 'For registered companies, offices, agencies, showrooms, and stores. Requires Commercial Register & Tax Card.';
  String get serviceProviderTitle =>
      isArabic ? 'مقدم خدمات' : 'Service Provider';
  String get serviceProviderDesc => isArabic
      ? 'للفنيين والمهندسين ومقدمي الخدمات المستقلين. يتبع متطلبات توثيق الهوية مع إمكانية إضافة التراخيص المهنية.'
      : 'For independent technicians, engineers, and service professionals. Follows identity verification with optional trade licenses.';

  // Screen 03: Seller Information Form
  String get sellerInfoTitle =>
      isArabic ? 'بيانات البائع' : 'Seller Information';
  String get sellerInfoSubtitle => isArabic
      ? 'أدخل بياناتك الأساسية بدقة كما تظهر في مستنداتك الرسمية.'
      : 'Enter your details accurately as they appear on your official documents.';
  String get fullNameLabel =>
      isArabic ? 'الاسم الكامل / اسم البائع' : 'Full Name / Seller Name';
  String get businessNameLabel =>
      isArabic ? 'اسم الشركة / المكتب التجاري' : 'Business / Office Name';
  String get commercialRegisterLabel =>
      isArabic ? 'رقم السجل التجاري' : 'Commercial Register Number';
  String get taxIdLabel =>
      isArabic ? 'رقم البطاقة الضريبية (اختياري)' : 'Tax Card Number (Optional)';
  String get nationalIdLabel =>
      isArabic ? 'الرقم القومي' : 'National ID Number';
  String get contactPersonLabel => isArabic
      ? 'اسم الممثل القانوني / مسؤول التواصل'
      : 'Contact Person / Legal Representative';
  String get phoneLabel => isArabic ? 'رقم الهاتف' : 'Phone Number';
  String get emailLabel =>
      isArabic ? 'البريد الإلكتروني (اختياري)' : 'Email Address (Optional)';
  String get addressLabel => isArabic ? 'العنوان بالتفصيل' : 'Full Address';
  String get governorateLabel => isArabic ? 'المحافظة' : 'Governorate';
  String get cityLabel => isArabic ? 'المدينة / المنطقة' : 'City / Area';
  String get activityLabel =>
      isArabic ? 'النشاط / القسم التجاري' : 'Marketplace Activity / Section';
  String get businessTypeLabel =>
      isArabic ? 'نوع الكيان التجاري' : 'Commercial Entity Type';

  // Screen 04 & 05: Requirements & Document Upload
  String get requirementsTitle =>
      isArabic ? 'المستندات المطلوبة' : 'Required Documents';
  String get requirementsSubtitle => isArabic
      ? 'يتم تحديد هذه المستندات تلقائياً بناءً على نوع حسابك ونشاطك.'
      : 'These requirements are loaded dynamically based on your seller type and activity.';
  String get uploadTitle =>
      isArabic ? 'رفع مستندات التوثيق' : 'Upload Verification Documents';
  String get uploadSubtitle => isArabic
      ? 'ارفع صوراً واضحة أو ملفات PDF لمستنداتك. المستندات الاختيارية لا تمنع إرسال الطلب.'
      : 'Upload clear photos or PDF scans of your documents. Optional documents do not block submission.';
  String get uploadDocumentBtn => isArabic ? 'رفع المستند' : 'Upload Document';
  String get replaceDocumentBtn => isArabic ? 'استبدال' : 'Replace';
  String get removeDocumentBtn => isArabic ? 'حذف' : 'Remove';
  String get cameraBtn => isArabic ? 'الكاميرا' : 'Camera';
  String get galleryBtn => isArabic ? 'المعرض' : 'Gallery';
  String get filePickerBtn => isArabic ? 'ملف PDF / صورة' : 'Pick File';
  String get uploadedSuccessLabel =>
      isArabic ? 'تم الرفع بنجاح' : 'Uploaded Successfully';
  String get uploadHelpTitle =>
      isArabic ? 'نصائح لقبول مستنداتك بسرعة' : 'Tips for Fast Approval';
  String get uploadHelpBody => isArabic
      ? 'تأكد من وضوح البيانات وعدم اقتصاص أطراف المستند، وأن يكون حجم الملف أقل من 10 ميجابايت بصيغة JPG أو PNG أو PDF.'
      : 'Ensure all text is readable, corners are visible, and files are under 10 MB in JPG, PNG, or PDF format.';
  String get formatsAcceptedPrefix =>
      isArabic ? 'الصيغ المقبولة:' : 'Accepted formats:';
  String get maxSizePrefix => isArabic ? 'الحد الأقصى:' : 'Max size:';

  // Screen 06: Review
  String get reviewTitle =>
      isArabic ? 'مراجعة الطلب قبل الإرسال' : 'Review Before Submission';
  String get reviewSubtitle => isArabic
      ? 'راجع جميع بياناتك ومستنداتك قبل إرسال الطلب للمراجعة.'
      : 'Review your information and uploaded documents before submitting for verification.';
  String get sellerInfoSection =>
      isArabic ? 'معلومات البائع' : 'Seller Information';
  String get uploadedDocsSection =>
      isArabic ? 'المستندات المرفوعة' : 'Uploaded Documents';
  String get missingDocsWarning => isArabic
      ? 'يرجى استكمال رفع جميع المستندات المطلوبة قبل الإرسال.'
      : 'Please upload all required documents before submitting.';
  String get editInfoBtn =>
      isArabic ? 'تعديل البيانات' : 'Edit Information';
  String get editDocsBtn =>
      isArabic ? 'تعديل المستندات' : 'Edit Documents';
  String get confirmationCheckboxText => isArabic
      ? 'أقر بأن جميع البيانات والمستندات المقدمة صحيحة وتخصني أو أملك تفويضاً قانونياً بتقديمها.'
      : 'I confirm that all provided information and documents are accurate and authentic.';
  String get submitVerificationBtn =>
      isArabic ? 'إرسال طلب التوثيق' : 'Submit Verification Application';

  // Screen 07: Success
  String get successTitle =>
      isArabic ? 'تم إرسال طلبك بنجاح!' : 'Application Submitted!';
  String get successSubtitle => isArabic
      ? 'فريق التوثيق سيقوم بمراجعة مستنداتك وإشعارك فور صدور القرار.'
      : 'Our verification team will review your documents and notify you once a decision is made.';
  String get referenceNumberLabel =>
      isArabic ? 'رقم مرجع الطلب' : 'Application Reference';
  String get submissionDateLabel =>
      isArabic ? 'تاريخ الإرسال' : 'Submission Date';
  String get trackApplicationBtn =>
      isArabic ? 'متابعة حالة الطلب' : 'Track Application';

  // Screen 08: Tracking Center
  String get trackingTitle =>
      isArabic ? 'مركز متابعة التوثيق' : 'Verification Tracking Center';
  String get timelineTitle =>
      isArabic ? 'سجل مراحل الطلب' : 'Verification Timeline';
  String get rejectionReasonTitle =>
      isArabic ? 'سبب الرفض' : 'Rejection Reason';
  String get correctionNoticeTitle =>
      isArabic ? 'مطلوب تعديل واستكمال' : 'Corrections Required';
  String get resubmitBtn =>
      isArabic ? 'تعديل وإعادة الإرسال' : 'Edit & Resubmit';
  String get approvedCardTitle =>
      isArabic ? 'حسابك موثق ونشط' : 'Your Account is Verified';
  String get suspendedCardTitle =>
      isArabic ? 'تم تعليق التوثيق' : 'Verification Suspended';
  String get suspendedCardBody => isArabic
      ? 'تم تعليق صلاحيات البائع مؤقتاً. لا يزال بإمكانك استخدام حسابك كمشتري. تواصل مع الدعم لمزيد من التفاصيل.'
      : 'Seller privileges are temporarily suspended. Your buyer account remains active. Contact support for assistance.';

  // Screen 09: Verified Profile
  String get verifiedProfileTitle =>
      isArabic ? 'ملف البائع الموثق' : 'Verified Seller Profile';
  String get accountTypeLabel => isArabic ? 'تصنيف الحساب' : 'Seller Type';
  String get verificationLevelLabel =>
      isArabic ? 'مستوى التوثيق' : 'Verification Tier';

  // Screen 10: Business Upgrade
  String get businessUpgradeTitle => isArabic
      ? 'الترقية إلى شركة / مكتب موثق'
      : 'Upgrade to Business Verified';
  String get businessUpgradeSubtitle => isArabic
      ? 'قم بترقية حسابك الفردي الموثق إلى حساب شركة أو مكتب موثق مع الاحتفاظ بجميع إعلاناتك ومحادثاتك وتاريخك.'
      : 'Upgrade your Identity Verified account to Business Verified while keeping all listings, chats, and history intact.';
  String get currentTierLabel =>
      isArabic ? 'مستوى التوثيق الحالي' : 'Current Verification Level';
  String get upgradeBenefitsTitle =>
      isArabic ? 'ماذا تحصل عليه عند الترقية؟' : 'Upgrade Benefits';
  String get upgradePreservationNote => isArabic
      ? 'لن يتم إنشاء حساب جديد ولن تتأثر إعلاناتك أو محادثاتك الحالية. تظل شارة «هوية موثقة» نشطة أثناء مراجعة طلب الترقية.'
      : 'No second account is created. Your existing listings, chats, and Identity Verified badge remain active while under review.';
  String get startUpgradeBtn =>
      isArabic ? 'بدء طلب الترقية التجارية' : 'Start Business Upgrade';
  String get submitUpgradeBtn =>
      isArabic ? 'إرسال طلب الترقية' : 'Submit Upgrade Request';
  String get alreadyBusinessVerified => isArabic
      ? 'حسابك حاصل بالفعل على توثيق شركة / مكتب موثق.'
      : 'Your account is already Business Verified.';

  String statusLabel(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.notSubmitted:
        return isArabic ? 'لم يتم التقديم' : 'Not Submitted';
      case VerificationStatus.draft:
        return isArabic ? 'مسودة' : 'Draft';
      case VerificationStatus.pending:
        return isArabic ? 'قيد الانتظار' : 'Pending Review';
      case VerificationStatus.underReview:
        return isArabic ? 'قيد المراجعة' : 'Under Review';
      case VerificationStatus.needsChanges:
        return isArabic ? 'يتطلب تعديلات' : 'Needs Changes';
      case VerificationStatus.approved:
        return isArabic ? 'موثق ومعتمد' : 'Approved';
      case VerificationStatus.rejected:
        return isArabic ? 'مرفوض' : 'Rejected';
      case VerificationStatus.suspended:
        return isArabic ? 'معلّق' : 'Suspended';
      case VerificationStatus.expired:
        return isArabic ? 'منتهي الصلاحية' : 'Expired';
    }
  }

  String sellerTypeLabel(SellerType type) {
    switch (type) {
      case SellerType.individual:
        return individualTitle;
      case SellerType.business:
        return businessTitle;
      case SellerType.serviceProvider:
        return serviceProviderTitle;
    }
  }

  String sectionLabel(MarketplaceSectionSlug section) {
    switch (section) {
      case MarketplaceSectionSlug.realEstate:
        return isArabic ? 'العقارات' : 'Real Estate';
      case MarketplaceSectionSlug.buildingMaterials:
        return isArabic ? 'مواد البناء والكهرباء' : 'Building Materials';
      case MarketplaceSectionSlug.services:
        return isArabic ? 'الخدمات المنزلية والهندسية' : 'Home & Engineering Services';
      case MarketplaceSectionSlug.homeAppliances:
        return isArabic ? 'الأجهزة المنزلية والديكور' : 'Appliances & Decor';
      case MarketplaceSectionSlug.cars:
        return isArabic ? 'السيارات' : 'Cars';
      case MarketplaceSectionSlug.fashion:
        return isArabic ? 'الملابس والإكسسوارات' : 'Fashion & Accessories';
    }
  }

  String businessEntityTypeLabel(BusinessAccountType type) {
    switch (type) {
      case BusinessAccountType.company:
        return isArabic ? 'شركة' : 'Company';
      case BusinessAccountType.office:
        return isArabic ? 'مكتب عقاري / تجاري' : 'Office / Agency';
      case BusinessAccountType.store:
        return isArabic ? 'متجر / معرض' : 'Store / Showroom';
      case BusinessAccountType.factory:
        return isArabic ? 'مصنع / مورّد' : 'Factory / Supplier';
      case BusinessAccountType.individual:
        return isArabic ? 'فردي' : 'Individual';
    }
  }
}
