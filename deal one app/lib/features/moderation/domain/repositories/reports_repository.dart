import 'package:market_space/features/moderation/data/dto/report_dto.dart';

abstract class ReportsRepository {
  Future<void> fileReport(CreateReportDto dto);
}
