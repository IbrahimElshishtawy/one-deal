# Deal One — Dynamic Role-Based Navigation Drawer Business Integration Report

## 1. Shared Drawer Architecture

Implemented a single shared, dynamic, role-based Navigation Drawer (`DealOneNavigationDrawer`) attached to all 6 Deal One category home screens and opened directly from the shared `DealOneHomeHeader` menu button.

### Core Modules (`lib/core/navigation/drawer/`)
- **`drawer_item_config.dart`**: Immutable configuration models (`DrawerItemConfig`, `DrawerCategoryEntry`, `ResolvedDrawerConfig`, `DrawerItemAction`). Every item defines:
  - `id` (Stable ID)
  - `labelAr` / `labelEn`
  - `icon`
  - `route`
  - `categoryContext`
  - `requiredCapability` (`NavigationCapability`)
  - `visibilityRule` (`NavigationVisibilityRule`)
  - `featureAvailable` (hard gate preventing unsupported features from ever rendering)
  - `badgeKey` (optional live real count)
- **`category_drawer_registry.dart`**: Authoritative registry defining all 6 category configurations, the Category Switcher, Account Management, and Help & Legal sections. Strictly complements Bottom Navigation without duplicating it.
- **`drawer_providers.dart`**: Riverpod integration (`drawerConfigProvider`, `drawerBadgeCountProvider`) reusing the single authoritative `accountCapabilitiesProvider` with zero duplicate permission logic.
- **`deal_one_navigation_drawer.dart`**: Shared responsive RTL/LTR presentation widget rendering the 5 required sections:
  1. **Account Header**: Active user/account display, verification status pill, Guest Sign-In CTA, multi-account switcher chips, loading indicator, and network error + retry banner.
  2. **Category Switcher**: All 6 Deal One sections + Main Hub, highlighting the active category and preserving state.
  3. **Current Category Actions**: Capability-gated, feature-available tools with live badges and a loading skeleton while permissions resolve (zero unauthorized flash).
  4. **Account Management**: Profile & Verification (`/profile`), Edit Account (`/profile/edit`), Notifications (`/notifications` with unread badge), Messages (`/conversations` for non-Real-Estate sections), Settings sheet (`showProfileSettingsSheet`), and Sign Out.
  5. **Help & Legal**: Terms of Service (`/terms`) and Privacy Policy (`/privacy`).

### Integration Across All 6 Category Pages
- `lib/core/design_system/deal_one_header.dart`: Menu button automatically opens `Scaffold.of(context).openDrawer()` when a drawer is present while preserving existing fallbacks elsewhere.
- Attached `DealOneNavigationDrawer(activeCategorySlug: ...)` to:
  1. `lib/features/real_estate/presentation/pages/real_estate_home_page.dart`
  2. `lib/features/services_engineering/presentation/pages/services_engineering_home_page.dart`
  3. `lib/features/construction_electrical/presentation/pages/construction_electrical_home_page.dart`
  4. `lib/features/appliances_decor/presentation/pages/appliances_decor_home_page.dart`
  5. `lib/features/cars_maintenance/presentation/pages/cars_maintenance_home_page.dart`
  6. `lib/features/fashion_accessories/presentation/pages/fashion_accessories_home_page.dart`
- Updated `SellerManagementPage` + `AppRouter` to support `?tab=incoming` so Drawer links for Incoming Service Requests, Maintenance Requests, and Incoming RFQs land directly on the incoming requests tab.

---

## 2. Category-Specific Drawer Items & Routes (Supported Only)

