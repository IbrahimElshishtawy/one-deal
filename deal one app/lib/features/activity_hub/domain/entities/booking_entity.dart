/// Supported marketplace categories for Bookings & Appointments.
enum BookingCategory {
  realEstate,
  carsMaintenance,
  servicesEngineering;

  static BookingCategory fromBackend(String? raw) {
    final v = (raw ?? '').toLowerCase().trim();
    if (v.contains('real') || v.contains('estate') || v.contains('property')) {
      return BookingCategory.realEstate;
    }
    if (v.contains('car') || v.contains('vehicle') || v.contains('auto')) {
      return BookingCategory.carsMaintenance;
    }
    return BookingCategory.servicesEngineering;
  }
}

/// Specific booking / appointment sub-types across the 3 service-oriented sectors.
enum BookingType {
  propertyViewing,
  propertyInspection,
  agentContact,
  vehicleInspection,
  maintenanceBooking,
  serviceCenter,
  plumbing,
  electricity,
  airConditioning,
  construction,
  engineering;

  static BookingType fromBackend(String? raw) {
    final v = (raw ?? '').toLowerCase().trim();
    return switch (v) {
      'property_viewing' => BookingType.propertyViewing,
      'property_inspection' => BookingType.propertyInspection,
      'agent_contact' => BookingType.agentContact,
      'vehicle_inspection' => BookingType.vehicleInspection,
      'maintenance' || 'maintenance_booking' => BookingType.maintenanceBooking,
      'service_center' => BookingType.serviceCenter,
      'plumbing' => BookingType.plumbing,
      'electricity' || 'electrical' => BookingType.electricity,
      'ac' || 'air_conditioning' => BookingType.airConditioning,
      'construction' => BookingType.construction,
      'engineering' => BookingType.engineering,
      _ => BookingType.propertyViewing,
    };
  }
}

/// Presentation-level booking status mapped strictly from backend status strings.
enum BookingStatus {
  pending,
  confirmed,
  rejected,
  cancelled,
  completed,
  unknown;

  /// Maps raw backend status strings to presentation states without inventing statuses.
  static BookingStatus fromBackend(String? raw) {
    final normalized = (raw ?? '').toLowerCase().trim();
    return switch (normalized) {
      'pending' || 'requested' || 'awaiting_confirmation' => BookingStatus.pending,
      'confirmed' || 'approved' || 'accepted' || 'scheduled' => BookingStatus.confirmed,
      'rejected' || 'declined' => BookingStatus.rejected,
      'cancelled' || 'canceled' => BookingStatus.cancelled,
      'completed' || 'done' || 'finished' => BookingStatus.completed,
      _ => BookingStatus.unknown,
    };
  }
}

/// Domain entity representing a Booking or Appointment.
class BookingEntity {
  final String id;
  final String? listingId;
  final String title;
  final String? imageUrl;
  final String providerName;
  final BookingCategory category;
  final BookingType type;
  final DateTime? bookingDate;
  final String? bookingTime;
  final String address;
  final BookingStatus status;
  final String rawStatus;
  final String? referenceCode;
  final String? notes;
  final bool canCancel;
  final bool canContactProvider;
  final bool hasTracking;

  const BookingEntity({
    required this.id,
    this.listingId,
    required this.title,
    this.imageUrl,
    required this.providerName,
    required this.category,
    required this.type,
    this.bookingDate,
    this.bookingTime,
    required this.address,
    required this.status,
    required this.rawStatus,
    this.referenceCode,
    this.notes,
    this.canCancel = false,
    this.canContactProvider = true,
    this.hasTracking = false,
  });
}

/// Payload for requesting a new booking/viewing/inspection.
class CreateBookingPayload {
  final String? listingId;
  final String title;
  final String providerName;
  final BookingCategory category;
  final BookingType type;
  final DateTime date;
  final String timeSlot;
  final String address;
  final String? notes;

  const CreateBookingPayload({
    this.listingId,
    required this.title,
    required this.providerName,
    required this.category,
    required this.type,
    required this.date,
    required this.timeSlot,
    required this.address,
    this.notes,
  });
}
