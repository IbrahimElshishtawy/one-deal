// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Deal One';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get networkError =>
      'No internet connection. Please check your network.';

  @override
  String get serverError =>
      'An unexpected server error occurred. Please try again later.';

  @override
  String get timeoutError => 'The connection timed out. Please try again.';

  @override
  String get unauthorizedError =>
      'Your session has expired. Please log in again.';

  @override
  String get unknownError => 'Something went wrong. Please try again.';

  @override
  String get emptyStateMessage => 'No data available at the moment.';

  @override
  String get loading => 'Loading...';

  @override
  String get initializationFailed => 'Application failed to initialize.';

  @override
  String get pageNotFound => 'Page not found.';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get timeRemainingText => 'Time remaining';

  @override
  String get authBrandNameAr => 'Deal One';

  @override
  String get authBrandNameEn => 'DEAL ONE';

  @override
  String get authSkip => 'Skip';

  @override
  String get authNext => 'Next';

  @override
  String get authPrevious => 'Previous';

  @override
  String get authCreateAccount => 'Create Account';

  @override
  String get authBrowseAsGuest => 'Browse as guest';

  @override
  String get onboarding1Subtitle => 'Real Estate & Cars';

  @override
  String get onboarding1Title => 'A World of Real Estate & Cars in Your Hands';

  @override
  String get onboarding1Desc =>
      'Discover the latest offers to buy and sell properties, cars, maintenance services, and spare parts with ease.';

  @override
  String get onboarding2Subtitle => 'Home Services & Materials';

  @override
  String get onboarding2Title => 'Finishing & Home Services Near You';

  @override
  String get onboarding2Desc =>
      'Connect with engineering offices and order building materials and electrical supplies from the nearest suppliers and technicians.';

  @override
  String get onboarding3Subtitle => 'Fashion, Decor & Appliances';

  @override
  String get onboarding3Title => 'Your Style & Home Decor with Direct Contact';

  @override
  String get onboarding3Desc =>
      'Browse the latest fashion trends, decor pieces, and home appliances, and connect directly with sellers to close your deals safely and easily.';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle =>
      'Enter your WhatsApp number to continue and explore real estate and purchases';

  @override
  String get loginSubmitButton => 'Log In';

  @override
  String get loginNoAccountPrompt => 'Don\'t have an account? ';

  @override
  String get loginCreateAccountLink => 'Create an account now';

  @override
  String get signUpTitle => 'Create your Deal One account';

  @override
  String get signUpSubtitle =>
      'Find your property, car, and deals all in one place.';

  @override
  String get signUpFullNameHint => 'Enter your name here';

  @override
  String get signUpPhoneHint => '01XXXXXXXXX';

  @override
  String get signUpWhatsAppHelper =>
      'A verification code will be sent via WhatsApp';

  @override
  String get signUpSubmitButton => 'Send Verification Code';

  @override
  String get signUpHaveAccountPrompt => 'Already have an account? ';

  @override
  String get signUpLoginLink => 'Log In';

  @override
  String get authOrContinueWith => 'Or continue with';

  @override
  String get authEmailProvider => 'Email';

  @override
  String get authAppleProvider => 'Apple ID';

  @override
  String get authLegalPrefix => 'By continuing, you agree to the ';

  @override
  String get authTermsOfService => 'Terms of Service';

  @override
  String get authLegalAnd => ' and ';

  @override
  String get authPrivacyPolicy => 'Privacy Policy';

  @override
  String get authLegalSuffix => '.';

  @override
  String get otpTitle => 'Enter Verification Code';

  @override
  String otpSubtitle(String phone) {
    return 'Enter the 6-digit code sent to\n[$phone] via WhatsApp';
  }

  @override
  String get otpChangePhone => 'Change number';

  @override
  String get otpVerifyButton => 'Confirm Code';

  @override
  String get otpRetryButton => 'Try Again';

  @override
  String otpRetryWithCooldown(String cooldown) {
    return 'Try Again ($cooldown)';
  }

  @override
  String get otpResendingLabel => 'Sending new code...';

  @override
  String get otpDidNotReceive => 'Didn\'t receive the code? ';

  @override
  String otpResendCountdown(String cooldown) {
    return 'Resend $cooldown';
  }

  @override
  String get otpResendNow => 'Resend';

  @override
  String get otpResendSending => 'Sending...';

  @override
  String otpCodeExpiryLabel(String expiry) {
    return 'Code expires in: $expiry';
  }

  @override
  String get otpWhatsAppHelpLink => 'Didn\'t receive the code on WhatsApp?';

  @override
  String get otpSupportLink => 'Having trouble logging in? Contact Support';

  @override
  String otpRequestNewIn(String cooldown) {
    return 'Send new code in $cooldown';
  }

  @override
  String get otpRequestNewCode => 'Request new verification code';

  @override
  String get otpResentSuccess => 'A new verification code has been sent';

  @override
  String otpWaitBeforeResend(String cooldown) {
    return 'Please wait $cooldown before requesting a new code';
  }

  @override
  String otpWaitBeforeSms(String cooldown) {
    return 'Please wait $cooldown before resending via SMS';
  }

  @override
  String get otpNoActiveSessionTitle => 'No Active Verification Session';

  @override
  String get otpNoActiveSessionSubtitle =>
      'Please enter your phone number first to receive a verification code.';

  @override
  String get otpBackToLogin => 'Back to Login';

  @override
  String otpSemanticsLabel(int length) {
    return 'Verification code input field for $length digits';
  }

  @override
  String get otpRemainingAttemptOne =>
      'You have 1 attempt left before temporary lock';

  @override
  String get otpRemainingAttemptTwo =>
      'You have 2 attempts left before temporary lock';

  @override
  String otpRemainingAttemptsMany(int count) {
    return 'You have $count attempts left before temporary lock';
  }

  @override
  String get otpExpiredTitle =>
      'Verification code expired, please request a new code';

  @override
  String get otpExpiredBody =>
      'The security time limit has elapsed to protect your account and transactions. You can generate an instant new code and continue verifying.';

  @override
  String get whatsappSheetTitle => 'Unable to Send via WhatsApp';

  @override
  String get whatsappSheetDefaultSubtitle =>
      'Sorry, this number is not registered on WhatsApp. Please use another method';

  @override
  String get whatsappSheetEmailCta => 'Send message via Email';

  @override
  String get whatsappSheetSmsCta => 'Resend via SMS';

  @override
  String get whatsappSheetEditPhone => 'Edit Number';

  @override
  String get whatsappSheetNeedHelp => 'Need help logging in?';

  @override
  String get emailFallbackTitle => 'Email Verification';

  @override
  String get emailFallbackSubtitle =>
      'Enter your email address to check alternative code delivery availability.';

  @override
  String get emailFallbackLabel => 'Email Address';

  @override
  String get emailFallbackHint => 'name@example.com';

  @override
  String get emailFallbackSubmit => 'Check Email Delivery';

  @override
  String get emailFallbackUnsupported =>
      'Email OTP delivery is not currently available on the server. Please complete verification via SMS on your Egyptian mobile number (+20).';

  @override
  String get supportSheetTitle => 'Technical Support - Deal One';

  @override
  String get supportSheetSubtitle =>
      'If you repeatedly face issues receiving your verification code, contact our support team or copy the contact details below:';

  @override
  String get supportEmailTitle => 'Support Email';

  @override
  String get supportHotlineTitle => 'Customer Service';

  @override
  String get supportCopyTooltip => 'Copy';

  @override
  String supportCopiedSnack(String label) {
    return '$label copied';
  }

  @override
  String unavailableProviderTitle(String provider) {
    return 'Sign in with $provider is currently unavailable';
  }

  @override
  String get unavailableProviderBody =>
      'Deal One currently supports secure registration and verification via Egyptian mobile number and one-time password (OTP). Please enter your phone number to continue.';

  @override
  String get unavailableProviderCta => 'Got it, continue with phone';

  @override
  String get successTitle => 'Verified Successfully!';

  @override
  String get successSubtitleDefault =>
      'Your account is now ready to use and search for your property and purchases.';

  @override
  String successSubtitlePersonalized(String name) {
    return 'Welcome, $name\nYour account is now ready to use and search for your property and purchases.';
  }

  @override
  String get successContinueButton => 'Continue to Login';

  @override
  String get valFullNameEmpty => 'Please enter your full name';

  @override
  String get valFullNameTooShort => 'Full name must be at least 2 characters';

  @override
  String get valFullNameTooLong => 'Full name is too long';

  @override
  String get valFullNameNoLetters =>
      'Please enter a valid name containing letters';

  @override
  String get valPhoneEmpty => 'Please enter your phone number';

  @override
  String get valPhoneInvalid =>
      'Enter a valid Egyptian mobile number (e.g. 01012345678)';

  @override
  String get valEmailEmpty => 'Please enter your email address';

  @override
  String get valEmailInvalid => 'Invalid email address format';

  @override
  String get valOtpEmpty => 'Please enter the verification code';

  @override
  String valOtpLength(int length) {
    return 'Please enter the $length-digit verification code';
  }

  @override
  String get valOtpDigitsOnly => 'Verification code must contain digits only';

  @override
  String get errAuthNetwork =>
      'No internet connection. Please check your network and try again.';

  @override
  String get errAuthTimeout => 'Server connection timed out. Please try again.';

  @override
  String get errAuthUnexpectedResponse =>
      'Received an unexpected response from the server. Please try again later.';

  @override
  String get errAuthWhatsappUnavailable =>
      'Sorry, this number is not registered on WhatsApp. Please use another method.';

  @override
  String get errAuthOtpDeliveryFailed =>
      'Unable to send the verification code right now. Please verify the number or try again later.';

  @override
  String get errAuthMaxAttempts =>
      'Maximum verification attempts exceeded (5 attempts). Please request a new code.';

  @override
  String get errAuthOtpExpired =>
      'Verification code expired, please request a new code';

  @override
  String get errAuthOtpInvalid =>
      'Incorrect verification code, please check and try again';

  @override
  String get errAuthInvalidRefresh =>
      'Your session has expired. Please log in again.';

  @override
  String get errAuthRateLimited =>
      'Too many recent requests. Please wait for the countdown before requesting a new code.';

  @override
  String get errAuthAccountNotFound =>
      'No account found associated with this number.';

  @override
  String get errAuthExistingAccount =>
      'This phone number is already registered. You can log in directly.';

  @override
  String get errAuthValidation =>
      'Please review your entered details and try again.';

  @override
  String get errAuthUnauthorized =>
      'This account is not authorized to sign in right now. Contact support.';

  @override
  String get errAuthServer =>
      'An unexpected server error occurred. Please try again later.';

  @override
  String get legalTermsTitle => 'Terms of Service';

  @override
  String get legalPrivacyTitle => 'Privacy Policy';

  @override
  String get legalTermsSec1Heading => '1. Using Deal One';

  @override
  String get legalTermsSec1Body =>
      'By using Deal One, you agree to publish accurate listings compliant with Egyptian laws and never impersonate others or provide misleading information.';

  @override
  String get legalTermsSec2Heading => '2. Account & Phone Verification';

  @override
  String get legalTermsSec2Body =>
      'Accounts are verified with an active Egyptian mobile number via one-time password (OTP). You are responsible for keeping your session and OTP codes confidential.';

  @override
  String get legalTermsSec3Heading => '3. Transactions Between Users';

  @override
  String get legalTermsSec3Body =>
      'Deal One connects buyers and sellers. Please inspect items carefully and verify ownership documents before completing any financial transaction.';

  @override
  String get legalPrivacySec1Heading => '1. Data We Collect';

  @override
  String get legalPrivacySec1Body =>
      'We collect only your full name, Egyptian mobile number, and listing details to activate your account and enable trusted communication.';

  @override
  String get legalPrivacySec2Heading => '2. Token & Session Security';

  @override
  String get legalPrivacySec2Body =>
      'Session tokens (JWT Access & Refresh Tokens) are stored inside encrypted device storage and are never shared with third parties for marketing.';

  @override
  String get legalPrivacySec3Heading => '3. Your Account Rights';

  @override
  String get legalPrivacySec3Body =>
      'You may update your name, terminate all active sessions, or request account deletion at any time through account settings or technical support.';

  @override
  String get profileTitleGuest => 'My Account';

  @override
  String get profileTitleAuth => 'My Account & Profile';

  @override
  String get profileGuestPrompt =>
      'Log in to access your listings and connect with sellers';

  @override
  String get profileLoginButton => 'Log in with Phone Number';

  @override
  String get profileRegisteredUser => 'Registered User';

  @override
  String get profileIdAvailable => 'ID available';

  @override
  String get profileDailyQuotaTitle => 'Daily Contact Quota (Cairo Time)';

  @override
  String profileQuotaRemaining(int remaining, int limit) {
    return 'Remaining today: $remaining of $limit phone reveals';
  }

  @override
  String get profileQuotaResetNote =>
      'Quota resets automatically at midnight Cairo time.';

  @override
  String get profileQuotaLoadError => 'Unable to load daily quota details';

  @override
  String get profileAccountsTitle => 'Seller & Showroom Accounts';

  @override
  String get profileNoAccounts => 'No additional showroom accounts';

  @override
  String profileAccountSubtitle(String role, String status) {
    return 'Role: $role • $status';
  }

  @override
  String get profileStatusVerified => 'Verified';

  @override
  String get profileStatusPending => 'Under Review';

  @override
  String get profileAccountsLoadError => 'Unable to load accounts';

  @override
  String get profileThemeTitle => 'App Appearance';

  @override
  String get profileThemeSystem => 'System';

  @override
  String get profileThemeLight => 'Light';

  @override
  String get profileThemeDark => 'Dark';

  @override
  String get profileLanguageTitle => 'App Language';

  @override
  String get profileLanguageArabic => 'العربية';

  @override
  String get profileLanguageEnglish => 'English';

  @override
  String get profileLogoutButton => 'Log Out';
}