| Category | Stable ID | Label (EN / AR) | Route / Action | Live Badge |
|---|---|---|---|---|
| **Real Estate** | `drawer_re_favorites` | Favorites / المفضلة | `/favorites` (complements seller Bottom Nav) | — |
| **Real Estate** | `drawer_re_create_listing` | Create Listing / إضافة عقار جديد | `/listings/create?category=real-estate` | — |
| **Real Estate** | `drawer_re_listing_management` | Listing Management / إدارة العقارات | `/seller/real-estate/listings` | — |
| **Real Estate** | `drawer_re_viewings` | Property Viewings / مواعيد المعاينات | `/activity-hub?tab=bookings&category=real-estate` | — |
| **Services & Engineering** | `drawer_srv_favorites` | Favorites / المفضلة | `/favorites` (complements provider Bottom Nav) | — |
| **Services & Engineering** | `drawer_srv_booking_history` | Booking History / سجل الحجوزات | `/activity-hub?tab=bookings&category=services` | — |
| **Services & Engineering** | `drawer_srv_create_service` | Create Service / إضافة خدمة جديدة | `/listings/create?category=services&kind=service` | — |
| **Services & Engineering** | `drawer_srv_incoming_requests` | Incoming Service Requests / طلبات الخدمة الواردة | `/seller/services/services?tab=incoming` | `incoming_bookings_services` |
| **Building Materials** | `drawer_bm_favorites` | Favorites / المفضلة | `/favorites` (complements supplier Bottom Nav) | — |
| **Building Materials** | `drawer_bm_supplier_discovery` | Supplier Discovery / استكشاف الموردين | Category-scoped `/search` (`building-materials`) | — |
| **Building Materials** | `drawer_bm_add_product` | Add Product / إضافة منتج مواد بناء | `/listings/create?category=building-materials&kind=product` | — |
| **Building Materials** | `drawer_bm_incoming_rfqs` | Incoming RFQs / طلبات الأسعار الواردة | `/seller/building-materials/products?tab=incoming` | `incoming_rfqs_building_materials` |
| **Appliances & Decor** | `drawer_app_favorites` | Favorites / المفضلة | `/favorites` (complements seller Bottom Nav) | — |
| **Appliances & Decor** | `drawer_app_create_listing` | Create Listing / إضافة إعلان جديد | `/listings/create?category=home-appliances` | — |
| **Appliances & Decor** | `drawer_app_listing_management` | Listing Management / إدارة الإعلانات | `/seller/home-appliances/listings` | — |
| **Cars & Maintenance** | `drawer_cars_favorites` | Favorites / المفضلة | `/favorites` (complements provider Bottom Nav) | — |
| **Cars & Maintenance** | `drawer_cars_service_history` | Service History / سجل الصيانة والحجوزات | `/activity-hub?tab=bookings&category=cars` | — |
| **Cars & Maintenance** | `drawer_cars_my_listings` | My Cars & Listings / سياراتي وإعلاناتي | `/seller/cars/listings` (distinct from maintenance) | — |
| **Cars & Maintenance** | `drawer_cars_create_maintenance` | Create Maintenance Service / إضافة خدمة صيانة | `/listings/create?category=cars&kind=service` | — |
| **Cars & Maintenance** | `drawer_cars_maintenance_requests` | Maintenance Requests / طلبات الصيانة الواردة | `/seller/cars/services?tab=incoming` | `incoming_bookings_cars` |
| **Fashion & Accessories** | `drawer_fash_favorites` | Favorites / المفضلة | `/favorites` (complements seller Bottom Nav) | — |
| **Fashion & Accessories** | `drawer_fash_create_listing` | Create Listing / إضافة إعلان أزياء | `/listings/create?category=fashion` | — |
| **Fashion & Accessories** | `drawer_fash_listing_management` | Listing Management / إدارة الإعلانات | `/seller/fashion/listings` | — |

---

## 3. Capability Mapping & Permission Matrix

Reuses `AccountCapabilities` (`lib/core/navigation/domain/account_capabilities.dart`) with **zero** reliance on a generic `isSeller` flag or `account.verified` alone.

