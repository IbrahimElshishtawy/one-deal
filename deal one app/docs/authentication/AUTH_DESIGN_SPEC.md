# Deal One — Authentication & Account Design Specification

## 1. Screen Inventory (10 Figma Reference Exports)

Source directory: `ui/Authentication & Account Screens/`

| # | Figma Export | Route / Component | Purpose |
|---|---|---|---|
| 1 | `Onboarding 1 _Real Estate and Cars_.png` | `/onboarding` (`OnboardingPage` slide 0) | Real estate, cars, maintenance & spare parts intro |
| 2 | `Onboarding 2 _Home services, construction materials, and electrical supplies_.png` | `/onboarding` (`OnboardingPage` slide 1) | Engineering offices, construction & electrical supplies intro |
| 3 | `Onboarding 3 _Clothing, accessories, appliances, and decor_.png` | `/onboarding` (`OnboardingPage` slide 2) | Fashion, decor, appliances & direct seller contact intro |
| 4 | `Sign-Up.png` | `/sign-up` (`SignUpPage`) | New user full name + Egyptian mobile OTP registration |
| 5 | `Log-in.png` | `/login` (`LoginPage`) | Returning user Egyptian mobile OTP login |
| 6 | `Verification via OTP code.png` | `/otp-verification` (`OtpVerificationPage` default) | 6-digit OTP entry (reconciled with backend contract) + cooldown countdown |
| 7 | `Verification via OTP code _Faild State_.png` | `/otp-verification` (`OtpStatus.invalid` / `locked`) | Invalid OTP red borders, error banner, remaining attempts pill, retry CTA & support |
| 8 | `Verification via OTP code _Timeout State_.png` | `/otp-verification` (`OtpStatus.expired`) | Blurred/dimmed upper content, floating rose expiry alert card, resend CTA |
| 9 | `Verification via OTP code _Unable to send to WhatsApp State_.png` | `WhatsAppDeliveryFailureSheet` | Modal bottom sheet for WhatsApp/SMS delivery failure with phone pill, email notice, SMS retry, edit phone & support |
| 10 | `Success State Screen.png` | `/verification-success` (`VerificationSuccessPage`) | Concentric dashed ring emblem, checkmark medallion, localized confirmation & continue CTA |

---

## 2. Color Palette (Light & Dark Themes)

Centralized in `lib/features/auth/presentation/theme/auth_design_tokens.dart` and `lib/core/theme/app_colors.dart`.

| Token | Light Mode | Dark Mode | Usage |
|---|---|---|---|
| Background | `#F8FAFC` | `#0F172A` | Scaffold background for auth pages |
| Surface / Card / Input | `#FFFFFF` | `#1E293B` | Text fields, OTP boxes, bottom sheets, social pills |
| Border / Divider | `#E2E8F0` | `#334155` | Input borders, social button borders, horizontal dividers |
| Primary Heading | `#1E293B` | `#F8FAFC` | Screen titles, bold links, OTP digits |
| Body Copy | `#475569` | `#CBD5E1` | Secondary labels, legal links, attempt pill text |
| Muted Copy | `#64748B` | `#94A3B8` | Subtitles, placeholders, legal footer, icons |
| Primary CTA (Navy) | `#1D2B44` | `#3A7AFE` | Login, Sign-Up, Verify, Retry, Continue CTAs |
| Onboarding CTA (Blue) | `#4285F4` | `#4285F4` | Onboarding Next / Create Account CTA (with 1.2px white border) |
| Onboarding Scrim | `#0E1521` | `#0E1521` | Full-bleed bottom gradient scrim behind white onboarding copy |
| OTP Focus Accent | `#E68A2E` | `#E68A2E` | Focused OTP box border & vertical cursor bar |
| Input Focus Border | `#111111` | `#F8FAFC` | Focused text field outline |
| Error / Destructive | `#DC2626` / `#B91C1C` | `#FCA5A5` | Error borders, error banners, expired card text |
| Error Surface | `#FDECEC` / `#FADBD8` | `#3F1518` | Invalid OTP banner & expired floating alert card |
| Soft Pill | `#EBF0F7` | `#1E293B` | Remaining attempts pill & WhatsApp sheet phone pill |
| Success Accent Dot | `#0F766E` / `#16A34A` | `#0F766E` / `#4ADE80` | Verification success ring accent dot |

---

## 3. Typography Scale

- **Brand Wordmark**: `22px` ExtraBold (`w900`) Arabic + `13px` ExtraBold (`w800`, `letterSpacing: 1.2`) `DEAL ONE`.
- **Screen Heading**: `24px–25px` ExtraBold (`w800`), line height `1.35`.
- **Onboarding Title**: `21px` ExtraBold (`w800`), pure white over dark scrim.
- **Subtitle / Description**: `13.5px–14.5px` Regular, line height `1.55–1.65`.
- **Primary Button Label**: `15.5px–17px` Bold (`w700`).
- **Input Text & Placeholder**: `15px` Medium/Regular.
- **OTP Digits**: `21px` Bold (`w700`), forced `TextDirection.ltr`.
- **Helper / Legal Caption**: `11.5px–12.5px` Regular/Medium.

---

## 4. Spacing System & Radii (4/8pt Grid)

- Scale: `spaceXs=4`, `spaceSm=8`, `spaceMd=12`, `spaceBase=16`, `spaceLg=20`, `spaceXl=24`, `space2xl=32`, `space3xl=40`.
- Content max width: `440px` (centered on tablets/large screens).
- Horizontal page padding: `24px` (`20px` on Onboarding overlay).
- Input height: `52px`, radius: `12px`.
- Primary CTA height: `52px`, radius: `12px`.
- Social buttons height: `48px`, pill radius: `24px`.
- Floating alert card radius: `16px`; Modal bottom sheets top radius: `24px`.

---

## 5. Component Inventory

- **Onboarding**: `OnboardingIllustration`, `OnboardingPageIndicator` (3 equal segmented bars), `OnboardingBottomControls`, `OnboardingSlideData`.
- **Common**: `AuthScaffoldShell`, `AuthTopBar`, `AuthLogoHeader`, `AuthTextField`, `AuthPrimaryButton`, `AuthSecondaryButton`, `AuthSocialSection`, `AuthLegalFooter`, `AuthErrorBanner`, `AuthCountryPrefixBadge`, `WhatsAppGlyphIcon`, `GmailMarkIcon`.
- **Forms**: `LoginFormCard`, `SignUpFormCard`.
- **OTP**: `OtpPinBoxes`, `OtpExpiredCard`, `OtpAttemptsPill`.
- **Success**: `SuccessEmblemWidget`.
- **Sheets & Dialogs**: `WhatsAppDeliveryFailureSheet`, `EmailFallbackSheet`, `SupportContactSheet`, `UnavailableProviderDialog`.

---

## 6. Navigation Flow & Responsive Behavior

- First launch (`onboardingCompleted == false`): `/onboarding` -> Skip or Slide 3 CTA -> `/sign-up`.
- Auth switching: `/sign-up` <-> `/login` (preserving `?redirect=` query param).
- OTP verification: `/sign-up` or `/login` -> `POST /auth/otp/send` -> `/otp-verification` (`PendingAuthContext`) -> `POST /auth/otp/verify` (+ `PUT /users/me` on Sign-Up) -> `/verification-success` -> target route (default `/`).
- Responsiveness: `SafeArea`, `SingleChildScrollView`, `ConstrainedBox(maxWidth: 440)`, `Wrap` on footer/resend rows to prevent horizontal overflow on narrow screens or large font scales, and `MediaQuery.viewInsets.bottom` padding on modal sheets.
