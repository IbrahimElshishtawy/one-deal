import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';
import 'package:market_space/features/activity_hub/domain/repositories/rfq_repository.dart';

/// RFQ repository implementation.
///
/// Backend audit confirmed no `/rfqs` or `/quotations` endpoints exist in Deal One V1.
/// This implementation reports [isBackendSupported] = `false` and never
/// fabricates fake quotations or fake server submissions.
class RfqRepositoryImpl implements RfqRepository {
  @override
  bool get isBackendSupported => false;

  @override
  Future<List<RfqRequestEntity>> getMyRfqs() async {
    return const [];
  }

  @override
  Future<RfqRequestEntity> createRfq(CreateRfqPayload payload) async {
    throw UnsupportedError(
      'RFQ API endpoint is not yet implemented on the backend.',
    );
  }

  @override
  Future<void> acceptQuotation(String rfqId, String quotationId) async {
    throw UnsupportedError(
      'Quotation acceptance endpoint is not yet implemented on the backend.',
    );
  }

  @override
  Future<void> rejectQuotation(String rfqId, String quotationId) async {
    throw UnsupportedError(
      'Quotation rejection endpoint is not yet implemented on the backend.',
    );
  }
}
