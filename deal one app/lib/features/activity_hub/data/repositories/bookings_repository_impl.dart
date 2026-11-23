import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/activity_hub/data/models/booking_dto.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/domain/repositories/bookings_repository.dart';

/// Bookings repository implementation connected to Deal One Backend
/// (`GET /api/v1/bookings`, `POST /api/v1/bookings`, `PATCH /api/v1/bookings/:id/cancel`,
/// `PATCH /api/v1/bookings/:id/status`).
///
/// Supports both requester (`role=requester`, buyer's My Bookings) and
/// provider (`role=provider`, incoming service/maintenance requests).
class BookingsRepositoryImpl implements BookingsRepository {
  final ApiClient? apiClient;

  BookingsRepositoryImpl({this.apiClient});

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
  Future<List<BookingEntity>> getBookings({
    String role = 'requester',
    String? categorySlug,
    int page = 1,
    int limit = 20,
  }) async {
    final client = apiClient;
    if (client == null) return const [];

    final response = await client.get(
      ApiEndpoints.bookings,
      queryParameters: {
        'role': role,
        'page': page,
        'limit': limit,
        if (categorySlug != null && categorySlug.isNotEmpty)
          'categorySlug': categorySlug,
      },
    );

    return _unwrapList(response.data)
        .whereType<Map>()
        .map((m) => BookingDto.fromJson(Map<String, dynamic>.from(m)).toEntity())
        .toList();
  }

  @override
  Future<BookingEntity> createBooking(CreateBookingPayload payload) async {
    final client = apiClient;
    if (client == null) {
      throw UnsupportedError(
        'Bookings API client is not configured.',
      );
    }

    final response = await client.post(
      ApiEndpoints.bookings,
      data: {
        if (payload.listingId != null && payload.listingId!.isNotEmpty)
          'listingId': payload.listingId,
        'bookingType': _backendBookingType(payload.type),
        'scheduledDate':
            '${payload.date.year.toString().padLeft(4, '0')}-${payload.date.month.toString().padLeft(2, '0')}-${payload.date.day.toString().padLeft(2, '0')}',
        'scheduledTime': payload.timeSlot,
        'location': payload.address,
        if (payload.notes != null && payload.notes!.isNotEmpty)
          'notes': payload.notes,
      },
    );
    return BookingDto.fromJson(_unwrapObject(response.data)).toEntity();
  }

  String _backendBookingType(BookingType type) {
    switch (type) {
      case BookingType.propertyViewing:
        return 'PROPERTY_VIEWING';
      case BookingType.propertyInspection:
        return 'PROPERTY_INSPECTION';
      case BookingType.agentContact:
        return 'GENERAL_INQUIRY';
      case BookingType.vehicleInspection:
        return 'VEHICLE_INSPECTION';
      case BookingType.maintenanceBooking:
        return 'MAINTENANCE_APPOINTMENT';
      case BookingType.serviceCenter:
        return 'SERVICE_CENTER_BOOKING';
      case BookingType.plumbing:
        return 'PLUMBING_SERVICE';
      case BookingType.electricity:
        return 'ELECTRICAL_SERVICE';
      case BookingType.airConditioning:
        return 'AC_SERVICE';
      case BookingType.construction:
        return 'CONSTRUCTION_SERVICE';
      case BookingType.engineering:
        return 'ENGINEERING_SERVICE';
    }
  }

  @override
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    final client = apiClient;
    if (client == null) {
      throw UnsupportedError(
        'Bookings API client is not configured.',
      );
    }

    await client.patch(
      ApiEndpoints.bookingCancel(bookingId),
      data: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  Future<BookingEntity> updateBookingStatus(
    String bookingId,
    String status,
  ) async {
    final client = apiClient;
    if (client == null) {
      throw UnsupportedError(
        'Bookings API client is not configured.',
      );
    }

    final response = await client.patch(
      ApiEndpoints.bookingStatus(bookingId),
      data: {'status': status},
    );
    return BookingDto.fromJson(_unwrapObject(response.data)).toEntity();
  }
}
