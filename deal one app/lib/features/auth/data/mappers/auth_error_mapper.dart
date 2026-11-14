import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/error_mapper.dart';

/// Semantic classification of authentication and OTP backend errors.
enum AuthErrorKind {
  invalidOtp,
  expiredOtp,
  maxAttemptsExceeded,
  rateLimited,
  network,
  timeout,
  validation,
  server,
}

class AuthErrorFeedback {
  final AuthErrorKind kind;
  final String message;

  const AuthErrorFeedback({
    required this.kind,
    required this.message,
  });
}

/// Converts raw exceptions or [AppFailure]s into Arabic user-facing feedback
/// aligned with the actual Deal One NestJS auth backend contract.
class AuthErrorMapper {
  static AuthErrorFeedback map(Object error) {
    final failure = ErrorMapper.map(error);
    final rawMessage = failure.userFriendlyMessage.toLowerCase();

    if (failure is NetworkFailure) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.network,
        message: 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.',
      );
    }

    if (failure is TimeoutFailure) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.timeout,
        message: 'انتهت مهلة الاتصال بالخادم. يرجى المحاولة مرة أخرى.',
      );
    }

    if (rawMessage.contains('maximum verification attempts') ||
        rawMessage.contains('max_attempts') ||
        rawMessage.contains('attempts exceeded')) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.maxAttemptsExceeded,
        message:
            'تم تجاوز الحد الأقصى للمحاولات (5 محاولات). يرجى طلب رمز تحقق جديد.',
      );
    }

    if (rawMessage.contains('expired') ||
        rawMessage.contains('invalid or expired otp')) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.expiredOtp,
        message: 'انتهت صلاحية الرمز، يرجى طلب رمز جديد',
      );
    }

    if (rawMessage.contains('incorrect otp') ||
        rawMessage.contains('wrong otp') ||
        (failure is UnauthorizedFailure && rawMessage.contains('otp'))) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.invalidOtp,
        message: 'الرمز غير صحيح، يرجى المحاولة مرة أخرى',
      );
    }

    if (failure is RateLimitFailure ||
        rawMessage.contains('cooldown') ||
        rawMessage.contains('too many')) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.rateLimited,
        message:
            'تم إرسال عدة طلبات مؤخراً. يرجى الانتظار انتهاء العداد قبل طلب رمز جديد.',
      );
    }

    if (failure is ValidationFailure) {
      return AuthErrorFeedback(
        kind: AuthErrorKind.validation,
        message: _translateValidationMessage(rawMessage),
      );
    }

    if (failure is ConflictFailure) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.validation,
        message: 'بيانات الحساب مسجلة مسبقاً. يمكنك تسجيل الدخول برقمك.',
      );
    }

    if (failure is ForbiddenFailure) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.server,
        message: 'هذا الحساب غير مصرح له بالدخول حالياً. تواصل مع الدعم الفني.',
      );
    }

    if (failure is UnauthorizedFailure) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.invalidOtp,
        message: 'بيانات التحقق غير صحيحة أو انتهت الجلسة. حاول مرة أخرى.',
      );
    }

    return const AuthErrorFeedback(
      kind: AuthErrorKind.server,
      message: 'حدث خطأ غير متوقع في الخادم. يرجى المحاولة لاحقاً.',
    );
  }

  static String _translateValidationMessage(String rawLower) {
    if (rawLower.contains('egyptian') || rawLower.contains('phone')) {
      return 'أدخل رقم موبايل مصري صحيح (مثال: 01012345678)';
    }
    if (rawLower.contains('6 digits') || rawLower.contains('code')) {
      return 'يرجى إدخال رمز التحقق المكون من 6 أرقام';
    }
    if (rawLower.contains('fullname') || rawLower.contains('name')) {
      return 'يرجى إدخال الاسم الكامل بشكل صحيح';
    }
    return 'يرجى مراجعة البيانات المدخلة والمحاولة مرة أخرى';
  }
}
