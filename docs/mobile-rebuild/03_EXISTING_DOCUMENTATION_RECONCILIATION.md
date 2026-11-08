# 03 — Existing Documentation Reconciliation

**Project:** Deal One Mobile Application  
**Audit Date:** November 8, 2026  
**Auditor:** Principal Flutter Architect & Technical Documentation Engineer  
**Status:** RECONCILED & UPDATED

---

## 1. Documentation vs Reality Comparison

| Document | Historical Claim / Description | Verified Current Reality | Approved Action / Direction |
|---|---|---|---|
| **`docs/mobile-system-design/05 – State_Management_and_Data_Flow.md`** | Prescribed `ValueNotifier` and custom `InheritedWidget` (`AppDependenciesScope`) for state and DI. | Legacy approach led to manual boilerplate, race conditions in refresh, and memory leaks. The owner explicitly approved **Riverpod 2 only**. | **SUPERSEDED:** All state and DI will exclusively use `flutter_riverpod` (Riverpod 2). Old custom scopes will be decommissioned. |
| **`docs/mobile-system-design/03 – Application_Modules.md`** | Described e-commerce capabilities: cart, checkout, staged shipments, RFQs, order management. | Deal One is an Egyptian classifieds marketplace. E-commerce retail carts were deleted in commit `dae153d`. | **INVALIDATED:** E-commerce carts are strictly OUT OF SCOPE for V1. Only classified listings and contact reveal apply. |
| **`30_FLUTTER_BACKEND_INTEGRATION_REPORT.md`** | Claimed all 6 sectors were connected and integrated. | Integration was superficial; it relied on static mock arrays (`mock_building_materials_data.dart`, etc.) and did not use real API contracts. | **PURGED:** All mock UI and fake models were deleted in `dae153d`. New repositories will map directly to verified OpenAPI contracts. |
| **`BACKEND_PROJECT_STATUS.md`** | Reported backend is fully operational in staging with 340 demo listings. | Health probes and OpenAPI are operational (`/health/ready` 200, `/api/docs` 200), but PostgreSQL queries in production return 500. | **DOCUMENTED GAP:** Documented as an external infrastructure blocker; contracts verified via `/api/docs-json` and backend TypeScript source. |
| **`docs/mobile/folder-structure.md`** | Legacy folder layout from early prototype. | Diverged from the Feature-First + Clean Architecture target specified in the master prompt. | **ALIGNED:** New standard folder structure defined in Phase 02 specification. |

---

## 2. Reusable Product Rules Extracted from Legacy Docs

While obsolete architecture is rejected, the following business domain rules remain valid:
1. **Egyptian Geographic Hierarchy:** 27 Governorates, subdivided into Cities/Districts.
2. **Dialect and Search Tolerances:** Users search with mixed Arabic orthography (أ / ا / إ / آ and ه / ة and ي / ى). Search normalization must be handled gracefully.
3. **Contact Privacy Flow:** Seller phone numbers are shielded; clicking "Show Number" increments the reveal counter and logs the lead event.
4. **Dynamic Attributes by Subcategory:** Automotive subcategories require year/make/model/transmission; Real Estate requires property type/rooms/area; Electronics requires brand/warranty. All must be driven by backend `/categories/:slug/fields`.

---

## 3. Approved Modern Architectural Stack

- **State Management & Dependency Injection:** Riverpod 2 (`flutter_riverpod`) only.
- **Networking:** Centrally configured `Dio` client with interceptors for trace IDs, auth token injection, concurrency-safe 401 refresh, and redacted logging.
- **Architecture Pattern:** Feature-First + Clean Architecture (Data, Domain, Presentation).
- **Navigation:** `go_router` with declarative, typed route definitions.
- **Secure Persistence:** `flutter_secure_storage` for tokens; `shared_preferences` for non-sensitive user preferences.
- **Local Cache:** Hybrid in-memory TTL cache with server revalidation.
