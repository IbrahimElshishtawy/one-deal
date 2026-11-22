# 04 — Bookings & Appointments Module

**Source:** `src/modules/bookings/`

## Supported Categories & Booking Types
- **Real Estate:** `property_viewing`, `property_inspection`, `general_inquiry`
- **Cars & Maintenance:** `vehicle_inspection`, `maintenance_appointment`, `service_center_booking`
- **Services & Engineering:** `plumbing_service`, `electrical_service`, `ac_service`, `construction_service`, `engineering_service`

## State Machine (`bookings-state-machine.ts`)
- `PENDING` -> `CONFIRMED` | `REJECTED` | `CANCELLED`
- `CONFIRMED` -> `CANCELLED` | `COMPLETED`
- `REJECTED`, `CANCELLED`, `COMPLETED` -> terminal (no transitions allowed)

## Security & Concurrency
- `providerAccountId` and `categoryId` are derived server-side from `listing` when `listingId` is provided.
- `bookingType` is validated against the listing's root category (`real-estate`, `cars`, `services`).
- Self-booking is rejected for both the account owner and any `AccountMember` of the provider account.
- `scheduledDate` (`YYYY-MM-DD`) and `scheduledTime` (`HH:mm`, DST-aware `Africa/Cairo` via `Intl.DateTimeFormat`: `+02:00` winter / `+03:00` summer) are parsed into UTC `scheduledAt` and validated to be in the future.
- `createBooking`, `cancelBooking`, and `updateBookingStatus` read, validate transitions, and update inside `Prisma.TransactionIsolationLevel.Serializable` transactions backed by the partial unique index `uq_bookings_provider_confirmed_slot`.
- Detail, cancel, and status endpoints use `AdminJwtAuthGuard` (supporting both mobile `User` JWTs and Enterprise Admin `StaffUser` JWTs); `PATCH /api/v1/bookings/:id/status` is restricted to the provider account owner, authorized account members (`owner`, `manager`, `responder`), or `MODERATOR` / `SUPER_ADMIN` staff.
