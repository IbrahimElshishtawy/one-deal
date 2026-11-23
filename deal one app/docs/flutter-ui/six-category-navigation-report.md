# Deal One — Six-Category Navigation & Universal Maps Integration Report

## 1. Overview

This report documents the **Six-Category Bottom Navigation** and **Universal Category Maps Integration** in Deal One.

**Core Principle:** One shared map architecture and UI codebase (`lib/features/maps/`), delivering six distinct, category-isolated map experiences across all six Deal One sections.

---

## 2. Universal Map Tab Across All 6 Categories

Registered all 6 canonical section configurations in `lib/core/navigation/config/section_navigation_registry.dart` and rendered them via `lib/core/navigation/presentation/widgets/deal_one_section_bottom_nav.dart`. Every category section includes a fixed **Map Tab (`الخريطة` / `Map`)** bound to its category-scoped map route:

| # | Category (EN) | Category (AR) | Canonical Slug | Section Home Route | Universal Map Route | Map Context |
|---|---|---|---|---|---|---|
| 1 | Real Estate & Lands | العقارات والأراضي | `real-estate` | `/real-estate` | `/map/real-estate` | Properties & lands for sale/rent |
| 2 | Services & Engineering | الخدمات والهندسة | `services` | `/home-services` | `/map/services` | Service providers, engineers & technicians |
| 3 | Building Materials & Electricity | مواد البناء والكهرباء | `building-materials` | `/building-materials` | `/map/building-materials` | Stores, suppliers & showrooms |
| 4 | Appliances & Decor | الأجهزة والديكور | `home-appliances` | `/home-appliances` | `/map/home-appliances` | Appliances, furniture & decor stores |
| 5 | Cars & Maintenance | السيارات والصيانة | `cars` | `/cars` | `/map/cars` | Car showrooms, maintenance centers & spare parts |
| 6 | Fashion & Accessories | الأزياء والإكسسوارات | `fashion` | `/fashion` | `/map/fashion` | Clothing, footwear & accessories shops |

### Navigation Files Updated / Created
- `lib/core/routing/route_names.dart` — Added `RouteNames.categoryMap` (`/map/:categorySlug`) and `RouteNames.categoryMapFor(slug)`.
- `lib/core/navigation/config/section_navigation_registry.dart` — Registered all 6 section navigation configs (`realEstateConfig`, `servicesConfig`, `buildingMaterialsConfig`, `homeAppliancesConfig`, `carsConfig`, `fashionConfig`), each with 5 tabs (`home`, `map`, `explore`, `favorites`, `profile`), while preserving `defaultConfig` for global fallback.
- `lib/core/navigation/presentation/widgets/deal_one_section_bottom_nav.dart` — Reusable, RTL/LTR-aware, overflow-safe bottom navigation bar using `DealOneBottomNavTokens`, sliding active pill indicator, clamped text scaling (`1.0..1.2x`), `SafeArea`, and keyboard auto-hide.
- `lib/app/app_router.dart` — Added `GoRoute` for `/map/:categorySlug` rendering `CategoryMapPage(categorySlug: slug)`.
- All 6 Section Home Pages updated to host `DealOneSectionBottomNav`:
  - `lib/features/real_estate/presentation/pages/real_estate_home_page.dart`
  - `lib/features/services_engineering/presentation/pages/services_engineering_home_page.dart`
  - `lib/features/construction_electrical/presentation/pages/construction_electrical_home_page.dart`
  - `lib/features/appliances_decor/presentation/pages/appliances_decor_home_page.dart`
  - `lib/features/cars_maintenance/presentation/pages/cars_maintenance_home_page.dart`
  - `lib/features/fashion_accessories/presentation/pages/fashion_accessories_home_page.dart`

---

## 3. Shared Map Feature Architecture (`lib/features/maps/`)

