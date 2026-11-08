class UserAccountEntity {
  final String id;
  final String accountType;
  final String displayName;
  final String slug;
  final String? bio;
  final String? logoUrl;
  final String verificationStatus;
  final bool isActive;
  final String role;
  final DateTime? joinedAt;

  const UserAccountEntity({
    required this.id,
    required this.accountType,
    required this.displayName,
    required this.slug,
    this.bio,
    this.logoUrl,
    required this.verificationStatus,
    this.isActive = true,
    required this.role,
    this.joinedAt,
  });

  bool get isOwner => role == 'owner';
  bool get isVerified => verificationStatus == 'approved';
}

class BranchEntity {
  final String id;
  final String accountId;
  final String name;
  final String address;
  final int cityId;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final bool isMain;

  const BranchEntity({
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
}
