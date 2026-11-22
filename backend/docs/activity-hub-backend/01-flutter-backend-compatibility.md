# 01 — Flutter-to-Backend Compatibility Matrix (Activity Hub)

**Date:** 2026-11-22  
**Flutter Source Inspected:** `../deal one app/lib/features/activity_hub/`, `../deal one app/lib/features/favorites/`, `../deal one app/lib/core/network/`  
**Backend Source Verified:** `backend/src/modules/{favorites,bookings,rfq,cart,activity-hub}/`

---

## 1. Network & Envelope Compatibility

- **Flutter Client:** `DioApiClient` (`lib/core/network/api_client.dart`) + `AuthInterceptor` (`lib/core/network/interceptors/auth_interceptor.dart`) sends `Authorization: Bearer <accessToken>`, `X-Request-ID`, and expects standard `{ "success": true, "data": ..., "meta"?: { ... } }`.
- **Backend:** Global prefix `/api/v1`, `TransformInterceptor` (`{ success: true, data, meta? }`), `HttpExceptionFilter` (`{ success: false, error: { code, message, details, trace_id } }`).
- **Result:** `100% COMPATIBLE`.

---

## 2. Feature-by-Feature Compatibility Matrix

### A. Favorites (`FavoriteItemDto`, `FavoriteToggleResultDto`, `ListingItemDto`)

| Flutter Model / Field | Flutter Expectation | Backend Response (`FavoritesService`) | Status |
|---|---|---|---|
| `GET /favorites` | `{ data: FavoriteItemDto[] }` | Returns `{ success: true, data: [...], meta: {...} }` | `COMPATIBLE` |
| `FavoriteItemDto.favoriteId`, `savedAt` | Top-level strings | Returned as `favoriteId`, `savedAt` | `COMPATIBLE` |
| `ListingItemDto.sellerName`, `sellerType`, `isVerified`, `account` | Reads `sellerName` / `account.displayName`, `sellerType` / `account.accountType`, `isVerified` / `account.verificationStatus == 'approved'` | **Updated:** Now returns `account`, `sellerName`, `sellerType`, `isVerified` alongside `seller` | `COMPATIBLE` |
| `FavoriteToggleResultDto.success`, `isFavorite`, `favoriteId` | Reads `json['success'] == true`, `json['isFavorite'] == true` | **Preserved:** `POST/DELETE /favorites/:listingId` keeps `success: true`, `isFavorite`, `favoriteId` inside `data` | `COMPATIBLE` |
| `GET /favorites/:listingId/status` | `{ isFavorite, favoriteId, savedAt, isListingAvailable }` | **Fixed:** `isListingAvailable` now queries `listing` even when unfavorited | `COMPATIBLE` |

---

### B. Bookings (`BookingEntity`, `BookingDto`, `CreateBookingPayload`, `BookingRequestSheet`)

| Flutter Model / Field | Flutter Expectation | Backend Contract (`BookingsController` / `BookingsService`) | Status |
|---|---|---|---|
| `CreateBookingPayload` (`POST /api/v1/bookings`) | Sends `listingId`, `type` (e.g. `agent_contact`, `maintenance_booking`, `plumbing`, `electricity`, `ac`), `date` (ISO/YYYY-MM-DD), `timeSlot` (12h `"02:00 PM"` or 24h `"14:00"`), `address`, `notes` | **Updated:** `CreateBookingDto` accepts BOTH canonical fields (`bookingType`, `scheduledDate`, `scheduledTime`, `location`) AND Flutter aliases (`type`, `date`/`bookingDate`, `timeSlot`/`bookingTime`, `address`), normalizing 12-hour slots & Flutter booking type strings server-side | `COMPATIBLE` |
| `BookingDto.title`, `imageUrl`, `providerName` | Top-level strings | **Updated:** Serialized top-level from `listing.title`, `listing.media[0].publicUrl`, `providerAccount.displayName` | `COMPATIBLE` |
| `BookingDto.type` (`BookingType.fromBackend`) | Expects `property_viewing`, `property_inspection`, `agent_contact`, `vehicle_inspection`, `maintenance_booking`, `service_center`, `plumbing`, `electricity`, `ac`, `construction`, `engineering` | **Updated:** `serializeBooking` emits exact Flutter `type` string alongside canonical `bookingType` | `COMPATIBLE` |
| `BookingDto.bookingDate`, `bookingTime`, `address`, `referenceCode` | Top-level strings | **Updated:** Mapped from `scheduledAt.toISOString()`, `scheduledTime`, `location`, `reference` | `COMPATIBLE` |
| `BookingDto.canCancel`, `canContactProvider`, `hasTracking` | Top-level booleans | **Updated:** `canCancel = status in [PENDING, CONFIRMED]`, `canContactProvider = true`, `hasTracking = false` | `COMPATIBLE` |
| `BookingDto.category` (`BookingCategory.fromBackend`) | Checks `category.toString()` for `'real'`, `'car'`, else `servicesEngineering` | `category` includes `slug` and `parent.slug` (`real-estate`, `cars`, `services`) | `COMPATIBLE` |
| `BookingStatus.fromBackend` | `pending`, `confirmed`, `rejected`, `cancelled`, `completed` (case-insensitive) | `PENDING`, `CONFIRMED`, `REJECTED`, `CANCELLED`, `COMPLETED` | `COMPATIBLE` |
| `BookingsRepositoryImpl` (Flutter wiring note) | Currently stubbed with `isBackendSupported => false` | Backend endpoints ready: `GET /api/v1/bookings`, `POST /api/v1/bookings`, `GET /api/v1/bookings/:id`, `PATCH /api/v1/bookings/:id/cancel`, `PATCH /api/v1/bookings/:id/status` | **Flutter wiring ready** |