```text
lib/features/maps/
├── domain/
│   ├── entities/
│   │   ├── map_category_config.dart       # 6 category configs (title, accent, marker icon, quick filters)
│   │   ├── map_place_entity.dart          # Unified place entity (listing/store/provider + real coords + distance)
│   │   ├── map_bounds.dart                # Geographic bounding box, haversine distance, viewport shift detection
│   │   ├── map_cluster.dart               # Deterministic spatial-grid marker clustering engine
│   │   └── location_permission_state.dart # Non-blocking user location & permission state
│   └── repositories/
│       └── category_map_repository.dart   # Repository contract + MapPlacesQuery
├── data/
│   ├── datasources/
│   │   └── category_map_remote_datasource.dart # Real GET /api/v1/search integration + Dio CancelToken
│   ├── models/
│   │   └── map_place_mapper.dart          # Maps ListingItemDto -> MapPlaceEntity (zero mock coordinates)
│   └── repositories/
│       └── category_map_repository_impl.dart
└── presentation/
    ├── providers/
    │   ├── category_map_provider.dart     # Riverpod StateNotifierProvider.family keyed by categorySlug
    │   └── map_location_service.dart      # Rationale-gated location permission service
    ├── widgets/
    │   ├── map_markers.dart               # User location pulse, cluster bubbles, category/store pins
    │   ├── map_search_bar.dart            # Debounced search input, filter badge, tile layer toggle
    │   ├── map_filters.dart               # Category quick-filter chips, all-categories opt-in, filter sheet
    │   ├── map_place_preview.dart         # Bottom preview card (image, address, distance, details, directions)
    │   └── map_current_location_button.dart # Current location, recenter, zoom +/- controls
    └── pages/
        └── category_map_page.dart         # Universal map screen shared across all 6 categories
```

### Category Isolation Guarantee
- Every query passes `categorySlug: activeCategorySlug` by default.
- `CategoryMapState.belongsToActiveCategory` enforces client-side isolation so places belonging to any of the other 5 sections are never mixed into the active map.
- Cross-category discovery is strictly opt-in via the explicit **"جميع الأقسام" / "All Categories"** chip or advanced filter switch.

---

## 4. Backend Integration & APIs Used

**No backend files were modified.** The Flutter map feature integrates strictly with existing verified endpoints:

### Active Endpoints Used
1. **`GET /api/v1/search`** (`SearchService.searchListings` in `backend/src/modules/search/search.service.ts`):
   - **Category Scoping**: `categorySlug` (with hierarchical subcategory resolution in Prisma).
   - **Full-Text Search**: `q` (Arabic dialect normalization & fuzzy matching).
   - **Spatial Radius Filtering**: `lat`, `lng`, `radiusKm` (backed by PostGIS `ST_DWithin(display_location, ..., radius)` with a 300-row cap).
   - **Faceted Filters**: `listingKind`, `condition`, `featured`, `minPrice`, `maxPrice`, `governorateId`, `cityId`, `sort`, `page`, `limit`.
   - **Request Cancellation**: Per-section `Dio` `CancelToken` cancels superseded in-flight requests on rapid typing or filter changes.

### Documented Backend Gaps (No Fake APIs / No Mock Production Data)
During backend inspection (`backend/prisma/schema.prisma`, `backend/src/modules/search/search.service.ts`, `backend/src/modules/listings/listings.service.ts`, `backend/src/modules/accounts/accounts.controller.ts`), the following gaps were identified and handled honestly on the client:

1. **GPS Coordinates Not Serialized in `/search` or `/listings` Responses**:
   - `listings.display_location` and `areas.centroid` exist in PostgreSQL/PostGIS (`Unsupported("geometry(Point, 4326)")`), and `ST_DWithin` works for filtering, **but** neither `SearchService.searchListings` nor `ListingsService.getListingsFeed` extracts `ST_Y(display_location)` / `ST_X(display_location)` into JSON `latitude` / `longitude` fields.
   - **Client Handling**: The app reads real `latitude`/`longitude` whenever serialized in the payload or `attributes` JSONB. When absent, **zero mock coordinates are fabricated**; instead, an honest informational banner surfaces the real area results in an expandable list sheet so users can still inspect and open details.
