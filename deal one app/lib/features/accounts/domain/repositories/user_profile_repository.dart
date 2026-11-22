import 'package:market_space/features/accounts/domain/entities/user_profile_entity.dart';

abstract class UserProfileRepository {
  Future<UserProfileEntity> getMyProfile();
  Future<UserProfileEntity> updateMyProfile(UpdateUserProfileInput input);
  Future<void> createBusinessAccount({
    required String displayName,
    required String accountType,
    String? bio,
  });
}
