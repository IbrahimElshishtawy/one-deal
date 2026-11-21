# 05 — Backend Integration

## 1. Integrated Live Endpoints
| Feature | Method | Endpoint | Repository | Auth |
|---|---|---|---|---|
| List Favorites | `GET` | `/api/v1/favorites` | `FavoritesRepositoryImpl` | Bearer |
| Toggle/Add Favorite | `POST` | `/api/v1/favorites/:listingId` | `FavoritesRepositoryImpl` | Bearer |
| Remove Favorite | `DELETE` | `/api/v1/favorites/:listingId` | `FavoritesRepositoryImpl` | Bearer |
| Listing Details | `GET` | `/api/v1/listings/:id` | `ListingsRepositoryImpl` | Public |
| Contact Reveal | `POST` | `/api/v1/listings/:id/contact` | `ListingsRepositoryImpl` | Bearer |

## 2. Client-Persisted Capability
- **Shopping Cart (`LocalCartRepository`):** Persisted in `PreferencesService` under key `activity_hub_cart_items_v1`. No fake `/cart` or `/checkout` API calls are made. Checkout entry routes to the listing detail contact reveal workflow in accordance with V1 free-listing mode.

## 3. Backend-Dependent Capabilities (Awaiting Backend Endpoints)
- **Bookings & Appointments (`BookingsRepositoryImpl`):** `isBackendSupported = false`. `BookingDto` and `BookingStatus.fromBackend` are implemented and unit-tested; live submission and cancellation remain disabled with an explicit notice until `/bookings` endpoints are added to the backend.
- **RFQ & Quotations (`RfqRepositoryImpl`):** `isBackendSupported = false`. `RfqRequestDto`, `RfqQuotationDto`, and `RfqStatus.fromBackend` are implemented and unit-tested; live submission and quotation accept/reject remain disabled with an explicit notice until `/rfqs` endpoints are added to the backend.
