import 'package:market_space/features/quotas/domain/entities/quota_entity.dart';

abstract class QuotasRepository {
  Future<QuotaUsageEntity> getMyQuotaUsage();
}
