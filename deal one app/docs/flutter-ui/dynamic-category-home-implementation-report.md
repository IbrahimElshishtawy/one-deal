# DealOne — Dynamic Category Home Pages Implementation Report

## 1. Existing Home Architecture (Pre-Implementation Audit)

Prior to this implementation, each of the 6 category Home Pages (`RealEstateHomePage`, `ServicesEngineeringHomePage`, `ConstructionElectricalHomePage`, `AppliancesDecorHomePage`, `CarsMaintenanceHomePage`, `FashionAccessoriesHomePage`) operated as buyer-only discovery screens backed by `sectionHomeControllerProvider(slug)` (`SectionHomeRepository` + `HybridCacheManager` Stale-While-Revalidate). While role-aware Navigation Drawers (`DealOneNavigationDrawer`) and Bottom Navigation (`DealOneSectionBottomNav`) existed, **none of the 6 Category Home Pages rendered inline Role-Based Business Overview widgets**, and `AccountCapabilities` did not separate **Automotive Sales** from **Automotive Maintenance Services**.

---

## 2. Final Home Page Architecture

Every category retains **one single Home Page** that dynamically adapts to the active category and verified backend `AccountCapabilities`:

- **Buyer Core (Always Shown)**: `DealOneHomeHeader` (`assets/image/logo.png`, `BoxFit.contain`), `DealOneOfflineBanner`, `DealOneSearchBar` + server-driven `ServerDrivenFilterSheet`, Category Quick Access & Domain Switchers, Promotional Banners, Domain-Specific Listing Cards, Verified Suppliers/Providers (`SuppliersStripSection`), Cursor Pagination, and `RecentlyViewedSectionWidget`.
- **Role-Based Business Section (Capability-Gated)**: `RoleBasedBusinessSection(categorySlug)` powered by `categoryBusinessOverviewProvider(slug)`. Renders `SizedBox.shrink()` with zero flicker and zero unauthorized API calls for buyers, guests, loading states, and unverified accounts.
- **Navigation Shell**: Dedicated category `DealOneNavigationDrawer` + `DealOneSectionBottomNav`. No separate Dashboard screen was created; every business stat/quick-action links directly to existing `SellerManagementPage` and `CreateListingPage` routes.

---

## 3. Six Category Specifications

| Category | Canonical Slug | Buyer Discovery Sections | Activated Role-Based Business Widgets |
| :--- | :--- | :--- | :--- |
| **Real Estate & Lands** | `real-estate` | Search, Sale/Rent quick switcher, Property subcategories, Map/Sort shortcuts, Live Previews, `RealEstatePropertyCard` feed, Recently Viewed | `Real Estate Business Overview` (Total, Published, Pending Review, Views if > 0, Inquiries, Add Property, Manage Listings) |
| **Services & Engineering** | `services` | Search, Promo Banner, Service Categories Grid, Most Requested Services Grid, Certified Partners & Providers (`ServicesProviderTile` with Booking Sheet) | `Service Provider Overview` (My Services, Pending, Incoming Bookings `role=provider`, Upcoming Appointments, Add Service, Manage Services) |
| **Building Materials & Electricity** | `building-materials` | Search, Promo Banner, Building vs. Electrical toggle, Subcategories Grid, `ConstructionMaterialCard` grid, Nearby Suppliers (`SuppliersStripSection`), Contractor RFQ CTA (routes to `activityHub?tab=rfq`) | `Supplier Business Overview` (My Products, Pending, Incoming RFQs `scope=open_for_suppliers`, Submitted Quotations, Add Product, Manage Products) |
| **Appliances & Decor** | `home-appliances` | Search, Promo Banner, Appliances vs. Decor toggle, Subcategories Grid, Installment Info Card, `ApplianceProductCard` grid, Nearby Sellers, Recently Viewed *(no unsupported Checkout/Payment)* | `Appliances Seller Overview` (My Listings, Published, Pending, Views if > 0, Inquiries, Add Listing, Manage Listings) |
| **Cars & Maintenance** | `cars` | Search, Promo Banner, Live Previews, Cars vs. Maintenance (`listingKind=service`) switcher, Subcategories Grid, Roadside Assistance CTAs, `CarShowcaseCard` feed, Nearby Service Centers | **Strictly Separated**: `Automotive Sales Overview` (My Cars, Pending, Inquiries, Add Car, Manage Cars) and/or `Maintenance Provider Overview` (My Services, Incoming Requests, Upcoming Bookings, Add Maintenance Service, Manage Services) |
| **Fashion & Accessories** | `fashion` | Search, Promo Banner, Fashion Categories Grid, Featured Look Card, `FashionBrandCard` grid, Popular Sellers (`SuppliersStripSection`), Recently Viewed | `Fashion Seller Overview` (My Listings, Published, Pending, Views if > 0, Inquiries, Add Listing, Manage Listings) |

