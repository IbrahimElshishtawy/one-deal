import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/activity_hub/data/models/rfq_dto.dart';
import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';
import 'package:market_space/features/activity_hub/domain/repositories/rfq_repository.dart';

/// RFQ repository implementation connected to Deal One Backend
/// (`GET/POST /api/v1/rfqs`, `POST /api/v1/rfqs/:id/quotations`,
/// `PATCH /api/v1/quotations/:id/status`).
///
/// Strictly separates buyer RFQs (`scope=mine`) from supplier incoming RFQs
/// (`scope=open_for_suppliers`).
class RfqRepositoryImpl implements RfqRepository {
  final ApiClient? apiClient;

  RfqRepositoryImpl({this.apiClient});

  @override
  bool get isBackendSupported => apiClient != null;

  List<dynamic> _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      if (raw['data'] is List) return raw['data'] as List;
      if (raw['items'] is List) return raw['items'] as List;
      if (raw['data'] is Map && (raw['data'] as Map)['items'] is List) {
        return (raw['data'] as Map)['items'] as List;
      }
    }
    return const [];
  }

  Map<String, dynamic> _unwrapObject(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }
    return const <String, dynamic>{};
  }

  @override
  Future<List<RfqRequestEntity>> getMyRfqs({
    String scope = 'mine',
    String? categorySlug,
    int page = 1,
    int limit = 20,
  }) async {
    final client = apiClient;
    if (client == null) return const [];

    final response = await client.get(
      ApiEndpoints.rfqs,
      queryParameters: {
        'scope': scope,
        'page': page,
        'limit': limit,
        if (categorySlug != null && categorySlug.isNotEmpty)
          'categorySlug': categorySlug,
      },
    );

    return _unwrapList(response.data)
        .whereType<Map>()
        .map(
          (m) => RfqRequestDto.fromJson(Map<String, dynamic>.from(m)).toEntity(),
        )
        .toList();
  }

  @override
  Future<RfqRequestEntity> createRfq(CreateRfqPayload payload) async {
    final client = apiClient;
    if (client == null) {
      throw UnsupportedError('RFQ API client is not configured.');
    }

    final response = await client.post(
      ApiEndpoints.rfqs,
      data: {
        'title': payload.title,
        'materials': payload.materials,
        'quantity': payload.quantity,
        'deliveryLocation': payload.deliveryLocation,
        if (payload.description != null && payload.description!.isNotEmpty)
          'description': payload.description,
        if (payload.listingIds.isNotEmpty) 'listingIds': payload.listingIds,
      },
    );
    return RfqRequestDto.fromJson(_unwrapObject(response.data)).toEntity();
  }

  @override
  Future<void> acceptQuotation(String rfqId, String quotationId) async {
    final client = apiClient;
    if (client == null) {
      throw UnsupportedError('RFQ API client is not configured.');
    }

    await client.patch(
      ApiEndpoints.quotationStatus(quotationId),
      data: const {'status': 'ACCEPTED'},
    );
  }

  @override
  Future<void> rejectQuotation(String rfqId, String quotationId) async {
    final client = apiClient;
    if (client == null) {
      throw UnsupportedError('RFQ API client is not configured.');
    }

    await client.patch(
      ApiEndpoints.quotationStatus(quotationId),
      data: const {'status': 'REJECTED'},
    );
  }
}
