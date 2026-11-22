# 09 — Security & Permissions

## Authentication & Authorization
- All Favorites, Bookings, RFQ, Cart, and Activity Hub endpoints require `JwtAuthGuard` (`Authorization: Bearer <JWT>`).
- `userId` is always extracted from `@CurrentUser()` (JWT payload), never from request bodies or query strings.

## Mass Assignment & Input Validation
- Global `ValidationPipe` (`whitelist: true`, `forbidNonWhitelisted: true`, `transform: true`) rejects any unexpected properties such as client-supplied `userId`, `providerAccountId` (when `listingId` is present), or `totalAmount`.
- All UUID path parameters use `ParseUUIDPipe`.

## IDOR & Resource Ownership
- **Favorites:** Scoped to `userId` via `uq_user_favorite`.
- **Bookings:** `GET /bookings/:id` and `PATCH /bookings/:id/cancel` verify `booking.userId === userId` OR authorized `providerAccount` membership (`owner`, `manager`, `responder`) OR `MODERATOR`/`SUPER_ADMIN`. `PATCH /bookings/:id/status` is restricted strictly to authorized provider members or `MODERATOR`/`SUPER_ADMIN`.
- **RFQs & Quotations:** Only the RFQ owner (or admin/moderator) can view/compare all quotations (`GET /rfqs/:id/quotations`), cancel the RFQ, or shortlist/accept/reject quotations. Only the submitting supplier account member can view or withdraw their own quotation.
- **Cart:** `PATCH /cart/items/:id` and `DELETE /cart/items/:id` verify `item.userId === userId`.

## Rate Limiting & Server-Side Pricing
- `POST /bookings` (`@RateLimit(15, 60)`), `POST /rfqs` (`@RateLimit(10, 60)`), and `POST /rfqs/:id/quotations` (`@RateLimit(15, 60)`) are protected by `RateLimitGuard`.
- Quotation totals and cart price snapshots are computed strictly on the server.
