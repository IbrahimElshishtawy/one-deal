# 03 — Widget Architecture

Every meaningful visual component is isolated into its own single-responsibility widget under `lib/features/activity_hub/presentation/widgets/`:

| Group | Widget | Responsibility |
|---|---|---|
| **Shell** | `ActivityHubHeader` | Back navigation, title, subtitle, clear-cart action |
| **Shell** | `ActivityHubTabBar` | 4-tab switcher with icons & count badges |
| **Shell** | `ActivitySummarySection` | Quick-jump summary pills for all 4 sections |
| **Shell** | `ActivitySearchBar` | Unified search input with clear button |
| **Shell** | `ActivityFilterBar<T>` | Generic horizontal chip filter bar |
| **Cart** | `CartTabView` | Cart list, pull-to-refresh, removal confirmation, save-for-later |
| **Cart** | `CartItemCard` | Product card with seller, variants, unit price, qty, actions |
| **Cart** | `CartItemImage` | Rounded product thumbnail with safe network fallback |
| **Cart** | `CartQuantitySelector` | Increment/decrement stepper with min-1 guard |
| **Cart** | `CartPriceSummary` | Subtotal, estimated total, V1 commerce notice, seller contact CTA |
| **Cart** | `CartEmptyState` | Empty cart state with Explore CTA |
| **Cart** | `CartVariantPickerSheet` | Size, color, and quantity bottom sheet |
| **Bookings** | `BookingsTabView` | Category filter bar, backend notice, bookings list |
| **Bookings** | `BookingCard` | Service/property image, type, status badge, details, actions |
| **Bookings** | `BookingStatusBadge` | Semantic localized status pill (Pending/Confirmed/Rejected/Cancelled/Completed) |
| **Bookings** | `BookingDateWidget` | Localized date & time display |
| **Bookings** | `BookingDetailsSection` | Date, time, address, and booking reference |
| **Bookings** | `BookingEmptyState` | Empty bookings state |
| **Bookings** | `BookingRequestSheet` | Viewing/inspection/service request modal with validation |
| **RFQ** | `RfqTabView` | Section header, New RFQ button, backend notice, RFQ list |
| **RFQ** | `RfqRequestCard` | Reference, status badge, dates, item/quote counts, expandable quotes |
| **RFQ** | `RfqStatusBadge` | Semantic localized RFQ status pill |
| **RFQ** | `RfqQuotationCard` | Supplier quote price, delivery estimate, accept/reject actions |
| **RFQ** | `RfqEmptyState` | Empty RFQ state with New RFQ CTA |
| **RFQ** | `RfqCreateSheet` | Validated RFQ creation form |
| **Favorites** | `FavoritesTabView` | 6-sector filter bar, search filtering, favorites list |
| **Favorites** | `FavoriteListingCard` | Listing thumbnail, sector label, price, remove & section nav |
| **Favorites** | `FavoritesCategoryFilter` | 6-sector filter chips |
| **Favorites** | `FavoritesEmptyState` | Empty & filtered-empty states |
| **Shared** | `ActivityLoadingWidget`, `ActivityErrorWidget`, `ActivityEmptyWidget`, `ActivitySectionHeader`, `ActivityActionButton`, `ActivityBackendNoticeBanner` | Consistent states and actions |
