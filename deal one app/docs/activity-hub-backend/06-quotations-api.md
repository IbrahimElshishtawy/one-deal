# 06 — Quotations API Specification

- **Module:** `backend/src/modules/rfq/` (`RfqController`, `RfqService`, `rfq-state-machine.ts`).
- **Endpoints:**
  - `POST /api/v1/rfqs/:id/quotations` — Rate-limited (`15/min`). Requires an active seller/supplier account (`owner`, `manager`, or `responder`). Prevents RFQ owner from quoting their own RFQ.
  - `GET /api/v1/rfqs/:id/quotations` — RFQ owner or admin only; supports `sortBy` (`totalAmount | estimatedDeliveryDays | createdAt`) for side-by-side comparison.
  - `GET /api/v1/quotations/:id` — RFQ owner, submitting supplier account member, or admin only.
  - `PATCH /api/v1/quotations/:id/status` — State machine transitions: RFQ owner can `SHORTLISTED`, `ACCEPTED`, or `REJECTED`; supplier can `WITHDRAWN`. Accepting a quotation does **not** create a paid order in V1.
