# Deal One — Final Category Navigation & Role-Based Seller Integration Report

## 1. Executive Summary

This report documents the final implementation of **Dynamic, Role-Based Six-Category Bottom Navigation** and **Backend-Verified Seller/Provider Actions** across Deal One's six marketplace sections.

All navigation items are resolved dynamically from a single Riverpod capability source (`accountCapabilitiesProvider`) backed by authoritative Backend account & permission data (`GET /api/v1/accounts/my-accounts` + `AccountTenantGuard` role permissions) and rendered through one shared navigation component (`DealOneSectionBottomNav`).

- **Zero backend contracts modified.**
- **Zero mock data or fake pages created.**
- **Zero existing features or deep links deleted** (`RouteNames.realEstateReels` remains intact; `Reels` is removed only from Real Estate Bottom Navigation).
- **Zero Favorites → Seller Action flicker** during account capability loading.

---

## 2. Final Navigation Matrix (All 6 Categories)

### A. Buyer / Non-Activated Account Navigation

Applies to guests, unverified (`pending` / `rejected`) accounts, inactive accounts, `responder`-only memberships, and sellers visiting a category outside their verified activity type.

| # | Category | Canonical Slug | Tab 1 | Tab 2 | Tab 3 | Tab 4 | Tab 5 (Buyer) |
|---|---|---|---|---|---|---|---|
| 1 | Real Estate & Lands | `real-estate` | Home (`/real-estate`) | Explore (`/search`) | Map (`/map/real-estate`) | Chat (`/conversations`) | Favorites (`/favorites`) |
| 2 | Services & Engineering | `services` | Home (`/home-services`) | Explore (`/search`) | Map (`/map/services`) | My Bookings (`/activity-hub?tab=bookings&category=services`) | Favorites (`/favorites`) |
| 3 | Building Materials & Electricity | `building-materials` | Home (`/building-materials`) | Categories (`/categories/building-materials`) | Map (`/map/building-materials`) | Price Requests (`/activity-hub?tab=rfq&category=building-materials`) | Favorites (`/favorites`) |
| 4 | Appliances & Decor | `home-appliances` | Home (`/home-appliances`) | Categories (`/categories/home-appliances`) | Map (`/map/home-appliances`) | Cart (`/activity-hub?tab=cart&category=home-appliances`) | Favorites (`/favorites`) |
| 5 | Cars & Maintenance | `cars` | Home (`/cars`) | Explore (`/search`) | Map (`/map/cars`) | Maintenance (`/activity-hub?tab=bookings&category=cars`) | Favorites (`/favorites`) |
| 6 | Fashion & Accessories | `fashion` | Home (`/fashion`) | Categories (`/categories/fashion`) | Map (`/map/fashion`) | Cart (`/activity-hub?tab=cart&category=fashion` — shown only when supported) | Favorites (`/favorites`) |

### B. Activated Seller / Provider Navigation

Tab 5 dynamically swaps from **Favorites** to the category-specific Seller Action **only** when Backend confirms an active, `approved` account with listing management role (`owner`, `manager`, or `lister`) and eligible `accountType`.

| # | Category | Tab 5 (Activated) | Stable ID | Destination Route | Required Capability |
|---|---|---|---|---|---|
| 1 | Real Estate & Lands | **My Listings** (`إعلاناتي`) | `my_listings` | `/seller/real-estate/listings` | `NavigationCapability.manageRealEstateListings` |
| 2 | Services & Engineering | **My Services** (`خدماتي`) | `my_services` | `/seller/services/services` | `NavigationCapability.manageEngineeringServices` |
| 3 | Building Materials & Electricity | **My Products** (`منتجاتي`) | `my_products` | `/seller/building-materials/products` | `NavigationCapability.manageBuildingMaterialsProducts` |
| 4 | Appliances & Decor | **My Listings** (`إعلاناتي`) | `my_listings` | `/seller/home-appliances/listings` | `NavigationCapability.manageAppliancesListings` |
| 5 | Cars & Maintenance | **My Services** (`خدماتي`) | `my_services` | `/seller/cars/services` | `NavigationCapability.manageAutomotiveMaintenanceServices` |
| 6 | Fashion & Accessories | **My Listings** (`إعلاناتي`) | `my_listings` | `/seller/fashion/listings` | `NavigationCapability.manageFashionListings` |

---

## 3. Capabilities & Backend Authorization Rules

Implemented in `lib/core/navigation/domain/account_capabilities.dart` and `lib/core/navigation/providers/section_navigation_provider.dart`.

