# Deal One — Authentication Design-to-Implementation Mapping

> **Source of Truth**: Visual inspection of the 7 supplied design screens in `ui/` and `assets/image/logo.png`.

---

## 1. Visual Design System & Tokens

| Token | Value / Spec | Source |
|---|---|---|
| Page Background (Light) | `#F8FAFC` | All 7 PNG screens |
| Card / Input / Sheet Surface | `#FFFFFF` | Input cards, OTP boxes, bottom sheet |
| Soft Pill / Secondary Badge Fill | `#EEF2F7` / `#EBF0F7` | Attempt counter pill, phone pill in sheet |
| Primary Action (Dark Navy) | `#1D2B44` (`AuthDesignTokens.navyPrimary`) | All primary CTA buttons & check emblem |
| Active Focus Accent (Amber/Orange) | `#E68A2E` | Focused OTP box border & cursor (`otp.png`) |
| Error / Destructive Red | `#DC2626` / `#D9534F` | Invalid OTP borders, alert text, icons |
| Error Banner / Card Fill | `#FDECEC` / `#FADBD8` | Error banner & expired floating alert card |
| Success Accent Dot | `#0F766E` / `#16A34A` | Bottom dot in verification success ring |
| Primary Heading Text | `#1E293B` / `#182949` | Screen titles, bold links |
| Body / Muted Copy | `#64748B` | Subtitles, placeholders, legal footer |
| Input / Card Border | `#E2E8F0` (1.0px–1.2px) | Text fields, social buttons, OTP boxes |
| Input & Button Corner Radius | `12px`–`14px` | Primary CTA, text inputs, OTP boxes |
| Floating Card / Sheet Radius | `16px` (alert card), `24px` (top sheet) | Expired card, WhatsApp sheet |
| Subtle Card Shadow | `Color(0x0D0F172A)`, blur `12`, offset `(0, 4)` | Text fields, social buttons, OTP boxes |
| Brand Asset | `assets/image/logo.png` (rendered without enclosing border box) | Handshake + `ديل ون` + `DEAL ONE` |

---

## 2. Screen-by-Screen Mapping

### 2.1 `ui/login.png` — Main Login Screen
- **Widget / Page**: `LoginPage` (`lib/features/auth/presentation/pages/login/login_page.dart`) + `LoginFormCard`
- **Screen Type**: Full-screen route (`/login`, `RouteNames.login`)
- **RTL Layout & Components (Top to Bottom)**:
  1. Optional subtle top bar (back button if `canPop()`, `"تصفح كزائر"` guest action).
  2. Unboxed brand logo (`assets/image/logo.png`, ~92px height).
  3. Title: `"أهلاً بك مجدداً"` (24px ExtraBold, centered).
  4. Subtitle: `"أدخل رقم الواتساب للمتابعة واستكشاف العقارات والمشاريع"` (13.5px muted, centered).
  5. Single white floating phone input (`LoginFormCard` -> `AuthTextField` without external label above box):
     - RTL start (right): WhatsApp/chat-phone icon (`#64748B`) + subtle Egypt `+20` badge/support.
     - Placeholder: `"01XXXXXXXXX"`.
     - Keyboard: `TextInputType.phone`, LTR text entry, Egyptian normalization (`+201XXXXXXXXX`).
  6. Primary Dark Navy CTA (`54px` height, `12px` radius): `"تسجيل الدخول"` (shows spinner during API call).
  7. Horizontal divider with centered label: `"أو المتابعة عبر"`.
  8. Two equal-width white buttons side-by-side (`Row`):
     - `"البريد الإلكتروني"` with Gmail multicolor `M` badge.
     - `"حساب آبل"` with Apple icon.
     - *Behavior*: Backend does not implement Email OTP or Apple OAuth; tapping opens `UnavailableProviderDialog` transparently explaining phone verification is required.
  9. Bottom footer (pushed to bottom on tall viewports, scrollable when keyboard opens):
     - `"ليس لديك حساب؟ "` + underlined bold `"إنشاء حساب الآن"` -> navigates to `RouteNames.signUp`.
     - `"بالمتابعة، فإنك توافق على شروط الخدمة وسياسة الخصوصية."` (tappable Terms / Privacy routes).

