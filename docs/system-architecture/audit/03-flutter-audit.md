# 03 — Flutter Architecture & Compatibility Audit

## 1. Inspected Components

- `deal one app/lib/core/network/api_client.dart`, `api_endpoints.dart`
- `deal one app/lib/core/network/interceptors/auth_interceptor.dart`, `retry_interceptor.dart`
- `deal one app/lib/features/seller_verification/domain/enums/seller_verification_enums.dart`
- `deal one app/lib/features/seller_verification/services/document_upload/document_upload_service.dart`

## 2. Verified Strengths

- **Single-Flight Token Refresh (`auth_interceptor.dart:17-18,111-186`):** Uses `_isRefreshing` + `Completer<String?>` so concurrent `401` responses share a single refresh call, avoiding refresh-token reuse detection triggers on the backend.
- **Trusted-Origin Bearer Scoping (`auth_interceptor.dart:32-45,193-201`):** Only attaches `Authorization: Bearer` to `trustedOrigin`, preventing JWT leakage to Cloudflare R2 presigned PUT/GET requests.
- **Safe Retry Method Scoping (`retry_interceptor.dart:20-22,59-61`):** Standard transient retries are strictly restricted to `GET` and `HEAD` (`isIdempotentMethod`).

## 3. Verified Findings

### Finding `MOB-001` — HIGH — Flutter Client Missing `WITHDRAWN` Status & `/me/withdraw`, `/me/renew` Integration
- **Status:** VERIFIED
- **Evidence:**
  - `deal one app/lib/features/seller_verification/domain/enums/seller_verification_enums.dart:56,92` (supports `EXPIRED`, lacks `WITHDRAWN`)
  - `deal one app/lib/core/network/api_endpoints.dart:52-82` (lacks `/seller-applications/me/withdraw` and `/seller-applications/me/renew`)
- **Actual Behavior:** If a seller withdraws an application (or an admin/API returns `WITHDRAWN`), the Flutter enum parser falls back/fails to represent `WITHDRAWN`, and mobile users have no UI/API wiring to withdraw or renew expired verifications.
- **Recommended Resolution:** Add `withdrawn('WITHDRAWN')` to `seller_verification_enums.dart`, add `sellerApplicationWithdraw` & `sellerApplicationRenew` to `api_endpoints.dart`, and wire UI actions + status banners in `features/seller_verification`.
- **Business Decision Required:** No (scheduled mobile release dependency).

### Finding `MOB-002` — LOW — Emulator Fallback in `RetryInterceptor` Does Not Check `isIdempotentMethod`
- **Status:** VERIFIED
- **Evidence:** `deal one app/lib/core/network/interceptors/retry_interceptor.dart:32-55`
- **Actual Behavior:** On `DioExceptionType.connectionError`, if `baseUrl` contains `://localhost:`, `://127.0.0.1:`, or `://10.0.2.2:`, it replays the request regardless of HTTP method (`POST` included).
- **Production Impact:** None in production (only matches localhost/loopback URLs), but could duplicate a local dev `POST` if the emulator bridge switches mid-request.
- **Recommended Resolution:** Restrict emulator fallback to `kDebugMode` and/or idempotent methods.
- **Business Decision Required:** No.

### Finding `MOB-003` — INFO — Uneven Feature Layering Across Vertical Hubs
- **Status:** VERIFIED
- **Evidence:** `deal one app/lib/features/`
- **Actual Behavior:** `auth`, `activity_hub`, and `seller_verification` implement 4 layers (`application/data/domain/presentation`); 13 domain features implement 3 layers (`data/domain/presentation`); 6 hubs (`main_hub`, `cars_maintenance`, `appliances_decor`, `construction_electrical`, `fashion_accessories`, `services_engineering`) are presentation shells reusing `listings`/`search` providers.
- **Recommended Resolution:** Document as an intentional lightweight shell pattern (already noted in `04-flutter-architecture.md`).
