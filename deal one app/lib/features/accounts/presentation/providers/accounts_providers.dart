import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/accounts/data/repositories/accounts_repository_impl.dart';
import 'package:market_space/features/accounts/domain/entities/account_entity.dart';
import 'package:market_space/features/accounts/domain/repositories/accounts_repository.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AccountsRepositoryImpl(apiClient: apiClient);
});

final myAccountsProvider = FutureProvider<List<UserAccountEntity>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.isAuthenticated) {
    return const [];
  }
  final repository = ref.watch(accountsRepositoryProvider);
  return repository.getMyAccounts();
});

final activeAccountProvider = StateProvider<UserAccountEntity?>((ref) {
  final session = ref.watch(sessionProvider);
  if (!session.isAuthenticated) {
    return null;
  }
  final accounts = ref.watch(myAccountsProvider).valueOrNull;
  if (accounts != null && accounts.isNotEmpty) {
    for (final acc in accounts) {
      if (acc.isActive && acc.isVerified) return acc;
    }
    return accounts.first;
  }
  return null;
});
