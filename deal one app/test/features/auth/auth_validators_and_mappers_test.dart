import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/errors/app_exception.dart';
import 'package:market_space/features/auth/data/dto/auth_dto.dart';
import 'package:market_space/features/auth/data/mappers/auth_error_mapper.dart';
import 'package:market_space/features/auth/data/mappers/auth_mapper.dart';
import 'package:market_space/features/auth/domain/validators/auth_validators.dart';

void main() {
  group('Auth Validators', () {
    test(
      'FullNameValidator validates empty, short, digit-only, and valid names',
      () {
        expect(FullNameValidator.validate(''), isNotNull);
        expect(FullNameValidator.validate('   '), isNotNull);
        expect(FullNameValidator.validate('أ'), isNotNull);
        expect(FullNameValidator.validate('12345'), isNotNull);
        expect(FullNameValidator.validate('  أحمد   محمد  '), isNull);
        expect(
          FullNameValidator.normalize('  أحمد   محمد  '),
          equals('أحمد محمد'),
        );
      },
    );

    test('EgyptianPhoneValidator normalizes all Egyptian mobile formats', () {
      expect(EgyptianPhoneValidator.normalize('01012345678'), '+201012345678');
      expect(EgyptianPhoneValidator.normalize('1012345678'), '+201012345678');
      expect(EgyptianPhoneValidator.normalize('201112345678'), '+201112345678');
      expect(
        EgyptianPhoneValidator.normalize('00201212345678'),
        '+201212345678',
      );
      expect(
        EgyptianPhoneValidator.normalize('+20 151 234 5678'),
        '+201512345678',
      );
      expect(EgyptianPhoneValidator.normalize('٠١٠١٢٣٤٥٦٧٨'), '+201012345678');

      expect(EgyptianPhoneValidator.normalize('01312345678'), isNull);
      expect(EgyptianPhoneValidator.normalize('010123'), isNull);
      expect(EgyptianPhoneValidator.validate('010123'), isNotNull);
      expect(EgyptianPhoneValidator.validate('01012345678'), isNull);

      expect(
        EgyptianPhoneValidator.formatForDisplay('+201012345678'),
        '+20 101 234 5678',
      );
    });

    test('EmailValidator validates email syntax cleanly', () {
      expect(EmailValidator.validate(''), isNotNull);
      expect(EmailValidator.validate('invalid-email'), isNotNull);
      expect(EmailValidator.validate('user@dealone.eg'), isNull);
    });

    test('OtpCodeValidator normalizes Arabic digits and requires 6 digits', () {
      expect(OtpCodeValidator.normalizeDigits('١٢٣ ٤٥٦'), '123456');
      expect(OtpCodeValidator.validate('1234'), isNotNull);
      expect(OtpCodeValidator.validate('123456'), isNull);
      expect(OtpCodeValidator.validate('١٢٣٤٥٦'), isNull);
    });
  });

  group('Auth DTOs & Mappers', () {
    test('AuthResponseDto parses nested tokens and activeAccount from NestJS response', () {
      final dto = AuthResponseDto.fromJson({
        'user': {
          'id': 'usr_123',
          'phone': '+201012345678',
          'fullName': 'سارة علي',
          'isPhoneVerified': true,
          'preferredLanguage': 'ar',
        },
        'activeAccount': {
          'id': 'acc_456',
          'accountType': 'individual',
          'displayName': 'حساب سارة',
          'verificationStatus': 'approved',
          'role': 'owner',
        },
        'tokens': {
          'accessToken': 'nested_access_jwt',
          'refreshToken': 'nested_refresh_opaque',
          'expiresIn': 900,
          'sessionId': 'sess_789',
        },
      });

      final session = AuthMapper.toSessionEntity(dto);
      expect(session.accessToken, 'nested_access_jwt');
      expect(session.refreshToken, 'nested_refresh_opaque');
      expect(session.expiresIn, 900);
      expect(session.sessionId, 'sess_789');
      expect(session.user.fullName, 'سارة علي');
      expect(session.activeAccount?.id, 'acc_456');
      expect(session.activeAccount?.accountType, 'individual');
    });

    test(
      'OtpDispatchResponseDto reads cooldownSeconds and falls back safely',
      () {
        final explicitDto = OtpDispatchResponseDto.fromJson({
          'success': true,
          'message': 'OTP sent successfully',
          'cooldownSeconds': 45,
          'otpExpirySeconds': 180,
        });
        final entity = AuthMapper.toOtpDispatchEntity(explicitDto);
        expect(entity.cooldownSeconds, 45);
        expect(entity.otpExpirySeconds, 180);

        final emptyDto = OtpDispatchResponseDto.fromJson({});
        expect(emptyDto.cooldownSeconds, 60);
        expect(emptyDto.otpExpirySeconds, 180);
      },
    );
  });

  group('AuthErrorMapper', () {
    test('maps backend OTP error messages accurately to Arabic states', () {
      final invalid = AuthErrorMapper.map(
        const UnauthorizedException(message: 'Incorrect OTP code.'),
      );
      expect(invalid.kind, AuthErrorKind.invalidOtp);

      final expired = AuthErrorMapper.map(
        const UnauthorizedException(
          message: 'Invalid or expired OTP code. Please request a new code.',
        ),
      );
      expect(expired.kind, AuthErrorKind.expiredOtp);

      final locked = AuthErrorMapper.map(
        const UnauthorizedException(
          message: 'Maximum verification attempts exceeded. Please request a new OTP code.',
        ),
      );
      expect(locked.kind, AuthErrorKind.maxAttemptsExceeded);

      final rateLimited = AuthErrorMapper.map(
        const RateLimitException(
          message: 'Please wait for the cooldown timer to elapse before requesting another OTP.',
        ),
      );
      expect(rateLimited.kind, AuthErrorKind.rateLimited);

      final network = AuthErrorMapper.map(const NetworkException());
      expect(network.kind, AuthErrorKind.network);

      final dio400 = AuthErrorMapper.map(
        DioException(
          requestOptions: RequestOptions(path: '/auth/otp/verify'),
          response: Response(
            statusCode: 400,
            data: {
              'success': false,
              'error': {'message': 'code must be 6 digits'},
            },
            requestOptions: RequestOptions(path: '/auth/otp/verify'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(dio400.kind, AuthErrorKind.validation);
    });
  });
}
