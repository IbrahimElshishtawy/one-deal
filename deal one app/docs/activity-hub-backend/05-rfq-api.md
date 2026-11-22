# 05 — RFQ API Specification

- **Module:** `backend/src/modules/rfq/` (`RfqController`, `RfqService`, `rfq-state-machine.ts`).
- **Endpoints:**
  - `POST /api/v1/rfqs` — Rate-limited (`10/min`). Validates `items` (1..50), `requiredByDate` (non-past), `supportingImages` (HTTPS URLs, max 10), optional `categoryId` and `listingId`s. Generates unique `rfqNumber` (`RFQ-YYYYMMDD-XXXXXX`).
  - `GET /api/v1/rfqs` — Paginated list with `scope` (`mine | open_for_suppliers`), `status`, `categoryId`, `categorySlug`.
  - `GET /api/v1/rfqs/:id` — Returns RFQ with `items` and `quotationsCount`; enforces owner, admin, or open-to-suppliers visibility.
  - `PATCH /api/v1/rfqs/:id/cancel` — Owner-only cancellation via state machine.
