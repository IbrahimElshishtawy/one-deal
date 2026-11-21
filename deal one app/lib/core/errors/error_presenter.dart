import 'package:market_space/core/errors/app_exception.dart';
import 'package:market_space/core/errors/app_failure.dart';
import 'package:market_space/core/errors/error_mapper.dart';

/// Categorized UI feature state for structured error rendering.
enum FeatureErrorKind {
  offline,
  timeout,
  rateLimited,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  unknown,
}

class UserFriendlyError {
  final FeatureErrorKind kind;
  final String title;
  final String message;
  final bool canRetry;

  const UserFriendlyError({
    required this.kind,
    required this.title,
    required this.message,
    this.canRetry = true,
  });
}

/// Converts any exception or failure into clean, localized Arabic/English copy.
/// Never exposes stack traces, HTTP internals, or database details to the user.
class ErrorPresenter {
  static UserFriendlyError present(Object error, {bool isArabic = true}) {
    final failure = error is AppFailure ? error : ErrorMapper.map(error);

    if (failure is NetworkFailure || error is NetworkException) {
      return UserFriendlyError(
        kind: FeatureErrorKind.offline,
        title: isArabic ? 'لا يوجد اتصال بالإنترنت' : 'No Internet Connection',
        message: isArabic
            ? 'تحقق من اتصالك بالشبكة وحاول مرة أخرى.'
            : 'Check your network connection and try again.',
        canRetry: true,
      );
    }

    if (failure is TimeoutFailure || error is TimeoutException) {
      return UserFriendlyError(
        kind: FeatureErrorKind.timeout,
        title: isArabic ? 'انتهت مهلة الاتصال' : 'Connection Timed Out',
        message: isArabic
            ? 'الخادم يستغرق وقتاً أطول من المعتاد. يرجى المحاولة مجدداً.'
            : 'The server is taking too long to respond. Please retry.',
        canRetry: true,
      );
    }

    if (failure is RateLimitFailure) {
      return UserFriendlyError(
        kind: FeatureErrorKind.rateLimited,
        title: isArabic ? 'طلبات كثيرة جداً' : 'Too Many Requests',
        message: isArabic
            ? 'يرجى الانتظار لحظات قبل المحاولة مرة أخرى.'
            : 'Please wait a moment before trying again.',
        canRetry: true,
      );
    }

    if (failure is UnauthorizedFailure) {
      return UserFriendlyError(
        kind: FeatureErrorKind.unauthorized,
        title: isArabic ? 'انتهت الجلسة' : 'Session Expired',
        message: isArabic
            ? 'يرجى تسجيل الدخول للمتابعة.'
            : 'Please sign in to continue.',
        canRetry: false,
      );
    }

    if (failure is ForbiddenFailure) {
      return UserFriendlyError(
        kind: FeatureErrorKind.forbidden,
        title: isArabic ? 'صلاحية غير متاحة' : 'Access Restricted',
        message: isArabic
            ? 'ليس لديك صلاحية للوصول إلى هذا المحتوى حالياً.'
            : 'You do not have permission to access this content.',
        canRetry: false,
      );
    }

    if (failure is NotFoundFailure) {
      return UserFriendlyError(
        kind: FeatureErrorKind.notFound,
        title: isArabic ? 'المحتوى غير متوفر' : 'Content Not Found',
        message: isArabic
            ? 'قد يكون هذا العنصر قد تم حذفه أو لم يعد متاحاً.'
            : 'This item may have been removed or is no longer available.',
        canRetry: false,
      );
    }

    if (failure is ValidationFailure || failure is ConflictFailure) {
      return UserFriendlyError(
        kind: FeatureErrorKind.validation,
        title: isArabic ? 'بيانات غير مكتملة' : 'Invalid Request',
        message: isArabic
            ? 'يرجى مراجعة المدخلات والمحاولة مرة أخرى.'
            : 'Please check your input and try again.',
        canRetry: true,
      );
    }

    if (failure is ServerFailure) {
      return UserFriendlyError(
        kind: FeatureErrorKind.server,
        title: isArabic
            ? 'الخدمة غير متاحة مؤقتاً'
            : 'Service Temporarily Unavailable',
        message: isArabic
            ? 'نواجه ضغطاً مؤقتاً على الخادم. حاول مرة أخرى بعد قليل.'
            : 'We are experiencing temporary server load. Please retry shortly.',
        canRetry: true,
      );
    }

    return UserFriendlyError(
      kind: FeatureErrorKind.unknown,
      title: isArabic ? 'حدث خطأ غير متوقع' : 'Something Went Wrong',
      message: isArabic
          ? 'تعذر تحميل البيانات حالياً. يرجى المحاولة مرة أخرى.'
          : 'Unable to load data right now. Please try again.',
      canRetry: true,
    );
  }
}
