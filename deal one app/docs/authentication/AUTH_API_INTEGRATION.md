# Deal One — Authentication API Integration Map

- **Production Base URL**: `https://one-deal-cjjt-production.up.railway.app/api/v1`
- **Source of Truth**: `docs/mobile-rebuild/api_contracts/production_openapi.json` and `lib/core/network/api_endpoints.dart`.
- **Success Envelope**: `{ "success": true, "data": { ... }, "meta": { ... } }`
- **Error Envelope**: `{ "success": false, "error": { "code": "...", "message": "...", "details": [...], "trace_id": "..." } }`

---

## 1. Integrated Endpoints

| Method | Endpoint | Auth | Request DTO | Response DTO | Status Codes |
|---|---|---|---|---|---|
| `POST` | `/auth/otp/send` | Public | `SendOtpRequestDto { phone }` | `OtpDispatchResponseDto { success, message, cooldownSeconds, otpExpirySeconds? }` | `200`, `400`, `429`, `500` |
| `POST` | `/auth/otp/resend` | Public | `SendOtpRequestDto { phone }` | `OtpDispatchResponseDto` | `200`, `400`, `429`, `500` |
| `POST` | `/auth/otp/verify` | Public | `VerifyOtpRequestDto { phone, code }` | `AuthResponseDto { user, activeAccount, tokens: { accessToken, refreshToken, expiresIn, sessionId } }` | `200`, `400`, `401`, `429` |
| `POST` | `/auth/refresh` | Refresh token in body | `{ refreshToken }` | `{ accessToken, refreshToken, expiresIn, tokenType, sessionId }` | `200`, `401` |
| `POST` | `/auth/logout` | Optional Bearer + Refresh token | `RefreshTokenRequestDto { refreshToken }` | `{ success, message }` | `200`, `401` |
| `GET` | `/users/me` | Bearer JWT | — | `AuthUserDto` | `200`, `401` |
| `PUT` | `/users/me` | Bearer JWT | `UpdateProfileRequestDto { fullName }` | `AuthUserDto` | `200`, `400`, `401` |

---

## 2. Backend Contract Rules Enforced on Client

1. **Phone Normalization**: Strictly Egyptian mobile numbers (`010`, `011`, `012`, `015`) normalized to E.164 `^\+20(10|11|12|15)[0-9]{8}$`. Arabic-Indic digits (`٠-٩`) are normalized to ASCII digits before validation and dispatch.
2. **OTP Length**: Backend strictly enforces **6 numeric digits** (`/^[0-9]{6}$/`). Although static Figma mockups depict 4 boxes, the client enforces 6 digits to match the authoritative backend contract.
3. **Unified Login & Registration**: `POST /auth/otp/verify` atomically creates a new user + individual account if the phone number is new. For Sign-Up flows, the client immediately executes `PUT /users/me { fullName }` to persist the user's entered name.
4. **Cooldown & Expiry**: Default resend cooldown is `60s` (`cooldownSeconds`) and OTP expiry is `180s` (`otpExpirySeconds`), with max `5` verification attempts per challenge.
5. **Single-Flight Token Rotation**: `AuthInterceptor` serializes concurrent `401` refreshes via a shared `Completer` so the backend's single-use refresh-token reuse detector never revokes a valid session family.

---

## 3. Documented Backend Limitations (No Fake Implementations)

1. **No WhatsApp Delivery Adapter / Lookup Endpoint**: Backend currently dispatches OTPs via SMS (`SmsMisrAdapter`). No WhatsApp delivery or WhatsApp-registration-check endpoint exists; the `WhatsAppDeliveryFailureSheet` is triggered on real backend delivery failures (`500` / `OTP_DELIVERY_FAILED` / `WHATSAPP_UNAVAILABLE`) and via user delivery troubleshooting.
2. **No Email OTP Endpoint**: Tapping Email fallback validates the email format and transparently informs the user that Email OTP delivery is not enabled on the server.
3. **No Google / Apple OAuth Endpoints**: Tapping Email or Apple provider buttons opens `UnavailableProviderDialog` explaining phone OTP is required.
4. **Live Production Availability Note**: During verification on `2026-11-19`, probing `https://one-deal-cjjt-production.up.railway.app/api/v1/health` returned `HTTP/2 502 {"status":"error","code":502,"message":"Application failed to respond"}` from Railway edge (`railway-hikari`). Live end-to-end tests against the production server therefore could not be executed until the Railway service is restored.
