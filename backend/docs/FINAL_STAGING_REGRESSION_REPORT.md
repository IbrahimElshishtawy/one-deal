# Deal One — Final Staging Regression Report (Phase Nine)

**Execution Date:** 2026-11-19  
**Branch:** `staging-validation` (`712c254`)  
**Environment:** Local Linux Workspace + Real Local Docker (`postgis/postgis:16-3.4-alpine`, `redis:7.2-alpine` Cache & Queue)  
**Overall Local Regression Status:** **PASS (100% of Backend & Flutter checks passed)**

---

## 1. Backend Regression Results

| Check | Command | Result | Details |
|---|---|---|---|
| **Build** | `npm run build` (`nest build`) | **PASS** | Exit code `0` |
| **TypeScript Typecheck** | `npx tsc --noEmit` | **PASS** | Exit code `0`, 0 type errors |
| **ESLint Static Analysis** | `npx eslint "{src,apps,libs,test}/**/*.ts"` | **PASS** | Exit code `0`, **0 errors** (3 non-blocking unused-var warnings in `src/core/config/env.config.spec.ts` lines 85, 92, 154) |
| **Unit Tests** | `npm test` | **PASS** | **35/35 suites, 222/222 tests passed** (`17.061s`) |
| **E2E & Security Integration Tests (Real DB + Real Redis)** | `npm run test:e2e` | **PASS** | **6/6 suites, 43/43 tests passed** (`9.419s`): `app`, `auth-database-redis`, `auth`, `security-integration`, `staging-validation`, `new-features` |

---

## 2. Flutter Regression & API Compatibility Results

Directory: `../deal one app`

| Check | Command | Result | Details |
|---|---|---|---|
| **Static Analysis** | `flutter analyze --no-pub` | **PASS** | `No issues found! (ran in 3.9s)` |
| **Full Flutter Test Suite** | `flutter test` | **PASS** | **81/81 tests passed** (includes `listings_repository_test.dart`, `search_repository_test.dart`, `auth_repository_test.dart`, `media_repository_test.dart`, `notification_repository_test.dart`, `auth_integration_test.dart`, `auth_widgets_test.dart`, theme & navigation tests) |
| **Feed API & Pagination Contract** | `test/staging-validation.e2e-spec.ts` + DTO inspection | **PASS** | `GET /api/v1/listings` returns `{ success: true, data: [...], meta: { nextCursor, next_cursor, limit, hasMore } }` without duplicate `items`; matches `ListingFeedResponseDto.fromJson`, `SearchResponseDto.fromJson`, `PaginatedResponse.fromJson`, and `MarketRepository`. |

---

## 3. Notes & Remaining Remote Verification

- Zero previously passing tests regressed.
- Remote Railway Staging E2E regression remains **BLOCKED** until the Railway `staging` environment is provisioned (see `docs/RAILWAY_STAGING_E2E_REPORT.md`).
