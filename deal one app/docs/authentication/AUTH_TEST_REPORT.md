# Deal One — Authentication & Account Test Report

## 1. Execution Summary

| Suite / Command | Result | Details |
|---|---|---|
| `flutter gen-l10n` | PASS (0 warnings) | Generated `lib/l10n/generated/app_localizations*.dart` (`ar` + `en`) |
| `flutter analyze` | PASS (0 issues) | Clean static analysis across entire workspace |
| `flutter test` (Full Suite) | **83 / 83 PASS** | All core, unit, repository, controller, widget, and simulated E2E tests passed |
| `flutter build apk --debug` | PASS (`18.1s`) | Built `build/app/outputs/flutter-apk/app-debug.apk` |
| Live Production Backend Smoke Test | **BLOCKED (HTTP 502)** | `https://one-deal-cjjt-production.up.railway.app/api/v1/health` returned `HTTP/2 502 Application failed to respond` |

---

## 2. Authentication Test Coverage Breakdown

### Unit Tests (`test/features/auth/`)
- `auth_validators_and_mappers_test.dart`:
  - `FullNameValidator` (empty, short, digit-only, valid names, whitespace normalization).
  - `EgyptianPhoneValidator` (all Egyptian formats: `010/011/012/015`, `10...`, `201...`, `00201...`, `+20 ...`, Arabic-Indic digits `٠-٩`, invalid prefixes/lengths, display formatting).
  - `EmailValidator` and `OtpCodeValidator` (6-digit strict validation + Arabic digit normalization).
  - `AuthResponseDto` / `OtpDispatchResponseDto` parsing and `AuthMapper` entity mapping.
  - `AuthErrorMapper` mapping for invalid OTP, expired OTP, max attempts exceeded, rate limit, network, timeout, and Dio `400` envelopes.
- `auth_repository_test.dart`:
  - `sendOtp`, `verifyOtp` (token persistence in secure storage), `OTP_DELIVERY_FAILED` on `success: false`, `UNEXPECTED_RESPONSE` on missing tokens, and `logout` clearing tokens.
- `auth_controllers_test.dart`:
  - `OnboardingController` page advancement & `onboardingCompleted` persistence.
  - `SignUpController` & `LoginController` validation, normalization, rate-limit & delivery error mapping.
  - `OtpVerificationController` 6-digit verification, profile `fullName` update on Sign-Up, invalid attempt tracking, lock, expiration, and resend.

### Widget Tests (`test/features/auth/auth_widgets_test.dart`)
- **Onboarding (3 Figma slides)**: Verifies all 3 exact Arabic titles, Skip button visible on slides 1–2 and hidden on slide 3, `"إنشاء حساب"` CTA navigation to Sign-Up, and `onboardingCompleted` persistence.
- **Sign-Up**: Input validation, Email/Apple unavailable provider dialog, focus border in light mode, navigation to Login.
- **Login**: OTP dispatch, automatic `WhatsAppDeliveryFailureSheet` trigger on delivery failure.
- **OTP Verification**: LTR 6-digit input boxes, invalid state banner + remaining attempts pill + retry flow, expired/timeout floating alert card + resend unlock, WhatsApp failure sheet, and navigation to Verification Success screen.
- **Light & Dark Theme**: `ProfileScreen` System / Dark / Light selector + dynamic color adaptation across auth & shared widgets.
- **English LTR & Dark Mode**: Full end-to-end Onboarding -> Sign-Up -> Login -> OTP (invalid + retry + valid) -> Verification Success in English (`Locale('en')`, `TextDirection.ltr`) under `ThemeMode.dark`.
- **Live Language Switching**: `ProfileScreen` Arabic (`ar`, RTL) <-> English (`en`, LTR) switching with immediate UI update and `StorageKeys.languageCode` persistence.

### Integration Tests (`test/features/auth/auth_integration_test.dart`)
- Single-flight token refresh rotating tokens once across concurrent `401` calls and restoring session.
- Invalid/reused refresh token clearing secure storage and logging out session.
- Protected route guard redirecting unauthenticated user to `/login?redirect=...`, completing Sign-Up + OTP + profile update, and unlocking the guarded route.

---

## 3. Live Backend Integration Note

Live HTTP requests against `https://one-deal-cjjt-production.up.railway.app/api/v1/health` and `/api/docs-json` returned `HTTP/2 502` from Railway (`Application failed to respond`) during this verification run. No live production credentials or destructive API tests were fabricated or claimed as passed. Once the Railway service is healthy, live OTP smoke tests should be executed against staging/production before production release.
