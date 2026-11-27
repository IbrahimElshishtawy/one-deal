# 07 — Authentication & Authorization Flows

## Overview

Deal One runs **two strictly separated authentication stacks**:
1. **Marketplace User Auth** (`/api/v1/auth/*` via `AuthModule`, `JwtAuthGuard`, `UserSession` with refresh token family rotation & reuse detection).
2. **Enterprise Admin Auth** (`/api/v1/admin/auth/*` via `AdminAuthModule`, `AdminJwtAuthGuard`, `PermissionsGuard`, `StaffSession`, HttpOnly refresh cookie, and TOTP MFA).

---

## A. Marketplace OTP Registration / Login & Password Login

```mermaid
sequenceDiagram
    actor User
    participant App as Flutter App
    participant API as AuthController
    participant OTP as OtpService
    participant GW as WhatsApp / SMS Misr
    participant Session as SessionService
    participant DB as PostgreSQL

    User->>App: Enter Egyptian phone (+20...)
    App->>API: POST /api/v1/auth/otp/send
    API->>OTP: Generate 6-digit OTP & hash
    OTP->>DB: Save Otp (expiresAt, attempts=0)
    OTP->>GW: Send via WhatsApp Cloud API (optional SMS Misr fallback)
    API-->>App: 200 OK (masked delivery status)

    User->>App: Submit 6-digit OTP code
    App->>API: POST /api/v1/auth/otp/verify
    API->>OTP: Verify hash, expiry & max attempts
    OTP->>DB: Mark Otp isConsumed=true
    API->>DB: Upsert User (default role=USER, sellerStatus=NOT_REQUESTED)
    API->>Session: Create UserSession (familyId, hashed refreshToken)
    Session->>DB: Insert UserSession
    API-->>App: 200 OK { accessToken (15m), refreshToken (30d), user }
```

*Note: Password login (`POST /api/v1/auth/password/login` / `POST /api/v1/auth/login`), password set/change (`POST /password/set`, `POST /password/change`), and forgot/reset (`POST /password/forgot`, `POST /password/reset`) are all implemented in `AuthController` using bcrypt password hashing and OTP verification.*

---

## B. Refresh Token Rotation, Reuse Detection & Logout

```mermaid
sequenceDiagram
    participant App as Flutter App (AuthInterceptor)
    participant API as AuthController
    participant Session as SessionService
    participant DB as PostgreSQL
    participant Audit as SecurityAuditService

    App->>API: POST /api/v1/auth/refresh { refreshToken }
    API->>Session: Verify JWT signature & lookup hash in UserSession

    alt Valid Active Session
        Session->>DB: Revoke old session + issue new UserSession in same familyId
        API-->>App: 200 OK { newAccessToken, newRefreshToken }
    else Revoked Token Replayed (Token Theft Detected!)
        Session->>DB: Revoke ALL sessions in familyId
        Session->>Audit: Log REFRESH_TOKEN_REUSE_DETECTED alert
        API-->>App: 401 Unauthorized
    end

    App->>API: POST /api/v1/auth/logout (or /sessions/terminate-all)
    API->>DB: Mark UserSession(s) isRevoked=true
    API-->>App: 200 OK
```

---

## C. Admin Login, TOTP MFA & RBAC Guard Pipeline

```mermaid
sequenceDiagram
    actor Staff as Admin Staff User
    participant Web as Admin Web SPA
    participant API as AdminAuthController
    participant Guards as AdminJwtAuthGuard + PermissionsGuard
    participant DB as PostgreSQL

    Staff->>Web: Submit email + password
    Web->>API: POST /api/v1/admin/auth/login
    API->>DB: Verify StaffUser password + record StaffLoginAttempt

    alt MFA Enabled on StaffUser
        API-->>Web: 200 OK { mfaRequired: true, mfaChallengeToken }
        Staff->>Web: Enter 6-digit TOTP code
        Web->>API: POST /api/v1/admin/auth/mfa/verify
    end

    API->>DB: Create StaffSession
    API-->>Web: 200 OK { accessToken (15m) } + Set-Cookie: dealone_admin_rt (HttpOnly, SameSite)

    Web->>API: POST /api/v1/admin/seller-applications/:id/approve (Bearer Admin JWT)
    API->>Guards: 1. Validate Admin JWT & active StaffSession
    Guards->>Guards: 2. Check @Permissions('verification.approve') against StaffRole.permissions
    Guards-->>API: Authorized -> Execute Controller
```

## Authorization Layers Summary

| Guard | Protects | Verified Source |
| :--- | :--- | :--- |
| `JwtAuthGuard` | Authenticated marketplace user endpoints | `backend/src/modules/auth/guards/jwt-auth.guard.ts` |
| `SellerAuthorizationGuard` | Seller-only actions (`CAN_CREATE_LISTING`, `CAN_ACCESS_SELLER_DASHBOARD`, `CAN_SUBMIT_SELLER_APPLICATION`) | `backend/src/modules/accounts/guards/seller-authorization.guard.ts` |
| `AccountTenantGuard` | Multi-tenant Account ownership & `AccountMember` roles (`owner`, `manager`, `lister`, `responder`) | `backend/src/modules/auth/guards/account-tenant.guard.ts` |
| `AdminJwtAuthGuard` + `PermissionsGuard` | All `/api/v1/admin/*` endpoints using `@Permissions(...)` / `@AnyPermissions(...)` | `backend/src/modules/admin-auth/guards/` |
| `RateLimitGuard` | Brute-force & upload abuse protection backed by Redis Cache | `backend/src/core/guards/rate-limit.guard.ts` |
