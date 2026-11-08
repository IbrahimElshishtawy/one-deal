import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/accounts/data/dto/account_dto.dart';
import 'package:market_space/features/accounts/data/mappers/account_mapper.dart';
import 'package:market_space/features/accounts/domain/entities/account_entity.dart';
import 'package:market_space/features/accounts/domain/repositories/accounts_repository.dart';

class AccountsRepositoryImpl implements AccountsRepository {
  final ApiClient apiClient;

  AccountsRepositoryImpl({required this.apiClient});

  @override
  Future<List<UserAccountEntity>> getMyAccounts() async {
    final response = await apiClient.get(ApiEndpoints.myAccounts);
    final data = response.data;

    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    }

    final dtos = items
        .map((e) => AccountMemberDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return dtos.map(AccountMapper.toEntity).toList();
  }

  @override
  Future<List<BranchEntity>> getAccountBranches(String accountId) async {
    final response = await apiClient.get(ApiEndpoints.accountBranches(accountId));
    final data = response.data;

    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    }

    final dtos = items
        .map((e) => BranchDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return dtos.map(AccountMapper.toBranchEntity).toList();
  }
}
