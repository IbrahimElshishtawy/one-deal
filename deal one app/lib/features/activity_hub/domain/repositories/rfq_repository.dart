import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';

abstract class RfqRepository {
  /// Indicates whether the backend currently exposes live RFQ endpoints.
  bool get isBackendSupported;

  Future<List<RfqRequestEntity>> getMyRfqs();
  Future<RfqRequestEntity> createRfq(CreateRfqPayload payload);
  Future<void> acceptQuotation(String rfqId, String quotationId);
  Future<void> rejectQuotation(String rfqId, String quotationId);
}
