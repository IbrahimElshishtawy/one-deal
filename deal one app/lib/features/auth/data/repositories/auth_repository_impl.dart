import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:market_space/core/errors/app_exception.dart';
import 'package:market_space/core/errors/app_failure.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/security/token_provider.dart';
import 'package:market_space/features/auth/domain/entities/auth_session.dart';
import 'package:market_space/features/auth/domain/repositories/auth_repository.dart';
import 'package:market_space/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:market_space/features/auth/data/dto/auth_dto.dart';
import 'package:market_space/features/auth/data/mappers/auth_mapper.dart';

/// Production implementation of [AuthRepository] backed by [AuthRemoteDataSource]
/// and hardware-backed [TokenProvider] storage.
class AuthRepositoryImpl implements AuthRepository {
  static const String _devOfflineAccessToken = 'dev_offline_access_token';
  static const String _devOfflineRefreshToken = 'dev_offline_refresh_token';
  static final Map<String, String> _devOfflineOtps = <String, String>{};
  static String? _devOfflinePhone;
  static String _devOfflineFullName = 'Deal One Dev';

  final ApiClient apiClient;
  final TokenProvider tokenProvider;
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({
    required this.apiClient,
    required this.tokenProvider,
    AuthRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource =
           remoteDataSource ?? AuthRemoteDataSourceImpl(apiClient: apiClient);

  bool _isConnectionUnavailable(Object error) {
    return error is NetworkFailure ||
        error is TimeoutFailure ||
        error is NetworkException ||
        error is TimeoutException;
  }

  OtpDispatchResult _issueDevOfflineOtp(String phone, {required bool isResend}) {
    final code = (100000 + Random().nextInt(900000)).toString();
    _devOfflineOtps[phone] = code;
    _logDevOtpToTerminal(phone, code, isResend: isResend);
    return OtpDispatchResult(
      success: true,
      message: 'تم إنشاء رمز تحقق تجريبي في Debug Console',
      cooldownSeconds: 60,
      otpExpirySeconds: 180,
      deliveryChannel: 'debug_console',
      devOtp: code,
    );
  }

  @override
  Future<OtpDispatchResult> sendOtp(String phone) async {
    try {
      final dto = await _remoteDataSource.sendOtp(
        SendOtpRequestDto(phone: phone),
      );
      _assertDispatchSucceeded(dto);
      final result = AuthMapper.toOtpDispatchEntity(dto);
      _logDevOtpToTerminal(phone, result.devOtp, isResend: false);
      return result;
    } catch (error) {
      // Temporary debug-only bypass when the local backend is unreachable.
      if (kDebugMode && _isConnectionUnavailable(error)) {
        return _issueDevOfflineOtp(phone, isResend: false);
      }
      rethrow;
    }
  }

  @override
  Future<OtpDispatchResult> resendOtp(String phone) async {
    try {
      final dto = await _remoteDataSource.resendOtp(
        SendOtpRequestDto(phone: phone),
      );
      _assertDispatchSucceeded(dto);
      final result = AuthMapper.toOtpDispatchEntity(dto);
      _logDevOtpToTerminal(phone, result.devOtp, isResend: true);
      return result;
    } catch (error) {
      // Temporary debug-only bypass when the local backend is unreachable.
      if (kDebugMode && _isConnectionUnavailable(error)) {
        return _issueDevOfflineOtp(phone, isResend: true);
      }
      rethrow;
    }
  }

  void _logDevOtpToTerminal(
    String phone,
    String? devOtp, {
    required bool isResend,
  }) {
    if (kReleaseMode || devOtp == null || devOtp.isEmpty) return;
    final action = isResend ? 'RESEND' : 'SEND';
    debugPrint(
      '\n╔══════════════════════════════════════════════════════════╗\n'
      '║ [DEV SMS OTP - $action]\n'
      '║ Phone    : $phone\n'
      '║ OTP CODE : $devOtp\n'
      '╚══════════════════════════════════════════════════════════╝',
    );
  }

  void _assertDispatchSucceeded(OtpDispatchResponseDto dto) {
    if (!dto.success || dto.whatsappAvailable == false) {
      final code = dto.whatsappAvailable == false
          ? 'WHATSAPP_UNAVAILABLE'
          : (dto.errorCode ?? 'OTP_DELIVERY_FAILED');
      throw ServerException(message: dto.message, errorCode: code);
    }
  }

  @override
  Future<AuthSession> verifyOtp(String phone, String code) async {
    if (kDebugMode && _devOfflineOtps.containsKey(phone)) {
      final expectedCode = _devOfflineOtps[phone];
      if (code.trim() != expectedCode) {
        throw const ValidationException(
          message: 'رمز التحقق غير صحيح',
          errorCode: 'INVALID_OTP',
        );
      }
      _devOfflineOtps.remove(phone);
      _devOfflinePhone = phone;
      await tokenProvider.saveTokens(
        accessToken: _devOfflineAccessToken,
        refreshToken: _devOfflineRefreshToken,
      );
      return AuthSession(
        accessToken: _devOfflineAccessToken,
        refreshToken: _devOfflineRefreshToken,
        user: AuthUser(
          id: 'dev-offline-user',
          phone: phone,
          fullName: 'Deal One Dev',
          isPhoneVerified: true,
        ),
      );
    }

    final authDto = await _remoteDataSource.verifyOtp(
      VerifyOtpRequestDto(phone: phone, code: code),
    );
    _assertValidAuthResponse(authDto);
    await _persistTokens(authDto);
    return AuthMapper.toSessionEntity(authDto);
  }

  @override
  Future<AuthSession> loginWithPassword(String phone, String password) async {
    final authDto = await _remoteDataSource.loginWithPassword(
      LoginPasswordRequestDto(phone: phone, password: password),
    );
    _assertValidAuthResponse(authDto);
    await _persistTokens(authDto);
    return AuthMapper.toSessionEntity(authDto);
  }

  void _assertValidAuthResponse(AuthResponseDto dto) {
    if (dto.accessToken.isEmpty ||
        dto.refreshToken.isEmpty ||
        dto.user.id.isEmpty) {
      throw const UnknownException(
        message: 'Unexpected authentication response from server.',
        errorCode: 'UNEXPECTED_RESPONSE',
      );
    }
  }

  @override
  Future<AuthUser> updateProfile({required String fullName}) async {
    try {
      final dto = await _remoteDataSource.updateProfile(
        UpdateProfileRequestDto(fullName: fullName),
      );
      return AuthMapper.toUserEntity(dto);
    } catch (error) {
      if (kDebugMode && _isConnectionUnavailable(error)) {
        final token = await tokenProvider.getAccessToken();
        if (token == _devOfflineAccessToken) {
          _devOfflineFullName = fullName.trim();
          return AuthUser(
            id: 'dev-offline-user',
            phone: _devOfflinePhone ?? '+201000000000',
            fullName: _devOfflineFullName,
            isPhoneVerified: true,
          );
        }
      }
      rethrow;
    }
  }

  @override
  Future<AuthUser?> fetchCurrentUser() async {
    try {
      final dto = await _remoteDataSource.fetchCurrentUser();
      if (dto == null) {
        return null;
      }
      return AuthMapper.toUserEntity(dto);
    } catch (error) {
      if (kDebugMode && _isConnectionUnavailable(error)) {
        final token = await tokenProvider.getAccessToken();
        if (token == _devOfflineAccessToken) {
          return AuthUser(
            id: 'dev-offline-user',
            phone: _devOfflinePhone ?? '+201000000000',
            fullName: _devOfflineFullName,
            isPhoneVerified: true,
          );
        }
      }
      rethrow;
    }
  }

  /// Dispatches a real email verification link for the authenticated user via
  /// `POST /auth/email/verification/request`.
  Future<EmailVerificationDispatchResponseDto> requestEmailVerification(
    String email,
  ) {
    return _remoteDataSource.requestEmailVerification(
      RequestEmailVerificationDto(email: email.trim().toLowerCase()),
    );
  }

  /// Verifies a single-use email verification token via `POST /auth/email/verify`.
  Future<bool> verifyEmailToken(String token) {
    return _remoteDataSource.verifyEmailToken(
      VerifyEmailTokenDto(token: token.trim()),
    );
  }

  @override
  Future<void> logout() async {
    try {
      final currentRefresh = await tokenProvider.getRefreshToken();
      if (currentRefresh != null && currentRefresh.isNotEmpty) {
        await _remoteDataSource.logout(
          RefreshTokenRequestDto(refreshToken: currentRefresh),
        );
      }
    } finally {
      await tokenProvider.clearTokens();
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await tokenProvider.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _persistTokens(AuthResponseDto dto) async {
    if (dto.accessToken.isNotEmpty || dto.refreshToken.isNotEmpty) {
      await tokenProvider.saveTokens(
        accessToken: dto.accessToken,
        refreshToken: dto.refreshToken,
      );
    }
  }
}
