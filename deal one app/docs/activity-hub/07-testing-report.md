# 07 — Testing Report

## 1. Static Analysis
- Command: `flutter analyze --no-pub`
- Result: **Passed (`No issues found!`)**

## 2. Activity Hub Unit & Widget Tests
- Command: `flutter test --no-pub test/features/activity_hub/`
- Result: **13 passed, 0 failed (`All tests passed!`)**

### Covered Unit Tests (`test/features/activity_hub/activity_hub_unit_test.dart`)
- `CartSummary.fromItems` subtotal, total, and total quantity calculations.
- `LocalCartRepository` persistence, variant deduplication (`listingId + selectedSize + selectedColor`), removal, and `ArgumentError` on quantity `< 1`.
- `CartNotifier.updateQuantity` validation & rollback with `mutationError`.
- `BookingStatus.fromBackend` & `BookingDto.fromJson` mapping.
- `RfqStatus.fromBackend` & `RfqRequestDto.fromJson` nested quotation mapping.
- `MarketplaceSectorCategory.fromCategorySlug` & `sectionRoute` mapping across all 6 marketplace sectors.
- `filteredFavoritesProvider` sector filtering & search query filtering.

### Covered Widget Tests (`test/features/activity_hub/activity_hub_widget_test.dart`)
- `ActivityHubPage` tab switching (Cart -> Bookings -> RFQ -> Favorites) in Arabic RTL + Dark Mode.
- `CartTabView` item rendering, quantity increment, remove confirmation dialog, and empty state.
- `BookingCard` status badge, date/time, address, and booking reference rendering.
- `RfqRequestCard` expand/collapse quotation comparison with Accept/Reject actions.
- Responsive layout verification on `320x568` (small phone) and `1024x1366` (tablet) with zero overflow exceptions.

## 3. Baseline Pre-Existing Suite Note
- Pre-existing `test/integration/home_backend_integration_test.dart` and `test/responsive/seven_homes_golden_test.dart` were already failing in the baseline run prior to Activity Hub changes (live backend / platform golden PNG baselines).
