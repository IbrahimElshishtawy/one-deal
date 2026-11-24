# 08 — Testing & Verification Report

All tests below were actually executed against the live NestJS + Fastify backend, PostgreSQL (`marketspace`), and Redis on `2026-11-24`. No mocked results were used in the E2E integration suite.

## Summary of Executed Suites

| Suite | Command | Result | Duration |
|---|---|---|---|
| **TypeScript Build** | `npm run build` | **PASS** (0 errors) | ~5s |
| **Full Backend Unit & Service Suite** | `npm test` | **50/50 suites passed, 345/345 tests passed** | 19.19s |
| **Seller Verification E2E Suite** | `npx jest --config ./test/jest-e2e.json test/seller-verification.e2e-spec.ts` | **1/1 suite passed, 9/9 blocks passed (23/23 scenarios)** | 4.07s |

## New Automated Test Files

1. `src/modules/accounts/seller-application-state-machine.spec.ts` — Unit tests for all 11 valid transitions, 13 invalid transitions, and individual/commercial document completeness rules.
2. `src/modules/accounts/guards/seller-authorization.guard.spec.ts` — Unit tests for `canCreateListing`, `canManageListing`, `canAccessSellerDashboard`, ownership mismatch, and `UNAUTHORIZED_SELLER_OPERATION_ATTEMPTED` audit logging.
3. `src/modules/accounts/services/seller-application.service.spec.ts` — Unit tests for self-approval prevention, incomplete application rejection, optimistic concurrency lock on duplicate approval, transactional rollback consistency on mid-transaction DB failure, and private storage key isolation (blocking `uploads/images/` and path traversal).
4. `test/seller-verification.e2e-spec.ts` — Live end-to-end HTTP integration tests against PostgreSQL & Redis.

## 23-Scenario Coverage Matrix (All Executed & Passing)

| # | Required Scenario | Verified By | Status |
|---|---|---|---|
| 1 | New registration creates BUYER (`sellerStatus=NOT_REQUESTED`, `roles=['BUYER']`, `activeAccount=null`) | `seller-verification.e2e-spec.ts` + `auth.service.spec.ts` | PASS |
| 2 | Buyer can request seller conversion (`DRAFT`) | `seller-verification.e2e-spec.ts` | PASS |
| 3 | Seller application becomes `PENDING` after document upload & submission | `seller-verification.e2e-spec.ts` | PASS |
| 4 | Pending seller cannot create listing (`403`) | `seller-verification.e2e-spec.ts` + guard spec | PASS |
| 5 | Pending seller cannot publish listing (`403`) | `seller-verification.e2e-spec.ts` | PASS |
| 6 | Pending seller cannot access seller dashboard (`403`) | `seller-verification.e2e-spec.ts` | PASS |
| 7 | Pending seller can retrieve application status & history (`200`) | `seller-verification.e2e-spec.ts` | PASS |
| 8 | Admin can list, inspect documents, and mark `UNDER_REVIEW` | `seller-verification.e2e-spec.ts` | PASS |
| 9 | Unauthorized user cannot approve application (`403`); self-approval blocked (`403`) | `seller-verification.e2e-spec.ts` + service spec | PASS |
| 10 | Admin can approve complete application (`APPROVED`) | `seller-verification.e2e-spec.ts` | PASS |
| 11 | Approved seller can create listings (`201`) | `seller-verification.e2e-spec.ts` | PASS |
| 12 | Approved seller can manage owned listings (`200`); non-owners blocked (`403`) | `seller-verification.e2e-spec.ts` + guard spec | PASS |
| 13 | Approved seller can still purchase (`POST /cart/items`) | `seller-verification.e2e-spec.ts` | PASS |
| 14 | Approved seller can still favorite (`POST /favorites`) | `seller-verification.e2e-spec.ts` | PASS |
| 15 | Rejected seller cannot publish (`403`) | `seller-verification.e2e-spec.ts` | PASS |
| 16 | Rejected seller can resubmit according to policy (`resubmissionCount` incremented) | `seller-verification.e2e-spec.ts` | PASS |
| 17 | Suspended seller loses seller privileges immediately (`403` on create/edit/dashboard) | `seller-verification.e2e-spec.ts` | PASS |
| 18 | Suspended seller retains buyer permissions (`GET /users/me`, `/listings`, `/favorites`, `/cart` all `200`) | `seller-verification.e2e-spec.ts` | PASS |
| 19 | Existing seller/listing relationships remain valid in DB | `seller-verification.e2e-spec.ts` | PASS |
| 20 | Invalid status transitions are rejected (`400`) | `seller-verification.e2e-spec.ts` + state machine spec | PASS |
| 21 | Duplicate active applications are prevented (`409` + DB partial unique index) | `seller-verification.e2e-spec.ts` | PASS |
| 22 | Unauthorized document access is rejected (`403`) | `seller-verification.e2e-spec.ts` + service spec | PASS |
| 23 | Approval & permission updates remain transactionally consistent | `seller-verification.e2e-spec.ts` + service spec | PASS |

## Real-DB Defect Caught & Resolved During E2E Testing

During E2E execution of scenario #17 (`suspendSeller`), PostgreSQL enforced legacy check constraint `chk_account_verification_status` on `accounts` (allowing only `'pending' | 'approved' | 'rejected'`). `suspendSeller()` was updated to deactivate seller `Account` records (`isActive: false`) while setting `User.sellerStatus = 'SUSPENDED'` and preserving `User.isActive = true`. Re-running the full E2E suite confirmed 100% pass without altering legacy constraints.
