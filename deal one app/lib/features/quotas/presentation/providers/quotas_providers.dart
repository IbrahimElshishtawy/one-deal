import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/quotas/data/repositories/quotas_repository_impl.dart';
import 'package:market_space/features/quotas/domain/entities/quota_entity.dart';
import 'package:market_space/features/quotas/domain/repositories/quotas_repository.dart';

final quotasRepositoryProvider = Provider<QuotasRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return QuotasRepositoryImpl(apiClient: apiClient);
});

final myQuotaUsageProvider = FutureProvider<QuotaUsageEntity>((ref) async {
  final repository = ref.watch(quotasRepositoryProvider);
  return repository.getMyQuotaUsage();
});
