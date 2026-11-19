import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Deal One'**
  String get appTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get networkError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected server error occurred. Please try again later.'**
  String get serverError;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'The connection timed out. Please try again.'**
  String get timeoutError;

  /// No description provided for @unauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get unauthorizedError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get unknownError;

  /// No description provided for @emptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'No data available at the moment.'**
  String get emptyStateMessage;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @initializationFailed.
  ///
  /// In en, this message translates to:
  /// **'Application failed to initialize.'**
  String get initializationFailed;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found.'**
  String get pageNotFound;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @timeRemainingText.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get timeRemainingText;

  /// No description provided for @authBrandNameAr.
  ///
  /// In en, this message translates to:
  /// **'Deal One'**
  String get authBrandNameAr;

  /// No description provided for @authBrandNameEn.
  ///
  /// In en, this message translates to:
  /// **'DEAL ONE'**
  String get authBrandNameEn;

  /// No description provided for @authSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get authSkip;

  /// No description provided for @authNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get authNext;

  /// No description provided for @authPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get authPrevious;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// No description provided for @authBrowseAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Browse as guest'**
  String get authBrowseAsGuest;

  /// No description provided for @onboarding1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Real Estate & Cars'**
  String get onboarding1Subtitle;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'A World of Real Estate & Cars in Your Hands'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Desc.
  ///
  /// In en, this message translates to:
  /// **'Discover the latest offers to buy and sell properties, cars, maintenance services, and spare parts with ease.'**
  String get onboarding1Desc;

  /// No description provided for @onboarding2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Home Services & Materials'**
  String get onboarding2Subtitle;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Finishing & Home Services Near You'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Desc.
  ///
  /// In en, this message translates to:
  /// **'Connect with engineering offices and order building materials and electrical supplies from the nearest suppliers and technicians.'**
  String get onboarding2Desc;

  /// No description provided for @onboarding3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Fashion, Decor & Appliances'**
  String get onboarding3Subtitle;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Your Style & Home Decor with Direct Contact'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Desc.
  ///
  /// In en, this message translates to:
  /// **'Browse the latest fashion trends, decor pieces, and home appliances, and connect directly with sellers to close your deals safely and easily.'**
  String get onboarding3Desc;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your WhatsApp number to continue and explore real estate and purchases'**
  String get loginSubtitle;

  /// No description provided for @loginSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginSubmitButton;

  /// No description provided for @loginNoAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get loginNoAccountPrompt;

  /// No description provided for @loginCreateAccountLink.
  ///
  /// In en, this message translates to:
  /// **'Create an account now'**
  String get loginCreateAccountLink;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your Deal One account'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find your property, car, and deals all in one place.'**
  String get signUpSubtitle;

  /// No description provided for @signUpFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name here'**
  String get signUpFullNameHint;

  /// No description provided for @signUpPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'01XXXXXXXXX'**
  String get signUpPhoneHint;

  /// No description provided for @signUpWhatsAppHelper.
  ///
  /// In en, this message translates to:
  /// **'A verification code will be sent via WhatsApp'**
  String get signUpWhatsAppHelper;

  /// No description provided for @signUpSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get signUpSubmitButton;

  /// No description provided for @signUpHaveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get signUpHaveAccountPrompt;

  /// No description provided for @signUpLoginLink.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get signUpLoginLink;

  /// No description provided for @authOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get authOrContinueWith;

  /// No description provided for @authEmailProvider.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailProvider;

  /// No description provided for @authAppleProvider.
  ///
  /// In en, this message translates to:
  /// **'Apple ID'**
  String get authAppleProvider;

  /// No description provided for @authLegalPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to the '**
  String get authLegalPrefix;

  /// No description provided for @authTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get authTermsOfService;

  /// No description provided for @authLegalAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get authLegalAnd;

  /// No description provided for @authPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyPolicy;

  /// No description provided for @authLegalSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get authLegalSuffix;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to\n[{phone}] via WhatsApp'**
  String otpSubtitle(String phone);

  /// No description provided for @otpChangePhone.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get otpChangePhone;

  /// No description provided for @otpVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Code'**
  String get otpVerifyButton;

  /// No description provided for @otpRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get otpRetryButton;

  /// No description provided for @otpRetryWithCooldown.
  ///
  /// In en, this message translates to:
  /// **'Try Again ({cooldown})'**
  String otpRetryWithCooldown(String cooldown);

  /// No description provided for @otpResendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Sending new code...'**
  String get otpResendingLabel;

  /// No description provided for @otpDidNotReceive.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code? '**
  String get otpDidNotReceive;

  /// No description provided for @otpResendCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend {cooldown}'**
  String otpResendCountdown(String cooldown);

  /// No description provided for @otpResendNow.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get otpResendNow;

  /// No description provided for @otpResendSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get otpResendSending;

  /// No description provided for @otpCodeExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Code expires in: {expiry}'**
  String otpCodeExpiryLabel(String expiry);

  /// No description provided for @otpWhatsAppHelpLink.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code on WhatsApp?'**
  String get otpWhatsAppHelpLink;

  /// No description provided for @otpSupportLink.
  ///
  /// In en, this message translates to:
  /// **'Having trouble logging in? Contact Support'**
  String get otpSupportLink;

  /// No description provided for @otpRequestNewIn.
  ///
  /// In en, this message translates to:
  /// **'Send new code in {cooldown}'**
  String otpRequestNewIn(String cooldown);

  /// No description provided for @otpRequestNewCode.
  ///
  /// In en, this message translates to:
  /// **'Request new verification code'**
  String get otpRequestNewCode;

  /// No description provided for @otpResentSuccess.
  ///
  /// In en, this message translates to:
  /// **'A new verification code has been sent'**
  String get otpResentSuccess;

  /// No description provided for @otpWaitBeforeResend.
  ///
  /// In en, this message translates to:
  /// **'Please wait {cooldown} before requesting a new code'**
  String otpWaitBeforeResend(String cooldown);

  /// No description provided for @otpWaitBeforeSms.
  ///
  /// In en, this message translates to:
  /// **'Please wait {cooldown} before resending via SMS'**
  String otpWaitBeforeSms(String cooldown);

  /// No description provided for @otpNoActiveSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'No Active Verification Session'**
  String get otpNoActiveSessionTitle;

  /// No description provided for @otpNoActiveSessionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number first to receive a verification code.'**
  String get otpNoActiveSessionSubtitle;

  /// No description provided for @otpBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get otpBackToLogin;

  /// No description provided for @otpSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code input field for {length} digits'**
  String otpSemanticsLabel(int length);

  /// No description provided for @otpRemainingAttemptOne.
  ///
  /// In en, this message translates to:
  /// **'You have 1 attempt left before temporary lock'**
  String get otpRemainingAttemptOne;

  /// No description provided for @otpRemainingAttemptTwo.
  ///
  /// In en, this message translates to:
  /// **'You have 2 attempts left before temporary lock'**
  String get otpRemainingAttemptTwo;

  /// No description provided for @otpRemainingAttemptsMany.
  ///
  /// In en, this message translates to:
  /// **'You have {count} attempts left before temporary lock'**
  String otpRemainingAttemptsMany(int count);

  /// No description provided for @otpExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification code expired, please request a new code'**
  String get otpExpiredTitle;

  /// No description provided for @otpExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'The security time limit has elapsed to protect your account and transactions. You can generate an instant new code and continue verifying.'**
  String get otpExpiredBody;

  /// No description provided for @whatsappSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to Send via WhatsApp'**
  String get whatsappSheetTitle;

  /// No description provided for @whatsappSheetDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sorry, this number is not registered on WhatsApp. Please use another method'**
  String get whatsappSheetDefaultSubtitle;

  /// No description provided for @whatsappSheetEmailCta.
  ///
  /// In en, this message translates to:
  /// **'Send message via Email'**
  String get whatsappSheetEmailCta;

  /// No description provided for @whatsappSheetSmsCta.
  ///
  /// In en, this message translates to:
  /// **'Resend via SMS'**
  String get whatsappSheetSmsCta;

  /// No description provided for @whatsappSheetEditPhone.
  ///
  /// In en, this message translates to:
  /// **'Edit Number'**
  String get whatsappSheetEditPhone;

  /// No description provided for @whatsappSheetNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help logging in?'**
  String get whatsappSheetNeedHelp;

  /// No description provided for @emailFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailFallbackTitle;

  /// No description provided for @emailFallbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address to check alternative code delivery availability.'**
  String get emailFallbackSubtitle;

  /// No description provided for @emailFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailFallbackLabel;

  /// No description provided for @emailFallbackHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailFallbackHint;

  /// No description provided for @emailFallbackSubmit.
  ///
  /// In en, this message translates to:
  /// **'Check Email Delivery'**
  String get emailFallbackSubmit;

  /// No description provided for @emailFallbackUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Email OTP delivery is not currently available on the server. Please complete verification via SMS on your Egyptian mobile number (+20).'**
  String get emailFallbackUnsupported;

  /// No description provided for @supportSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical Support - Deal One'**
  String get supportSheetTitle;

  /// No description provided for @supportSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If you repeatedly face issues receiving your verification code, contact our support team or copy the contact details below:'**
  String get supportSheetSubtitle;

  /// No description provided for @supportEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Support Email'**
  String get supportEmailTitle;

  /// No description provided for @supportHotlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Service'**
  String get supportHotlineTitle;

  /// No description provided for @supportCopyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get supportCopyTooltip;

  /// No description provided for @supportCopiedSnack.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String supportCopiedSnack(String label);

  /// No description provided for @unavailableProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with {provider} is currently unavailable'**
  String unavailableProviderTitle(String provider);

  /// No description provided for @unavailableProviderBody.
  ///
  /// In en, this message translates to:
  /// **'Deal One currently supports secure registration and verification via Egyptian mobile number and one-time password (OTP). Please enter your phone number to continue.'**
  String get unavailableProviderBody;

  /// No description provided for @unavailableProviderCta.
  ///
  /// In en, this message translates to:
  /// **'Got it, continue with phone'**
  String get unavailableProviderCta;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified Successfully!'**
  String get successTitle;

  /// No description provided for @successSubtitleDefault.
  ///
  /// In en, this message translates to:
  /// **'Your account is now ready to use and search for your property and purchases.'**
  String get successSubtitleDefault;

  /// No description provided for @successSubtitlePersonalized.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}\nYour account is now ready to use and search for your property and purchases.'**
  String successSubtitlePersonalized(String name);

  /// No description provided for @successContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to Login'**
  String get successContinueButton;

  /// No description provided for @valFullNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get valFullNameEmpty;

  /// No description provided for @valFullNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Full name must be at least 2 characters'**
  String get valFullNameTooShort;

  /// No description provided for @valFullNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Full name is too long'**
  String get valFullNameTooLong;

  /// No description provided for @valFullNameNoLetters.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid name containing letters'**
  String get valFullNameNoLetters;

  /// No description provided for @valPhoneEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get valPhoneEmpty;

  /// No description provided for @valPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Egyptian mobile number (e.g. 01012345678)'**
  String get valPhoneInvalid;

  /// No description provided for @valEmailEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get valEmailEmpty;

  /// No description provided for @valEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address format'**
  String get valEmailInvalid;

  /// No description provided for @valOtpEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code'**
  String get valOtpEmpty;

  /// No description provided for @valOtpLength.
  ///
  /// In en, this message translates to:
  /// **'Please enter the {length}-digit verification code'**
  String valOtpLength(int length);

  /// No description provided for @valOtpDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'Verification code must contain digits only'**
  String get valOtpDigitsOnly;

  /// No description provided for @errAuthNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network and try again.'**
  String get errAuthNetwork;

  /// No description provided for @errAuthTimeout.
  ///
  /// In en, this message translates to:
  /// **'Server connection timed out. Please try again.'**
  String get errAuthTimeout;

  /// No description provided for @errAuthUnexpectedResponse.
  ///
  /// In en, this message translates to:
  /// **'Received an unexpected response from the server. Please try again later.'**
  String get errAuthUnexpectedResponse;

  /// No description provided for @errAuthWhatsappUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sorry, this number is not registered on WhatsApp. Please use another method.'**
  String get errAuthWhatsappUnavailable;

  /// No description provided for @errAuthOtpDeliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to send the verification code right now. Please verify the number or try again later.'**
  String get errAuthOtpDeliveryFailed;

  /// No description provided for @errAuthMaxAttempts.
  ///
  /// In en, this message translates to:
  /// **'Maximum verification attempts exceeded (5 attempts). Please request a new code.'**
  String get errAuthMaxAttempts;

  /// No description provided for @errAuthOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'Verification code expired, please request a new code'**
  String get errAuthOtpExpired;

  /// No description provided for @errAuthOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Incorrect verification code, please check and try again'**
  String get errAuthOtpInvalid;

  /// No description provided for @errAuthInvalidRefresh.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get errAuthInvalidRefresh;

  /// No description provided for @errAuthRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many recent requests. Please wait for the countdown before requesting a new code.'**
  String get errAuthRateLimited;

  /// No description provided for @errAuthAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found associated with this number.'**
  String get errAuthAccountNotFound;

  /// No description provided for @errAuthExistingAccount.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already registered. You can log in directly.'**
  String get errAuthExistingAccount;

  /// No description provided for @errAuthValidation.
  ///
  /// In en, this message translates to:
  /// **'Please review your entered details and try again.'**
  String get errAuthValidation;

  /// No description provided for @errAuthUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'This account is not authorized to sign in right now. Contact support.'**
  String get errAuthUnauthorized;

  /// No description provided for @errAuthServer.
  ///
  /// In en, this message translates to:
  /// **'An unexpected server error occurred. Please try again later.'**
  String get errAuthServer;

  /// No description provided for @legalTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get legalTermsTitle;

  /// No description provided for @legalPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacyTitle;

  /// No description provided for @legalTermsSec1Heading.
  ///
  /// In en, this message translates to:
  /// **'1. Using Deal One'**
  String get legalTermsSec1Heading;

  /// No description provided for @legalTermsSec1Body.
  ///
  /// In en, this message translates to:
  /// **'By using Deal One, you agree to publish accurate listings compliant with Egyptian laws and never impersonate others or provide misleading information.'**
  String get legalTermsSec1Body;

  /// No description provided for @legalTermsSec2Heading.
  ///
  /// In en, this message translates to:
  /// **'2. Account & Phone Verification'**
  String get legalTermsSec2Heading;

  /// No description provided for @legalTermsSec2Body.
  ///
  /// In en, this message translates to:
  /// **'Accounts are verified with an active Egyptian mobile number via one-time password (OTP). You are responsible for keeping your session and OTP codes confidential.'**
  String get legalTermsSec2Body;

  /// No description provided for @legalTermsSec3Heading.
  ///
  /// In en, this message translates to:
  /// **'3. Transactions Between Users'**
  String get legalTermsSec3Heading;

  /// No description provided for @legalTermsSec3Body.
  ///
  /// In en, this message translates to:
  /// **'Deal One connects buyers and sellers. Please inspect items carefully and verify ownership documents before completing any financial transaction.'**
  String get legalTermsSec3Body;

  /// No description provided for @legalPrivacySec1Heading.
  ///
  /// In en, this message translates to:
  /// **'1. Data We Collect'**
  String get legalPrivacySec1Heading;

  /// No description provided for @legalPrivacySec1Body.
  ///
  /// In en, this message translates to:
  /// **'We collect only your full name, Egyptian mobile number, and listing details to activate your account and enable trusted communication.'**
  String get legalPrivacySec1Body;

  /// No description provided for @legalPrivacySec2Heading.
  ///
  /// In en, this message translates to:
  /// **'2. Token & Session Security'**
  String get legalPrivacySec2Heading;

  /// No description provided for @legalPrivacySec2Body.
  ///
  /// In en, this message translates to:
  /// **'Session tokens (JWT Access & Refresh Tokens) are stored inside encrypted device storage and are never shared with third parties for marketing.'**
  String get legalPrivacySec2Body;

  /// No description provided for @legalPrivacySec3Heading.
  ///
  /// In en, this message translates to:
  /// **'3. Your Account Rights'**
  String get legalPrivacySec3Heading;

  /// No description provided for @legalPrivacySec3Body.
  ///
  /// In en, this message translates to:
  /// **'You may update your name, terminate all active sessions, or request account deletion at any time through account settings or technical support.'**
  String get legalPrivacySec3Body;

  /// No description provided for @profileTitleGuest.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get profileTitleGuest;

  /// No description provided for @profileTitleAuth.
  ///
  /// In en, this message translates to:
  /// **'My Account & Profile'**
  String get profileTitleAuth;

  /// No description provided for @profileGuestPrompt.
  ///
  /// In en, this message translates to:
  /// **'Log in to access your listings and connect with sellers'**
  String get profileGuestPrompt;

  /// No description provided for @profileLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in with Phone Number'**
  String get profileLoginButton;

  /// No description provided for @profileRegisteredUser.
  ///
  /// In en, this message translates to:
  /// **'Registered User'**
  String get profileRegisteredUser;

  /// No description provided for @profileIdAvailable.
  ///
  /// In en, this message translates to:
  /// **'ID available'**
  String get profileIdAvailable;

  /// No description provided for @profileDailyQuotaTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Contact Quota (Cairo Time)'**
  String get profileDailyQuotaTitle;

  /// No description provided for @profileQuotaRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining today: {remaining} of {limit} phone reveals'**
  String profileQuotaRemaining(int remaining, int limit);

  /// No description provided for @profileQuotaResetNote.
  ///
  /// In en, this message translates to:
  /// **'Quota resets automatically at midnight Cairo time.'**
  String get profileQuotaResetNote;

  /// No description provided for @profileQuotaLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load daily quota details'**
  String get profileQuotaLoadError;

  /// No description provided for @profileAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Seller & Showroom Accounts'**
  String get profileAccountsTitle;

  /// No description provided for @profileNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No additional showroom accounts'**
  String get profileNoAccounts;

  /// No description provided for @profileAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Role: {role} • {status}'**
  String profileAccountSubtitle(String role, String status);

  /// No description provided for @profileStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileStatusVerified;

  /// No description provided for @profileStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get profileStatusPending;

  /// No description provided for @profileAccountsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load accounts'**
  String get profileAccountsLoadError;

  /// No description provided for @profileThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'App Appearance'**
  String get profileThemeTitle;

  /// No description provided for @profileThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get profileThemeSystem;

  /// No description provided for @profileThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get profileThemeLight;

  /// No description provided for @profileThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get profileThemeDark;

  /// No description provided for @profileLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get profileLanguageTitle;

  /// No description provided for @profileLanguageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get profileLanguageArabic;

  /// No description provided for @profileLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get profileLanguageEnglish;

  /// No description provided for @profileLogoutButton.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profileLogoutButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
