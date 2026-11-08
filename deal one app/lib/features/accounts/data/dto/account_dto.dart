class AccountMemberDto {
  final String id;
  final String accountType;
  final String displayName;
  final String slug;
  final String? bio;
  final String? logoUrl;
  final String verificationStatus;
  final bool isActive;
  final String role; // owner, admin, member
  final String joinedAt;

  const AccountMemberDto({
    required this.id,
    required this.accountType,
    required this.displayName,
    required this.slug,
    this.bio,
    this.logoUrl,
    required this.verificationStatus,
    this.isActive = true,
    required this.role,
    required this.joinedAt,
  });

  factory AccountMemberDto.fromJson(Map<String, dynamic> json) {
    return AccountMemberDto(
      id: json['id']?.toString() ?? '',
      accountType: json['accountType']?.toString() ?? json['account_type']?.toString() ?? 'individual',
      displayName: json['displayName']?.toString() ?? json['display_name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      bio: json['bio']?.toString(),
      logoUrl: json['logoUrl']?.toString() ?? json['logo_url']?.toString(),
      verificationStatus: json['verificationStatus']?.toString() ?? json['verification_status']?.toString() ?? 'pending',
      isActive: json['isActive'] != false && json['is_active'] != false,
      role: json['role']?.toString() ?? 'member',
      joinedAt: json['joinedAt']?.toString() ?? json['joined_at']?.toString() ?? '',
    );
  }
}

class BranchDto {
  final String id;
  final String accountId;
  final String name;
  final String address;
  final int cityId;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final bool isMain;

  const BranchDto({
    required this.id,
    required this.accountId,
    required this.name,
    required this.address,
    required this.cityId,
    this.latitude,
    this.longitude,
    this.phone,
    this.isMain = false,
  });

  factory BranchDto.fromJson(Map<String, dynamic> json) {
    return BranchDto(
      id: json['id']?.toString() ?? '',
      accountId: json['accountId']?.toString() ?? json['account_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      cityId: (json['cityId'] ?? json['city_id'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] ?? json['lat'] as num?)?.toDouble(),
      longitude: (json['longitude'] ?? json['lng'] as num?)?.toDouble(),
      phone: json['phone']?.toString(),
      isMain: json['isMain'] == true || json['is_main'] == true,
    );
  }
}
