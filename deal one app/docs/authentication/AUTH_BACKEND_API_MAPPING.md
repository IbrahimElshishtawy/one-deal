# Deal One — Authentication Backend API Mapping

> **Source of Truth**: Direct inspection of `backend/src/main.ts`, `backend/src/modules/auth/*`, `backend/src/modules/users/*`, `backend/src/core/identity/phone-normalization.service.ts`, `backend/src/core/interceptors/transform.interceptor.ts`, and `backend/src/core/filters/http-exception.filter.ts`.

---

## 1. Base Configuration & Envelopes

- **Production Base URL**: `https://one-deal-cjjt-production.up.railway.app/api/v1`
- **Global Prefix**: `/api/v1` (`backend/src/main.ts` line 58)
- **Global ValidationPipe**: `whitelist: true`, `forbidNonWhitelisted: true`, `transform: true`
- **Success Response Envelope** (`TransformInterceptor`):
  ```json
  {
    "success": true,
    "data": { ... },
    "meta": { ... }
  }
  ```
- **Error Response Envelope** (`HttpExceptionFilter`):
  ```json
  {
    "success": false,
    "error": {
      "code": "BAD_REQUEST | VALIDATION_FAILED | UNAUTHORIZED | TOO_MANY_REQUESTS | INTERNAL_SERVER_ERROR",
      "message": "Human-readable error string",
      "details": [{ "issue": "..." }] | null,
      "trace_id": "uuid"
    }
  }
  ```
- **Phone Normalization Policy** (`PhoneNormalizationService`):
  - Strictly Egyptian mobile numbers: Vodafone (`010`), Etisalat (`011`), Orange (`012`), WE (`015`).
  - Canonical E.164 format: `^\+20(10|11|12|15)[0-9]{8}$` (13 characters).

---

## 2. Authentication & User Endpoints

### 2.1 `POST /auth/otp/send`
- **Auth Required**: No
- **Headers**: `Content-Type: application/json`, optional `x-trace-id`
- **Request Body (`SendOtpDto`)**:
  ```json
  { "phone": "+201012345678" }
  ```
  - Regex: `/^(?:\+20|0020|0)?(10|11|12|15)[0-9]{8}$/`
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "data": {
      "success": true,
      "message": "OTP verification code dispatched successfully via SMS.",
      "cooldownSeconds": 60
    }
  }
  ```
- **Backend Rules**:
  - Generates **6-digit** OTP (`100000`–`999999`), SHA-256 hashed with pepper, valid for **180 seconds** (`otpExpirySeconds = 180`).
  - Resend cooldown: **60 seconds** (`otp:cooldown:<phone>`).
  - Rate limits: **10 req / 15 min per IP**, **3 req / 15 min per phone**.
  - Dispatches via **SMS** (`SmsMisrAdapter` in production, `MockSmsAdapter` in local dev/test).
- **Error Codes**:
  - `400 VALIDATION_FAILED` / `BAD_REQUEST`: Invalid Egyptian mobile number.
  - `429 TOO_MANY_REQUESTS`: IP rate limit, phone rate limit, or 60s cooldown active.
  - `500 INTERNAL_SERVER_ERROR`: `'Failed to deliver SMS verification code. Please try again shortly.'` when SMS gateway fails in production.

### 2.2 `POST /auth/otp/resend`
- **Auth Required**: No
- **Request Body (`ResendOtpDto`)**: `{ "phone": "+201012345678" }`
- **Success Response (`200 OK`)**: Same as `POST /auth/otp/send`.
- **Error Codes**: Same cooldown (`429`), rate limit (`429`), validation (`400`), delivery (`500`).

### 2.3 `POST /auth/otp/verify`
- **Auth Required**: No (unified login + registration endpoint)
- **Request Body (`VerifyOtpDto`)**:
  ```json
  {
    "phone": "+201012345678",
    "code": "123456"
  }
  ```
  - `code`: Required, exactly 6 numeric digits (`/^[0-9]{6}$/`).
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "data": {
      "user": {
        "id": "uuid",
        "phone": "+201012345678",
        "fullName": "مستخدم 5678",
        "role": "USER",
        "avatarUrl": null,
        "isPhoneVerified": true
      },
      "activeAccount": {
        "id": "uuid",
        "accountType": "individual",
        "displayName": "مستخدم 5678",
        "role": "owner"
      },
      "tokens": {
        "accessToken": "jwt...",
        "refreshToken": "80-char-hex...",
        "expiresIn": 900,
        "tokenType": "Bearer",
        "sessionId": "uuid"
      }
    }
  }
  ```
