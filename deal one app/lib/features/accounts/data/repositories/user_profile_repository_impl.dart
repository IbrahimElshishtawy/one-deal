import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/accounts/domain/entities/user_profile_entity.dart';
import 'package:market_space/features/accounts/domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final ApiClient apiClient;

  const UserProfileRepositoryImpl({required this.apiClient});

  @override
  Future<UserProfileEntity> getMyProfile() async {
    final response = await apiClient.get(ApiEndpoints.userMe);
    return _parseProfile(response.data);
  }

  @override
  Future<UserProfileEntity> updateMyProfile(
    UpdateUserProfileInput input,
  ) async {
    final response = await apiClient.put(
      ApiEndpoints.userMe,
      data: input.toJson(),
    );
    return _parseProfile(response.data);
  }

  @override
  Future<void> createBusinessAccount({
    required String displayName,
    required String accountType,
    String? bio,
  }) async {
    await apiClient.post(
      ApiEndpoints.accounts,
      data: {
        'displayName': displayName.trim(),
        'accountType': accountType,
        if (bio != null && bio.trim().isNotEmpty) 'bio': bio.trim(),
      },
    );
  }

  UserProfileEntity _parseProfile(dynamic raw) {
    Map<String, dynamic> map = <String, dynamic>{};
    if (raw is Map) {
      final inner = raw['data'] is Map ? raw['data'] as Map : raw;
      final userMap = inner['user'] is Map ? inner['user'] as Map : inner;
      map = Map<String, dynamic>.from(userMap);
    }

    return UserProfileEntity(
      id: map['id']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      fullName: map['fullName']?.toString() ??
          map['full_name']?.toString() ??
          '',
      email: map['email']?.toString(),
      avatarUrl: map['avatarUrl']?.toString() ?? map['avatar_url']?.toString(),
      isPhoneVerified:
          map['isPhoneVerified'] == true || map['is_phone_verified'] == true,
      isEmailVerified:
          map['isEmailVerified'] == true || map['is_email_verified'] == true,
      isActive: map['isActive'] != false,
      preferredLanguage: map['preferredLanguage']?.toString() ??
          map['preferred_language']?.toString() ??
          'ar',
      role: map['role']?.toString() ?? 'USER',
      status: map['status']?.toString() ?? 'ACTIVE',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }
}
