# Deal One — Authentication Backend API Integration

## 1. Environment & Base Configuration

- **Production Base URL**: `https://one-deal-cjjt-production.up.railway.app/api/v1`
- **Health Probes** (verified live):
  - `GET /health/live` → `200 OK` (`{"success":true,"data":{"status":"ok",...}}`)
  - `GET /health/ready` → `200 OK` (`database: up`, `postgis: up`, `redis_cache: up`, `redis_queue: up`, `workers: active`)
- **Phone Format**: Canonical Egyptian E.164 `^\+20(10|11|12|15)[0-9]{8}$`.

---

## 2. Integrated Endpoints

| Method | Path | Auth | Request DTO | Response DTO | Status Codes |
|---|---|---|---|---|---|
| `POST` | `/auth/otp/send` | Public | `{ "phone": "+2010..." }` | `{ success, message, cooldownSeconds }` | `200`, `400`, `429`, `500` |
| `POST` | `/auth/otp/resend` | Public | `{ "phone": "+2010..." }` | `{ success, message, cooldownSeconds }` | `200`, `400`, `429`, `500` |
| `POST` | `/auth/otp/verify` | Public | `{ "phone": "+2010...", "code": "123456" }` | `{ user, activeAccount, tokens }` | `200`, `400`, `401`, `429` |
| `POST` | `/auth/refresh` | Public (Refresh Token) | `{ "refreshToken": "..." }` | `{ accessToken, refreshToken, expiresIn, tokenType, sessionId }` | `200`, `401` |
| `POST` | `/auth/logout` | Optional Bearer | `{ "refreshToken": "..." }` | `{ success, message }` | `200`, `401` |
| `GET` | `/auth/me` | Bearer JWT | — | `{ id, phone, fullName, role, status }` | `200`, `401` |
| `GET` | `/users/me` | Bearer JWT | — | Full `AuthUserDto` | `200`, `401` |
| `PUT` | `/users/me` | Bearer JWT | `{ "fullName": "..." }` | Updated `AuthUserDto` | `200`, `400`, `401` |

---

## 3. Envelope & Validation Verification (Live Production Probes)

- Invalid phone `POST /api/v1/auth/otp/send` (`{"phone":"invalid"}`) verified live:
  ```json
  {
    "success": false,
    "error": {
      "code": "VALIDATION_FAILED",
      "message": "Validation failed for one or more fields",
      "details": [
        {
          "issue": "Phone number must be a valid Egyptian mobile number (Vodafone: 010, Etisalat: 011, Orange: 012, WE: 015)."
        }
      ],
      "trace_id": "..."
    }
  }
  ```
- Unauthenticated `GET /api/v1/auth/me` verified live:
  ```json
  {
    "success": false,
    "error": {
      "code": "UNAUTHORIZED",
      "message": "Authentication token is missing, invalid, or expired",
      "details": null,
      "trace_id": "..."
    }
  }
  ```

---

## 4. Documented Backend Limitations (No Fake Workarounds Implemented)

1. **WhatsApp OTP Delivery**: Production backend dispatches OTP via SMS (`SmsMisrAdapter`), not WhatsApp. When delivery errors or WhatsApp unavailability codes occur, the app presents `WhatsAppDeliveryFailureSheet` with SMS retry, Edit Phone, and Support actions.
2. **Email OTP Delivery**: No `/auth/email/otp` endpoint exists. `EmailFallbackSheet` validates email input and transparently communicates unavailability without faking delivery.
3. **Google / Apple OAuth**: No OAuth endpoints exist. Tapping Email/Apple buttons displays `UnavailableProviderDialog`.
4. **Registration Endpoint**: No separate `/auth/register` endpoint exists. Account creation happens atomically inside `POST /auth/otp/verify`, followed by `PUT /users/me` to save the user's `fullName`.
5. **OTP Length**: Backend enforces 6-digit OTPs (`100000`–`999999`), 180s expiry, 60s resend cooldown, and 5 max attempts.
