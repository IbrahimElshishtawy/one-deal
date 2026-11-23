# Deal One — Modular Widget-Based Navigation Drawer Architecture Report

## 1. Architecture Overview

The Deal One Navigation Drawer has been refactored into a **fully modular, widget-based, single-responsibility architecture** where `DealOneNavigationDrawer` acts solely as a thin container assembling independent, testable UI widgets and category-specific configurations backed by Riverpod and GoRouter Named Routes.

### Core Architectural Guarantees
- **Strict Dependency Direction (Zero Circular Dependencies)**:
  `models/` → `providers/` → `config/categories/` → `config/category_drawer_registry.dart` → `widgets/` → `deal_one_navigation_drawer.dart`.
- **Minimal Rebuilds (Performance)**:
  - 13 of 14 Drawer widgets are pure `StatelessWidget`s.
  - Only `DealOneNavigationDrawer` (top-level container) and `DrawerBadgeWidget` (tiny isolated badge pill watching a single `ProviderListenable<int>?`) are `ConsumerWidget`s.
- **Named Routes Only**: Every navigation item uses `RouteNames.*Name` with explicit `pathParameters` and `queryParameters` (`context.pushNamed` / `context.goNamed`).
- **Zero Duplicate Logic**: Reuses the single authoritative `accountCapabilitiesProvider` for both Bottom Navigation and Drawer.

---

## 2. File Structure (`lib/core/navigation/drawer/`)

```text
lib/core/navigation/drawer/
├── models/
│   └── drawer_item_config.dart                  # DrawerItemConfig contract (routeName, params, badgeProvider, visibility)
├── providers/
│   ├── drawer_badge_providers.dart              # Isolated live count providers (notifications, chat, incoming bookings/RFQs)
│   └── drawer_providers.dart                    # Unified drawerConfigProvider(categorySlug)
├── config/
│   ├── category_drawer_registry.dart            # Aggregates 6 category configs + shared Account/Legal sections
│   └── categories/
│       ├── real_estate_drawer.dart              # RealEstateDrawer + Real Estate items
│       ├── services_drawer.dart                 # ServicesDrawer + Services & Engineering items
│       ├── building_materials_drawer.dart       # BuildingMaterialsDrawer + Building Materials items
│       ├── appliances_drawer.dart               # AppliancesDrawer + Appliances & Decor items
│       ├── automotive_drawer.dart               # AutomotiveDrawer + Cars & Maintenance items
│       └── fashion_drawer.dart                  # FashionDrawer + Fashion & Accessories items
├── widgets/
│   ├── drawer_header_widget.dart                # Composes Avatar, Info, Verification, Guest CTA, Error/Retry, Account Switcher
│   ├── account_avatar_widget.dart               # Circular account/user avatar
│   ├── account_info_widget.dart                 # Account display name + verification pill
│   ├── account_verification_widget.dart         # Authoritative backend verification status badge
│   ├── category_switcher_widget.dart            # 6-category switcher + Main Hub shortcut
│   ├── drawer_section_widget.dart               # Titled Material card group (proper ink splashes & Light/Dark support)
│   ├── drawer_item_widget.dart                  # Reusable navigation tile with RTL/LTR chevron + isolated badge
│   ├── drawer_badge_widget.dart                 # Isolated ConsumerWidget watching only badgeProvider
│   ├── drawer_divider_widget.dart               # Consistent section divider
│   ├── drawer_account_widget.dart               # Account Management section (Profile, Edit, Notifications, Messages, Settings)
│   ├── drawer_settings_widget.dart              # Settings / Language / Theme bottom-sheet trigger
│   ├── drawer_support_widget.dart               # Help & Legal section (Terms & Privacy)
│   ├── drawer_footer_widget.dart                # Logout card + Deal One branding
│   └── drawer_logout_widget.dart                # Authenticated Sign Out tile
├── deal_one_navigation_drawer.dart              # Thin container assembling all modular widgets
├── drawer_item_config.dart                      # Backward-compatible barrel export
├── category_drawer_registry.dart                # Backward-compatible barrel export
└── drawer_providers.dart                        # Backward-compatible barrel export
```

---

## 3. Widgets Responsibilities

| Widget | Type | Single Responsibility |
|---|---|---|
| `DrawerHeaderWidget` | `StatelessWidget` | Composes header card, guest sign-in button, network error/retry banner, and multi-account switcher chips |
| `AccountAvatarWidget` | `StatelessWidget` | Renders circular account logo or fallback user icon |
| `AccountInfoWidget` | `StatelessWidget` | Displays active account/user name and nests `AccountVerificationWidget` |
| `AccountVerificationWidget` | `StatelessWidget` | Renders backend verification pill (`Verified` / `pending` / `rejected` / `Verifying...` / `Guest`) |
| `CategorySwitcherWidget` | `StatelessWidget` | Switches across all 6 categories + Main Hub while highlighting the active section |
| `DrawerSectionWidget` | `StatelessWidget` | Renders titled section header + Material surface card group |
| `DrawerItemWidget` | `StatelessWidget` | Accessible navigation tile with directional chevron and optional `DrawerBadgeWidget` |
| `DrawerBadgeWidget` | `ConsumerWidget` | Watches only its own `badgeProvider` / `badgeKey` so count changes never rebuild the whole Drawer |
| `DrawerDividerWidget` | `StatelessWidget` | Consistent themed horizontal divider |
| `DrawerAccountWidget` | `StatelessWidget` | Groups Account Management items + `DrawerSettingsWidget` |
| `DrawerSettingsWidget` | `StatelessWidget` | Opens `showProfileSettingsSheet(context)` for Language & Theme |
| `DrawerSupportWidget` | `StatelessWidget` | Groups Terms of Service & Privacy Policy items |
| `DrawerFooterWidget` | `StatelessWidget` | Renders `DrawerLogoutWidget` (when authenticated) and Deal One footer text |
| `DrawerLogoutWidget` | `StatelessWidget` | Dispatches `sessionProvider.notifier.logout()` |

