# Deal One — Authentication Flow Specification

## 1. End-to-End User Journeys

```text
App Launch
  |
  +--> Restore Session (TokenProvider -> GET /users/me)
         |--> Valid session (or refreshed via POST /auth/refresh) --> Authenticated State
         |--> Missing / 401 / Revoked refresh token --------------> Clear Tokens -> Unauthenticated
         |--> Offline with stored token & userId -----------------> Provisional Authenticated (revalidated on next API call)

Login (/login) or Sign Up (/sign-up)
  |
  | 1. Validate local inputs (FullName on Sign Up, Egyptian mobile on both; default +20)
  | 2. Normalize phone to E.164 (+2010/11/12/15XXXXXXXX)
  | 3. POST /auth/otp/send { phone }
  |
  +--> Delivery Failure (HTTP 500 SMS failure / WhatsApp unavailable / success == false)
  |      |
  |      +--> Show WhatsAppDeliveryFailureSheet (phone pill, email limitation/fallback, SMS retry, edit phone, support)
  |
  +--> Rate Limited (HTTP 429) / Validation Error (HTTP 400) / Network Error
  |      |
  |      +--> Show mapped Arabic error banner/field error on Login / Sign Up
  |
  +--> Success (200 OK, cooldownSeconds = 60, server/default otpExpirySeconds = 180)
         |
         +--> Navigate to /otp-verification with PendingAuthContext
                |
                | 1. Start 1-second timer (cooldown + expiry countdown)
                | 2. User enters 6-digit OTP (auto-focus, paste, backspace, Arabic numeral normalization)
                | 3. POST /auth/otp/verify { phone, code }
                |
                +--> Invalid OTP (400 Incorrect / Invalid code)
                |      +--> Red OTP borders, error banner, remaining attempts pill (5 - failedAttempts),
                |           "إعادة المحاولة" clears invalid code & refocuses input
                |
                +--> Max Attempts Exceeded (400 Maximum verification attempts exceeded)
                |      +--> Locked state (OtpStatus.locked), disable verification, prompt requesting new OTP
                |
                +--> Expired OTP (Server 400 expired OR local timer reaches 0)
                |      +--> Blurred/dimmed overlay + top pink expiry card, prevent verification,
                |           unlock/trigger POST /auth/otp/resend on retry
                |
                +--> Network / Timeout Error
                |      +--> Distinct network banner (never misclassified as invalid OTP; preserves code)
                |
                +--> Success (200 OK -> AuthSession)
                       +--> Persist accessToken, refreshToken, userId in FlutterSecureStorage
                       +--> If Sign Up flow with pendingFullName -> PUT /users/me { fullName }
                       +--> Update sessionProvider (authenticated) & authControllerProvider (AuthUser)
                       +--> Navigate to /verification-success
                       +--> User taps "المتابعة لتسجيل الدخول" -> Navigate to target destination (default /)
```

---

## 2. Token Lifecycle, Single-Flight Refresh & Security

1. **Storage**:
   - `accessToken`, `refreshToken`, `userId` stored exclusively in `FlutterSecureStorage` via `SecureTokenProvider` & `SecureStorageService`.
   - Never stored in `SharedPreferences`.
   - Never logged in `NetworkLoggingInterceptor` (`LogSanitizer` redacts `authorization`, `token`, `accessToken`, `refreshToken`, `otp`, `code`, `phone`, `mobile`).
2. **Single-Flight Refresh (`AuthInterceptor`)**:
   - Requests to trusted API origin automatically attach `Authorization: Bearer <accessToken>`.
   - On `401 Unauthorized` (excluding `/auth/refresh`, `/auth/login`, `/auth/otp/*`, `/auth/logout`):
     - First caller acquires `_isRefreshing` + `_refreshCompleter`.
     - Concurrent 401 callers await `_refreshCompleter.future` without issuing duplicate `POST /auth/refresh` requests (preventing backend reuse-detection revocation!).
     - Successful refresh persists rotated `accessToken` + `refreshToken` and retries original requests with `is_retry: true`.
     - Failed refresh (401/invalid/reused/expired) clears secure storage and triggers `onSessionExpired` -> `sessionProvider.notifier.logout()` -> router guard redirects away from protected routes.

---

## 3. Navigation & Route Guards (`SessionRouteGuard` + `AppRouter`)

- **Public / Guest-Accessible Routes**:
  - `/`, `/search`, `/listings/:id`, category browsing routes, `/onboarding`, `/login`, `/sign-up`, `/otp-verification`, `/verification-success`, `/terms`, `/privacy`, `/profile` (renders guest CTA when unauthenticated).
- **Protected Routes (Redirect to `/login?redirect=<encodedRoute>` when unauthenticated)**:
  - `/favorites`, `/my-activity`, `/notifications`,
  - `/building-materials/cart`, `/building-materials/checkout`, `/building-materials/orders`, `/building-materials/orders/detail`, `/building-materials/rfq`, `/building-materials/notifications`,
  - `/fashion/cart`,
  - `/home-services/bookings`, `/home-services/favorites`, `/home-services/notifications`, `/home-services/book`, `/home-services/booking-detail`, `/home-services/tracking`.
- **Auth-Only Redirect**:
  - Authenticated users navigating to `/login`, `/sign-up`, or `/otp-verification` are redirected to `/` (or decoded `redirect` target).
