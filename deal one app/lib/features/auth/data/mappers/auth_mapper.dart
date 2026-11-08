import '../../domain/entities/auth_session.dart';
import '../dto/auth_dto.dart';

class AuthMapper {
  static AuthUser toUserEntity(AuthUserDto dto) {
    return AuthUser(
      id: dto.id,
      phone: dto.phone,
      fullName: dto.fullName,
      email: dto.email,
      avatarUrl: dto.avatarUrl,
      isPhoneVerified: dto.isPhoneVerified,
    );
  }

  static AuthSession toSessionEntity(AuthResponseDto dto) {
    return AuthSession(
      accessToken: dto.accessToken,
      refreshToken: dto.refreshToken,
      user: toUserEntity(dto.user),
    );
  }
}