2. **No Rectangular Bounding Box (`bbox` / `minLat,maxLat,minLng,maxLng`) Parameter**:
   - Backend currently supports center + radius (`lat`, `lng`, `radiusKm`).
   - **Client Handling**: `MapBoundingBox` converts the visible viewport into `(center.latitude, center.longitude, radiusKm)` for backend queries, and `CategoryMapState.inBoundsMappablePlaces` strictly filters rendered markers to the visible bounds.
3. **No Public Category-Scoped Stores/Branches Geo Discovery Endpoint**:
   - `branches` stores PostGIS `location` and `address`, but `GET /api/v1/accounts/:id/branches` requires a known `accountId`. There is no public `GET /api/v1/stores/map` or `GET /api/v1/accounts/nearby` endpoint.
   - **Client Handling**: Uses `GET /api/v1/search` which returns listings together with real `account` (store/merchant/provider) metadata (`displayName`, `accountType`, `logoUrl`, `verificationStatus`).
4. **No Server-Side Map Clustering Endpoint**:
   - **Client Handling**: Implemented deterministic client-side spatial-grid clustering (`MapClusterEngine`) that clusters dense pins when zoomed out (`zoom < 15.2` and `count >= 12`) and expands clusters on tap/zoom-in.

---

## 5. Performance, Map Behavior & Location Permissions

- **Viewport-Gated Queries**: Small pans do not trigger API requests. `MapBoundingBox.hasMovedSignificantlyFrom` checks for a meaningful shift (`>= 28%` of viewport span or `>= 35%` zoom radius change) and surfaces a **"ابحث في هذه المنطقة" / "Search this area"** pill instead of spamming requests.
- **Debounced Search + Request Cancellation**: Text search is debounced (`450ms`) and cancels previous in-flight `Dio` requests via `CancelToken`.
- **Zero Reload on Marker Selection**: Tapping a marker updates `selectedPlace` in Riverpod state and animates `MapPlacePreviewCard` without reloading tiles or re-fetching backend data.
- **Per-Category State Preservation**: `categoryMapControllerProvider` is a non-`autoDispose` `StateNotifierProvider.family` keyed by `categorySlug`, preserving camera position, zoom, filters, search query, and selected place across section switches.
- **Privacy-First Location Permissions**:
  - `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION` declared in `android/app/src/main/AndroidManifest.xml`.
  - Permission is **never** requested automatically on app startup or map open.
  - Tapping the Current Location button displays a clear Arabic/English rationale dialog before requesting location or sending coordinates for nearby search.
  - Denying permission or running on a device without location services shows a non-blocking notice and allows full manual panning and searching.

---

## 6. Validation & Test Results

- `flutter analyze`: **0 issues found**.
- Automated test suites (`flutter test test/features/maps/universal_category_map_test.dart test/core/navigation/app_bottom_navigation_test.dart test/core/navigation/deal_one_bottom_navigation_test.dart test/features/profile_and_real_estate_ui_test.dart`): **27/27 tests PASSED**.
  - Verified Map Tab presence & unique `/map/<slug>` routes in all 6 categories.
  - Verified zero overflow on `DealOneSectionBottomNav` across `320×568`, `393×873`, and `768×1024` at `2.0x` text scale.
  - Verified strict category isolation and explicit opt-in "All Categories" toggle.
  - Verified zero mock coordinates when backend omits GPS fields.
  - Verified marker clustering with 150 dense locations (zoomed-out clusters + zoomed-in expansion).
  - Verified visible bounding-box marker filtering.
  - Verified independent state preservation across sections.
  - Verified rationale-gated location permission, graceful denial handling, marker preview without map reload, and network error handling.
