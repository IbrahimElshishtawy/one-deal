import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/security/token_provider.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../dto/auth_dto.dart';
import '../mappers/auth_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final TokenProvider tokenProvider;

  AuthRepositoryImpl({
    required this.apiClient,
    required this.tokenProvider,
  });

  @override
  Future<void> sendOtp(String phone) async {
    final dto = SendOtpRequestDto(phone: phone);
    await apiClient.post(ApiEndpoints.sendOtp, data: dto.toJson());
  }

  @override
  Future<void> resendOtp(String phone) async {
    final dto = SendOtpRequestDto(phone: phone);
    await apiClient.post(ApiEndpoints.resendOtp, data: dto.toJson());
  }

  @override
  Future<AuthSession> verifyOtp(String phone, String code) async {
    final dto = VerifyOtpRequestDto(phone: phone, code: code);
    final response = await apiClient.post(
      ApiEndpoints.verifyOtp,
      data: dto.toJson(),
    );

    final responseData = response.data is Map
        ? (response.data['data'] as Map<String, dynamic>? ?? response.data)
        : <String, dynamic>{};

    final authResponseDto = AuthResponseDto.fromJson(
      Map<String, dynamic>.from(responseData as Map),
    );

    // Save tokens in secure storage
    await tokenProvider.saveTokens(
      accessToken: authResponseDto.accessToken,
      refreshToken: authResponseDto.refreshToken,
    );

    return AuthMapper.toSessionEntity(authResponseDto);
  }

  @override
  Future<AuthSession> loginWithPassword(String phone, String password) async {
    final dto = LoginPasswordRequestDto(phone: phone, password: password);
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: dto.toJson(),
    );

    final responseData = response.data is Map
        ? (response.data['data'] as Map<String, dynamic>? ?? response.data)
        : <String, dynamic>{};

    final authResponseDto = AuthResponseDto.fromJson(
      Map<String, dynamic>.from(responseData as Map),
    );

    await tokenProvider.saveTokens(
      accessToken: authResponseDto.accessToken,
      refreshToken: authResponseDto.refreshToken,
    );

    return AuthMapper.toSessionEntity(authResponseDto);
  }

  @override
  Future<void> logout() async {
    try {
      final currentRefresh = await tokenProvider.getRefreshToken();
      if (currentRefresh != null && currentRefresh.isNotEmpty) {
        final dto = RefreshTokenRequestDto(refreshToken: currentRefresh);
        await apiClient.post(ApiEndpoints.logout, data: dto.toJson());
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
}
