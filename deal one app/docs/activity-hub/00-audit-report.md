# 00 — Project Audit Report: Unified Activity & Commerce Hub

**Project:** Deal One (صفقة ون) Flutter Mobile Application  
**Audit Date:** November 21, 2026  
**Scope:** Full codebase, backend API (`backend/`), Prisma schema, routing, state management, localization, design tokens, and existing 6 marketplace verticals.

---

## 1. Executive Summary

Deal One is a Flutter + Riverpod + GoRouter + Dio mobile marketplace targeting 6 Egyptian verticals:
1. Real Estate & Land (`real_estate`)
2. Cars & Maintenance (`cars_maintenance`)
3. Services & Engineering (`services_engineering`)
4. Building Materials & Electricity (`construction_electrical`)
5. Home Appliances & Decor (`appliances_decor`)
6. Fashion & Accessories (`fashion_accessories`)

A full audit of both the Flutter client (`deal one app/lib/`) and the NestJS + Prisma backend (`backend/src/` & `backend/prisma/schema.prisma`) confirms that **only Favorites, Listings, Contact Reveal, Categories, Locations, Search, Chat, Accounts, Quotas, Media, Moderation, and Auth** exist on the backend. **Cart, Checkout/Orders, Bookings/Appointments, and RFQ/Quotations do not exist in the backend database or API.**

---

## 2. Existing Implementations

### 2.1 Flutter Architecture & Core Infrastructure
- **State Management:** `flutter_riverpod` (`^2.5.1`) with `StateNotifierProvider`, `Provider`, and `FutureProvider.family`.
- **Routing:** `go_router` (`^18.0.2`) in `lib/app/app_router.dart` with `RouteNames` (`lib/core/routing/route_names.dart`) and `SessionRouteGuard` (`lib/core/routing/route_guards.dart`).
- **Networking:** `DioApiClient` (`lib/core/network/api_client.dart`) with `AuthInterceptor`, `RetryInterceptor`, `RequestIdInterceptor`, `LoggingInterceptor`, concurrency limiting, and `ErrorMapper` / `ErrorPresenter`.
- **Local Storage:** `PreferencesService` (SharedPreferences) and `SecureStorageService` (FlutterSecureStorage), plus `HybridCacheManager`.
- **Localization:** Flutter `gen_l10n` (`l10n.yaml`) using `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`, outputting to `lib/l10n/generated/app_localizations.dart` and accessed via `AppLocalization.of(context)`.
- **Theme & Design System:**
  - `AppColors` & `DealOneDesignColors` (`lib/core/theme/app_colors.dart`) — full Light & Dark mode tokens (`backgroundOf`, `surfaceOf`, `textPrimaryOf`, `borderOf`, `errorOf`, `successOf`, `warningOf`, `infoOf`, plus `DealOneDesignColors.navy` `#1B2B48` and `amberPrice` `#D97706`).
  - `AppSpacing` (`lib/core/theme/app_spacing.dart`) — `xxs` (2) through `huge` (48).
  - `AppRadii` (`lib/core/theme/app_radii.dart`) — `xs` (4) through `full` (999).
  - `ResponsiveContext` (`lib/core/utils/responsive_utils.dart`) — breakpoints (`smallPhone` 340, `compact` 360, `standard` 410, `large` 600, `tablet` 768, `largeTablet` 960), `effectiveTextScale`, `horizontalScreenPadding`.

### 2.2 Existing Reusable Widgets
- `DealOneHomeHeader` (`lib/core/design_system/deal_one_header.dart`) — shared header across all 7 home screens with user avatar, location selector, and shopping basket button (`Icons.shopping_basket_rounded` currently routing to `RouteNames.favorites`).
- `AppEmptyState` (`lib/shared/widgets/app_empty_state.dart`)
- `AppErrorView` (`lib/shared/widgets/app_error_view.dart`)
- `AppLoadingIndicator` (`lib/shared/widgets/app_loading_indicator.dart`)
- `SafeNetworkImage` (`lib/shared/widgets/market_widgets/safe_network_image.dart`) & `AppNetworkImage` (`lib/shared/widgets/app_network_image.dart`)

### 2.3 Existing Favorites Feature
- `lib/features/favorites/domain/entities/favorite_entity.dart` (`FavoriteItem`, `FavoriteToggleResult`)
- `lib/features/favorites/domain/repositories/favorites_repository.dart`
- `lib/features/favorites/data/repositories/favorites_repository_impl.dart`
- `lib/features/favorites/presentation/providers/favorites_providers.dart` (`favoritesProvider`, `favoritesControllerProvider`, `favoriteIdsProvider`)
- `lib/features/favorites/presentation/screens/favorites_screen.dart` — basic `ListView` without category filtering, search, localization keys, or navigation to sector home.

