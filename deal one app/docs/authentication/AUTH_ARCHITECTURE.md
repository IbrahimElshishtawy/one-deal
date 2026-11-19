# Deal One — Authentication & Account Architecture

## 1. Clean Architecture Layering

```text
lib/
├── core/
│   ├── errors/           # AppException, AppFailure, ErrorMapper
│   ├── localization/     # SupportedLocales, LocaleController
│   ├── network/          # DioApiClient, AuthInterceptor, RetryInterceptor, RequestIdInterceptor, NetworkLoggingInterceptor
│   ├── providers/        # Core Riverpod providers, LocaleNotifier, ThemeModeNotifier, SessionNotifier
│   ├── routing/          # RouteNames, SessionRouteGuard, AppPageTransitions
│   ├── security/         # TokenProvider, SecureTokenProvider, SessionState
│   ├── storage/          # SecureStorageService (flutter_secure_storage), PreferencesService
│   └── theme/            # AppColors, AppThemeData (Light & Dark), AppSpacing, AppRadii
├── l10n/                 # app_en.arb, app_ar.arb, generated/app_localizations*.dart
└── features/
    ├── auth/
    │   ├── domain/       # entities/auth_session.dart, repositories/auth_repository.dart,
    │   │                 # usecases/auth_usecases.dart, validators/auth_validators.dart
    │   ├── data/         # datasources/auth_remote_datasource.dart, dto/auth_dto.dart,
    │   │                 # mappers/auth_mapper.dart, mappers/auth_error_mapper.dart,
    │   │                 # repositories/auth_repository_impl.dart
    │   ├── application/  # state/auth_states.dart, controllers/{onboarding,sign_up,login,otp_verification}_controller.dart
    │   └── presentation/ # l10n/auth_l10n_extension.dart, theme/auth_design_tokens.dart,
    │                     # providers/auth_providers.dart, pages/*, widgets/*
    └── accounts/         # ProfileScreen (with live Theme & Language switchers, quota, accounts, logout)
```

---

## 2. State Management & Data Flow (Riverpod 2)

- **Global Session**: `sessionProvider` (`SessionNotifier`) synchronizes authentication status with `GoRouter` via `refreshListenable` and `SessionRouteGuard`.
- **Feature Controllers**:
  - `onboardingControllerProvider` (`OnboardingController`): manages page index and persists `StorageKeys.onboardingCompleted`.
  - `signUpControllerProvider` (`SignUpController`): validates `fullName` + Egyptian phone, normalizes to `+201...`, dispatches OTP, prevents duplicate submits.
  - `loginControllerProvider` (`LoginController`): validates + normalizes phone, dispatches OTP, surfaces delivery failures.
  - `otpVerificationControllerProvider(PendingAuthContext)` (`OtpVerificationController`): manages 60s resend cooldown, 180s expiry countdown, 6-digit verification, atomic `PUT /users/me` profile completion on sign-up, and session activation.
- **Settings Persistence**:
  - `appThemeModeProvider` (`ThemeModeNotifier`): Light / Dark / System persisted in `PreferencesService`.
  - `appLocaleProvider` (`LocaleNotifier`): Arabic (`ar`, RTL) / English (`en`, LTR) persisted in `PreferencesService`, updating UI immediately without restart.

---

## 3. Security & Navigation Guards

- **Secure Token Storage**: Access & refresh tokens are stored exclusively in `flutter_secure_storage` (`SecureTokenProvider`) — never in `SharedPreferences`.
- **Single-Flight Token Refresh**: `AuthInterceptor` serializes concurrent `401` refreshes into a single `POST /auth/refresh` call and clears secure storage + triggers `onSessionExpired` on refresh token failure/reuse.
- **Safe Logging**: `NetworkLoggingInterceptor` + `LogSanitizer` redact `Authorization` headers, tokens, and sensitive fields.
- **Route Guards**: `SessionRouteGuard` blocks unauthenticated users from protected routes (redirecting to `/login?redirect=...`) and redirects authenticated users away from `/login` and `/sign-up`.
