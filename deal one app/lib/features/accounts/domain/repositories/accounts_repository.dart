import 'package:market_space/features/accounts/domain/entities/account_entity.dart';

abstract class AccountsRepository {
  Future<List<UserAccountEntity>> getMyAccounts();
  Future<List<BranchEntity>> getAccountBranches(String accountId);
}
