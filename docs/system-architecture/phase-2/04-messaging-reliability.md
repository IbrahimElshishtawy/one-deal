# 04 — Messaging Reliability (Workstream D)

## D1. Database-Enforced Message Idempotency (`MSG-001`)

- **Files:** `backend/prisma/schema.prisma`, Migration #16, `backend/src/modules/chat/dto/send-message.dto.ts`, `chat.controller.ts`, `chat.service.ts`
- **Mechanism:**
  - Accepts `dto.clientMessageId` (body) or `Idempotency-Key` HTTP header (max 100 chars).
  - Validates conversation existence and participant ownership **first** (prevents unauthorized probing).
  - Fast-path lookup + DB unique index `uq_messages_sender_conversation_client_id` on `(conversation_id, sender_user_id, client_message_id)` + `P2002` concurrent race handler return the original message without duplicating DB rows, outbox events, or SSE broadcasts.
  - Legacy messages without `clientMessageId` store `NULL` (PostgreSQL treats `NULL`s as distinct).

## D2. Transactional Outbox Push Dispatch (`MSG-002`)

- **Mechanism:** Inside the same `$transaction` that persists `Message` and updates `Conversation.lastMessageAt`, `ChatService.sendMessage()` writes a `PUSH_NOTIFICATION` `OutboxEvent` targeting the recipient user.
- **Benefits:**
  - Message persistence is 100% independent of FCM availability and never blocks on external HTTP calls.
  - Existing `OutboxPublisherProcessor` (every 10s) relays `PUSH_NOTIFICATION` events with atomic claims and exponential backoff retries.
  - Real-time Redis Pub/Sub SSE (`@Sse('stream')`) is preserved unchanged.

## D3. Flutter Chat Client Alignment

- **Files:** `deal one app/lib/features/conversations/domain/repositories/conversations_repository.dart`, `conversations_repository_impl.dart`
- **Behavior:** `sendMessage()` accepts optional `clientMessageId` (auto-generating one if omitted) and sends it in both the JSON payload and `Idempotency-Key` header.
