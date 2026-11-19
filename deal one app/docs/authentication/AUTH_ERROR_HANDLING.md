# Deal One — Authentication Error Handling Architecture

## 1. Layered Error Pipeline

```text
DioException / SocketException / FormatException / AppException
  -> ErrorMapper.map()            [core/errors/error_mapper.dart]
       -> Typed AppFailure (NetworkFailure, TimeoutFailure, ValidationFailure,
          UnauthorizedFailure, ForbiddenFailure, NotFoundFailure, ConflictFailure,
          RateLimitFailure, ServerFailure, UnknownFailure)
  -> AuthErrorMapper.map()        [features/auth/data/mappers/auth_error_mapper.dart]
       -> Semantic AuthErrorKind (16 domain-specific authentication error kinds)
  -> AuthErrorLocalizer           [features/auth/presentation/utils/auth_error_localizer.dart]
       -> Localized Arabic / English copy via AppLocalizations (ARB)
```

---

## 2. Error Classification & Presentation Matrix

| HTTP / Exception | Backend Pattern | `AuthErrorKind` | UI Presentation |
|---|---|---|---|
| No connectivity / Socket error | `NetworkException` / `DioExceptionType.connectionError` | `network` | `AuthErrorBanner` (preserves OTP code; never misclassified as invalid OTP) |
| Connect / Receive / Send timeout | `TimeoutException` | `timeout` | `AuthErrorBanner` with retry option |
| `400` / `422` Phone validation | `egyptian`, `phone`, `mobile` | `invalidPhoneNumber` | Inline field error under phone input |
| `400` / `422` OTP length | `6 digits`, `otp code` | `validation` | Inline error banner |
| `400` Incorrect OTP | `incorrect otp`, `wrong otp` | `invalidOtp` | Red OTP box borders + pink `AuthErrorBanner` + `OtpAttemptsPill` + Retry CTA |
| `400` Expired / Consumed OTP | `expired`, `invalid or expired otp`, `already been consumed` | `expiredOtp` | Blurred upper section + floating `OtpExpiredCard` + Resend CTA |
| `400` Max attempts exceeded | `maximum verification attempts`, `attempts exceeded` | `maxAttemptsExceeded` | Locked state (`OtpStatus.locked`), disables input, prompts new OTP |
| `401` / `403` Suspended / Unauthorized | `deactivated`, `suspended`, `401`, `403` | `unauthorizedSession` | `AuthErrorBanner` directing user to support |
| `401` Refresh token invalid/reused | `refresh token` | `invalidRefreshToken` | Clears secure storage, logs out globally, redirects via guard |
| `404` Account not found | `user not found`, `account not found` | `accountNotFound` | `AuthErrorBanner` |
| `409` Existing account | `already exists`, `already registered` | `existingAccount` | `AuthErrorBanner` |
| `429` Cooldown / Rate limit | `cooldown`, `too many` | `rateLimited` | `AuthErrorBanner` + disabled resend until timer reaches `0:00` |
| `500` / `OTP_DELIVERY_FAILED` | `failed to deliver sms/otp`, `success: false` | `otpDeliveryFailed` | Automatically opens `WhatsAppDeliveryFailureSheet` |
| `WHATSAPP_UNAVAILABLE` | `whatsapp` + `not registered/unavailable` | `whatsappUnavailable` | Automatically opens `WhatsAppDeliveryFailureSheet` |
| Malformed payload | Missing tokens or user ID | `unexpectedResponse` | `AuthErrorBanner` (never exposes stack trace or raw JSON) |
| Other `5xx` | Server failure | `server` | `AuthErrorBanner` |

---

## 3. Security & Privacy Guarantees

- Raw backend stack traces, SQL/ORM errors, JWTs, and internal error payloads are never rendered in the UI.
- Every user-facing error message is served through `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`.