| Account Profile | Real Estate Tools | Services Tools | Building Materials Tools | Appliances Tools | Cars Maintenance Tools | Fashion Tools |
|---|---|---|---|---|---|---|
| **Guest / Buyer / Pending / Rejected / Inactive** | Hidden | Hidden | Hidden | Hidden | Hidden | Hidden |
| **`responder`-only on Approved Account** | Hidden | Hidden | Hidden | Hidden | Hidden | Hidden |
| **Approved `individual` (`owner/manager/lister`)** | Visible | Visible | Hidden | Visible | Hidden | Visible |
| **Approved `office` (`owner/manager/lister`)** | Visible | Visible | Hidden | Hidden | Visible | Hidden |
| **Approved `factory` (`owner/manager/lister`)** | Hidden | Hidden | Visible | Visible | Hidden | Visible |
| **Approved `store` (`owner/manager/lister`)** | Hidden | Hidden | Visible | Visible | Visible | Visible |
| **Approved `company` (`owner/manager/lister`)** | Visible | Visible | Visible | Visible | Visible | Visible |

---

## 4. Backend APIs Connected

- `GET /api/v1/accounts/my-accounts` — Authoritative account list, type, verification status, active flag, and RBAC membership role.
- `GET /api/v1/listings`, `POST /api/v1/listings`, `PATCH /api/v1/listings/:id/status`, `PATCH /api/v1/listings/:id/availability`, `DELETE /api/v1/listings/:id` — Listing creation & management.
- `GET /api/v1/bookings?role=requester|provider&categorySlug=...` & `PATCH /api/v1/bookings/:id/status` — Booking History, Property Viewings, Incoming Service Requests, Maintenance Requests + live badge counts.
- `GET /api/v1/rfqs?scope=mine|open_for_suppliers&categorySlug=...` — Buyer RFQs & Supplier Incoming RFQs + live badge counts.
- `GET /api/v1/search` — Supplier Discovery (Building Materials).
- `GET /api/v1/conversations` & `GET /api/v1/notifications` — Messages & Notifications with live unread badges.

---

## 5. Missing Features (Honest Backend/Flutter Gap Audit — Hidden in UI)

All items below are explicitly declared with `featureAvailable: false` in `CategoryDrawerRegistry` so they are never shown as broken or fake UI:

1. **Real Estate — Contact Requests**: Backend `POST /api/v1/listings/:id/contact` increments a counter and reveals phone, but there is no `GET /api/v1/contact-requests` endpoint.
2. **Real Estate — Saved Searches**: No backend table/endpoint or local persistence exists for saved searches.
3. **Real Estate / Appliances / Fashion — Recently Viewed**: No backend endpoint or local recently-viewed history store exists.
4. **Services & Engineering — Schedule Management**: No provider working-hours or availability slot management API exists in Backend.
5. **Services & Engineering — Service Areas UI**: Backend exposes `GET/POST/DELETE /api/v1/accounts/:id/service-areas`, but no Flutter Service Areas management screen is implemented yet.
6. **Building Materials — My Quotations**: Backend exposes `GET /api/v1/rfqs/:id/quotations` (RFQ owner) and `GET /api/v1/quotations/:id`, but no `GET /api/v1/quotations/mine` endpoint exists to list a supplier's submitted quotations across RFQs.

---

## 6. Validation & Test Results

- **`flutter analyze`**: **0 issues found**.
- **Automated Test Suites (`flutter test test/core/navigation/ test/features/seven_homes_widget_test.dart`)**: **33 / 33 tests PASSED**.
  - Verified all 6 categories in Buyer, Activated Seller, Activated Service Provider, Multi-Capability, and Unauthorized (`pending` / `rejected` / `inactive` / `responder`) states.
  - Verified zero unsupported backend features ever render in any category.
  - Verified Loading state hides unauthorized items and renders skeleton; Error state shows retry banner.
  - Verified live badge counts for Incoming Service Requests and exact deep-link route resolution (`?tab=incoming`).
  - Verified RTL (Arabic) and LTR (English) rendering with zero overflow across `320×640` and `768×1024` viewports.
  - Verified all 7 Home screens (`seven_homes_widget_test.dart`) continue to pass cleanly with the integrated Drawer.