---

### C. RFQ & Quotations (`RfqRequestEntity`, `RfqRequestDto`, `RfqQuotationDto`, `CreateRfqPayload`)

| Flutter Model / Field | Flutter Expectation | Backend Contract (`RfqController` / `RfqService`) | Status |
|---|---|---|---|
| `CreateRfqPayload` (`POST /api/v1/rfqs`) | Sends `title`, `materials`, `quantity`, `deliveryLocation`, optional `description`, optional `listingIds` | **Updated:** `CreateRfqDto` accepts BOTH structured `items[]` + `description` AND Flutter shorthand (`materials`, `quantity`, `listingIds`), parsing Arabic/English comma-separated materials into `RfqItem` rows server-side | `COMPATIBLE` |
| `RfqRequestDto` response fields | `referenceNumber`, `submittedAt`, `updatedAt`, `requestedItemsCount`, `materialsSummary`, `quantitySummary`, `deliveryLocation`, `projectDescription`, `status`, `quotations[]` | **Updated:** `serializeRfq` emits all exact `RfqRequestDto` fields and embeds `quotations[]` for RFQ owner/admin (never leaked to other suppliers) | `COMPATIBLE` |
| `RfqQuotationDto` response fields | `id`, `rfqId`, `supplierName`, `totalPrice` (num), `currency`, `deliveryEstimate`, `notes`, `status`, `canAccept`, `canReject`, `createdAt` | **Updated:** `serializeQuotation` emits `supplierName`, numeric `totalPrice`, `deliveryEstimate` (`"${days} days"`), `canAccept`, `canReject` | `COMPATIBLE` |
| `RfqStatus.fromBackend` (`rfq_entity.dart:18`) | Maps `'quoted' \|\| 'has_quotes' => RfqStatus.quoted` | Backend persists canonical `'QUOTATIONS_RECEIVED'`. **Required 1-line Flutter adjustment when wiring `RfqRepositoryImpl`:** add `\|\| 'quotations_received'` to `RfqStatus.fromBackend` (line 18 of `rfq_entity.dart`). Backend status preserved to avoid breaking existing DB/API contracts. | **1-line Flutter adjustment documented** |
| `RfqRepositoryImpl` (Flutter wiring note) | Currently stubbed with `isBackendSupported => false` | Backend endpoints ready: `GET /api/v1/rfqs`, `POST /api/v1/rfqs`, `GET /api/v1/rfqs/:id`, `PATCH /api/v1/rfqs/:id`, `PATCH /api/v1/rfqs/:id/submit`, `PATCH /api/v1/rfqs/:id/cancel`, `POST /api/v1/rfqs/:id/quotations`, `GET /api/v1/rfqs/:id/quotations`, `PATCH /api/v1/quotations/:id/status` | **Flutter wiring ready** |

---

### D. Cart (`CartItemEntity`, `CartItemModel`, `LocalCartRepository`) — V1 Boundary Decision

- **V1 Decision:** Deal One V1 is a **free-listing marketplace with no online product checkout, orders, or product payments**.
- **Flutter Current State:** Uses `LocalCartRepository` (`PreferencesService` key `activity_hub_cart_items_v1`) — works offline immediately without backend dependency.
- **Backend Support:** `CartModule` (`GET/POST/PATCH/DELETE /api/v1/cart`) provides an **optional, non-transactional V1 Server-Synchronized Saved Basket** (`commerceMode: 'V1_SAVED_BASKET'`, `checkoutSupported: false`).
- **Model Compatibility:** `CartService.getCart` now emits all `CartItemModel.fromJson` fields (`id`, `listingId`, `title`, `imageUrl`, `sellerName`, `sellerType`, `unitPrice`, `currency`, `quantity`, `selectedSize`, `selectedColor`, `categorySlug`, `addedAt`) alongside authoritative server-side `unitPriceSnapshot`, `liveUnitPrice`, `priceChanged`, and `isAvailable`.

---

### E. Unified Activity Hub (`GET /api/v1/activity-hub`)

- Aggregates real authenticated user data across `CartService`, `BookingsService`, `RfqService`, and `FavoritesService` with `?include=`, `page`, `limit`, `categoryId`, `categorySlug`, summary counts, and zero fabricated data.
