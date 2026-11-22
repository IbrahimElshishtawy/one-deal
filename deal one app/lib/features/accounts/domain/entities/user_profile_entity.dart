class UserProfileEntity {
  final String id;
  final String phone;
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final bool isActive;
  final String preferredLanguage;
  final String role;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfileEntity({
    required this.id,
    required this.phone,
    required this.fullName,
    this.email,
    this.avatarUrl,
    this.isPhoneVerified = false,
    this.isEmailVerified = false,
    this.isActive = true,
    this.preferredLanguage = 'ar',
    this.role = 'USER',
    this.status = 'ACTIVE',
    this.createdAt,
    this.updatedAt,
  });

  UserProfileEntity copyWith({
    String? fullName,
    String? email,
    String? avatarUrl,
    bool? isPhoneVerified,
    bool? isEmailVerified,
    String? preferredLanguage,
  }) {
    return UserProfileEntity(
      id: id,
      phone: phone,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      role: role,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class UpdateUserProfileInput {
  final String? fullName;
  final String? avatarUrl;
  final String? preferredLanguage;
  final int? governorateId;
  final int? cityId;

  const UpdateUserProfileInput({
    this.fullName,
    this.avatarUrl,
    this.preferredLanguage,
    this.governorateId,
    this.cityId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (fullName != null && fullName!.trim().isNotEmpty)
        'fullName': fullName!.trim(),
      if (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
        'avatarUrl': avatarUrl!.trim(),
      if (preferredLanguage != null && preferredLanguage!.isNotEmpty)
        'preferredLanguage': preferredLanguage,
      if (governorateId != null) 'governorateId': governorateId,
      if (cityId != null) 'cityId': cityId,
    };
  }
}
