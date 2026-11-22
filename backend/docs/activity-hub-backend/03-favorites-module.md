# 03 — Favorites Module

**Source:** `src/modules/favorites/`

## Implemented Capabilities
- `GET /api/v1/favorites` (and alias `GET /api/v1/listings/favorites`): Paginated favorites (`page`, `limit`), category filtering (`categoryId`, `categorySlug` matching both category and parent root category), keyword search (`search` with Arabic normalization), and optional `includeUnavailable` flag.
- `POST /api/v1/favorites` (body `{ listingId }`) & `POST /api/v1/favorites/:listingId`: Idempotent favorite creation. Validates listing exists, `deletedAt === null`, `publicationStatus === 'published'`, and `moderationStatus === 'approved'`.
- `GET /api/v1/favorites/:listingId/status`: Returns `{ listingId, isFavorite, favoriteId, savedAt, isListingAvailable }`.
- `DELETE /api/v1/favorites/:listingId`: Idempotent removal.
- `POST /api/v1/listings/:listingId/favorite`: Preserved mobile toggle alias.
