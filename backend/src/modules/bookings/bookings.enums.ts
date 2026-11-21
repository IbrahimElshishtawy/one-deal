export enum BookingStatus {
  PENDING = 'PENDING',
  CONFIRMED = 'CONFIRMED',
  REJECTED = 'REJECTED',
  CANCELLED = 'CANCELLED',
  COMPLETED = 'COMPLETED',
}

export enum BookingType {
  // Real Estate
  PROPERTY_VIEWING = 'property_viewing',
  PROPERTY_INSPECTION = 'property_inspection',
  GENERAL_INQUIRY = 'general_inquiry',
  // Cars & Maintenance
  VEHICLE_INSPECTION = 'vehicle_inspection',
  MAINTENANCE_APPOINTMENT = 'maintenance_appointment',
  SERVICE_CENTER_BOOKING = 'service_center_booking',
  // Services & Engineering
  PLUMBING_SERVICE = 'plumbing_service',
  ELECTRICAL_SERVICE = 'electrical_service',
  AC_SERVICE = 'ac_service',
  CONSTRUCTION_SERVICE = 'construction_service',
  ENGINEERING_SERVICE = 'engineering_service',
}

export const ACTIVE_BOOKING_STATUSES: BookingStatus[] = [
  BookingStatus.PENDING,
  BookingStatus.CONFIRMED,
];
