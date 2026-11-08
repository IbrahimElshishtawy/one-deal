# 06 — Mobile Architecture Decisions (ADRs)

**Project:** Deal One Mobile Application  
**Framework:** Flutter (Dart 3.13+)  
**State Management & DI:** Riverpod 2 (`flutter_riverpod`) only  
**Architecture:** Feature-First + Clean Architecture + Repository Pattern  
**Networking:** Dio with centralized `DioApiClient`  

---

## ADR 01: Riverpod 2 as the Single State & DI Solution
- **Context:** The legacy codebase used custom `InheritedWidget` (`AppDependenciesScope`) and `ValueNotifier`, causing race conditions, memory leaks, and complex dependency wiring.
- **Decision:** Use `flutter_riverpod` (v2.x) exclusively. No Provider, GetX, Bloc, or custom scopes.
- **Consequences:** Predictable lifecycle, compile-safe dependency overrides for tests, autoDispose for ephemeral screens, and fine-grained UI rebuilds with `ref.watch(provider.select(...))`.

## ADR 02: Feature-First + Clean Architecture Structure
- **Context:** Code was previously scattered between global `core` and duplicate monolithic features.
- **Decision:** Each feature under `lib/features/<feature_name>/` contains:
  - `data/`: DTOs, Data Sources (Remote/Local), Mappers, Repository Implementations.
  - `domain/`: Entities, Value Objects, Repository Interfaces, Use Cases (where justified).
  - `presentation/`: Providers/Controllers (Notifier/AsyncNotifier), Pages, Widgets.
- **Consequences:** Domain remains pure Dart with 0 Flutter/Dio dependencies. Features can be developed and tested in isolation.

## ADR 03: Centralized Dio HTTP Client & Concurrency-Safe Refresh
- **Context:** Features previously created independent HTTP calls or relied on unstable token passing.
- **Decision:** A single `DioApiClient` in `core/network/` manages:
  - Base URL selection from `AppConfig`.
  - Ordered interceptors: `RequestIdInterceptor` -> `AuthInterceptor` -> `LoggingInterceptor`.
  - Single-flight token refresh queue preventing refresh storms on concurrent 401s.
- **Consequences:** Token values are never leaked in logs, refresh is thread-safe, and unauthorized access cleanly triggers logout.

## ADR 04: Hybrid In-Memory & Persistent Caching Policy
- **Context:** A large catalog (2M design target) cannot be stored in-memory without causing OOM crashes.
- **Decision:** 
  - Short-lived In-Memory Cache (TTL: 5-15 mins) for feeds and search results.
  - Disk Cache (`shared_preferences`) only for non-sensitive offline-friendly metadata (Governorates, Categories).
  - Secure Storage (`flutter_secure_storage`) strictly for JWT tokens and refresh tokens.
  - Server is always source-of-truth for availability, prices, moderation, and quotas.

## ADR 05: Privacy-First Contact Reveal Architecture
- **Context:** Public feeds must never expose seller phone numbers to prevent automated scraping.
- **Decision:** Listing entities in feeds have `sellerPhone: null`. Phone numbers are only obtained by calling `POST /api/v1/listings/:id/contact`, which enforces Cairo daily quotas and IP rate limiting.