---

## 4. Buyer Widgets

- `DealOneHomeHeader` (`lib/core/design_system/deal_one_header.dart`) using `DealOneLogo` (`assets/image/logo.png`, `BoxFit.contain`)
- `DealOneSearchBar` & `showServerDrivenFilterSheet`
- `DealOnePromoBannerCarousel` & `DealOneSegmentedToggle` & `DealOneLivePreviewsStrip`
- `SuppliersStripSection` & `SupplierCardWidget` (`lib/core/home/widgets/`)
- `RecentlyViewedSectionWidget` (`lib/core/home/widgets/recently_viewed_section_widget.dart`)
- `BuyerRfqCtaCard` (`lib/core/home/widgets/buyer_rfq_cta_card.dart`)
- Domain-specific cards: `RealEstatePropertyCard`, `ServicesProviderTile`, `MainHubPopularCard`, `ConstructionMaterialCard`, `ApplianceProductCard`, `CarShowcaseCard`, `FashionBrandCard`

---

## 5. Seller & Provider Widgets

- `RoleBasedBusinessSection` (`lib/core/home/widgets/role_based_business_section.dart`)
- Compact responsive stat grid (`2` columns on phones, `4` columns on tablets/wide screens) with independent loading/error/retry states that never block or crash buyer content.
- Orthogonal listing lifecycle separation: `moderationStatus` (`pending`), `publicationStatus` (`published`), and `availabilityStatus` (`available`).

---

## 6. Capability Mapping

Authoritative resolution in `lib/core/navigation/domain/account_capabilities.dart`:
- Requires `isAuthenticated == true`, `isLoading == false`, `account.isActive == true`, `account.verificationStatus == 'approved'`, and `AccountTenantGuard` role permissions (`owner`, `manager`, `lister`; plus `responder` for `chat:respond`).
- `canManageRealEstateListings`: `individual`, `office`, `company`
- `canManageEngineeringServices`: `individual`, `office`, `company`
- `canManageBuildingMaterialsProducts`: `company`, `factory`, `store`
- `canManageAppliancesListings`: `individual`, `store`, `company`, `factory`
- `canManageAutomotiveListings`: `individual`, `store`, `company` *(strictly separated from maintenance)*
- `canManageAutomotiveMaintenanceServices`: `company`, `office` *(strictly separated from car sales)*
- `canManageFashionListings`: `individual`, `store`, `company`, `factory`

---

## 7. API Mapping

- `GET /api/v1/home/sections/:slug` — Section metadata, subcategories, promotions, featured, latest, recommended, providers, filterConfig
- `GET /api/v1/listings` — Filtered & cursor-paginated listings (`categorySlug`, `listingKind`, `sort`, `cursor`, `limit`)
- `POST /api/v1/listings/prices/batch` — Authoritative live batch price freshness
- `GET /api/v1/accounts/my-accounts` — Verified account & role capability resolution
- `GET /api/v1/bookings?role=provider&categorySlug=...` — Provider-scoped incoming bookings (strictly separated from `role=requester`)
- `GET /api/v1/rfqs?scope=open_for_suppliers&categorySlug=building-materials` — Supplier-scoped open RFQs (strictly separated from `scope=mine`)
- `GET /api/v1/conversations` — Unread buyer inquiries count (only when `canRespondAsProvider`)

---

## 8. Repository Mapping