- **Backend Behavior**:
  - If user does not exist: atomically creates `User` (with placeholder `fullName: "مستخدم <last4>"`), `Account` (`individual`, `approved`), and `AccountMember` (`owner`).
  - If user exists: validates `isActive && !deletedAt`, sets `isPhoneVerified = true`, returns primary owned account.
  - Max verification attempts per OTP challenge: **5** (`maxAttempts = 5`).
- **Error Codes**:
  - `400 VALIDATION_FAILED`: Code not 6 digits or invalid phone.
  - `400 BAD_REQUEST`:
    - `'Invalid or expired OTP code. Please request a new code.'`
    - `'Maximum verification attempts exceeded. Please request a new OTP code.'`
    - `'Incorrect OTP code.'`
    - `'OTP code has already been consumed.'`
  - `401 UNAUTHORIZED`: `'Your account has been deactivated or suspended by administration.'`

### 2.4 `POST /auth/refresh` (and alias `POST /auth/token/refresh`)
- **Auth Required**: No (uses refresh token in body)
- **Request Body (`RefreshTokenDto`)**:
  ```json
  { "refreshToken": "..." }
  ```
  *(also accepts `refresh_token`)*
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "data": {
      "accessToken": "new-jwt...",
      "refreshToken": "new-opaque-hex...",
      "expiresIn": 900,
      "tokenType": "Bearer",
      "sessionId": "uuid"
    }
  }
  ```
- **Security Rules**:
  - **Strict single-use rotation**: old refresh token is atomically marked `isRevoked = true`.
  - **Reuse detection**: presenting a previously rotated/revoked refresh token revokes the entire session family (`401 UNAUTHORIZED`: `'Security violation: Refresh token reuse detected...'`).
  - Access token TTL: **15 minutes** (`900` seconds), `HS256`, `iss: deal-one.eg`, `aud: deal-one-mobile`.
  - Refresh token TTL: **30 days**.

### 2.5 `POST /auth/logout`
- **Auth Required**: Optional Bearer (revokes by refresh token, validates ownership if authenticated)
- **Request Body (`RefreshTokenDto`)**: `{ "refreshToken": "..." }`
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "data": { "success": true, "message": "Active session revoked successfully." }
  }
  ```

### 2.6 `GET /auth/me`
- **Auth Required**: `Authorization: Bearer <accessToken>` (`JwtAuthGuard`)
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "data": {
      "id": "uuid",
      "phone": "+201012345678",
      "fullName": "...",
      "role": "USER",
      "status": "ACTIVE"
    }
  }
  ```

### 2.7 `GET /users/me` & `PUT /users/me`
- **Auth Required**: `Authorization: Bearer <accessToken>` (`JwtAuthGuard`)
- **`GET /users/me` Response (`200 OK`)**:
  Returns `{ id, phone, fullName, email, avatarUrl, isPhoneVerified, isEmailVerified, isActive, preferredLanguage, createdAt, updatedAt, role, status }`.
- **`PUT /users/me` Request (`UpdateProfileDto`)**:
  `{ "fullName"?: string, "avatarUrl"?: string, "preferredLanguage"?: "ar" | "en", "governorateId"?: number, "cityId"?: number }`
  - Used immediately after `POST /auth/otp/verify` during **Sign Up** to persist the user's entered `fullName`.

### 2.8 `GET /auth/sessions` & `POST /auth/sessions/terminate-all`
- **Auth Required**: `Authorization: Bearer <accessToken>`
- Lists active sessions or revokes all active sessions for the current user.

---

## 3. Capabilities Absent from the Backend (Explicitly Documented)

1. **WhatsApp OTP Delivery & Registration Check**: Backend uses `SMS_MISR` (`SmsMisrAdapter`) for SMS OTP delivery. There is no WhatsApp delivery adapter or phone-on-WhatsApp lookup endpoint.
2. **Email OTP Delivery**: No endpoint exists to send OTP codes via email.
3. **Google / Apple OAuth**: No `/auth/google` or `/auth/apple` endpoints exist.
4. **Separate Registration Endpoint**: No `POST /auth/register` exists; registration happens atomically inside `POST /auth/otp/verify` followed by `PUT /users/me` to set `fullName`.
5. **4-Digit OTP**: Backend strictly generates and validates 6-digit OTPs (`@Length(6, 6)`), not 4-digit OTPs shown in static design mockups.
