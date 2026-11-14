import '../../domain/entities/auth_session.dart';
import '../dto/auth_dto.dart';

/// Maps authentication DTO payloads into domain entities.
class AuthMapper {
  static AuthUser toUserEntity(AuthUserDto dto) {
    return AuthUser(
      id: dto.id,
      phone: dto.phone,
      fullName: dto.fullName,
      email: dto.email,
      avatarUrl: dto.avatarUrl,
      isPhoneVerified: dto.isPhoneVerified,
      preferredLanguage: dto.preferredLanguage,
      role: dto.role,
    );
  }

  static ActiveAccountSummary? toActiveAccountEntity(
    ActiveAccountSummaryDto? dto,
  ) {
    if (dto == null || dto.id.isEmpty) {
      return null;
    }
    return ActiveAccountSummary(
      id: dto.id,
      accountType: dto.accountType,
      displayName: dto.displayName,
      verificationStatus: dto.verificationStatus,
      role: dto.role,
    );
  }

  static AuthSession toSessionEntity(AuthResponseDto dto) {
    return AuthSession(
      accessToken: dto.accessToken,
      refreshToken: dto.refreshToken,
      user: toUserEntity(dto.user),
      activeAccount: toActiveAccountEntity(dto.activeAccount),
      expiresIn: dto.expiresIn,
      sessionId: dto.sessionId,
    );
  }

  static OtpDispatchResult toOtpDispatchEntity(OtpDispatchResponseDto dto) {
    return OtpDispatchResult(
      success: dto.success,
      message: dto.message,
      cooldownSeconds: dto.cooldownSeconds,
      otpExpirySeconds: dto.otpExpirySeconds,
    );
  }
}
