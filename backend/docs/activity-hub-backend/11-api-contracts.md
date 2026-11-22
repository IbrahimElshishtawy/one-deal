# 11 — Frontend Integration API Contracts (Flutter Ready)

**Base Prefix:** `/api/v1`  
**Envelope:** All responses follow `{ "success": true, "data": ..., "meta"?: { "total", "page", "limit", "totalPages" } }`.  
**Auth Header:** `Authorization: Bearer <accessToken>`

## Endpoints Summary

### Unified Activity Hub
- `GET /api/v1/activity-hub?include=cart,bookings,rfqs,favorites&page=1&limit=10&categoryId=&categorySlug=`

### Favorites
- `GET /api/v1/favorites?page=1&limit=20&categoryId=&categorySlug=&search=&includeUnavailable=false`
- `POST /api/v1/favorites` (body: `{ "listingId": "uuid" }`)
- `POST /api/v1/favorites/:listingId`
- `GET /api/v1/favorites/:listingId/status`
- `DELETE /api/v1/favorites/:listingId`
- Legacy mobile aliases preserved: `GET /api/v1/listings/favorites`, `POST /api/v1/listings/:listingId/favorite`

### Bookings & Appointments
- `POST /api/v1/bookings`
- `GET /api/v1/bookings?page=1&limit=20&status=&bookingType=&categoryId=&categorySlug=&role=requester|provider`
- `GET /api/v1/bookings/:id`
- `PATCH /api/v1/bookings/:id/cancel` (body: `{ "reason"?: "string" }`)
- `PATCH /api/v1/bookings/:id/status` (body: `{ "status": "CONFIRMED|REJECTED|COMPLETED", "reason"?: "string" }`)

### RFQ & Quotations
- `POST /api/v1/rfqs`
- `GET /api/v1/rfqs?page=1&limit=20&status=&categoryId=&categorySlug=&scope=mine|open_for_suppliers` (non-open `status` values rejected with `400` in `open_for_suppliers` scope)
- `GET /api/v1/rfqs/:id`
- `PATCH /api/v1/rfqs/:id` (edit `DRAFT` RFQ)
- `PATCH /api/v1/rfqs/:id/submit` (submit `DRAFT` RFQ -> `SUBMITTED`)
- `PATCH /api/v1/rfqs/:id/cancel` (body: `{ "reason"?: "string" }`)
- `POST /api/v1/rfqs/:id/quotations`
- `GET /api/v1/rfqs/:id/quotations?sortBy=totalAmount|estimatedDeliveryDays|createdAt&page=1&limit=20` (paginated `{ data, meta }`)
- `GET /api/v1/quotations/:id`
- `PATCH /api/v1/quotations/:id/status` (body: `{ "status": "SHORTLISTED|ACCEPTED|REJECTED|WITHDRAWN", "reason"?: "string" }`)

### Cart (V1 Non-Transactional Saved Basket)
- `GET /api/v1/cart?page=1&limit=20&categoryId=&categorySlug=` (strictly validated via `GetCartQueryDto`; `estimatedSubtotal` spans full matching basket)
- `POST /api/v1/cart/items` (body: `{ "listingId": "uuid", "quantity": 1, "variantKey"?: "default", "variantAttributes"?: {}, "notes"?: "" }`)
- `PATCH /api/v1/cart/items/:id` (body: `{ "quantity"?: 2, "notes"?: "" }`)
- `DELETE /api/v1/cart/items/:id` (returns `{ deletedId }`)
- `DELETE /api/v1/cart` (returns `{ deletedCount }`)

> **Flutter Compatibility Note:** Favorites mutation endpoints (`POST /favorites`, `POST /favorites/:listingId`, `DELETE /favorites/:listingId`, `POST /listings/:listingId/favorite`) intentionally retain `success: true` inside `data` because the existing Flutter `FavoriteToggleResultDto.fromJson` reads `json['success'] == true`.
