# 08 — Unified Activity Hub Aggregation API

- **Endpoint:** `GET /api/v1/activity-hub`
- **Controller/Service:** `backend/src/modules/activity-hub/` (`ActivityHubController`, `ActivityHubService`).
- **Query Params:** `include` (`cart,bookings,rfqs,favorites`), `page`, `limit`, `categoryId`, `categorySlug`.
- **Behavior:** Aggregates summary counters (`cartItemsCount`, `activeBookingsCount`, `activeRfqCount`, `favoritesCount`) and requested paginated sections in parallel via `Promise.all` without N+1 queries or duplicated domain logic.
