# 04 — Bookings & Appointments API

- **Controller:** `backend/src/modules/bookings/bookings.controller.ts`
- **Service & State Machine:** `bookings.service.ts`, `bookings-state-machine.ts`
- **Endpoints:**
  - `POST /api/v1/bookings` (Rate-limited: 15/min; validates future `Africa/Cairo` date/time, prevents duplicate active slot conflicts with HTTP 409)
  - `GET /api/v1/bookings` (Paginated; filters by `role=requester|provider`, `status`, `bookingType`, `categoryId`, `categorySlug`)
  - `GET /api/v1/bookings/:id` (IDOR-protected: requester, provider account member, or admin only)
  - `PATCH /api/v1/bookings/:id/cancel` (`PENDING` / `CONFIRMED` -> `CANCELLED`)
  - `PATCH /api/v1/bookings/:id/status` (Provider/admin only; enforces `PENDING -> CONFIRMED | REJECTED`, `CONFIRMED -> COMPLETED`)
