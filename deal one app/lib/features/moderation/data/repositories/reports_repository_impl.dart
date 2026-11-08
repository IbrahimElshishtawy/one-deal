import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/moderation/data/dto/report_dto.dart';
import 'package:market_space/features/moderation/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ApiClient apiClient;

  ReportsRepositoryImpl({required this.apiClient});

  @override
  Future<void> fileReport(CreateReportDto dto) async {
    await apiClient.post(
      ApiEndpoints.reports,
      data: dto.toJson(),
    );
  }
}