### 2.2 `ui/انشاء حساب.png` — Account Creation Screen
- **Widget / Page**: `SignUpPage` (`lib/features/auth/presentation/pages/sign_up/sign_up_page.dart`) + `SignUpFormCard`
- **Screen Type**: Full-screen route (`/sign-up`, `RouteNames.signUp`)
- **RTL Layout & Components (Top to Bottom)**:
  1. Unboxed brand logo (`assets/image/logo.png`).
  2. Title: `"أنشئ حسابك في Deal One"` (23px ExtraBold, centered).
  3. Subtitle: `"ابحث عن عقارك، سيارتك، وصفقاتك في مكان واحد."` (13.5px muted, centered).
  4. Name input (white floating rounded card, no external label):
     - RTL start (right): Person icon (`Icons.person`).
     - Placeholder: `"اكتب اسمك هنا"`.
  5. Phone input (white floating rounded card, no external label):
     - RTL start (right): WhatsApp/chat-phone icon + default `+20` Egyptian validation/normalization.
     - Placeholder: `"01XXXXXXXXX"`.
  6. Helper caption aligned to RTL start (right) below phone field: `"سيتم إرسال رمز التحقق عبر الواتساب"`.
  7. Primary Dark Navy CTA: `"إرسال رمز التحقق"`.
  8. Divider `"أو المتابعة عبر"` + `"البريد الإلكتروني"` and `"حساب آبل"` buttons.
  9. Secondary switch link (`"لديك حساب بالفعل؟ تسجيل الدخول"`) + legal footer `"بالمتابعة، فإنك توافق على شروط الخدمة وسياسة الخصوصية."`.

### 2.3 `ui/otp.png` — OTP Verification Screen (Default State)
- **Widget / Page**: `OtpVerificationPage` (`lib/features/auth/presentation/pages/otp_verification/otp_verification_page.dart`) + `OtpPinBoxes`
- **Screen Type**: Full-screen route (`/otp-verification`, `RouteNames.otpVerification`)
- **Backend Reconciliation Note**:
  - The static mockup shows 4 boxes (`4 أرقام`).
  - The **actual backend** (`VerifyOtpDto` & `OtpService`) strictly generates and requires a **6-digit numeric OTP** (`100000`–`999999`).
  - Per strict backend contract rules, the implementation renders **6 responsive LTR boxes** matching the exact box styling of `otp.png` (white fill, subtle shadow, `12px` radius, amber/orange `#E68A2E` border + vertical cursor `|` on the active box) and states `6 أرقام`.
