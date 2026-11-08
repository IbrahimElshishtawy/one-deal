import 'package:market_space/features/accounts/data/dto/account_dto.dart';
import 'package:market_space/features/accounts/domain/entities/account_entity.dart';

class AccountMapper {
  static UserAccountEntity toEntity(AccountMemberDto dto) {
    DateTime? parsedJoined;
    if (dto.joinedAt.isNotEmpty) {
      parsedJoined = DateTime.tryParse(dto.joinedAt);
    }

    return UserAccountEntity(
      id: dto.id,
      accountType: dto.accountType,
      displayName: dto.displayName,
      slug: dto.slug,
      bio: dto.bio,
      logoUrl: dto.logoUrl,
      verificationStatus: dto.verificationStatus,
      isActive: dto.isActive,
      role: dto.role,
      joinedAt: parsedJoined,
    );
  }

  static BranchEntity toBranchEntity(BranchDto dto) {
    return BranchEntity(
      id: dto.id,
      accountId: dto.accountId,
      name: dto.name,
      address: dto.address,
      cityId: dto.cityId,
      latitude: dto.latitude,
      longitude: dto.longitude,
      phone: dto.phone,
      isMain: dto.isMain,
    );
  }
}
