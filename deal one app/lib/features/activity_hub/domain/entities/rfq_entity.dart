/// Presentation-level RFQ status mapped from backend strings.
enum RfqStatus {
  draft,
  submitted,
  underReview,
  quoted,
  accepted,
  rejected,
  closed,
  unknown;

  static RfqStatus fromBackend(String? raw) {
    final normalized = (raw ?? '').toLowerCase().trim();
    return switch (normalized) {
      'draft' => RfqStatus.draft,
      'submitted' || 'open' || 'pending' => RfqStatus.submitted,
      'under_review' || 'reviewing' => RfqStatus.underReview,
      'quoted' || 'has_quotes' => RfqStatus.quoted,
      'accepted' || 'awarded' => RfqStatus.accepted,
      'rejected' || 'declined' => RfqStatus.rejected,
      'closed' || 'expired' || 'cancelled' => RfqStatus.closed,
      _ => RfqStatus.unknown,
    };
  }
}

/// Represents a supplier quotation received for an RFQ.
class RfqQuotationEntity {
  final String id;
  final String rfqId;
  final String supplierName;
  final double totalPrice;
  final String currency;
  final String? deliveryEstimate;
  final String? notes;
  final String rawStatus;
  final bool canAccept;
  final bool canReject;
  final DateTime? createdAt;

  const RfqQuotationEntity({
    required this.id,
    required this.rfqId,
    required this.supplierName,
    required this.totalPrice,
    this.currency = 'EGP',
    this.deliveryEstimate,
    this.notes,
    required this.rawStatus,
    this.canAccept = false,
    this.canReject = false,
    this.createdAt,
  });
}

/// Represents a Request for Quotation (RFQ) for building materials / construction.
class RfqRequestEntity {
  final String id;
  final String title;
  final String referenceNumber;
  final DateTime submittedAt;
  final DateTime? updatedAt;
  final int requestedItemsCount;
  final String materialsSummary;
  final String quantitySummary;
  final String deliveryLocation;
  final String? projectDescription;
  final RfqStatus status;
  final String rawStatus;
  final List<RfqQuotationEntity> quotations;

  const RfqRequestEntity({
    required this.id,
    required this.title,
    required this.referenceNumber,
    required this.submittedAt,
    this.updatedAt,
    required this.requestedItemsCount,
    required this.materialsSummary,
    required this.quantitySummary,
    required this.deliveryLocation,
    this.projectDescription,
    required this.status,
    required this.rawStatus,
    this.quotations = const [],
  });

  int get quotationsCount => quotations.length;
}

/// Payload for submitting a new RFQ.
class CreateRfqPayload {
  final String title;
  final String materials;
  final String quantity;
  final String deliveryLocation;
  final String? description;
  final List<String> listingIds;

  const CreateRfqPayload({
    required this.title,
    required this.materials,
    required this.quantity,
    required this.deliveryLocation,
    this.description,
    this.listingIds = const [],
  });
}
