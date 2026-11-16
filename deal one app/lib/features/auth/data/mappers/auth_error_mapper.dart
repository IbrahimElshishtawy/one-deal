import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/error_mapper.dart';

/// Semantic classification of authentication and OTP backend errors.
enum AuthErrorKind {
  invalidPhoneNumber,
  accountNotFound,
  existingAccount,
  invalidOtp,
  expiredOtp,
  maxAttemptsExceeded,
  otpDeliveryFailed,
  whatsappUnavailable,
  rateLimited,
  network,
  timeout,
  unauthorizedSession,
  invalidRefreshToken,
  validation,
  server,
  unexpectedResponse,
}

class AuthErrorFeedback {
  final AuthErrorKind kind;
  final String message;

  const AuthErrorFeedback({required this.kind, required this.message});

  bool get isDeliveryFailure =>
      kind == AuthErrorKind.whatsappUnavailable ||
      kind == AuthErrorKind.otpDeliveryFailed;
}

/// Converts raw exceptions or [AppFailure]s into Arabic user-facing feedback
/// aligned with the actual Deal One NestJS auth backend contract.
class AuthErrorMapper {
  static AuthErrorFeedback map(Object error) {
    final failure = ErrorMapper.map(error);
    final rawMessage = failure.userFriendlyMessage.toLowerCase();
    final rawCode = (failure.technicalCode ?? '').toUpperCase();

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

    if (rawCode == 'UNEXPECTED_RESPONSE' ||
        rawMessage.contains('unexpected authentication response')) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.unexpectedResponse,
        message:
            'تم استلام استجابة غير متوقعة من الخادم. يرجى المحاولة لاحقاً.',
      );
    }

    if (rawCode.contains('WHATSAPP') ||
        (rawMessage.contains('whatsapp') &&
            (rawMessage.contains('not registered') ||
                rawMessage.contains('unavailable') ||
                rawMessage.contains('not found') ||
                rawMessage.contains('no whatsapp')))) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.whatsappUnavailable,
        message: 'عذراً، هذا الرقم غير مسجل على تطبيق واتساب. يرجى استخدام طريقة أخرى.',
      );
    }

    if (rawCode == 'OTP_DELIVERY_FAILED' ||
        rawCode == 'SMS_DELIVERY_FAILED' ||
        rawMessage.contains('failed to deliver sms') ||
        rawMessage.contains('failed to deliver otp') ||
        rawMessage.contains('sms gateway')) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.otpDeliveryFailed,
        message: 'تعذر إرسال رمز التحقق حالياً. يرجى التأكد من الرقم أو المحاولة لاحقاً.',
      );
    }

    if (rawMessage.contains('maximum verification attempts') ||
        rawMessage.contains('max_attempts') ||
        rawMessage.contains('attempts exceeded')) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.maxAttemptsExceeded,
        message: 'تم تجاوز الحد الأقصى للمحاولات (5 محاولات). يرجى طلب رمز تحقق جديد.',
      );
    }

    if (rawMessage.contains('expired') ||
        rawMessage.contains('invalid or expired otp') ||
        rawMessage.contains('already been consumed')) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.expiredOtp,
        message: 'انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد',
      );
    }

    if (rawMessage.contains('incorrect otp') ||
        rawMessage.contains('wrong otp') ||
        (failure is UnauthorizedFailure && rawMessage.contains('otp'))) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.invalidOtp,
        message: 'رمز التحقق غير صحيح، يرجى التأكد وإعادة المحاولة',
      );
    }

    if (rawMessage.contains('refresh token')) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.invalidRefreshToken,
        message: 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.',
      );
    }

    if (failure is RateLimitFailure ||
        rawMessage.contains('cooldown') ||
        rawMessage.contains('too many')) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.rateLimited,
        message: 'تم إرسال عدة طلبات مؤخراً. يرجى انتظار انتهاء العداد قبل طلب رمز جديد.',
      );
    }

    if (failure is NotFoundFailure ||
        rawMessage.contains('user not found') ||
        rawMessage.contains('account not found')) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.accountNotFound,
        message: 'لم يتم العثور على حساب مرتبط بهذا الرقم.',
      );
    }

    if (failure is ConflictFailure ||
        rawMessage.contains('already exists') ||
        rawMessage.contains('already registered')) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.existingAccount,
        message: 'رقم الهاتف مسجل مسبقاً. يمكنك تسجيل الدخول مباشرة.',
      );
    }

    if (failure is ValidationFailure) {
      if (rawMessage.contains('egyptian') ||
          rawMessage.contains('phone') ||
          rawMessage.contains('mobile') ||
          rawMessage.contains('landline')) {
        return const AuthErrorFeedback(
          kind: AuthErrorKind.invalidPhoneNumber,
          message: 'أدخل رقم موبايل مصري صحيح (مثال: 01012345678)',
        );
      }
      if (rawMessage.contains('6 digits') || rawMessage.contains('otp code')) {
        return const AuthErrorFeedback(
          kind: AuthErrorKind.validation,
          message: 'يرجى إدخال رمز التحقق المكون من 6 أرقام',
        );
      }
      return AuthErrorFeedback(
        kind: AuthErrorKind.validation,
        message: _translateValidationMessage(rawMessage),
      );
    }

    if (failure is ForbiddenFailure ||
        rawMessage.contains('deactivated') ||
        rawMessage.contains('suspended')) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.unauthorizedSession,
        message: 'هذا الحساب غير مصرح له بالدخول حالياً. تواصل مع الدعم الفني.',
      );
    }

    if (failure is UnauthorizedFailure) {
      return const AuthErrorFeedback(
        kind: AuthErrorKind.unauthorizedSession,
        message:
            'انتهت صلاحية الجلسة أو بيانات التحقق غير صالحة. حاول مرة أخرى.',
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
