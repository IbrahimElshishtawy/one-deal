# 10 — Performance & Reliability

## Query & Index Optimization
- **Composite Indexes:**
  - `bookings(user_id, status, scheduled_at DESC)` for requester Activity Hub & filtered pagination.
  - `bookings(provider_account_id, status, scheduled_at)` for provider schedule and slot conflict checks.
  - `rfq_requests(user_id, status, created_at DESC)` and `rfq_requests(status, created_at DESC)`.
  - `quotations(rfq_id, status)` and `quotations(supplier_account_id, created_at DESC)`.
  - `cart_items(user_id, updated_at DESC)`.
  - `favorites(listing_id)` added alongside `favorites(user_id, created_at DESC)`.
- **Parallel Execution:** Summary counts and requested sections in `ActivityHubService.getActivityHub()` run concurrently via `Promise.all()`, and unrequested sections are skipped entirely when `?include=` is provided.
- **No N+1 Queries:** All list queries use Prisma `include` / `select` projections and `_count` aggregations.
- **Transaction Safety:** Booking creation and status confirmation use `Prisma.TransactionIsolationLevel.Serializable` to prevent concurrent double-booking race conditions.
- **Cache Safety:** Mutable per-user private activity data (`ActivityHub`, `Bookings`, `RFQs`, `Cart`, `Favorites`) is not cached in shared Redis keys to avoid stale statuses and cross-user cache leaks.
