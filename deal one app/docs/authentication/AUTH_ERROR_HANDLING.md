# Deal One — Authentication Error Handling & Validation Strategy

## 1. Typed Failure Pipeline

```text
DioException / SocketException / FormatException / ServerException
        │
        ▼
  ErrorMapper.map()  ──▶  AppFailure (NetworkFailure, TimeoutFailure, ValidationFailure,
        │                 UnauthorizedFailure, ForbiddenFailure, NotFoundFailure,
        │                 ConflictFailure, RateLimitFailure, ServerFailure, UnknownFailure)
        ▼
  AuthErrorMapper.map() ──▶ AuthErrorFeedback(kind: AuthErrorKind, message: String)
        │
        ▼
  AuthLocalizedMessages.authError(l10n, kind)  ──▶ Arabic (ar) / English (en) UI copy
```

## 2. HTTP & Business Error Classification

| Category / HTTP Status | `AuthErrorKind` | UI Presentation |
|---|---|---|
| No connectivity | `network` | `AuthErrorBanner` / retry CTA |
| Connect / Receive / Send timeout | `timeout` | `AuthErrorBanner` / retry CTA |
| `400` / `422` invalid Egyptian phone | `invalidPhoneNumber` | Inline field error / banner |
| `400` / `422` validation failure | `validation` | Inline field error / banner |
| `400` incorrect OTP | `invalidOtp` | Red OTP boxes + `AuthErrorBanner` + `OtpAttemptsPill` + Retry CTA |
| `400` expired / consumed OTP | `expiredOtp` | Blurred backdrop + `OtpExpiredAlertCard` + Resend CTA |
| `400` max attempts exceeded (5) | `maxAttemptsExceeded` | Locked OTP state + `AuthErrorBanner` + Support & Resend |
| `401` deactivated / suspended | `unauthorizedSession` | `AuthErrorBanner` + support guidance |
| `401` invalid / reused refresh token | `invalidRefreshToken` | Clear secure storage + force re-login |
| `403` forbidden | `unauthorizedSession` | `AuthErrorBanner` |
| `404` account not found | `accountNotFound` | `AuthErrorBanner` |
| `409` existing account | `existingAccount` | `AuthErrorBanner` |
| `429` cooldown / rate limit | `rateLimited` | `AuthErrorBanner` + active countdown |
| `500` SMS/WhatsApp delivery failure | `whatsappUnavailable` / `otpDeliveryFailed` | `WhatsAppDeliveryFailureSheet` (blurred modal) |
| Malformed / incomplete auth JSON | `unexpectedResponse` | `AuthErrorBanner` (never saves partial tokens) |
| `500+` other server errors | `server` | `AuthErrorBanner` (never exposes stack traces/SQL) |

## 3. Input Validation & Normalization

- **Full Name (`FullNameValidator`)**: Trims & collapses whitespace, 2–80 chars, must contain Arabic or Latin letters.
- **Egyptian Mobile (`EgyptianPhoneValidator`)**: Converts Arabic numerals (`٠-٩`) to Western digits, strips spaces/hyphens/parentheses, accepts `01...`, `10...`, `201...`, `00201...`, `+201...`, normalizes to `+20(10|11|12|15)[0-9]{8}`.
- **OTP (`OtpCodeValidator`)**: Converts Arabic digits, strips non-digits, enforces exact 6-digit backend length.
- **Email (`EmailValidator`)**: RFC-style format validation for fallback sheet.
