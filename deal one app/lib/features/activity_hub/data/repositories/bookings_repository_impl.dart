import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/domain/repositories/bookings_repository.dart';

/// Bookings repository implementation.
///
/// Backend audit confirmed no `/bookings` endpoints exist in Deal One V1.
/// This implementation reports [isBackendSupported] = `false` and never
/// fabricates fake server responses or fake booking records.
class BookingsRepositoryImpl implements BookingsRepository {
  @override
  bool get isBackendSupported => false;

  @override
  Future<List<BookingEntity>> getBookings() async {
    return const [];
  }

  @override
  Future<BookingEntity> createBooking(CreateBookingPayload payload) async {
    throw UnsupportedError(
      'Bookings API endpoint is not yet implemented on the backend.',
    );
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    throw UnsupportedError(
      'Booking cancellation endpoint is not yet implemented on the backend.',
    );
  }
}
