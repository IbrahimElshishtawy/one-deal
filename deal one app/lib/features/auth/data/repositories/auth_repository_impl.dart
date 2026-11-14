import '../../../../core/network/api_client.dart';
import '../../../../core/security/token_provider.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../dto/auth_dto.dart';
import '../mappers/auth_mapper.dart';

/// Production implementation of [AuthRepository] backed by [AuthRemoteDataSource]
/// and hardware-backed [TokenProvider] storage.
class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final TokenProvider tokenProvider;
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({
    required this.apiClient,
    required this.tokenProvider,
    AuthRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource =
            remoteDataSource ?? AuthRemoteDataSourceImpl(apiClient: apiClient);

  @override
  Future<OtpDispatchResult> sendOtp(String phone) async {
    final dto = await _remoteDataSource.sendOtp(SendOtpRequestDto(phone: phone));
    return AuthMapper.toOtpDispatchEntity(dto);
  }

  @override
  Future<OtpDispatchResult> resendOtp(String phone) async {
    final dto = await _remoteDataSource.resendOtp(
      SendOtpRequestDto(phone: phone),
    );
    return AuthMapper.toOtpDispatchEntity(dto);
  }

  @override
  Future<AuthSession> verifyOtp(String phone, String code) async {
    final authDto = await _remoteDataSource.verifyOtp(
      VerifyOtpRequestDto(phone: phone, code: code),
    );
    await _persistTokens(authDto);
    return AuthMapper.toSessionEntity(authDto);
  }

  @override
  Future<AuthSession> loginWithPassword(String phone, String password) async {
    final authDto = await _remoteDataSource.loginWithPassword(
      LoginPasswordRequestDto(phone: phone, password: password),
    );
    await _persistTokens(authDto);
    return AuthMapper.toSessionEntity(authDto);
  }

  @override
  Future<AuthUser> updateProfile({required String fullName}) async {
    final dto = await _remoteDataSource.updateProfile(
      UpdateProfileRequestDto(fullName: fullName),
    );
    return AuthMapper.toUserEntity(dto);
  }

  @override
  Future<AuthUser?> fetchCurrentUser() async {
    final dto = await _remoteDataSource.fetchCurrentUser();
    if (dto == null) {
      return null;
    }
    return AuthMapper.toUserEntity(dto);
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
