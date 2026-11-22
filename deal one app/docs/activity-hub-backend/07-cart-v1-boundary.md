# 07 — Cart V1 Business Boundary

- **Decision:** Deal One V1 is a free-listing, direct-communication marketplace.
- **Flutter Side:** `LocalCartRepository` persists items locally in `PreferencesService`.
- **Backend Side:** `CartController` (`/api/v1/cart`) provides a V1 non-transactional saved product basket (`CartItem`) with authoritative server-side price snapshots (`unitPriceSnapshot`, `liveUnitPrice`, `priceChanged`, `lineEstimate`).
- **Boundary Enforcement:** No `/checkout`, no `/orders`, and no V2 payment activation (`ENABLE_V2_PAYMENTS` remains disabled).
