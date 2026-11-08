import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/quotas/data/dto/quota_dto.dart';
import 'package:market_space/features/quotas/domain/entities/quota_entity.dart';
import 'package:market_space/features/quotas/domain/repositories/quotas_repository.dart';

class QuotasRepositoryImpl implements QuotasRepository {
  final ApiClient apiClient;

  QuotasRepositoryImpl({required this.apiClient});

  @override
  Future<QuotaUsageEntity> getMyQuotaUsage() async {
    final response = await apiClient.get(ApiEndpoints.myQuotas);
    final data = response.data;
    final dto = QuotaUsageDto.fromJson(Map<String, dynamic>.from(data as Map));
    return QuotaUsageEntity(
      timezone: dto.timezone,
      date: dto.date,
      used: dto.used,
      limit: dto.limit,
      remaining: dto.remaining,
      isLimitReached: dto.isLimitReached,
    );
  }
}
