import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../dto/auth_dto.dart';

/// Remote API datasource executing HTTP requests for authentication & user profile.
abstract class AuthRemoteDataSource {
  Future<OtpDispatchResponseDto> sendOtp(SendOtpRequestDto dto);
  Future<OtpDispatchResponseDto> resendOtp(SendOtpRequestDto dto);
  Future<AuthResponseDto> verifyOtp(VerifyOtpRequestDto dto);
  Future<AuthResponseDto> loginWithPassword(LoginPasswordRequestDto dto);
  Future<AuthUserDto> updateProfile(UpdateProfileRequestDto dto);
  Future<AuthUserDto?> fetchCurrentUser();
  Future<void> logout(RefreshTokenRequestDto dto);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  const AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<OtpDispatchResponseDto> sendOtp(SendOtpRequestDto dto) async {
    final response = await apiClient.post(
      ApiEndpoints.sendOtp,
      data: dto.toJson(),
    );
    return OtpDispatchResponseDto.fromJson(_unwrapMap(response.data));
  }

  @override
  Future<OtpDispatchResponseDto> resendOtp(SendOtpRequestDto dto) async {
    final response = await apiClient.post(
      ApiEndpoints.resendOtp,
      data: dto.toJson(),
    );
    return OtpDispatchResponseDto.fromJson(_unwrapMap(response.data));
  }

  @override
  Future<AuthResponseDto> verifyOtp(VerifyOtpRequestDto dto) async {
    final response = await apiClient.post(
      ApiEndpoints.verifyOtp,
      data: dto.toJson(),
    );
    return AuthResponseDto.fromJson(_unwrapMap(response.data));
  }

  @override
  Future<AuthResponseDto> loginWithPassword(LoginPasswordRequestDto dto) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: dto.toJson(),
    );
    return AuthResponseDto.fromJson(_unwrapMap(response.data));
  }

  @override
  Future<AuthUserDto> updateProfile(UpdateProfileRequestDto dto) async {
    final response = await apiClient.put(
      ApiEndpoints.userMe,
      data: dto.toJson(),
    );
    final payload = _unwrapMap(response.data);
    final userMap = payload['user'] is Map
        ? Map<String, dynamic>.from(payload['user'] as Map)
        : payload;
    return AuthUserDto.fromJson(userMap);
  }

  @override
  Future<AuthUserDto?> fetchCurrentUser() async {
    final response = await apiClient.get(ApiEndpoints.userMe);
    final payload = _unwrapMap(response.data);
    if (payload.isEmpty) {
      return null;
    }
    final userMap = payload['user'] is Map
        ? Map<String, dynamic>.from(payload['user'] as Map)
        : payload;
    final dto = AuthUserDto.fromJson(userMap);
    return dto.id.isEmpty ? null : dto;
  }

  @override
  Future<void> logout(RefreshTokenRequestDto dto) async {
    await apiClient.post(ApiEndpoints.logout, data: dto.toJson());
  }

  /// Unwraps NestJS `{ success: true, data: ... }` envelope or returns raw Map.
  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is! Map) {
      return <String, dynamic>{};
    }
    final envelope = Map<String, dynamic>.from(raw);
    final innerData = envelope['data'];
    if (innerData is Map) {
      return Map<String, dynamic>.from(innerData);
    }
    return envelope;
  }
}