- **RTL Layout & Components**:
  1. Unboxed brand logo (`assets/image/logo.png`).
  2. Title: `"أدخل رمز التحقق"`.
  3. Subtitle: `"أدخل الرمز المكون من 6 أرقام المرسل إلى [01XXXXXXXXX]"` (displays user's number).
  4. Underlined action row with pencil icon: `"تغيير الرقم"` -> returns to Login/SignUp preserving input.
  5. 6-digit LTR `OtpPinBoxes` with auto-focus, backspace, paste, Arabic-to-Western digit normalization, and `AutofillHints.oneTimeCode`.
  6. Primary Dark Navy CTA: `"تأكيد الرمز"`.
  7. Resend row directly beneath CTA: `"ألم تستلم الرمز؟ "` + `"إرسال مجدداً 0:59"` (live cooldown timer; turns clickable when cooldown hits `0:00`).
  8. Server expiry indicator (subtle caption) & legal footer at bottom.

### 2.4 `ui/لو المستخدم دخل الرمز غلط.png` — Invalid OTP State
- **Screen Type**: In-place state of `OtpVerificationPage` (`OtpStatus.invalid` / `OtpStatus.locked`)
- **Visual Changes**:
  1. All OTP boxes switch to red border (`#DC2626`) and soft error tint.
  2. Full-width soft pink banner (`#FDECEC`) below OTP boxes with filled red `!` circle icon at RTL start and red message: `"رمز التحقق غير صحيح، يرجى التأكد وإعادة المحاولة"` (or locked message when max attempts exceeded).
  3. Centered blue-grey pill (`#EBF0F7`) with lock icon: `"متبقي لك محاولتان (2) فقط قبل القفل المؤقت"` (dynamically computed from `maxAttempts - failedAttempts`, where backend `maxAttempts = 5`).
  4. Primary Dark Navy CTA updates to refresh icon + `"إعادة المحاولة"` (clears invalid digits and focuses input to retry, or requests new code when locked).
  5. Below CTA: `"تواجه مشكلة في تسجيل الدخول؟ تواصل مع الدعم"` with headset icon -> opens `SupportContactSheet` / troubleshooting options.

### 2.5 `ui/لو الكود صلاحيات خلصت .png` — Expired OTP State
- **Screen Type**: Blurred/dimmed overlay state of `OtpVerificationPage` (`OtpStatus.expired`)
- **Visual Components**:
  1. Underlying OTP boxes shown with muted red borders; header/boxes are softly blurred (`BackdropFilter`) and dimmed.
  2. Top floating pink/rose alert card (`#FADBD8`, `16px` radius, shadow):
     - RTL start (right): White circle (`44px`) with red dashed timer icon.
     - Red bold title: `"انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد"`.
     - Red body copy explaining security timeout and immediate code regeneration.
  3. Primary Dark Navy CTA remains crisp and interactive below/above scrim with refresh icon + `"إعادة المحاولة"` (or `"طلب رمز جديد"`), triggering `resendCode()` against `POST /auth/otp/resend` (respecting cooldown if still active).
  4. Support link `"تواجه مشكلة في تسجيل الدخول؟ تواصل مع الدعم"` remains accessible.

### 2.6 `ui/هنا لو المستخدم الرقم مش موجود عليها واتس.png` — Delivery Failure / Not on WhatsApp Bottom Sheet
- **Widget**: `WhatsAppDeliveryFailureSheet` (`lib/features/auth/presentation/widgets/bottom_sheets/whatsapp_delivery_failure_sheet.dart`)
- **Screen Type**: Modal bottom sheet triggered automatically when the backend returns an OTP delivery failure (`AuthErrorKind.whatsappUnavailable` / `AuthErrorKind.otpDeliveryFailed`), or opened from OTP delivery help.
- **Visual Components**:
  1. Top drag handle (`40x4`, `#CBD5E1`).
  2. Soft pink circle (`68px`) with red chat-X icon and dark red circular `×` badge at bottom-right.
  3. Title: `"تعذر الإرسال عبر واتساب"`.
  4. Subtitle: `"عذراً، هذا الرقم غير مسجل على تطبيق واتساب. يرجى استخدام طريقة أخرى"` (or actual backend failure explanation).
  5. Light blue-grey phone pill (`#EEF2F7`): red status dot + LTR formatted phone (`+20 101 903 8129`) + smartphone icon.
  6. Primary Dark Navy CTA with Gmail `M` icon: `"إرسال رسالة عبر البريد الإلكتروني"` (opens `EmailFallbackSheet` which honestly states Email OTP is not supported by the current backend and offers SMS retry if available) + secondary `"إعادة الإرسال عبر رسالة SMS"` action when retrying OTP dispatch.
  7. `"تعديل الرقم"` with pencil icon -> dismisses sheet & returns to edit phone.
  8. `"تحتاج مساعدة في تسجيل الدخول؟"` with headset icon -> opens `SupportContactSheet`.

### 2.7 `ui/لو العملية التحقق نجحت.png` — Successful Verification Screen
- **Widget / Page**: `VerificationSuccessPage` (`lib/features/auth/presentation/pages/verification_success/verification_success_page.dart`)
- **Screen Type**: Full-screen route (`/verification-success`, `RouteNames.verificationSuccess`)
- **Visual Components**:
  1. Top brand wordmark (`ديل ون` / `DEAL ONE`).
  2. Center concentric dashed circular rings (`CustomPaint`), soft white glowing inner circle with dark navy dot at 12 o'clock and teal dot at 6 o'clock, and central dark navy circle (`#1D2B44`) with white checkmark.
  3. Title: `"تم التحقق بنجاح!"`.
  4. Subtitle: `"أصبح حسابك جاهزاً الآن للاستخدام والبحث عن عقارك ومشاريعك."` (and personalized user display when available).
  5. Primary Dark Navy CTA: `"المتابعة لتسجيل الدخول"` -> navigates to authenticated home (`RouteNames.root`) or intended redirect destination.
