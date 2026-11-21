# 01 — System Architecture: Activity & Commerce Hub

## 1. Architectural Pattern
The `activity_hub` feature follows Deal One's existing Clean Architecture + Riverpod layered structure:
- **Domain (`lib/features/activity_hub/domain/`)**: Pure Dart entities (`ActivityHubTab`, `MarketplaceSectorCategory`, `CartItemEntity`, `CartSummary`, `BookingEntity`, `BookingStatus`, `RfqRequestEntity`, `RfqStatus`) and repository interfaces (`CartRepository`, `BookingsRepository`, `RfqRepository`).
- **Data (`lib/features/activity_hub/data/`)**:
  - `LocalCartRepository` backed by `PreferencesService` (`CartItemModel` JSON encoding) for persistent local cart storage across restarts.
  - `BookingsRepositoryImpl` and `RfqRepositoryImpl` with DTOs (`BookingDto`, `RfqRequestDto`, `RfqQuotationDto`) ready for backend contracts, explicitly reporting `isBackendSupported = false` in V1.
- **Application (`lib/features/activity_hub/application/providers/`)**: Independent Riverpod `StateNotifierProvider`s and derived `Provider`s (`activityHubControllerProvider`, `activityHubSummaryProvider`, `cartProvider`, `cartSummaryProvider`, `bookingsProvider`, `rfqProvider`, `filteredFavoritesProvider`).
- **Presentation (`lib/features/activity_hub/presentation/`)**: `ActivityHubPage` plus modular, single-responsibility widgets under `widgets/`, `widgets/cart/`, `widgets/bookings/`, `widgets/rfq/`, `widgets/favorites/`, and `widgets/shared/`.

## 2. Navigation & Entry Points
- **Header Entry:** `DealOneHomeHeader` (`lib/core/design_system/deal_one_header.dart`) shopping basket button (`Icons.shopping_basket_rounded`) navigates to `RouteNames.activityHub` (`/activity-hub`).
- **Route Registration:** `AppRouter` (`lib/app/app_router.dart`) registers `/activity-hub` (supporting `?tab=cart|bookings|rfq|favorites`) and routes `/favorites` to `ActivityHubPage(initialTab: ActivityHubTab.favorites)`.
- **Marketplace Integrations:**
  - Appliances (`ApplianceProductCard`) & Building Materials (`ConstructionMaterialCard`) add to `cartProvider`.
  - Fashion (`FashionBrandCard`) opens `CartVariantPickerSheet` for size, color, and quantity selection before adding to `cartProvider`.
  - Services (`ServicesEngineeringHomePage` / `ServicesProviderTile`) opens `BookingRequestSheet`.
  - `ListingDetailScreen` exposes sector-appropriate actions (Request Viewing, Book Inspection, Book Service, Add to Cart, Request Quotation).
