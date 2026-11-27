# 04 — Flutter Application Architecture Diagram

## Overview

The Deal One mobile application (`deal one app/lib/`) is built with **Flutter**, **Riverpod** (`flutter_riverpod`) for state management, **Dio** for HTTP networking, and **GoRouter** for declarative navigation and route guards.

As verified in `deal one app/lib/features/`, the app uses **feature-first modularization** with three practical layering depths depending on feature complexity (not every vertical hub duplicates data/domain layers).

## Diagram

```mermaid
flowchart TB
    subgraph Entry["App Entry & Bootstrap"]
        Main["main.dart\n(AppConfig.fromEnvironment)"]
        Bootstrap["bootstrap/bootstrap.dart\n(ProviderScope, Localization, Error Hooks)"]
    end

    subgraph Core["Core Layer (lib/core/)"]
        Routing["core/routing/ & core/navigation/\n(GoRouter, route_names.dart, route_guards.dart,\nDrawer & Bottom Nav Shell)"]
        Network["core/network/\nApiClient (Dio) + ApiEndpoints"]
        Interceptors["Dio Interceptors:\n1. RequestIdInterceptor\n2. AuthInterceptor (Bearer JWT + Auto Refresh)\n3. RetryInterceptor\n4. LoggingInterceptor"]
        Storage["core/storage/ & core/security/\n(FlutterSecureStorage Tokens + Local Cache)"]
        CoreUI["core/theme/ | core/localization/ (AR/EN RTL)\ncore/errors/ | core/constants/ | core/logging/"]
    end

    subgraph Shared["Shared Layer (lib/shared/)"]
        SharedModels["shared/models/ & shared/state/\n(Common DTOs, Pagination, Global Providers)"]
        SharedWidgets["shared/widgets/ & market_widgets/\n(Reusable Cards, Badges, Skeletons, Empty States)"]
    end

    subgraph Features4["4-Layer Features (application / data / domain / presentation)"]
        FAuth["features/auth\n(OTP, Password, Session, Guest)"]
        FVerify["features/seller_verification\n(Wizard, Doc Upload/R2 PUT, Tracking, Upgrade)"]
        FActivity["features/activity_hub\n(Bookings, RFQs, Quotations, Cart)"]
    end

    subgraph Features3["3-Layer Features (data / domain / presentation)"]
        FAccounts["features/accounts"]
        FListings["features/listings"]
        FCategories["features/categories"]
        FSearch["features/search"]
        FChat["features/conversations"]
        FFavorites["features/favorites"]
        FLocations["features/locations & maps"]
        FMedia["features/media"]
        FNotif["features/notifications"]
        FMod["features/moderation & quotas"]
        FRealEstate["features/real_estate"]
    end

    subgraph FeaturesShell["Presentation Vertical Hubs (presentation only — reuse shared listings/search)"]
        VHubs["features/main_hub\nfeatures/cars_maintenance\nfeatures/appliances_decor\nfeatures/construction_electrical\nfeatures/fashion_accessories\nfeatures/services_engineering"]
    end

    Main --> Bootstrap
    Bootstrap --> Routing
    Routing --> Features4
    Routing --> Features3
    Routing --> FeaturesShell

    Features4 -->|"Riverpod Providers"| Shared
    Features3 -->|"Riverpod Providers"| Shared
    FeaturesShell -->|"Reuses Providers & Widgets"| FListings
    FeaturesShell -->|"Reuses Providers & Widgets"| FSearch
    FeaturesShell --> SharedWidgets

    Features4 -->|"Repositories / DataSources"| Network
    Features3 -->|"Repositories / DataSources"| Network
    Network --> Interceptors
    Interceptors --> Storage
    Routing --> CoreUI
```

## Layering & Error Handling Notes

1. **Single Dio Client:** All features share `core/network/api_client.dart`. `AuthInterceptor` injects `Authorization: Bearer <token>` and handles `401` token refresh transparently via `core/security/` secure storage.
2. **Direct R2 Document Upload:** `features/seller_verification/services/` uses presigned PUT URLs returned by the backend to upload binary KYC documents directly to Cloudflare R2 without sending auth headers to R2.
3. **Localization (AR/EN):** Managed via `lib/l10n/` ARB files and generated delegates (`lib/l10n/generated/`), supporting full RTL layout switching.
4. **Honest Layering Note:** Only `auth`, `seller_verification`, and `activity_hub` contain an explicit `application/` layer; other transactional features use `data/domain/presentation`, and 5 category verticals are thin presentation shells over `listings` and `search`.
