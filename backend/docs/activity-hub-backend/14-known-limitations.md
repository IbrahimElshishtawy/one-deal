# 14 — Known Limitations & V1 Scope Boundaries

1. **No Online Product Checkout or Payments (V1 Policy):**
   - `CartModule` operates strictly as a non-transactional saved product basket (`commerceMode: 'V1_SAVED_BASKET'`, `checkoutSupported: false`).
   - Accepting an RFQ quotation marks the RFQ `ACCEPTED` without creating a paid order or triggering payment gateways.
   - `PaymentsModule` remains strictly for V2 listing promotion packages (`ENABLE_V2_PAYMENTS`).
2. **Favorite Unavailability Notifications:**
   - Currently, `FavoritesService` safely handles unavailable/deleted listings in `getMyFavorites` and `getFavoriteStatus` (`isAvailable` / `isListingAvailable` flags). Automatic push notification emission when a listing transitions to `sold`/`archived`/`deleted` is not yet hooked into `ListingsService` status mutations.
3. **Time Zone Assumption for Bookings:**
   - `BookingsService` interprets `scheduledDate` + `scheduledTime` in `Africa/Cairo` (`+02:00`) when constructing UTC `scheduledAt`.
4. **Pre-existing Redis Unit Test Timeout:**
   - Under heavy parallel Jest execution, `src/core/redis/redis.service.spec.ts` can hit its 5000ms `beforeEach` hook timeout; running with `--runInBand` avoids CPU contention.
