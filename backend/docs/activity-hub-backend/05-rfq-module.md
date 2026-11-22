# 05 — RFQ (Request for Quotation) Module

**Source:** `src/modules/rfq/`

## Lifecycle & State Machines (`rfq-state-machine.ts`)
- **RFQ Statuses:** `DRAFT` -> `SUBMITTED` | `CANCELLED`; `SUBMITTED` / `UNDER_REVIEW` -> `QUOTATIONS_RECEIVED` | `CANCELLED` | `EXPIRED`; `QUOTATIONS_RECEIVED` -> `ACCEPTED` | `REJECTED` | `CANCELLED` | `EXPIRED`.
- **Quotation Statuses:** `SUBMITTED` / `SHORTLISTED` -> `ACCEPTED` | `REJECTED` | `WITHDRAWN` | `EXPIRED`.

## Business & Security Rules
- **Authoritative Pricing:** Quotation `subtotalAmount` and `totalAmount` are calculated server-side from `items` (`quantity * unitPrice`) + `deliveryFee`.
- **Supplier Authorization:** Submitting a quotation requires an active `Account` owned or managed (`owner`, `manager`, `responder`) by the authenticated user. Suppliers cannot quote on their own RFQs, and `uq_rfq_supplier_quotation` prevents duplicate quotations per supplier account.
- **Quotation Comparison:** `GET /api/v1/rfqs/:id/quotations?sortBy=totalAmount|estimatedDeliveryDays|createdAt` is restricted to the RFQ owner (or admin/moderator).
- **V1 Commerce Boundary:** Accepting a quotation (`PATCH /api/v1/quotations/:id/status` with `ACCEPTED`) updates `rfq.status = 'ACCEPTED'` and `rfq.acceptedQuotationId`, and does **not** create a fake paid order or payment.