### Authoritative Backend Inputs Audited
- **Session**: `sessionProvider` (`isAuthenticated`, `userId`) — clearing session immediately clears `myAccountsProvider` and resets navigation to Buyer mode.
- **Accounts**: `GET /api/v1/accounts/my-accounts` (`backend/src/modules/accounts/accounts.service.ts`) returns `{ id, accountType, displayName, slug, verificationStatus, isActive, role, joinedAt }`.
- **RBAC Role Permissions** (matching `backend/src/modules/auth/guards/account-tenant.guard.ts`):
  - `owner`: `*`, `account:manage`, `team:manage`, `listings:manage`, `listings:create`, `listings:edit`, `chat:respond`
  - `manager`: `team:view`, `listings:manage`, `listings:create`, `listings:edit`, `chat:respond`
  - `lister`: `listings:create`, `listings:edit`
  - `responder`: `chat:respond` only (does **not** unlock seller listing management).

### Capability Resolution Rules
Every seller capability requires **all four** conditions simultaneously (never `verificationStatus` alone):
1. `session.isAuthenticated == true`
2. `account.isActive == true`
3. `account.verificationStatus == 'approved'`
4. `role` grants listing management (`owner`, `manager`, or `lister`)
5. `accountType` matches sector eligibility:
   - `manageRealEstateListings`: `individual`, `office`, `company`
   - `manageEngineeringServices`: `individual`, `office`, `company`
   - `manageBuildingMaterialsProducts`: `company`, `factory`, `store`
   - `manageAppliancesListings`: `individual`, `store`, `company`, `factory`
   - `manageAutomotiveMaintenanceServices`: `company`, `store`, `office`
   - `manageFashionListings`: `individual`, `store`, `company`, `factory`

---

## 4. Real APIs Integrated

| Feature | Endpoints Used | Flutter Layer |
|---|---|---|
| Accounts & Activation | `GET /api/v1/accounts/my-accounts`, `GET /api/v1/accounts/:id/branches` | `AccountsRepositoryImpl`, `myAccountsProvider`, `accountCapabilitiesProvider` |
| Listings & Orthogonal Lifecycle | `GET /api/v1/listings`, `POST /api/v1/listings`, `PATCH /api/v1/listings/:id/status`, `PATCH /api/v1/listings/:id/availability`, `POST /api/v1/listings/:id/submit`, `DELETE /api/v1/listings/:id` | `ListingsRepositoryImpl`, `SellerListingsController`, `CreateListingPage` |
| Categories Browser | `GET /api/v1/categories/:slug` | `CategoriesRepositoryImpl`, `SectionCategoriesPage` |
| Chat (Real Estate Tab 4) | `GET /api/v1/conversations`, `GET/POST /api/v1/conversations/:id/messages` | `ConversationsRepositoryImpl`, `ConversationsPage`, `unreadChatCountProvider` |
| Bookings (Services & Cars Maintenance) | `GET /api/v1/bookings?role=requester\|provider&categorySlug=...`, `POST /api/v1/bookings`, `PATCH /api/v1/bookings/:id/cancel`, `PATCH /api/v1/bookings/:id/status` | `BookingsRepositoryImpl`, `ActivityHubPage`, `providerIncomingBookingsProvider` |
| RFQ & Quotations (Building Materials) | `GET /api/v1/rfqs?scope=mine\|open_for_suppliers&categorySlug=...`, `POST /api/v1/rfqs`, `PATCH /api/v1/quotations/:id/status` | `RfqRepositoryImpl`, `ActivityHubPage`, `supplierOpenRfqsProvider` |
| Cart (V1 Saved Basket) | `GET/POST/PATCH/DELETE /api/v1/cart` (`commerceMode: V1_SAVED_BASKET`, `checkoutSupported: false`) | `ActivityHubPage` (`CartTabView` — no fake checkout or online payment) |

---

## 5. Actual Screens & Separation of Concerns

- **Shared Navigation Bar**: `lib/core/navigation/presentation/widgets/deal_one_section_bottom_nav.dart`
  - Uses `sectionNavigationConfigProvider(sectionId)`.
  - Renders `_RoleSlotLoadingPlaceholder` during initial account fetch (zero flicker).
  - Animates slot swaps via `AnimatedSwitcher` when account verification/selection changes live without logout.
  - Displays live unread badge on Real Estate `Chat` tab and item count badge on `Cart` tabs.