---

## 4. Existing Pages Integration & Route Mapping

Every visible Drawer item opens an **existing real screen** via GoRouter Named Routes (`lib/app/app_router.dart` + `lib/core/routing/route_names.dart`):

| Drawer Action | Existing Target Screen | Named Route | Parameters |
|---|---|---|---|
| Category Switcher (6 Sections) | `RealEstateHomePage`, `ServicesEngineeringHomePage`, `ConstructionElectricalHomePage`, `AppliancesDecorHomePage`, `CarsMaintenanceHomePage`, `FashionAccessoriesHomePage` | `realEstateName`, `homeServicesName`, `buildingMaterialsName`, `homeAppliancesName`, `carsName`, `fashionName` | — |
| Main Hub | `MainHubPage` | `rootName` | — |
| Favorites (complementary for sellers) | `ActivityHubPage(initialTab: favorites)` | `favoritesName` | — |
| Create Listing / Service / Product | `CreateListingPage` | `createListingName` | `queryParameters: {'category': slug, 'kind': ...}` |
| Listing Management / My Cars | `SellerManagementPage` | `sellerManagementName` | `pathParameters: {'categorySlug': slug, 'mode': 'listings'}` |
| Incoming Service / Maintenance Requests | `SellerManagementPage(initialTabIndex: 1)` | `sellerManagementName` | `pathParameters: {'categorySlug': slug, 'mode': 'services'}, queryParameters: {'tab': 'incoming'}` |
| Incoming RFQs | `SellerManagementPage(initialTabIndex: 1)` | `sellerManagementName` | `pathParameters: {'categorySlug': 'building-materials', 'mode': 'products'}, queryParameters: {'tab': 'incoming'}` |
| Property Viewings / Booking & Service History | `ActivityHubPage(initialTab: bookings)` | `activityHubName` | `queryParameters: {'tab': 'bookings', 'category': slug}` |
| Supplier Discovery | `SearchScreen` (pre-scoped to `building-materials`) | `searchName` | Sets `searchActiveQueryDtoProvider` |
| Profile & Verification | `ProfileScreen` | `profileName` | — |
| Edit Account Details | `EditAccountPage` | `editAccountName` | — |
| Notifications | `NotificationsPage` | `globalNotificationsName` | — |
| Messages (non-Real-Estate sections) | `ConversationsPage` | `conversationsName` | — |
| Settings | `showProfileSettingsSheet(context)` | Modal Bottom Sheet | — |
| Terms & Privacy | `LegalDocumentPage` | `termsName`, `privacyName` | — |

---

## 5. Riverpod Integration & Capability Mapping

- **Unified Capabilities Source**: `accountCapabilitiesProvider` (`lib/core/navigation/providers/section_navigation_provider.dart`) resolves authoritative permissions from `sessionProvider`, `myAccountsProvider`, and `activeAccountProvider`.
- **Unified Drawer Config Source**: `drawerConfigProvider(categorySlug)` resolves all visible items for the active category and user capabilities.
- **Isolated Live Badge Providers**:
  - `drawerNotificationsUnreadProvider`
  - `drawerChatUnreadProvider`
  - `drawerIncomingServiceRequestsCountProvider`
  - `drawerIncomingMaintenanceRequestsCountProvider`
  - `drawerIncomingRfqsCountProvider`
- **No direct Backend calls in Widgets**: All API calls stay inside repositories/providers.

---

## 6. Missing Screens (Not Fabricated — Explicitly Hidden)

Per strict rules, no placeholder or fake screens were created for features lacking Backend/Flutter implementation:
1. **Real Estate**: `Contact Requests` (no `GET /contact-requests`), `Saved Searches` (no backend/local store), `Recently Viewed` (no history store).
2. **Services & Engineering**: `Schedule Management` (no provider schedule API), `Service Areas` (backend endpoints exist, dedicated Flutter management screen not yet built).
3. **Building Materials**: `My Quotations` (no `GET /quotations/mine` endpoint for suppliers).
4. **Appliances & Fashion**: `Recently Viewed` (no history store).

---

## 7. Validation & Test Results

- **`flutter analyze`**: **0 issues found**.
- **`flutter test test/core/navigation/ test/features/seven_homes_widget_test.dart`**: **39 / 39 tests PASSED**.
  - Verified standalone modular widgets (`DrawerHeaderWidget`, `AccountAvatarWidget`, `AccountInfoWidget`, `AccountVerificationWidget`, `CategorySwitcherWidget`, `DrawerItemWidget`, `DrawerBadgeWidget`, `DrawerFooterWidget`, `DrawerLogoutWidget`).
  - Verified all 6 category-specific drawer widgets (`RealEstateDrawer`, `ServicesDrawer`, `BuildingMaterialsDrawer`, `AppliancesDrawer`, `AutomotiveDrawer`, `FashionDrawer`).
  - Verified live permission changes during an active session without logout.
  - Verified Buyer, Activated Seller, Activated Provider, Multi-Capability, Unauthorized, Loading, Error, RTL/LTR, and responsive layouts with zero overflow.
