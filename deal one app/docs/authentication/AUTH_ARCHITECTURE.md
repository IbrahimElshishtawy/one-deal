# Deal One — Authentication & Account Architecture

## 1. Clean Architecture Layering

The module follows Clean Architecture with Riverpod 2 (`Notifier` / `AutoDisposeNotifier` / `AutoDisposeFamilyNotifier`) and Dio:

```text
lib/
  core/
    errors/           # AppException, AppFailure, ErrorMapper
    localization/     # LocaleController, SupportedLocales
    logging/          # AppLogger, LogSanitizer (redacts tokens/OTP/phone)
    network/          # ApiClient, ApiEndpoints, AuthInterceptor, RetryInterceptor, NetworkLoggingInterceptor
    providers/        # core_providers.dart (sessionProvider, tokenProvider, apiClientProvider), app_settings_providers.dart (appLocaleProvider, appThemeModeProvider)
    routing/          # RouteNames, SessionRouteGuard, AppPageTransitions
    security/         # SessionState, TokenProvider, SecureTokenProvider (FlutterSecureStorage)
    storage/          # PreferencesService, SecureStorageService, StorageKeys
    theme/            # AppColors, AppThemeData (Light & Dark), AppSpacing, AppRadii, AppTextStyles
  features/
    auth/
      domain/
        entities/     # AuthUser, AuthAccount, AuthSession, OtpDispatchResult, PendingAuthContext
        repositories/ # AuthRepository interface
        usecases/     # SendOtpUseCase, ResendOtpUseCase, VerifyOtpAndCompleteProfileUseCase, LogoutUseCase, RestoreSessionUseCase
        validators/   # FullNameValidator, EgyptianPhoneValidator, EmailValidator, OtpCodeValidator
      data/
        datasources/  # AuthRemoteDataSource / AuthRemoteDataSourceImpl
        dto/          # SendOtpRequestDto, VerifyOtpRequestDto, AuthResponseDto, OtpDispatchResponseDto, AuthUserDto
        mappers/      # AuthMapper, AuthErrorMapper
        repositories/ # AuthRepositoryImpl
      application/
        controllers/  # OnboardingController, SignUpController, LoginController, OtpVerificationController
        state/        # OnboardingState, SignUpState, LoginState, OtpVerificationState, OtpStatus
      presentation/
        pages/        # OnboardingPage, SignUpPage, LoginPage, OtpVerificationPage, VerificationSuccessPage, LegalDocumentPage
        widgets/      # onboarding/, common/, login/, sign_up/, otp/, success/, bottom_sheets/, dialogs/
        providers/    # auth_providers.dart (AuthController + feature providers)
        theme/        # AuthDesignTokens (Light & Dark semantic tokens)
        utils/        # AuthErrorLocalizer (maps AuthErrorKind & validators to AppLocalizations)
    accounts/
      presentation/   # ProfileScreen (with ThemeMode + Language selectors, quota, accounts, logout)
```

---

## 2. State Management & Navigation Synchronization

- **Global Session State**: `sessionProvider` (`SessionNotifier`) restores persisted tokens on startup via `GET /users/me`, refreshes transparently on `401`, and triggers `GoRouter` `refreshListenable` updates automatically.
- **Route Guards**: `SessionRouteGuard` blocks unauthenticated access to protected routes (`/favorites`, `/my-activity`, `/notifications`, cart/checkout/orders/bookings) and redirects to `/login?redirect=<encodedPath>`. Authenticated users visiting `/login`, `/sign-up`, or `/otp-verification` are redirected to `/` (or their decoded `redirect` target).
- **Theme & Locale Persistence**: `appThemeModeProvider` and `appLocaleProvider` persist selections in `SharedPreferences` (`StorageKeys.themeMode`, `StorageKeys.languageCode`) with race-condition guards (`_userUpdated`) and rebuild the entire `MaterialApp.router` immediately without restarting.

---

## 3. Security Architecture

- **Hardware-Backed Token Storage**: `accessToken`, `refreshToken`, and `userId` are stored strictly in `FlutterSecureStorage` via `SecureTokenProvider` — never in `SharedPreferences`.
- **Log Sanitization**: `LogSanitizer` recursively masks `authorization`, `token`, `accessToken`, `refreshToken`, `password`, `otp`, `code`, `phone`, and `mobile` fields before any diagnostic log output.
- **Single-Flight Refresh**: `AuthInterceptor` prevents concurrent `POST /auth/refresh` calls and clears all tokens + notifies `onSessionExpired` on refresh revocation (`401`).
- **Duplicate Submission Prevention**: All controllers (`LoginController`, `SignUpController`, `OtpVerificationController`, `OnboardingController`) guard against concurrent submissions (`if (state.isSubmitting) return` / `if (state.isBusy) return`).
