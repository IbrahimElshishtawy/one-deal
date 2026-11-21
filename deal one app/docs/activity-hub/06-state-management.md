# 06 — State Management

All state is managed via Riverpod (`flutter_riverpod`) without full-screen rebuilds:

- **`activityHubControllerProvider` (`ActivityHubController`):** Holds `selectedTab` (`ActivityHubTab`) and `searchQuery` (`String`).
- **`activityHubSummaryProvider`:** Derived `Provider<ActivityHubSummaryCounts>` aggregating cart quantity, bookings count, RFQ count, and favorites count.
- **`cartProvider` (`CartNotifier`):** Manages `CartState` (`AsyncValue<List<CartItemEntity>>`, `isMutating`, `isRefreshing`, `mutationError`) with optimistic quantity updates and automatic rollback on validation/storage error.
- **`cartSummaryProvider`:** Derived `Provider<CartSummary>` computing `itemCount`, `totalQuantity`, `subtotal`, and `total`.
- **`bookingsProvider` (`BookingsNotifier`):** Manages `BookingsState` (`AsyncValue<List<BookingEntity>>`, `selectedCategory`, `isBackendSupported`, `isMutating`, `isRefreshing`, `mutationError`).
- **`rfqProvider` (`RfqNotifier`):** Manages `RfqState` (`AsyncValue<List<RfqRequestEntity>>`, `isBackendSupported`, `isMutating`, `isRefreshing`, `mutationError`).
- **`favoritesProvider` & `filteredFavoritesProvider`:** Reuses existing server-synced `FavoritesNotifier` and applies 6-sector category filtering (`favoritesFilterCategoryProvider`) and search query filtering.
