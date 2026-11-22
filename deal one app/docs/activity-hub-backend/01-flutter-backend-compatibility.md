# 01 — Flutter-to-Backend Compatibility Matrix

> **Rule:** Neither Flutter nor Backend contracts are silently altered. Below is the exact field-by-field comparison between Flutter (`lib/features/activity_hub/`) and Backend (`backend/src/modules/`).

---

## 1. Unified Activity Hub (`GET /api/v1/activity-hub`)
- **Backend Endpoint:** `GET /api/v1/activity-hub?include=cart,bookings,rfqs,favorites&page=1&limit=10&categoryId=&categorySlug=`
- **Backend Response:** `{ success: true, data: { summary: { cartItemsCount, activeBookingsCount, activeRfqCount, favoritesCount }, cart?, bookings?, rfqs?, favorites? } }`
- **Flutter Status:** Flutter currently uses separate providers (`cartSummaryProvider`, `bookingsProvider`, `rfqProvider`, `favoritesProvider`) aggregated client-side by `activityHubSummaryProvider`.
- **Required Flutter Adjustment (Future Wire-Up):** Add `ActivityHubRemoteDataSource` calling `GET /activity-hub` when enabling live server sync.

---

## 2. Favorites (`GET/POST/DELETE /api/v1/favorites`)
| Operation | Flutter (`FavoritesRepositoryImpl`) | Backend (`FavoritesController`) | Compatibility |
|---|---|---|---|
| List | `GET /favorites` (reads `List` or `data.data`) | `GET /favorites` (`{ success: true, data: [...], meta }`) | **100% Compatible** |
| Toggle | `POST /favorites/:listingId` | `POST /listings/:listingId/favorite` (alias) & `POST /favorites/:listingId` (add) | **Compatible** (Note: `POST /favorites/:listingId` adds; `POST /listings/:listingId/favorite` toggles) |
| Remove | `DELETE /favorites/:listingId` | `DELETE /favorites/:listingId` | **100% Compatible** |

---

## 3. Bookings (`POST/GET /api/v1/bookings`)
| Concept | Flutter (`BookingDto` / `CreateBookingPayload`) | Backend (`BookingsService` / `CreateBookingDto`) | Gap / Required Adjustment |
|---|---|---|---|
| Type | `type` (`property_viewing`, `maintenance_booking`, etc.) | `bookingType` (`property_viewing`, `maintenance_appointment`, `service_center_booking`, `plumbing_service`, etc.) | **Field & Enum Alignment:** Flutter `BookingDto` expects `type`; backend returns `bookingType`. Enum values for maintenance/services differ slightly (`maintenance_booking` vs `maintenance_appointment`). |
| Date & Time | `bookingDate`, `bookingTime` | `scheduledDate`, `scheduledTime` | **Field Name Diff:** Flutter reads `bookingDate`/`bookingTime`; backend uses `scheduledDate`/`scheduledTime`. |
| Location | `address` | `location` | **Field Name Diff:** Flutter reads `address`; backend uses `location`. |
| Reference | `referenceCode` | `bookingReference` | **Field Name Diff:** Flutter reads `referenceCode`; backend uses `bookingReference`. |
| Provider & Title | `providerName`, `title`, `imageUrl`, `category` | Nested `providerAccount.displayName`, `listing.title`, `listing.media[0].publicUrl`, `category.slug` | **Nesting Diff:** Flutter expects flat fields; backend returns nested relations. |
| Permissions | `canCancel`, `canContactProvider`, `hasTracking` | Not computed in response | **Adjustment:** Flutter can derive `canCancel` from `status == pending || confirmed` or backend serializer can emit flat aliases. |

---

## 4. RFQ & Quotations (`POST/GET /api/v1/rfqs`, `/api/v1/quotations`)
| Concept | Flutter (`RfqRequestDto` / `RfqQuotationDto`) | Backend (`RfqService` / `CreateRfqDto`) | Gap / Required Adjustment |
|---|---|---|---|
| Reference | `referenceNumber` | `rfqNumber` (and `reference` in outbox) | **Field Name Diff** |
| Dates | `submittedAt`, `updatedAt` | `createdAt`, `updatedAt` | **Field Name Diff** |
| Items Summary | `requestedItemsCount`, `materialsSummary`, `quantitySummary` | `items: RfqItem[]` | **Shape Diff:** Backend returns structured `items[]` array; Flutter `RfqRequestDto` expects summary strings + count. |
| Status | `RfqStatus.fromBackend` (`draft`, `submitted`, `under_review`, `quoted`, `accepted`, `rejected`, `closed`) | `RfqStatus` (`DRAFT`, `SUBMITTED`, `UNDER_REVIEW`, `QUOTATIONS_RECEIVED`, `ACCEPTED`, `REJECTED`, `CANCELLED`, `EXPIRED`) | **Enum Mapping:** Map `QUOTATIONS_RECEIVED` -> `RfqStatus.quoted` and `CANCELLED`/`EXPIRED` -> `RfqStatus.closed` in Flutter `RfqStatus.fromBackend`. |
| Quotation Fields | `supplierName`, `totalPrice`, `deliveryEstimate`, `canAccept`, `canReject` | `supplierAccount.displayName`, `totalAmount`, `estimatedDeliveryDays`, `status` | **Field Name Diff:** Update `RfqQuotationDto` when wiring live API. |

---

## 5. Cart (`GET/POST/PATCH/DELETE /api/v1/cart`)
- **Flutter:** `LocalCartRepository` stores `CartItemEntity` locally in `PreferencesService`.
- **Backend:** `CartController` exposes `/api/v1/cart` and `/api/v1/cart/items` as a V1 non-transactional saved basket with `unitPriceSnapshot`, `liveUnitPrice`, `priceChanged`, `variantKey`, `variantAttributes`.
- **Compatibility:** Both strictly preserve the V1 boundary (no checkout, no payment, no order creation).
