# 03 — Favorites Integration

- **Controller:** `backend/src/modules/favorites/favorites.controller.ts`
- **Service:** `backend/src/modules/favorites/favorites.service.ts`
- **Endpoints:**
  - `GET /api/v1/favorites` (paginated, supports `categoryId`, `categorySlug`, `search`, `includeUnavailable`)
  - `POST /api/v1/favorites` and `POST /api/v1/favorites/:listingId` (idempotent add, validates published/non-deleted listing)
  - `GET /api/v1/favorites/:listingId/status`
  - `DELETE /api/v1/favorites/:listingId`
  - Mobile aliases: `GET /api/v1/listings/favorites`, `POST /api/v1/listings/:listingId/favorite`
- **Security:** `JwtAuthGuard` enforced on all routes; user ownership scoped by `userId` from JWT; duplicate favorites prevented by unique `(userId, listingId)` constraint.
