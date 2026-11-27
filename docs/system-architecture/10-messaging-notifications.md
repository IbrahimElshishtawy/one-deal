# 10 — Messaging & Notifications Architecture

## Overview

As verified directly in `backend/src/modules/chat/` and `backend/src/modules/notifications/`:
- **Messaging is REST-based** (`/api/v1/conversations/*`). There is **NO WebSocket gateway** in the current codebase; the Flutter app loads and refreshes messages over HTTPS REST and receives new-message alerts via **Firebase Cloud Messaging (FCM)** push notifications.
- **Notifications** combine persistent PostgreSQL `Notification` records (in-app inbox with read/read-all endpoints) and `firebase-admin` FCM push delivery to registered `UserDevice` tokens.

---

## A. Conversation Creation, Message Send & Push Notification Flow

```mermaid
sequenceDiagram
    actor Buyer
    participant AppB as Buyer Flutter App
    participant ChatAPI as ChatController\n(/api/v1/conversations)
    participant DB as PostgreSQL
    participant NotifSvc as NotificationsService
    participant FCM as Firebase Cloud Messaging
    participant AppS as Seller Flutter App

    Buyer->>AppB: Tap "Chat with Seller" on Listing
    AppB->>ChatAPI: POST /api/v1/conversations { listingId }
    ChatAPI->>DB: Find or create Conversation (buyerUserId + sellerAccountId + listingId)
    ChatAPI-->>AppB: 201/200 { conversation }

    Buyer->>AppB: Send message text
    AppB->>ChatAPI: POST /api/v1/conversations/:id/messages { body }
    ChatAPI->>DB: Verify participant membership & conversation status = OPEN
    ChatAPI->>DB: Insert Message (status='sent') + update Conversation.lastMessageAt
    ChatAPI->>NotifSvc: sendPushNotification(recipientUserId, title, body, payload)
    NotifSvc->>DB: Insert in-app Notification (isRead=false)
    NotifSvc->>DB: Query recipient UserDevice fcmTokens
    NotifSvc->>FCM: Dispatch push notification (non-fatal on provider error)
    FCM-->>AppS: Push Alert ("New Message")
    ChatAPI-->>AppB: 201 Created { message }

    AppS->>ChatAPI: GET /api/v1/conversations/:id/messages
    ChatAPI->>DB: Fetch paginated messages & update read state
    ChatAPI-->>AppS: 200 OK { messages }
```

---

## B. In-App Notification Inbox, Device Tokens & Admin Oversight

```mermaid
flowchart LR
    subgraph ClientActions["Flutter Client Actions"]
        RegToken["POST /api/v1/notifications/device-token\n(Register Android/iOS FCM Token)"]
        ListNotif["GET /api/v1/notifications\n(Paginated Inbox)"]
        MarkRead["PATCH /api/v1/notifications/:id/read\nPATCH /api/v1/notifications/read-all"]
    end

    subgraph EventProducers["Backend Notification Producers"]
        Chat["ChatService (New Message)"]
        Verif["SellerApplicationService\n(Submit/Review/Approve/Reject/Suspend/Expire/Withdraw)"]
        Workers["SellerVerificationMaintenanceProcessor\n(Renewal Reminder / Expiry)"]
        AdminCamp["AdminNotificationsController\n(NotificationCampaign Dispatch)"]
    end

    subgraph AdminOversight["Admin Messaging Oversight (Audited)"]
        AdminChat["AdminMessagingController\n(/api/v1/admin/chat/*)\nRequires chat.oversight.read / messaging.complaints.read"]
    end

    ClientActions --> NotifSvc["NotificationsService"]
    EventProducers --> NotifSvc
    NotifSvc --> PG[("PostgreSQL\nNotification + UserDevice")]
    NotifSvc --> FCM["Firebase Cloud Messaging"]
    AdminOversight --> PG
    AdminOversight --> Audit[("AuditLog\n(Mandatory Access Audit)")]
```

## Planned / Future (Not Implemented Yet)
- WebSocket / SSE real-time messaging gateway for live typing indicators and instant read receipts without REST polling.
