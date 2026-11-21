// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'package:market_space/l10n/app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'سوق سبيس';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get close => 'إغلاق';

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
}
