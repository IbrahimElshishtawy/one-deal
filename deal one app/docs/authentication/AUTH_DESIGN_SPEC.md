# Deal One — Authentication & Account Design Specification

## 1. Screen Inventory (10 Figma Reference Exports)

| # | Figma Reference File | Flutter Implementation | Status |
|---|---|---|---|
| 1 | `Onboarding 1 _Real Estate and Cars_.png` | `OnboardingPage` (Slide 0) + `OnboardingIllustration` | Implemented |
| 2 | `Onboarding 2 _Home services, construction materials, and electrical supplies_.png` | `OnboardingPage` (Slide 1) + `OnboardingIllustration` | Implemented |
| 3 | `Onboarding 3 _Clothing, accessories, appliances, and decor_.png` | `OnboardingPage` (Slide 2) + `OnboardingIllustration` | Implemented |
| 4 | `Sign-Up.png` | `SignUpPage` + `SignUpFormCard` | Implemented |
| 5 | `Log-in.png` | `LoginPage` + `LoginFormCard` | Implemented |
| 6 | `Verification via OTP code.png` | `OtpVerificationPage` (normal) + `OtpPinBoxes` | Implemented |
| 7 | `Verification via OTP code _Faild State_.png` | `OtpVerificationPage` (invalid/locked) + `AuthErrorBanner` + `OtpAttemptsPill` | Implemented |
| 8 | `Verification via OTP code _Timeout State_.png` | `OtpVerificationPage` (expired) + `OtpExpiredAlertCard` | Implemented |
| 9 | `Verification via OTP code _Unable to send to WhatsApp State_.png` | `WhatsAppDeliveryFailureSheet` (blurred modal sheet) | Implemented |
| 10 | `Success State Screen.png` | `VerificationSuccessPage` + `SuccessBadgeWidget` | Implemented |

---

## 2. Color Palette (Light & Dark Mode)

All tokens are centralized in `lib/features/auth/presentation/theme/auth_design_tokens.dart` and `lib/core/theme/app_colors.dart`.

| Token | Light Mode | Dark Mode | Usage |
|---|---|---|---|
| Background | `#F8FAFC` | `#0F172A` | Auth screen canvas |
| Surface / Card | `#FFFFFF` | `#1E293B` | Inputs, OTP boxes, bottom sheets |
| Primary CTA | `#1D2B44` | `#3A7AFE` | Primary buttons, success circle |
| Onboarding CTA | `#4285F4` + `#FFFFFF` border | `#4285F4` + `#FFFFFF` border | Onboarding Next / Create Account CTA |
| Focus Orange | `#E68A2E` | `#E68A2E` | Active OTP box border & cursor bar |
| Heading Text | `#1E293B` | `#F8FAFC` | Screen titles, primary labels |
| Body Text | `#475569` | `#CBD5E1` | Secondary prose, attempts pill text |
| Muted Text | `#64748B` | `#94A3B8` | Hints, subtitles, legal copy |
| Border / Divider | `#E2E8F0` | `#334155` | Inputs, dividers, dashed rings |
| Error Red | `#DC2626` / `#B91C1C` | `#FCA5A5` | Error borders, banners, timeout text |
| Error Surface | `#FDECEC` / `#FADBD8` | `#3F1518` | Error banner, timeout alert card |
| Soft Pill | `#EBF0F7` | `#1E293B` | Remaining attempts pill, phone badge |
| Success Teal Dot | `#0F766E` | `#0F766E` | Lower accent dot in success emblem |

---

## 3. Typography Scale & Spacing System

- **Spacing Rhythm**: 4/8pt scale (`spaceXs = 4`, `spaceSm = 8`, `spaceMd = 12`, `spaceBase = 16`, `spaceLg = 20`, `spaceXl = 24`, `space2xl = 32`, `space3xl = 40`).
- **Typography**:
  - Screen Heading: `22–25px`, `FontWeight.w800`, `height: 1.35`
  - Subtitle: `13.5–14.5px`, `FontWeight.w400–w500`, `height: 1.55–1.65`
  - Input & CTA Label: `14.5–17px`, `FontWeight.w600–w700`
  - Helper / Legal: `11.5–12.5px`, `FontWeight.w500–w700`
- **Radii**: Inputs & primary buttons `12px`, onboarding CTA `10px`, cards `16px`, social pills & bottom sheets `24px`.

---

## 4. Component Inventory

- **Onboarding**: `OnboardingIllustration`, `OnboardingPageIndicator`, `OnboardingBottomControls`, `OnboardingSlideData`
- **Shared Auth**: `AuthScaffoldShell`, `AuthTopBar`, `AuthLogoHeader`, `AuthTextField`, `AuthCountryPrefixBadge`, `AuthPrimaryButton`, `AuthSecondaryButton`, `AuthSocialSection`, `AuthErrorBanner`, `AuthLegalFooter`, `WhatsAppGlyphIcon`, `GmailMarkIcon`
- **Sign-Up / Login**: `SignUpFormCard`, `LoginFormCard`, `UnavailableProviderDialog`
- **OTP**: `OtpPinBoxes`, `OtpExpiredAlertCard`, `OtpAttemptsPill`, `WhatsAppDeliveryFailureSheet`, `EmailFallbackSheet`, `SupportContactSheet`
- **Success**: `SuccessBadgeWidget`

---

## 5. Navigation Flow & Responsive Behavior

- **Flow**: `Onboarding (3 slides)` → `SignUp` ⇄ `Login` → `OtpVerification` (Normal / Failed / Timeout / WhatsApp Failure Sheet) → `VerificationSuccess` → `Home (/)` or protected `redirectTo`.
- **Responsiveness**: Max content width `440px` centered for tablets/large phones, `SafeArea`, `SingleChildScrollView` + `viewInsets.bottom` keyboard handling on all forms and bottom sheets, RTL (`ar`) and LTR (`en`) mirroring via `AlignmentDirectional`, `EdgeInsetsDirectional`, and `TextAlign.start`, while phone numbers and OTP boxes stay strictly LTR.
- **Design vs. Backend Contract Note**: Static Figma OTP screens illustrate 4 boxes, whereas the production backend strictly enforces 6-digit OTPs (`@Length(6, 6)`). The app renders 6 responsive boxes to honor the authoritative backend contract.
