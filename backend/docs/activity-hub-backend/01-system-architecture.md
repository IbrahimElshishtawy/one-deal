# 01 — System Architecture: Unified Activity & Commerce Hub

## Architectural Pattern
The Deal One backend is a **Modular Monolith** built on NestJS + Fastify + Prisma + PostgreSQL + Redis.

The **Unified Activity Hub** (`ActivityHubModule`) is implemented as a pure **aggregation layer** over four independent domain modules:
1. `FavoritesModule` (`src/modules/favorites/`)
2. `BookingsModule` (`src/modules/bookings/`)
3. `RfqModule` (`src/modules/rfq/`)
4. `CartModule` (`src/modules/cart/` — V1 Non-Transactional Saved Basket)

### Key Design Rules
- **Domain Independence:** Each domain owns its own Prisma tables, DTOs, state machines, authorization checks, and REST endpoints.
- **No Logic Duplication:** `ActivityHubService` injects `CartService`, `BookingsService`, `RfqService`, and `FavoritesService` via NestJS DI and delegates all queries and counts to them.
- **Selective Loading:** `GET /api/v1/activity-hub?include=bookings,rfqs` only queries the requested domain sections while fetching summary counts in parallel.
- **Transactional Outbox:** Domain state transitions (booking creation/confirmation/rejection/cancellation, RFQ submission, quotation received/status change) write `OutboxEvent` rows inside the same `prisma.$transaction`, which `OutboxPublisherProcessor` relays asynchronously to `NotificationsService`.
