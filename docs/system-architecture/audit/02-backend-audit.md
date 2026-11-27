# 02 — Backend Functional & Reliability Audit

## A. Seller Verification (`backend/src/modules/accounts/`)

| Area | Status | Evidence (`file:line`) | Audit Result |
| :--- | :--- | :--- | :--- |
| State Transitions & Auth | VERIFIED | `seller-application-state-machine.ts:28-65`, `seller-application.controller.ts`, `admin-seller-applications.controller.ts` | All 10 states (`NOT_REQUESTED`..`EXPIRED`, including `WITHDRAWN`) enforced by `assertValidSellerStatusTransition()`. |
| Rejection Reason Persistence | VERIFIED | `seller-application.service.ts:2871,3453,4352` | Persisted on `SellerApplication.rejectionReason` and `SellerApplicationDocument.rejectionReason`; cleared upon resubmission/approval. |
| Four-Eyes Enforcement & Default | VERIFIED | `env.config.ts:312` (`default: false`), `seller-application.service.ts:3080-3120` | Defaults to `false`. When `true`, blocks `firstReviewedByStaffId === null` (`403 FOUR_EYES_REVIEW_REQUIRED`) AND same-admin approval (`403 FOUR_EYES_APPROVAL_REQUIRED`), plus atomic `WHERE` clause in `$transaction`. |
| Account Sync (Expiry & Suspension) | VERIFIED | `seller-application.service.ts:3154-3237,3655-3672,3798-3805` | Sets `Account.verificationExpiresAt` on both update & create, `verificationSuspendedAt`/`Reason` on suspend, `VerificationStatus.EXPIRED` + `VerificationTier.NONE` on expire. |
| Renewal & Business Upgrade | VERIFIED | `seller-application.service.ts:1720-2045,4540-4680` | Both preserve existing `Account` ID, listings, branches, members, and conversations; neither restores/upgrades badge before admin approval. |
| Requirements Snapshot | VERIFIED | `seller-application.service.ts:1014-1045,2004-2035`, `seller-verification-requirements.service.ts:597-670` | Locked on `submitApplication` and `submitBusinessUpgrade`; `evaluateCompleteness()` honors saved snapshot. |
| Retention Purge | VERIFIED | `seller-verification-maintenance.processor.ts:180-290` | `0` returns `null` (no deletion). Excludes `PENDING`/`UNDER_REVIEW`/`NEEDS_CORRECTION`. Calls R2 `DELETE` before DB `PURGED` update. |
| Identifier Masking | VERIFIED | `seller-application.service.ts:2354-2366,2454-2465,4283-4288` | `nationalIdNumber`, `taxIdNumber`, `commercialRegisterNumber`, `authorizedRepresentativeId` masked in user, admin list, and admin detail responses. |

---

## B. Messaging & Notifications (`chat/` & `notifications/`)

### Finding `MSG-001` — HIGH — Chat `sendMessage` Lacks Idempotency & Push/Outbox Dispatch
- **Status:** VERIFIED
- **Evidence:** `backend/src/modules/chat/chat.service.ts:182-240`
- **Actual Behavior:** `sendMessage()` inserts a `Message` row with no `clientMessageId` / `Idempotency-Key` deduplication. It publishes an SSE event via Redis Pub/Sub (`publishChatEvent`, lines 233-237) to `chat:user:<uid>` (served by `@Sse('stream')` at `chat.controller.ts:38`), **but does NOT call `NotificationsService.sendPushNotification()` or write an `OutboxEvent`**. Offline users receive no push notification for new chat messages.
- **Expected Behavior:** Support optional client-supplied idempotency key (`unique(conversationId, clientMessageId)`) and enqueue/dispatch push notifications for offline recipients via outbox or notification queue.
- **Business Decision Required:** No (engineering reliability gap).

### Finding `MSG-002` — MEDIUM — FCM Push Delivery Runs Inline Without Retry Outbox
- **Status:** VERIFIED
- **Evidence:** `backend/src/modules/notifications/notifications.service.ts:88-159`
- **Actual Behavior:** `sendPushNotification()` persists the in-app `Notification` row, then fires `fetch(fcmEndpoint)` inline with a 5s `AbortSignal.timeout(5000)` and `Promise.allSettled`. Transient FCM/network failures drop the push permanently (in-app row still exists).
- **Expected Behavior:** Enqueue push dispatches to BullMQ / `OutboxEvent` with exponential backoff retries and prune stale/unregistered FCM tokens on `404`/`UNREGISTERED` responses.
- **Business Decision Required:** No.

### Read Status Synchronization (`chat.service.ts:140-151`)
- **Status:** VERIFIED (INFO)
- **Actual Behavior:** `getMessages()` marks unread messages from the other party as `status = 'read'` and `readAt = now` via `updateMany`. However, it does not emit a read-receipt SSE event back to the sender.

---

## C. Public Media Cleanup (`workers/media-cleanup.processor.ts`)

### Finding `OPS-001` — HIGH — `MediaCleanupProcessor` Deletes DB Records Without Deleting R2 Objects
- **Status:** VERIFIED
- **Evidence:** `backend/src/workers/media-cleanup.processor.ts:17-35`
- **Actual Behavior:** `processAbandonedMedia()` executes `this.prisma.listingMedia.deleteMany({ where: { processingStatus: 'pending', createdAt: { lte: twentyFourHoursAgo } } })` directly without calling Cloudflare R2 `DELETE` on the corresponding public storage keys.
- **Expected Behavior:** Query expired pending `ListingMedia` rows, delete corresponding R2 objects first (idempotently), and only delete DB records after R2 deletion succeeds (or returns 404).
- **Production Impact:** Unbounded orphaned public media accumulation in R2 storage.
- **Business Decision Required:** No.

### Finding `OPS-002` — MEDIUM — Unconfirmed Private KYC Uploads Are Not Tracked as `PENDING_UPLOAD`
- **Status:** VERIFIED
- **Evidence:** `backend/src/modules/accounts/services/seller-application.service.ts:549-595`, `backend/src/workers/seller-verification-maintenance.processor.ts:256-285`
- **Actual Behavior:** `requestDocumentUploadUrl()` generates a presigned PUT URL without creating a `PENDING_UPLOAD` row in `seller_application_documents`. Thus, if a client uploads to R2 and never calls `POST /me/documents`, the cleanup worker's `PENDING_UPLOAD` sweep cannot discover that R2 object.
- **Recommended Resolution:** Either persist a `PENDING_UPLOAD` row when issuing the upload URL OR enforce a Cloudflare R2 lifecycle rule on the private bucket.
- **Business Decision Required:** No.
