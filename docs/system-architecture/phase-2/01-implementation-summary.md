# 01 — Phase 2 Implementation Summary

## Finding Resolution Matrix

| Finding ID | Workstream | Status | Summary of Fix |
| :--- | :---: | :--- | :--- |
| `SEC-001` | A | **FIXED** | Added server-side R2 SigV4 ranged `GET` (`Range: bytes=0-15`) magic-byte validation in `PrivateDocumentStorageService.verifyUploadedObject()`. |
| `SEC-002` | A | **PARTIALLY FIXED (DOCUMENTED)** | Presigned PUT binds `content-type;host`; exact `content-length` and real file signature are strictly enforced server-side via `HEAD` + ranged `GET` before document acceptance. Limitation documented honestly. |
| `INF-001` | B | **FIXED (APP) / CONFIG PENDING (PROD)** | Added `RedisService.getTopologyStatus()`, explicit startup topology logging (`dual_isolated` vs `single_shared` warning without credentials), and `redis_topology` / `redis_separated` in `/health/ready`. Production still requires provisioning 2nd Redis instance. |
| `OPS-001` | C | **FIXED** | Added `MediaService.deletePublicObject()` (SigV4 `DELETE`) and updated `MediaCleanupProcessor` to delete R2 objects first, treat 404 as idempotent, protect published listings, validate key format, and keep DB rows on R2 failure for retry. |
| `MSG-001` | D1 | **FIXED** | Added additive `Message.clientMessageId` + unique index `uq_messages_sender_conversation_client_id`, `SendMessageDto.clientMessageId` + `Idempotency-Key` header support, participant auth before idempotency check, and `P2002` race handling. |
| `MSG-002` | D2 | **FIXED (CHAT)** | `ChatService.sendMessage()` atomically writes a `PUSH_NOTIFICATION` `OutboxEvent` inside `$transaction` for the recipient so `OutboxPublisherProcessor` delivers FCM asynchronously with exponential retries while preserving Redis Pub/Sub SSE. |
| `MOB-001` | E | **FIXED** | Added `VerificationStatus.withdrawn`, `SellerApplicationType.renewal`, `SellerDocumentStatus.purged`, `ApiEndpoints.sellerApplicationMeWithdraw` & `sellerApplicationMeRenew`, repository/datasource/notifier methods, and Withdraw/Renew actions in `VerificationTrackingPage`. |
| `DB-001` | F1 | **FIXED** | Added atomic `tx.payment.updateMany({ where: { id, status: PENDING } })` guard in `PaymentsService.handlePaymobWebhook()` (while keeping `PaymentsModule` disabled by default). |
| `DB-002` | F2 | **FIXED** | Extended `uq_seller_applications_active_user_type` in Migration #16 to include `'SUSPENDED'`, preventing duplicate live applications while preserving single-row reinstatement (`SUSPENDED -> APPROVED`). |
| `SEC-003` | G | **FIXED** | Expanded `SENSITIVE_KEY_PATTERN` and string value scrubbers in `request-context.ts` to recursively redact KYC IDs, presigned URLs (`X-Amz-Signature=`), and encrypted ciphertexts (`enc:v1:...`). |
| `OBS-001` | G | **OPEN (DECISION)** | Sentry SDK not installed/initialized per Phase 2 rule ("do not add Sentry integration unless separately approved"). |
| `RBAC-001`, `RBAC-002`, `OPS-002`, `SEC-004`, `DB-003` | — | **OPEN / BUSINESS DECISION** | Tracked in [07-business-decisions-pending.md](./07-business-decisions-pending.md). |