- `SectionHomeRepository` (`lib/core/marketplace/section_home_repository.dart`)
- `ListingsRepositoryImpl` (`lib/features/listings/data/repositories/listings_repository_impl.dart`)
- `AccountsRepositoryImpl` (`lib/features/accounts/data/repositories/accounts_repository_impl.dart`)
- `BookingsRepositoryImpl` (`lib/features/activity_hub/data/repositories/bookings_repository_impl.dart`)
- `RfqRepositoryImpl` (`lib/features/activity_hub/data/repositories/rfq_repository_impl.dart`)
- `ConversationsRepositoryImpl` (`lib/features/conversations/data/repositories/conversations_repository_impl.dart`)

---

## 9. Routes Mapping

- Category Homes: `/real-estate`, `/home-services`, `/building-materials`, `/home-appliances`, `/cars`, `/fashion`
- Listing Creation: `RouteNames.createListingFor(slug, listingKind: ...)` -> `/listings/create`
- Seller/Provider Management: `RouteNames.sellerManagementFor(slug, mode)` -> `/seller/:categorySlug/:mode` (with `?tab=incoming` for incoming bookings/RFQs)
- Buyer RFQ Flow: `RouteNames.activityHubFor(tab: 'rfq', categorySlug: 'building-materials')`
- Conversations: `RouteNames.conversations` -> `/conversations`

---

## 10. Performance Improvements

- Stale-While-Revalidate local caching (`HybridCacheManager`) per section + location key.
- In-flight request cancellation (`CancelToken`) on rapid filter/segment switches.
- Independent family providers (`sectionHomeControllerProvider(slug)`, `categoryBusinessOverviewProvider(slug)`, `categoryRecentlyViewedProvider(slug)`) preventing cross-category rebuilds and cross-section failures.
- `PageStorageKey` scroll preservation and lazy cursor pagination (`loadMore()`).
- Eliminated unnecessary startup `401` on `/favorites` for unauthenticated guests and `403` on `/auth/dev-guest` against production Railway.

---

## 11. Missing Backend Features (Documented Gaps)

1. **Owner-scoped Listings Endpoint (`GET /api/v1/listings/my`)**: Backend currently lacks an owner-scoped endpoint returning Draft/Pending/Rejected/Hidden listings; `SellerListingsController` tracks this via `ownerEndpointGapActive = true`.
2. **Per-Category Activation Field (`activatedCategories[]`)**: Backend `Account` model does not persist explicit per-category flags; capabilities are derived strictly from authoritative `accountType` + `verificationStatus` + `isActive` + `role`.
3. **Dedicated Seller Analytics Endpoint**: No `GET /api/v1/analytics/seller-summary` exists; views are computed strictly from real `ListingItem.viewsCount` and omitted when `0`.
4. **V1 Checkout / Orders / Payment**: Intentionally omitted from Appliances & Fashion Home Pages per V1 backend boundary (`checkoutSupported: false`).

---

## 12. Missing Screens

None required — all quick actions route directly to existing `CreateListingPage`, `SellerManagementPage`, `ActivityHubPage`, `ConversationsPage`, `SearchScreen`, and `RealEstateMapPage`.

---

## 13. Security Review

- **Zero-trust client**: Flutter UI hides business widgets unless verified backend capabilities match, while all mutations remain enforced by backend JWT + `AccountTenantGuard`.
- **Zero-flicker loading**: `categoryBusinessOverviewProvider` returns `null` while `capabilities.isLoading == true`.
- **Strict user/account scoping**: Listings are filtered by `activeAccount.id`, provider bookings use `role=provider`, supplier RFQs use `scope=open_for_suppliers`, and inquiries require `canRespondAsProvider`.

---

## 14. Test Results

Verified via `flutter analyze` (0 issues) and `flutter test`:
- `test/core/home/dynamic_category_home_test.dart` — All 10 account types, automotive sales vs. maintenance separation, multi-capability rendering, buyer zero-business visibility, RTL/LTR, Dark/Light, Recently Viewed, Suppliers strip.
- `test/core/navigation/category_role_based_navigation_test.dart` & `modular_drawer_widgets_test.dart` — Zero regressions in role-based navigation and drawers.
- `test/core/design_system/deal_one_logo_and_splash_test.dart` — DealOne branding, `assets/image/logo.png`, `BoxFit.contain`, SplashScreen.

---

## 15. Remaining Issues

- Backend team should add `GET /api/v1/listings/my` (returning Draft/Pending/Rejected/Hidden items for the active account) and explicit `activatedCategories[]` on `Account` when moving beyond V1.
