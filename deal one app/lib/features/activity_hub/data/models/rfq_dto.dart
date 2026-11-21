import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';

class RfqQuotationDto {
  final String id;
  final String rfqId;
  final String supplierName;
  final double totalPrice;
  final String currency;
  final String? deliveryEstimate;
  final String? notes;
  final String status;
  final bool canAccept;
  final bool canReject;
  final String? createdAt;

  const RfqQuotationDto({
    required this.id,
    required this.rfqId,
    required this.supplierName,
    required this.totalPrice,
    this.currency = 'EGP',
    this.deliveryEstimate,
    this.notes,
    required this.status,
    this.canAccept = false,
    this.canReject = false,
    this.createdAt,
  });

  factory RfqQuotationDto.fromJson(Map<String, dynamic> json) {
    return RfqQuotationDto(
      id: json['id']?.toString() ?? '',
      rfqId: json['rfqId']?.toString() ?? json['rfq_id']?.toString() ?? '',
      supplierName:
          json['supplierName']?.toString() ??
          json['supplier_name']?.toString() ??
          '',
      totalPrice:
          (json['totalPrice'] as num? ?? json['total_price'] as num?)
              ?.toDouble() ??
          0.0,
      currency: json['currency']?.toString() ?? 'EGP',
      deliveryEstimate:
          json['deliveryEstimate']?.toString() ??
          json['delivery_estimate']?.toString(),
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? '',
      canAccept: json['canAccept'] as bool? ?? json['can_accept'] as bool? ?? false,
      canReject: json['canReject'] as bool? ?? json['can_reject'] as bool? ?? false,
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString(),
    );
  }

  RfqQuotationEntity toEntity() {
    return RfqQuotationEntity(
      id: id,
      rfqId: rfqId,
      supplierName: supplierName,
      totalPrice: totalPrice,
      currency: currency,
      deliveryEstimate: deliveryEstimate,
      notes: notes,
      rawStatus: status,
      canAccept: canAccept,
      canReject: canReject,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
    );
  }
}

class RfqRequestDto {
  final String id;
  final String title;
  final String referenceNumber;
  final String submittedAt;
  final String? updatedAt;
  final int requestedItemsCount;
  final String materialsSummary;
  final String quantitySummary;
  final String deliveryLocation;
  final String? projectDescription;
  final String status;
  final List<RfqQuotationDto> quotations;

  const RfqRequestDto({
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
    this.quotations = const [],
  });

  factory RfqRequestDto.fromJson(Map<String, dynamic> json) {
    final rawQuotes = json['quotations'] as List? ?? const [];
    return RfqRequestDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      referenceNumber:
          json['referenceNumber']?.toString() ??
          json['reference_number']?.toString() ??
          '',
      submittedAt:
          json['submittedAt']?.toString() ??
          json['submitted_at']?.toString() ??
          '',
      updatedAt:
          json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
      requestedItemsCount:
          (json['requestedItemsCount'] as num? ??
                  json['requested_items_count'] as num?)
              ?.toInt() ??
          0,
      materialsSummary:
          json['materialsSummary']?.toString() ??
          json['materials_summary']?.toString() ??
          '',
      quantitySummary:
          json['quantitySummary']?.toString() ??
          json['quantity_summary']?.toString() ??
          '',
      deliveryLocation:
          json['deliveryLocation']?.toString() ??
          json['delivery_location']?.toString() ??
          '',
      projectDescription:
          json['projectDescription']?.toString() ??
          json['project_description']?.toString(),
      status: json['status']?.toString() ?? '',
      quotations: rawQuotes
          .whereType<Map>()
          .map((q) => RfqQuotationDto.fromJson(Map<String, dynamic>.from(q)))
          .toList(),
    );
  }

  RfqRequestEntity toEntity() {
    return RfqRequestEntity(
      id: id,
      title: title,
      referenceNumber: referenceNumber,
      submittedAt: DateTime.tryParse(submittedAt) ?? DateTime.now(),
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt!) : null,
      requestedItemsCount: requestedItemsCount,
      materialsSummary: materialsSummary,
      quantitySummary: quantitySummary,
      deliveryLocation: deliveryLocation,
      projectDescription: projectDescription,
      status: RfqStatus.fromBackend(status),
      rawStatus: status,
      quotations: quotations.map((q) => q.toEntity()).toList(),
    );
  }
}
