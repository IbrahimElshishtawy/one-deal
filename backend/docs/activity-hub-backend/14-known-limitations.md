# 14 — Known Limitations & V1 Scope Boundaries

1. **No Online Product Checkout or Payments (V1 Policy):**
   - `CartModule` operates strictly as a non-transactional saved product basket (`commerceMode: 'V1_SAVED_BASKET'`, `checkoutSupported: false`).
   - Accepting an RFQ quotation marks the RFQ `ACCEPTED` without creating a paid order or triggering payment gateways.
   - `PaymentsModule` remains strictly for V2 listing promotion packages (`ENABLE_V2_PAYMENTS`).
2. **Favorite Unavailability Notifications:**
   - Currently, `FavoritesService` safely handles unavailable/deleted listings in `getMyFavorites` and `getFavoriteStatus` (`isAvailable` / `isListingAvailable` flags). Automatic push notification emission when a listing transitions to `sold`/`archived`/`deleted` is not yet hooked into `ListingsService` status mutations.
3. **Time Zone Handling for Bookings (Resolved):**
   - `BookingsService` resolves `Africa/Cairo` dynamically using `Intl.DateTimeFormat` (`+02:00` standard / `+03:00` summer DST) when constructing UTC `scheduledAt`.
4. **Notification Preferences (Not Yet Implemented):**
   - Users can read/mark notifications and register FCM device tokens, but per-category notification opt-in/opt-out preferences are deferred to a future iteration.
5. **Pre-existing Redis Unit Test Timeout:**
   - Under heavy parallel Jest execution, `src/core/redis/redis.service.spec.ts` can hit its 5000ms `beforeEach` hook timeout; running with `--runInBand` avoids CPU contention.
