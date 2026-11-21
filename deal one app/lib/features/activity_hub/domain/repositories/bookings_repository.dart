import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';

abstract class BookingsRepository {
  /// Indicates whether the backend currently exposes live booking endpoints.
  bool get isBackendSupported;

  Future<List<BookingEntity>> getBookings();
  Future<BookingEntity> createBooking(CreateBookingPayload payload);
  Future<void> cancelBooking(String bookingId);
}