### 2.4 Existing 6 Marketplace Action Audit
- **Appliances (`ApplianceProductCard`):** "Add to Basket" button calls `favoritesControllerProvider.notifier.toggleFavorite(item.id)` and shows a SnackBar.
- **Construction (`ConstructionMaterialCard`):** "Add to order list" icon button calls `favoritesControllerProvider.notifier.toggleFavorite(item.id)` and shows a SnackBar.
- **Fashion (`FashionBrandCard`):** "+" button calls `favoritesControllerProvider.notifier.toggleFavorite(item.id)` and shows a SnackBar ("Added to bag & favorites").
- **Real Estate (`PropertyCard`):** Heart icon toggles favorite; card opens `ListingDetailScreen` (which has Contact Reveal + WhatsApp).
- **Cars (`CarShowcaseCard`):** Card opens `ListingDetailScreen`.
- **Services (`ServicesProviderTile`):** "Book Now" button calls `_openSearch(query: provider.displayName)`.

---

## 3. Existing vs. Missing Backend API Endpoints

### 3.1 Existing Backend Modules (`backend/src/modules/`)
`accounts`, `admin-auth`, `admin-operations`, `auth`, `categories`, `chat`, `email`, `favorites`, `home`, `listings`, `locations`, `media`, `moderation`, `notifications`, `payments` (V2 listing promotions only, gated by `ENABLE_V2_PAYMENTS`), `platform-settings`, `quotas`, `search`, `staff`, `users`, `video`.

### 3.2 Relevant Existing Endpoints
| Feature | Method | Endpoint | Auth | Status |
|---|---|---|---|---|
| List Favorites | `GET` | `/api/v1/favorites` | Bearer | Implemented |
| Toggle/Add Favorite | `POST` | `/api/v1/favorites/:listingId` | Bearer | Implemented |
| Remove Favorite | `DELETE` | `/api/v1/favorites/:listingId` | Bearer | Implemented |
| Listing Details | `GET` | `/api/v1/listings/:id` | Public | Implemented |
| Contact Reveal | `POST` | `/api/v1/listings/:id/contact` | Bearer | Implemented |

### 3.3 Missing Backend Endpoints (Verified Against `schema.prisma` & `modules/`)
| Domain | Missing Endpoints | Backend Status |
|---|---|---|
| **Shopping Cart** | `GET /cart`, `POST /cart/items`, `PATCH /cart/items/:id`, `DELETE /cart/items/:id`, `POST /checkout` | Not implemented (V1 is free listings without checkout) |
| **Bookings & Appointments** | `GET /bookings`, `POST /bookings`, `PATCH /bookings/:id/cancel`, `GET /bookings/:id/tracking` | Not implemented |
| **RFQ & Quotations** | `GET /rfqs`, `POST /rfqs`, `GET /rfqs/:id/quotations`, `POST /quotations/:id/accept`, `POST /quotations/:id/reject` | Not implemented |

---

## 4. Missing Implementations & Gaps in Flutter

1. **No Activity & Commerce Hub destination:** `DealOneHomeHeader` basket icon opens `FavoritesScreen` directly.
2. **Unregistered Routes:** `RouteNames` declares `buildingMaterialsCart`, `buildingMaterialsRfq`, `homeServicesBookings`, `fashionCart`, `myActivity`, etc., but `AppRouter` does not register them.
3. **No Shopping Cart module:** No cart entities, state management, or persistent local cart storage; marketplace cards misuse `toggleFavorite` as an "Add to Cart" action.
4. **No Bookings & Appointments module:** No booking entities, status mappers, booking cards, or booking request sheets.
5. **No RFQ module:** No RFQ entities, status mappers, RFQ cards, quotation comparison cards, or RFQ creation form.
6. **FavoritesScreen limitations:** Hardcoded Arabic strings, no 6-sector category filter, no search bar, no section navigation.

---

## 5. Potential Conflicts & Risks

1. **Golden Tests (`test/responsive/seven_homes_golden_test.dart`):** `DealOneHomeHeader` is rendered in all 7 home screens. Changing its visual pixels would break golden PNGs; changing only `onTap` and `tooltip` preserves pixel parity.
2. **Route Guard (`SessionRouteGuard`):** `RouteNames.favorites` is protected; `RouteNames.activityHub` should be handled consistently without breaking existing tests or unauthenticated flows.
3. **V1 Business Model Alignment:** Must not fabricate backend responses, fake payment checkout, fake received quotations, or fake technician tracking.

---

## 6. Required Implementation Phases

1. **Phase 1 (Complete):** Audit codebase, backend schema, and existing tests.
2. **Phase 2:** Add complete Arabic & English ARB localization keys and regenerate `AppLocalizations`.
3. **Phase 3:** Build `lib/features/activity_hub/` (Domain, Data, Application/Providers, Presentation with dedicated modular widgets for Hub, Cart, Bookings, RFQ, Favorites, and Shared states).
4. **Phase 4:** Wire `DealOneHomeHeader`, `AppRouter`, `RouteNames`, and integrate all 6 marketplace verticals (Cart add-to-bag for Appliances/Construction/Fashion with size/color selection; Booking/Inspection/Service request sheets for Real Estate/Cars/Services; RFQ creation from Construction).
5. **Phase 5:** Write comprehensive unit, widget, and integration tests (RTL/LTR, Light/Dark, responsive viewports, state transitions) and run `flutter analyze` and `flutter test`.
6. **Phase 6:** Complete all deliverables in `docs/activity-hub/` (`00` through `08`).
