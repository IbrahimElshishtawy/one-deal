# 06 — Cart & Future Commerce Boundary

**Source:** `src/modules/cart/`

## V1 Boundary
Deal One V1 is a free-listing marketplace and **does not** support online product checkout, order processing, or online product payments.
- Existing `PaymentsModule` (`src/modules/payments/`) is strictly for V2 listing promotion packages and is gated behind `ENABLE_V2_PAYMENTS === 'true'`.
- `CartModule` implements a **non-transactional V1 Saved Product Basket** (`cart_items` table).
- `GET /api/v1/cart` explicitly returns `commerceMode: 'V1_SAVED_BASKET'` and `checkoutSupported: false`.

## Future Commerce Readiness (V2+)
`CartItem` already includes:
- `variantKey` and `variantAttributes` (`JSONB`) for future product variants.
- `quantity` management (`1..999`).
- `unitPriceSnapshot` (populated server-side from `listing.price`, never client-supplied) and live price drift detection (`liveUnitPrice`, `priceChanged`).
- `isAvailable` live listing status check.

No fake checkout, fake order, or fake payment endpoints are exposed.
