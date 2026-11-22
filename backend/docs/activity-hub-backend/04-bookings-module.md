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
- Self-booking is rejected.
- `scheduledDate` (`YYYY-MM-DD`) and `scheduledTime` (`HH:mm`, Africa/Cairo `+02:00`) are parsed into UTC `scheduledAt` and validated to be in the future.
- `createBooking` and `updateBookingStatus` run inside `Prisma.TransactionIsolationLevel.Serializable` transactions to prevent double-booking race conditions.
- `PATCH /api/v1/bookings/:id/status` is restricted to the provider account owner, authorized account members (`owner`, `manager`, `responder`), or `MODERATOR` / `SUPER_ADMIN`.
