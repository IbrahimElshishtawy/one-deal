# 05 — RFQ (Request for Quotation) Module

**Source:** `src/modules/rfq/`

## Lifecycle & State Machines (`rfq-state-machine.ts`)
- **RFQ Statuses:** `DRAFT` -> `SUBMITTED` | `CANCELLED`; `SUBMITTED` / `UNDER_REVIEW` -> `QUOTATIONS_RECEIVED` | `CANCELLED` | `EXPIRED`; `QUOTATIONS_RECEIVED` -> `ACCEPTED` | `REJECTED` | `CANCELLED` | `EXPIRED`.
- **Quotation Statuses:** `SUBMITTED` / `SHORTLISTED` -> `ACCEPTED` | `REJECTED` | `WITHDRAWN` | `EXPIRED`.

## Business & Security Rules
- **Draft Lifecycle:** Draft RFQs (`isDraft: true`) can be edited via `PATCH /api/v1/rfqs/:id` and submitted via `PATCH /api/v1/rfqs/:id/submit`.
- **Expiration:** `rfq.expiresAt` and `quotation.validUntil` are enforced on quotation submission/acceptance/shortlisting, and `RfqExpiryProcessor` periodically transitions past-due open RFQs and quotations to `EXPIRED`.
- **Authoritative Pricing:** Quotation `subtotalAmount` and `totalAmount` are calculated server-side from `items` (`quantity * unitPrice`) + `deliveryFee` with `DECIMAL(14,2)` overflow validation.
- **Supplier Authorization:** Submitting or withdrawing a quotation requires an active `Account` owned or managed (`owner`, `manager`, `responder`) by the authenticated user. Suppliers cannot quote on their own RFQs, and `uq_rfq_supplier_quotation` prevents duplicate quotations per supplier account.
- **Privacy & Concurrency:** `GET /api/v1/rfqs?scope=open_for_suppliers` rejects non-open `status` filters (e.g. `DRAFT`) with `400`. `updateQuotationStatus` and `cancelRfq` run inside `Serializable` transactions backed by `uq_quotations_rfq_single_accepted`, persist `statusReason`, and notify affected suppliers on cancellation.
- **Quotation Comparison:** `GET /api/v1/rfqs/:id/quotations?sortBy=totalAmount|estimatedDeliveryDays|createdAt&page=1&limit=20` is paginated and restricted to the RFQ owner or admin/moderator staff.
- **V1 Commerce Boundary:** Accepting a quotation (`PATCH /api/v1/quotations/:id/status` with `ACCEPTED`) updates `rfq.status = 'ACCEPTED'` and `rfq.acceptedQuotationId`, and does **not** create a fake paid order or payment.
