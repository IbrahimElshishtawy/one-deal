# 09 — Automated Testing Report

## Test Suites Executed

All tests were executed against real local PostgreSQL (with all 13 Prisma migrations applied) and Redis — no mocked database or mocked HTTP pipeline for E2E tests.

### 1. Seller Verification Unit & Security Tests
- `src/modules/accounts/services/seller-verification-security.spec.ts` (7 tests)
- `src/modules/accounts/services/seller-application.service.spec.ts`
- `src/modules/accounts/seller-application-state-machine.spec.ts`
- `src/modules/accounts/guards/seller-authorization.guard.spec.ts`
- `src/modules/accounts/accounts.service.spec.ts`
- `src/core/database/migrate-deploy.spec.ts`
- **Result**: **6/6 suites passed, 57/57 tests passed**.

### 2. Seller Verification E2E Tests (Real PostgreSQL + Redis + Fastify/NestJS)
- `test/seller-verification.e2e-spec.ts` (9 test groups covering 23 buyer-to-seller scenarios)
- `test/seller-verification-identity-review.e2e-spec.ts` (8 test groups covering all 20 identity review & verification requirements)
- **Result**: **2/2 suites passed, 17/17 tests passed**.

### 3. Full Backend Unit Test Suite
- `npm test -- --runInBand --forceExit`
- **Result**: **50/51 suites passed (351/352 tests passed)**; the single pre-existing flake was `core/redis/redis.service.spec.ts` (`idem:event:1` key TTL collision in local Redis from a prior run, unrelated to seller verification).

## 20-Scenario Verification Matrix

| # | Requirement Scenario | Test File | Status |
| --- | --- | --- | --- |
| 1 | Buyer creates seller application | `seller-verification-identity-review.e2e-spec.ts` | PASS |
| 2 | Different seller types (`INDIVIDUAL`, `BUSINESS`, `SERVICE_PROVIDER`) & sections receive correct requirements | `seller-verification-identity-review.e2e-spec.ts` | PASS |
| 3 | Required documents & expiration dates are validated | `seller-verification-identity-review.e2e-spec.ts` | PASS |
| 4 | Invalid file formats (disallowed MIME & spoofed magic bytes) are rejected | `seller-verification-identity-review.e2e-spec.ts` + `seller-verification-security.spec.ts` | PASS |
| 5 | Oversized files are rejected | `seller-verification-identity-review.e2e-spec.ts` + `seller-verification-security.spec.ts` | PASS |
| 6 | Private documents cannot be accessed publicly or stored in public media paths | `seller-verification-identity-review.e2e-spec.ts` + `seller-verification-security.spec.ts` | PASS |
| 7 | Buyer cannot approve an application | `seller-verification-identity-review.e2e-spec.ts` | PASS |
| 8 | Admin can review an application (filtering, detail, start review, individual doc review) | `seller-verification-identity-review.e2e-spec.ts` | PASS |
| 9 | Incomplete application (missing or rejected doc) cannot be approved | `seller-verification-identity-review.e2e-spec.ts` | PASS |
| 10 | Admin can request corrections (`UNDER_REVIEW → NEEDS_CORRECTION`) | `seller-verification-identity-review.e2e-spec.ts` | PASS |
| 11 | User can replace rejected documents (version incremented, previous version preserved, accepted docs protected) | `seller-verification-identity-review.e2e-spec.ts` | PASS |
| 12 | User can resubmit corrected/rejected application | `seller-verification-identity-review.e2e-spec.ts` + `seller-verification.e2e-spec.ts` | PASS |
| 13 | Admin can approve a valid application | `seller-verification-identity-review.e2e-spec.ts` | PASS |
| 14 | Approval grants seller permissions | `seller-verification-identity-review.e2e-spec.ts` | PASS |
| 15 | Buyer permissions remain active | `seller-verification-identity-review.e2e-spec.ts` | PASS |
| 16 | Pending seller cannot publish listings | `seller-verification-identity-review.e2e-spec.ts` | PASS |
| 17 | Suspended seller loses seller privileges (retains buyer permissions & listings) | `seller-verification-identity-review.e2e-spec.ts` + `seller-verification.e2e-spec.ts` | PASS |
| 18 | Expired verification follows defined policy (revokes seller ops, preserves buyer ops & data) | `seller-verification-identity-review.e2e-spec.ts` | PASS |
| 19 | Unauthorized document access is rejected (other buyer, non-admin, admin without `verification.documents.read`) | `seller-verification-identity-review.e2e-spec.ts` | PASS |
| 20 | Audit history, document reviews, and safe in-app notifications are preserved with zero PII leakage | `seller-verification-identity-review.e2e-spec.ts` | PASS |
