# 07 — Unified Activity Hub API

**Source:** `src/modules/activity-hub/`

## Endpoint
`GET /api/v1/activity-hub` (JWT authenticated via `JwtAuthGuard`)

## Query Parameters
- `include`: Optional comma-separated list of sections (`cart,bookings,rfqs,favorites`). Defaults to all 4 sections.
- `page`: Page number (default `1`).
- `limit`: Items per section (default `10`, max `50`).
- `categoryId`: Optional category UUID filter applied across sections.
- `categorySlug`: Optional category slug filter applied across sections.

## Response Structure (inside standard `{ success: true, data }` envelope)
- `summary`: `{ cartItemsCount, activeBookingsCount, activeRfqCount, favoritesCount }`
- `cart` (when included): `{ commerceMode, checkoutSupported, estimatedSubtotal, currency, items, pagination }`
- `bookings` (when included): `{ items, pagination }`
- `rfqs` (when included): `{ items, pagination }`
- `favorites` (when included): `{ items, pagination }`
