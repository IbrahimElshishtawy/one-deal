# 08 — Notifications Integration

## Architecture
Activity Hub domains use the existing **Transactional Outbox** (`OutboxEvent` model + `OutboxPublisherProcessor` + `NotificationProcessor` + `NotificationsService`) rather than synchronous push calls inside HTTP handlers.

### Why Transactional Outbox?
- Notification delivery failures (e.g., FCM network timeout) never roll back or fail booking/RFQ business transactions.
- `OutboxPublisherProcessor` claims `PENDING` rows atomically (`updateMany` with `lockedAt`), recovers stale `PROCESSING` rows after 5 minutes, and retries failed deliveries with exponential backoff up to `maxRetries` (default `5`) before marking `FAILED`.
- `NotificationProcessor` propagates `{ success: false }` delivery failures back to the outbox processor so failed pushes are retried.
- `NotificationsService` caches Google OAuth2 access tokens (~50 min TTL) and enforces 5-second `AbortSignal.timeout(5000)` timeouts on OAuth2 and FCM HTTP v1 calls.

## Events Enqueued
- `BOOKING_SUBMITTED` -> Notifies `providerAccount.ownerUserId`
- `BOOKING_CONFIRMED` -> Notifies `booking.userId`
- `BOOKING_REJECTED` -> Notifies `booking.userId`
- `BOOKING_COMPLETED` -> Notifies `booking.userId`
- `BOOKING_CANCELLED` -> Notifies the counterparty (provider if cancelled by requester, requester if cancelled by provider)
- `RFQ_SUBMITTED` -> Notifies `rfq.userId`
- `RFQ_CANCELLED` -> Notifies each supplier account owner with an active (`SUBMITTED`/`SHORTLISTED`) quotation
- `QUOTATION_RECEIVED` -> Notifies `rfq.userId`
- `QUOTATION_STATUS_CHANGED` -> Notifies `supplierAccount.ownerUserId` (or `rfq.userId` when withdrawn by supplier)
