# 08 — Notifications Integration

## Architecture
Activity Hub domains use the existing **Transactional Outbox** (`OutboxEvent` model + `OutboxPublisherProcessor` + `NotificationProcessor` + `NotificationsService`) rather than synchronous push calls inside HTTP handlers.

### Why Transactional Outbox?
- Notification delivery failures (e.g., FCM network timeout) never roll back or fail booking/RFQ business transactions.
- `OutboxPublisherProcessor` claims `PENDING` rows atomically (`updateMany` where `status: 'PENDING'`) to prevent duplicate delivery across workers.

## Events Enqueued
- `BOOKING_SUBMITTED` -> Notifies `providerAccount.ownerUserId`
- `BOOKING_CONFIRMED` -> Notifies `booking.userId`
- `BOOKING_REJECTED` -> Notifies `booking.userId`
- `BOOKING_COMPLETED` -> Notifies `booking.userId`
- `BOOKING_CANCELLED` -> Notifies the counterparty (provider if cancelled by requester, requester if cancelled by provider)
- `RFQ_SUBMITTED` -> Notifies `rfq.userId`
- `QUOTATION_RECEIVED` -> Notifies `rfq.userId`
- `QUOTATION_STATUS_CHANGED` -> Notifies `supplierAccount.ownerUserId` (or `rfq.userId` when withdrawn by supplier)
