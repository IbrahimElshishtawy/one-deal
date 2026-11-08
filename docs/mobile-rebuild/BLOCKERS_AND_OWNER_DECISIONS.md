# Blockers and Owner Decisions

**Project:** Deal One Mobile Application  
**Phase:** Phase 00 — Discovery & Baseline Audit  
**Date:** November 8, 2026  
**Status:** AWAITING OWNER REVIEW & APPROVAL

---

## 1. Active Technical & Infrastructure Blockers

### Blocker 01: Remote Production Database Migration (External Backend Defect)
- **Observed Behavior:** `GET /health/live`, `GET /health/ready`, and `GET /api/docs-json` return HTTP 200, but any table query (`GET /api/v1/categories`, `GET /api/v1/listings`, `GET /api/v1/locations/governorates`) returns HTTP 500 with `INTERNAL_SERVER_ERROR`.
- **Root Cause:** Prisma migrations have not been applied to the Railway production PostgreSQL database, or table schema drift exists.
- **Mobile Mitigation:** Strictly adhere to Rule A1 (NO BACKEND MODIFICATIONS). Mobile integration will proceed using the verified OpenAPI 3.0 specification (`/api/docs-json`), source contracts, and sanitized mock fixtures for contract unit tests. No blocked production write calls will be attempted.
- **Required Owner Action:** Have backend/DevOps run `npx prisma migrate deploy` on Railway staging when convenient.

---

### Blocker 02: Flutter Baseline Static Analysis Failure (792 Compilation Errors)
- **Observed Behavior:** `flutter analyze` reports 792 errors in `deal one app`.
- **Root Cause:** In commit `dae153d`, the owner deleted all obsolete mock screens (299 files), but dangling imports remain in:
  1. `lib/app/app_dependencies.dart`
  2. `lib/bootstrap/bootstrap.dart`
  3. `lib/app/app_router.dart`
  4. `test/features/**` (32 obsolete test files testing deleted mock pages).
- **Mobile Action:** Cleanly prune these dangling imports and obsolete feature test files during Phase 03 (Foundation & Bootstrap) to restore a clean passing baseline (`flutter analyze` 0 errors, `flutter test` 100% pass).

---

### Blocker 03: Riverpod 2 Missing from `pubspec.yaml`
- **Observed Behavior:** The owner approved Riverpod 2 as the sole state management & DI framework, but `deal one app/pubspec.yaml` currently only lists `dio`, `go_router`, `flutter_secure_storage`, etc., without `flutter_riverpod`.
- **Mobile Action:** Add `flutter_riverpod: ^2.5.1` to `pubspec.yaml` during Phase 03.

---

## 2. Explicit Decisions Requested from Project Owner

| Decision ID | Topic | Recommended Option | Impact |
|---|---|---|---|
| **DEC-001** | Pruning Dangling Imports & Tests | **APPROVED** (Prune in Phase 03) | Clears all 792 analyzer errors and restores a pristine compilation baseline. |
| **DEC-002** | Add `flutter_riverpod` to `pubspec.yaml` | **APPROVED** (`flutter_riverpod: ^2.5.1`) | Enables implementation of approved Riverpod 2 state architecture. |
| **DEC-003** | Live Testing Strategy During Backend DB Gap | **APPROVED** (Use OpenAPI fixtures) | Unblocks mobile foundation and API contract mapping without waiting for remote DB migration. |

---

## 3. Phase 00 Gate Verdict

- **Phase Status:** **PASS** (Audit and baseline requirements met; all findings documented without modifying backend).
- **Next Step:** Proceed to **Phase 01 — Production API and OpenAPI Contract Verification** upon owner sign-off.