- **Real Estate Chat**: Opens real `ConversationsPage` (`/conversations`), preserving all existing conversation logic and unread filters.
- **Section Categories**: `lib/features/categories/presentation/screens/section_categories_page.dart` (`/categories/:categorySlug`) — real subcategory browsing for Building Materials, Appliances & Decor, and Fashion.
- **Seller Management**: `lib/features/listings/presentation/screens/seller_management_page.dart` (`/seller/:categorySlug/:mode`)
  - Strictly gated by `accountCapabilitiesProvider.isActivatedSellerForSection(slug)` (deep-linking as a buyer shows an authorization-required view and hides all create/manage controls).
  - Displays the three orthogonal axes independently on every card and filter row: **Moderation** (`draft`, `pending`, `approved`, `rejected`), **Publication** (`published`, `hidden`, `expired`, `archived`), and **Availability** (`available`, `reserved`, `sold`, `rented`).
  - **Services & Engineering / Cars Maintenance (`mode=services`)**: Separates **My Services** tab from **Incoming Requests** tab (`role=provider`), while **My Bookings** / **Maintenance** bottom tab remains dedicated to buyer-created bookings (`role=requester`).
  - **Building Materials (`mode=products`)**: Separates **My Products** tab (creating material listings via `POST /listings`, never RFQs) from **Incoming RFQs** tab (`scope=open_for_suppliers`), while **Price Requests** bottom tab opens buyer RFQs (`scope=mine`).
- **Create Listing / Service / Product**: `lib/features/listings/presentation/screens/create_listing_page.dart` (`/listings/create?category=...&kind=...`) — capability-gated form wired to `POST /api/v1/listings`.

---

## 6. Documented Backend Gaps (Honest Audit — No Backend Contracts Altered)

1. **Missing Owner-Scoped Listings Endpoint (`GET /api/v1/listings/my` or `GET /api/v1/accounts/:id/listings`)**:
   - `backend/src/modules/listings/listings.controller.ts` currently only exposes `GET /api/v1/listings` (public feed filtered to `moderationStatus: 'approved'` and `publicationStatus: 'published'`, without an `accountId` filter).
   - **Impact**: `SellerManagementPage` can currently display only published listings belonging to the active account; displaying `draft`, `pending`, `rejected`, `hidden`, `expired`, and `archived` records requires adding an authenticated `GET /api/v1/listings/my` endpoint on Backend.
   - **Client Handling**: An honest informational banner (`seller_owner_endpoint_gap_banner`) explains this limitation directly in the UI; zero mock listings are fabricated. All orthogonal status filters and real lifecycle mutation APIs (`PATCH /listings/:id/status`, `PATCH /listings/:id/availability`, `DELETE /listings/:id`) are fully wired and ready.
2. **No Explicit Per-Category Activation Field on `Account` Model**:
   - `backend/prisma/schema.prisma` (`Account` model) stores `accountType` (`individual`, `company`, `factory`, `office`, `store`), `verificationStatus` (`pending`, `approved`, `rejected`), and `isActive`, but does **not** store an explicit `activatedCategories[]` or `providerSpecialties[]` column.
   - **Client Handling**: No synthetic backend roles or permissions were invented. Category activation is derived strictly from existing backend `accountType` + `verificationStatus == 'approved'` + `isActive` + `AccountTenantGuard` role permissions. Adding an explicit `activatedCategories` array to `GET /api/v1/accounts/my-accounts` in Backend is recommended for finer-grained multi-sector seller control.
3. **Unread Message Count in `GET /api/v1/conversations`**:
   - `ConversationEntity` and `unreadChatCountProvider` read `unreadCount` / `unread_count` and render the Real Estate `Chat` tab badge whenever `> 0`. Backend `ChatService.getUserConversations` currently does not aggregate per-conversation unread message counts in SQL; once Backend includes `unreadCount` in the payload, the badge will populate automatically with zero Flutter changes.
4. **Building Materials `listingKind` on `POST /api/v1/listings`**:
   - `ListingsService.createListing` currently defaults `listingKind` to `'sale'` on creation. Flutter passes `attributes.listingKind` (`'product'` / `'service'` / `'sale'`) without altering backend DTO contracts; updating `CreateListingDto` on Backend to accept `listingKind` explicitly is recommended.

---

## 7. Validation & Test Results

- **`flutter analyze`**: **0 issues found**.
- **Automated Test Suites (`flutter test test/core/navigation/ test/features/maps/universal_category_map_test.dart test/features/activity_hub/ test/features/listings/`)**: **43 / 43 tests PASSED**.
  - Verified all 6 categories in both **Buyer / Non-Activated** (`guest`, `pending`, `rejected`, `inactive`, `responder`) and **Activated Seller / Provider** (`company`, `office`, `factory`, `store`, verified `individual`) states.
  - Verified cross-category permission isolation (no seller actions in unpermitted categories).
  - Verified `Reels` removed from Real Estate bottom navigation and replaced by `Chat` with unread badge support.
  - Verified Fashion hides `Cart` when `isCartSupported == false`.
  - Verified zero-flicker loading placeholder while account permissions load.
  - Verified live navigation update on account activation and deactivation without logout.
  - Verified `SellerManagementPage` authorization guard and Services/Products secondary tab separation.
  - Verified RTL/LTR and responsive layout (`320×568`, `393×873`, `768×1024`) at `2.0x` text scale with zero overflow.
