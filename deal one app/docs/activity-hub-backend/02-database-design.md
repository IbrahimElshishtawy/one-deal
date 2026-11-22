# 02 — Database Design & Migrations

## 1. Prisma Schema (`backend/prisma/schema.prisma`)
Migration `20261121213256_add_activity_hub_domains` added the following models and enums without destructive changes:
- **Bookings:** `Booking` (`bookingReference` unique, `userId`, `providerAccountId`, `listingId`, `categoryId`, `bookingType`, `scheduledDate`, `scheduledTime`, `scheduledAt`, `location`, `notes`, `status`, `cancellationReason`, `cancelledByUserId`, `confirmedAt`, `completedAt`). Indexed on `(userId, status)`, `(providerAccountId, scheduledAt)`, and `(listingId)`.
- **RFQ & Quotations:** `RfqRequest`, `RfqItem`, `Quotation`, `QuotationItem`. Unique constraint `uq_rfq_supplier_quotation` on `(rfqId, supplierAccountId)` prevents duplicate supplier quotations per RFQ.
- **Cart (V1 Saved Basket):** `CartItem` with unique constraint on `(userId, listingId, variantKey)` and `unitPriceSnapshot` / `currency`.

## 2. Migration Safety
- Verified via `backend/src/core/database/migrate-deploy.spec.ts` (all 10 migrations discovered and validated).
- Production database was never reset.
