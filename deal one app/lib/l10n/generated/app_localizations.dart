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
  /// **'DealOne'**
  String get appTitle;

  /// No description provided for @brandNameAr.
  ///
  /// In en, this message translates to:
  /// **'DealOne'**
  String get brandNameAr;

  /// No description provided for @brandNameEn.
  ///
  /// In en, this message translates to:
  /// **'DealOne'**
  String get brandNameEn;

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

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copiedItem.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String copiedItem(String label);

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

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get onboardingCreateAccount;

  /// No description provided for @onboardingBrowseGuest.
  ///
  /// In en, this message translates to:
  /// **'Browse as Guest'**
  String get onboardingBrowseGuest;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'A World of Real Estate & Cars in Your Hands'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Description.
  ///
  /// In en, this message translates to:
  /// **'Discover the latest offers to buy and sell properties, cars, maintenance services, and spare parts with ease.'**
  String get onboardingSlide1Description;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Finishing & Home Services Near You'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Description.
  ///
  /// In en, this message translates to:
  /// **'Connect with engineering offices and order construction materials and electrical supplies from the nearest suppliers and technicians.'**
  String get onboardingSlide2Description;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Your Style & Home Decor with Direct Contact'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Description.
  ///
  /// In en, this message translates to:
  /// **'Browse the latest fashion trends, decor pieces, and home appliances, and contact sellers directly to complete your deals safely and easily.'**
  String get onboardingSlide3Description;

  /// No description provided for @authBrowseAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Browse as Guest'**
  String get authBrowseAsGuest;

  /// No description provided for @authOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get authOrContinueWith;

  /// No description provided for @authProviderEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authProviderEmail;

  /// No description provided for @authProviderApple.
  ///
  /// In en, this message translates to:
  /// **'Apple Account'**
  String get authProviderApple;

  /// No description provided for @authLegalPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get authLegalPrefix;

  /// No description provided for @authLegalTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get authLegalTerms;

  /// No description provided for @authLegalAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get authLegalAnd;

  /// No description provided for @authLegalPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authLegalPrivacy;

  /// No description provided for @authLegalSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get authLegalSuffix;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your Deal One account'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find your property, car, and deals in one place.'**
  String get signUpSubtitle;

  /// No description provided for @signUpNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name here'**
  String get signUpNameHint;

  /// No description provided for @signUpPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'01XXXXXXXXX'**
  String get signUpPhoneHint;

  /// No description provided for @signUpWhatsappNote.
  ///
  /// In en, this message translates to:
  /// **'A verification code will be sent via WhatsApp'**
  String get signUpWhatsappNote;

  /// No description provided for @signUpSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get signUpSubmitButton;

  /// No description provided for @signUpAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get signUpAlreadyHaveAccount;

  /// No description provided for @signUpGoToLogin.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get signUpGoToLogin;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your WhatsApp number to continue exploring properties and purchases'**
  String get loginSubtitle;

  /// No description provided for @loginSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginSubmitButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get loginNoAccount;

  /// No description provided for @loginCreateAccountNow.
  ///
  /// In en, this message translates to:
  /// **'Create Account Now'**
  String get loginCreateAccountNow;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the {length}-digit code sent to\n[{phone}] via WhatsApp'**
  String otpSubtitle(int length, String phone);

  /// No description provided for @otpChangePhone.
  ///
  /// In en, this message translates to:
  /// **'Change Number'**
  String get otpChangePhone;

  /// No description provided for @otpVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
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
  /// **'Sending a new code...'**
  String get otpResendingLabel;

  /// No description provided for @otpDidNotReceive.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code? '**
  String get otpDidNotReceive;

  /// No description provided for @otpResendAgain.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get otpResendAgain;

  /// No description provided for @otpResendCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend {cooldown}'**
  String otpResendCountdown(String cooldown);

  /// No description provided for @otpSendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get otpSendingLabel;

  /// No description provided for @otpExpiryRemaining.
  ///
  /// In en, this message translates to:
  /// **'Code expires in: {time}'**
  String otpExpiryRemaining(String time);

  /// No description provided for @otpWhatsappHelp.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code via WhatsApp?'**
  String get otpWhatsappHelp;

  /// No description provided for @otpSupportPrompt.
  ///
  /// In en, this message translates to:
  /// **'Having trouble logging in? Contact Support'**
  String get otpSupportPrompt;

  /// No description provided for @otpResendInCooldown.
  ///
  /// In en, this message translates to:
  /// **'Send new code in {cooldown}'**
  String otpResendInCooldown(String cooldown);

  /// No description provided for @otpRequestNewCode.
  ///
  /// In en, this message translates to:
  /// **'Request a new verification code'**
  String get otpRequestNewCode;

  /// No description provided for @otpResentSuccess.
  ///
  /// In en, this message translates to:
  /// **'A new verification code has been sent'**
  String get otpResentSuccess;

  /// No description provided for @otpWaitCooldownSms.
  ///
  /// In en, this message translates to:
  /// **'Please wait {cooldown} before resending via SMS'**
  String otpWaitCooldownSms(String cooldown);

  /// No description provided for @otpWaitCooldownNewCode.
  ///
  /// In en, this message translates to:
  /// **'Please wait {cooldown} before requesting a new code'**
  String otpWaitCooldownNewCode(String cooldown);

  /// No description provided for @otpSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'{length}-digit verification code input'**
  String otpSemanticsLabel(int length);

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
  /// **'Back to Log In'**
  String get otpBackToLogin;

  /// No description provided for @otpRemainingAttemptsOne.
  ///
  /// In en, this message translates to:
  /// **'You have only 1 attempt remaining before temporary lockout'**
  String get otpRemainingAttemptsOne;

  /// No description provided for @otpRemainingAttemptsTwo.
  ///
  /// In en, this message translates to:
  /// **'You have only 2 attempts remaining before temporary lockout'**
  String get otpRemainingAttemptsTwo;

  /// No description provided for @otpRemainingAttemptsMany.
  ///
  /// In en, this message translates to:
  /// **'You have {count} attempts remaining before temporary lockout'**
  String otpRemainingAttemptsMany(int count);

  /// No description provided for @otpExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification code expired, please request a new code'**
  String get otpExpiredTitle;

  /// No description provided for @otpExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'The security timeout has elapsed to protect your account and transactions. You can generate a new code immediately and continue verification.'**
  String get otpExpiredBody;

  /// No description provided for @whatsappFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to Send via WhatsApp'**
  String get whatsappFailureTitle;

  /// No description provided for @whatsappFailureDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sorry, this number is not registered on WhatsApp. Please use another method.'**
  String get whatsappFailureDefaultSubtitle;

  /// No description provided for @whatsappFailureSendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send via Email'**
  String get whatsappFailureSendEmail;

  /// No description provided for @whatsappFailureResendSms.
  ///
  /// In en, this message translates to:
  /// **'Resend via SMS'**
  String get whatsappFailureResendSms;

  /// No description provided for @whatsappFailureEditPhone.
  ///
  /// In en, this message translates to:
  /// **'Edit Number'**
  String get whatsappFailureEditPhone;

  /// No description provided for @whatsappFailureNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help logging in?'**
  String get whatsappFailureNeedHelp;

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

  /// No description provided for @emailFallbackSubmit.
  ///
  /// In en, this message translates to:
  /// **'Verify Email Address'**
  String get emailFallbackSubmit;

  /// No description provided for @emailFallbackUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Email OTP delivery is not currently available from the server. Please complete verification via SMS on your Egyptian mobile number (+20).'**
  String get emailFallbackUnsupported;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical Support - Deal One'**
  String get supportTitle;

  /// No description provided for @supportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If you repeatedly have trouble receiving your verification code, contact our support team or copy the details below:'**
  String get supportSubtitle;

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

  /// No description provided for @providerUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with {provider} is not enabled yet'**
  String providerUnavailableTitle(String provider);

  /// No description provided for @providerUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Deal One currently supports secure registration and verification using an Egyptian phone number and one-time verification code (OTP). Please enter your phone number to continue.'**
  String get providerUnavailableBody;

  /// No description provided for @providerUnavailableButton.
  ///
  /// In en, this message translates to:
  /// **'Got it, continue with phone'**
  String get providerUnavailableButton;

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

  /// No description provided for @successSubtitleWithName.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}\nYour account is now ready to use and search for your property and purchases.'**
  String successSubtitleWithName(String name);

  /// No description provided for @successContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to App'**
  String get successContinueButton;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get validationNameRequired;

  /// No description provided for @validationNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Full name must be at least 2 characters'**
  String get validationNameTooShort;

  /// No description provided for @validationNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Full name is too long'**
  String get validationNameTooLong;

  /// No description provided for @validationNameLetters.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid name containing letters'**
  String get validationNameLetters;

  /// No description provided for @validationPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get validationPhoneRequired;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Egyptian mobile number (e.g. 01012345678)'**
  String get validationPhoneInvalid;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address format'**
  String get validationEmailInvalid;

  /// No description provided for @validationOtpRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code'**
  String get validationOtpRequired;

  /// No description provided for @validationOtpIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Please enter the {length}-digit verification code'**
  String validationOtpIncomplete(int length);

  /// No description provided for @validationOtpDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'Verification code must contain digits only'**
  String get validationOtpDigitsOnly;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection to the server timed out. Please try again.'**
  String get authErrorTimeout;

  /// No description provided for @authErrorUnexpectedResponse.
  ///
  /// In en, this message translates to:
  /// **'Received an unexpected response from the server. Please try again later.'**
  String get authErrorUnexpectedResponse;

  /// No description provided for @authErrorWhatsappUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sorry, this number is not registered on WhatsApp. Please use another method.'**
  String get authErrorWhatsappUnavailable;

  /// No description provided for @authErrorOtpDeliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to send the verification code right now. Please verify your number or try again later.'**
  String get authErrorOtpDeliveryFailed;

  /// No description provided for @authErrorMaxAttempts.
  ///
  /// In en, this message translates to:
  /// **'Maximum verification attempts exceeded (5 attempts). Please request a new verification code.'**
  String get authErrorMaxAttempts;

  /// No description provided for @authErrorOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'Verification code expired, please request a new code'**
  String get authErrorOtpExpired;

  /// No description provided for @authErrorOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Incorrect verification code, please check and try again'**
  String get authErrorOtpInvalid;

  /// No description provided for @authErrorInvalidRefreshToken.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get authErrorInvalidRefreshToken;

  /// No description provided for @authErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many recent requests. Please wait for the countdown to finish before requesting a new code.'**
  String get authErrorRateLimited;

  /// No description provided for @authErrorAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account was found associated with this number.'**
  String get authErrorAccountNotFound;

  /// No description provided for @authErrorExistingAccount.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already registered. You can log in directly.'**
  String get authErrorExistingAccount;

  /// No description provided for @authErrorInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Egyptian mobile number (e.g. 01012345678)'**
  String get authErrorInvalidPhone;

  /// No description provided for @authErrorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please review the entered information and try again.'**
  String get authErrorValidation;

  /// No description provided for @authErrorAccountSuspended.
  ///
  /// In en, this message translates to:
  /// **'This account is currently not authorized to sign in. Please contact support.'**
  String get authErrorAccountSuspended;

  /// No description provided for @authErrorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Session expired or invalid credentials. Please try again.'**
  String get authErrorUnauthorized;

  /// No description provided for @authErrorServer.
  ///
  /// In en, this message translates to:
  /// **'An unexpected server error occurred. Please try again later.'**
  String get authErrorServer;

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

  /// No description provided for @legalTermsSection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Using Deal One Platform'**
  String get legalTermsSection1Title;

  /// No description provided for @legalTermsSection1Body.
  ///
  /// In en, this message translates to:
  /// **'When using Deal One, you agree to publish accurate listings compliant with the laws of the Arab Republic of Egypt and refrain from impersonation or misleading information.'**
  String get legalTermsSection1Body;

  /// No description provided for @legalTermsSection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Account & Phone Verification'**
  String get legalTermsSection2Title;

  /// No description provided for @legalTermsSection2Body.
  ///
  /// In en, this message translates to:
  /// **'Accounts are verified using an active Egyptian mobile number via a one-time password (OTP). You are responsible for keeping your session secure and never sharing verification codes.'**
  String get legalTermsSection2Body;

  /// No description provided for @legalTermsSection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. User Transactions'**
  String get legalTermsSection3Title;

  /// No description provided for @legalTermsSection3Body.
  ///
  /// In en, this message translates to:
  /// **'Deal One is a classifieds and listing platform connecting buyers and sellers. Always inspect items and verify ownership documents before completing any financial transaction.'**
  String get legalTermsSection3Body;

  /// No description provided for @legalPrivacySection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Data We Collect'**
  String get legalPrivacySection1Title;

  /// No description provided for @legalPrivacySection1Body.
  ///
  /// In en, this message translates to:
  /// **'We collect only your full name, Egyptian phone number, and listing details you provide to activate your account and enable trusted in-app communication.'**
  String get legalPrivacySection1Body;

  /// No description provided for @legalPrivacySection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Token & Session Security'**
  String get legalPrivacySection2Title;

  /// No description provided for @legalPrivacySection2Body.
  ///
  /// In en, this message translates to:
  /// **'Session tokens (JWT Access & Refresh Tokens) are stored inside encrypted secure storage on your device and are never shared with third parties for marketing.'**
  String get legalPrivacySection2Body;

  /// No description provided for @legalPrivacySection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Your Account Rights'**
  String get legalPrivacySection3Title;

  /// No description provided for @legalPrivacySection3Body.
  ///
  /// In en, this message translates to:
  /// **'You can update your name, log out from all sessions, or request account deletion at any time through account settings or by contacting support.'**
  String get legalPrivacySection3Body;

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

  /// No description provided for @profileGuestHeadline.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your listings and messages'**
  String get profileGuestHeadline;

  /// No description provided for @profileLoginWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Log in with Phone Number'**
  String get profileLoginWithPhone;

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

  /// No description provided for @profileDailyQuotaRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining today: {remaining} of {limit} phone reveals'**
  String profileDailyQuotaRemaining(int remaining, int limit);

  /// No description provided for @profileDailyQuotaNote.
  ///
  /// In en, this message translates to:
  /// **'Quota resets automatically at midnight Cairo time.'**
  String get profileDailyQuotaNote;

  /// No description provided for @profileDailyQuotaError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load daily quota details'**
  String get profileDailyQuotaError;

  /// No description provided for @profileAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Seller & Showroom Accounts'**
  String get profileAccountsTitle;

  /// No description provided for @profileAccountsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No additional showroom accounts'**
  String get profileAccountsEmpty;

  /// No description provided for @profileAccountsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load accounts'**
  String get profileAccountsError;

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileVerified;

  /// No description provided for @profileUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get profileUnderReview;

  /// No description provided for @profileRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role: {role} • {status}'**
  String profileRoleLabel(String role, String status);

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profileLogout;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'App Appearance'**
  String get settingsThemeTitle;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get settingsLanguageArabic;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @activityHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity & Commerce Hub'**
  String get activityHubTitle;

  /// No description provided for @activityHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your cart, bookings, quotations, and favorites'**
  String get activityHubSubtitle;

  /// No description provided for @activityHubHeaderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Activity & Commerce Hub'**
  String get activityHubHeaderTooltip;

  /// No description provided for @activityTabCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get activityTabCart;

  /// No description provided for @activityTabBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get activityTabBookings;

  /// No description provided for @activityTabRfq.
  ///
  /// In en, this message translates to:
  /// **'RFQ'**
  String get activityTabRfq;

  /// No description provided for @activityTabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get activityTabFavorites;

  /// No description provided for @activitySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your activity...'**
  String get activitySearchHint;

  /// No description provided for @activityFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get activityFilterAll;

  /// No description provided for @activitySummaryCartItems.
  ///
  /// In en, this message translates to:
  /// **'{count} in cart'**
  String activitySummaryCartItems(int count);

  /// No description provided for @activitySummaryBookings.
  ///
  /// In en, this message translates to:
  /// **'{count} bookings'**
  String activitySummaryBookings(int count);

  /// No description provided for @activitySummaryRfqs.
  ///
  /// In en, this message translates to:
  /// **'{count} RFQs'**
  String activitySummaryRfqs(int count);

  /// No description provided for @activitySummaryFavorites.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String activitySummaryFavorites(int count);

  /// No description provided for @activityBackendPendingNotice.
  ///
  /// In en, this message translates to:
  /// **'Live server sync for this section is awaiting backend support.'**
  String get activityBackendPendingNotice;

  /// No description provided for @activityAuthRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your activity'**
  String get activityAuthRequiredTitle;

  /// No description provided for @activityAuthRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Log in to access your server-synced favorites and account activity.'**
  String get activityAuthRequiredMessage;

  /// No description provided for @activitySignInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get activitySignInAction;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get cartTitle;

  /// No description provided for @cartEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your shopping cart is empty'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add building materials, appliances, or fashion items to your cart to manage quantities and contact sellers.'**
  String get cartEmptyMessage;

  /// No description provided for @cartExploreProducts.
  ///
  /// In en, this message translates to:
  /// **'Explore Marketplace'**
  String get cartExploreProducts;

  /// No description provided for @cartSellerLabel.
  ///
  /// In en, this message translates to:
  /// **'Seller: {seller}'**
  String cartSellerLabel(String seller);

  /// No description provided for @cartUnitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get cartUnitPriceLabel;

  /// No description provided for @cartQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get cartQuantityLabel;

  /// No description provided for @cartSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size: {size}'**
  String cartSizeLabel(String size);

  /// No description provided for @cartColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color: {color}'**
  String cartColorLabel(String color);

  /// No description provided for @cartRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cartRemoveItem;

  /// No description provided for @cartSaveForLater.
  ///
  /// In en, this message translates to:
  /// **'Save for Later'**
  String get cartSaveForLater;

  /// No description provided for @cartSavedForLaterSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved to your favorites list'**
  String get cartSavedForLaterSuccess;

  /// No description provided for @cartRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Item removed from cart'**
  String get cartRemovedSuccess;

  /// No description provided for @cartAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Added to shopping cart'**
  String get cartAddedSuccess;

  /// No description provided for @cartRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Item'**
  String get cartRemoveConfirmTitle;

  /// No description provided for @cartRemoveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{title}\" from your cart?'**
  String cartRemoveConfirmMessage(String title);

  /// No description provided for @cartClearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get cartClearConfirmTitle;

  /// No description provided for @cartClearConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove all items from your shopping cart?'**
  String get cartClearConfirmMessage;

  /// No description provided for @cartClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get cartClearAction;

  /// No description provided for @cartSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get cartSubtotalLabel;

  /// No description provided for @cartTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated Total'**
  String get cartTotalLabel;

  /// No description provided for @cartItemsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String cartItemsCountLabel(int count);

  /// No description provided for @cartCheckoutAction.
  ///
  /// In en, this message translates to:
  /// **'Proceed / Contact Sellers'**
  String get cartCheckoutAction;

  /// No description provided for @cartV1CommerceNotice.
  ///
  /// In en, this message translates to:
  /// **'Deal One V1 operates on direct seller contact without in-app payment. Use Contact Seller on each item to finalize your deal.'**
  String get cartV1CommerceNotice;

  /// No description provided for @cartSelectVariantTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Options'**
  String get cartSelectVariantTitle;

  /// No description provided for @cartSelectSize.
  ///
  /// In en, this message translates to:
  /// **'Select Size'**
  String get cartSelectSize;

  /// No description provided for @cartSelectColor.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get cartSelectColor;

  /// No description provided for @cartAddToCartAction.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get cartAddToCartAction;

  /// No description provided for @cartQuantityMinError.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be at least 1'**
  String get cartQuantityMinError;

  /// No description provided for @bookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings & Appointments'**
  String get bookingsTitle;

  /// No description provided for @bookingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookings or appointments yet'**
  String get bookingsEmptyTitle;

  /// No description provided for @bookingsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Property viewings, vehicle inspections, and service appointments will appear here once scheduled.'**
  String get bookingsEmptyMessage;

  /// No description provided for @bookingsFilterRealEstate.
  ///
  /// In en, this message translates to:
  /// **'Real Estate'**
  String get bookingsFilterRealEstate;

  /// No description provided for @bookingsFilterCars.
  ///
  /// In en, this message translates to:
  /// **'Cars & Maintenance'**
  String get bookingsFilterCars;

  /// No description provided for @bookingsFilterServices.
  ///
  /// In en, this message translates to:
  /// **'Services & Engineering'**
  String get bookingsFilterServices;

  /// No description provided for @bookingsTypePropertyViewing.
  ///
  /// In en, this message translates to:
  /// **'Property Viewing'**
  String get bookingsTypePropertyViewing;

  /// No description provided for @bookingsTypePropertyInspection.
  ///
  /// In en, this message translates to:
  /// **'Property Inspection'**
  String get bookingsTypePropertyInspection;

  /// No description provided for @bookingsTypeAgentContact.
  ///
  /// In en, this message translates to:
  /// **'Agent Contact Request'**
  String get bookingsTypeAgentContact;

  /// No description provided for @bookingsTypeVehicleInspection.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Inspection'**
  String get bookingsTypeVehicleInspection;

  /// No description provided for @bookingsTypeMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Booking'**
  String get bookingsTypeMaintenance;

  /// No description provided for @bookingsTypeServiceCenter.
  ///
  /// In en, this message translates to:
  /// **'Service Center'**
  String get bookingsTypeServiceCenter;

  /// No description provided for @bookingsTypePlumbing.
  ///
  /// In en, this message translates to:
  /// **'Plumbing Service'**
  String get bookingsTypePlumbing;

  /// No description provided for @bookingsTypeElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electrical Service'**
  String get bookingsTypeElectricity;

  /// No description provided for @bookingsTypeAc.
  ///
  /// In en, this message translates to:
  /// **'AC Service'**
  String get bookingsTypeAc;

  /// No description provided for @bookingsTypeConstruction.
  ///
  /// In en, this message translates to:
  /// **'Construction Service'**
  String get bookingsTypeConstruction;

  /// No description provided for @bookingsTypeEngineering.
  ///
  /// In en, this message translates to:
  /// **'Engineering Service'**
  String get bookingsTypeEngineering;

  /// No description provided for @bookingsProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get bookingsProviderLabel;

  /// No description provided for @bookingsDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get bookingsDateLabel;

  /// No description provided for @bookingsTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get bookingsTimeLabel;

  /// No description provided for @bookingsAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get bookingsAddressLabel;

  /// No description provided for @bookingsReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Ref #{reference}'**
  String bookingsReferenceLabel(String reference);

  /// No description provided for @bookingsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get bookingsStatusPending;

  /// No description provided for @bookingsStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingsStatusConfirmed;

  /// No description provided for @bookingsStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get bookingsStatusRejected;

  /// No description provided for @bookingsStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingsStatusCancelled;

  /// No description provided for @bookingsStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingsStatusCompleted;

  /// No description provided for @bookingsStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get bookingsStatusUnknown;

  /// No description provided for @bookingsCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get bookingsCancelAction;

  /// No description provided for @bookingsCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get bookingsCancelConfirmTitle;

  /// No description provided for @bookingsCancelConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get bookingsCancelConfirmMessage;

  /// No description provided for @bookingsContactProviderAction.
  ///
  /// In en, this message translates to:
  /// **'Contact Provider'**
  String get bookingsContactProviderAction;

  /// No description provided for @bookingsViewListingAction.
  ///
  /// In en, this message translates to:
  /// **'View Listing'**
  String get bookingsViewListingAction;

  /// No description provided for @bookingsCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Appointment'**
  String get bookingsCreateTitle;

  /// No description provided for @bookingsSelectDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select appointment date'**
  String get bookingsSelectDateHint;

  /// No description provided for @bookingsSelectTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Select available time'**
  String get bookingsSelectTimeHint;

  /// No description provided for @bookingsAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter service or meeting address'**
  String get bookingsAddressHint;

  /// No description provided for @bookingsNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your request or notes'**
  String get bookingsNotesHint;

  /// No description provided for @bookingsSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get bookingsSubmitAction;

  /// No description provided for @bookingsValidationDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get bookingsValidationDateRequired;

  /// No description provided for @bookingsValidationTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a time'**
  String get bookingsValidationTimeRequired;

  /// No description provided for @bookingsValidationAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an address'**
  String get bookingsValidationAddressRequired;

  /// No description provided for @bookingsBackendUnavailableNotice.
  ///
  /// In en, this message translates to:
  /// **'Online booking submission requires backend endpoint support. You can contact the seller directly from the listing.'**
  String get bookingsBackendUnavailableNotice;

  /// No description provided for @rfqTitle.
  ///
  /// In en, this message translates to:
  /// **'Request for Quotation'**
  String get rfqTitle;

  /// No description provided for @rfqEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No quotation requests yet'**
  String get rfqEmptyTitle;

  /// No description provided for @rfqEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Submit bulk material requirements and compare supplier quotations here.'**
  String get rfqEmptyMessage;

  /// No description provided for @rfqCreateAction.
  ///
  /// In en, this message translates to:
  /// **'New RFQ'**
  String get rfqCreateAction;

  /// No description provided for @rfqCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Quotation Request'**
  String get rfqCreateTitle;

  /// No description provided for @rfqRequestTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Project / Request Title'**
  String get rfqRequestTitleLabel;

  /// No description provided for @rfqRequestTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Villa Electrical & Cement Supply'**
  String get rfqRequestTitleHint;

  /// No description provided for @rfqMaterialsLabel.
  ///
  /// In en, this message translates to:
  /// **'Products / Materials'**
  String get rfqMaterialsLabel;

  /// No description provided for @rfqMaterialsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Portland Cement, Steel Rebar 12mm'**
  String get rfqMaterialsHint;

  /// No description provided for @rfqQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity & Unit'**
  String get rfqQuantityLabel;

  /// No description provided for @rfqQuantityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 50 Tons / 200 Units'**
  String get rfqQuantityHint;

  /// No description provided for @rfqDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Project Description'**
  String get rfqDescriptionLabel;

  /// No description provided for @rfqDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Specify technical requirements and timeline'**
  String get rfqDescriptionHint;

  /// No description provided for @rfqDeliveryLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Location'**
  String get rfqDeliveryLocationLabel;

  /// No description provided for @rfqDeliveryLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Governorate, City, Site Address'**
  String get rfqDeliveryLocationHint;

  /// No description provided for @rfqAttachmentsNote.
  ///
  /// In en, this message translates to:
  /// **'Image attachments are supported once backend media upload for RFQs is enabled.'**
  String get rfqAttachmentsNote;

  /// No description provided for @rfqSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Submit Quotation Request'**
  String get rfqSubmitAction;

  /// No description provided for @rfqReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'RFQ #{reference}'**
  String rfqReferenceLabel(String reference);

  /// No description provided for @rfqSubmittedDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted: {date}'**
  String rfqSubmittedDateLabel(String date);

  /// No description provided for @rfqItemsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} items requested'**
  String rfqItemsCountLabel(int count);

  /// No description provided for @rfqQuotationsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} quotations received'**
  String rfqQuotationsCountLabel(int count);

  /// No description provided for @rfqLastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated: {date}'**
  String rfqLastUpdatedLabel(String date);

  /// No description provided for @rfqStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get rfqStatusDraft;

  /// No description provided for @rfqStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get rfqStatusSubmitted;

  /// No description provided for @rfqStatusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get rfqStatusUnderReview;

  /// No description provided for @rfqStatusQuoted.
  ///
  /// In en, this message translates to:
  /// **'Quoted'**
  String get rfqStatusQuoted;

  /// No description provided for @rfqStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get rfqStatusAccepted;

  /// No description provided for @rfqStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rfqStatusRejected;

  /// No description provided for @rfqStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get rfqStatusClosed;

  /// No description provided for @rfqViewQuotationsAction.
  ///
  /// In en, this message translates to:
  /// **'Compare Quotations'**
  String get rfqViewQuotationsAction;

  /// No description provided for @rfqNoQuotationsYet.
  ///
  /// In en, this message translates to:
  /// **'No supplier quotations received yet.'**
  String get rfqNoQuotationsYet;

  /// No description provided for @rfqAcceptQuotationAction.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get rfqAcceptQuotationAction;

  /// No description provided for @rfqRejectQuotationAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rfqRejectQuotationAction;

  /// No description provided for @rfqValidationTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a request title'**
  String get rfqValidationTitleRequired;

  /// No description provided for @rfqValidationMaterialsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please specify products or materials'**
  String get rfqValidationMaterialsRequired;

  /// No description provided for @rfqValidationQuantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Please specify quantities'**
  String get rfqValidationQuantityRequired;

  /// No description provided for @rfqValidationLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please specify delivery location'**
  String get rfqValidationLocationRequired;

  /// No description provided for @rfqBackendUnavailableNotice.
  ///
  /// In en, this message translates to:
  /// **'RFQ submission and quotation comparison are awaiting backend API support.'**
  String get rfqBackendUnavailableNotice;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved listings yet'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon on any listing across Deal One to save it here.'**
  String get favoritesEmptyMessage;

  /// No description provided for @favoritesSearchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching favorites'**
  String get favoritesSearchEmptyTitle;

  /// No description provided for @favoritesSearchEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Try clearing your search or selecting a different category.'**
  String get favoritesSearchEmptyMessage;

  /// No description provided for @favoritesExploreAction.
  ///
  /// In en, this message translates to:
  /// **'Browse Listings'**
  String get favoritesExploreAction;

  /// No description provided for @favoritesRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get favoritesRemoveAction;

  /// No description provided for @favoritesOpenListingAction.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get favoritesOpenListingAction;

  /// No description provided for @favoritesGoToSectionAction.
  ///
  /// In en, this message translates to:
  /// **'Open Section'**
  String get favoritesGoToSectionAction;

  /// No description provided for @favoritesRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get favoritesRemovedSuccess;

  /// No description provided for @favoritesSectorRealEstate.
  ///
  /// In en, this message translates to:
  /// **'Real Estate & Land'**
  String get favoritesSectorRealEstate;

  /// No description provided for @favoritesSectorCars.
  ///
  /// In en, this message translates to:
  /// **'Cars & Maintenance'**
  String get favoritesSectorCars;

  /// No description provided for @favoritesSectorServices.
  ///
  /// In en, this message translates to:
  /// **'Services & Engineering'**
  String get favoritesSectorServices;

  /// No description provided for @favoritesSectorBuildingMaterials.
  ///
  /// In en, this message translates to:
  /// **'Building Materials'**
  String get favoritesSectorBuildingMaterials;

  /// No description provided for @favoritesSectorAppliances.
  ///
  /// In en, this message translates to:
  /// **'Home Appliances & Decor'**
  String get favoritesSectorAppliances;

  /// No description provided for @favoritesSectorFashion.
  ///
  /// In en, this message translates to:
  /// **'Fashion & Accessories'**
  String get favoritesSectorFashion;

  /// No description provided for @actionRequestViewing.
  ///
  /// In en, this message translates to:
  /// **'Request Viewing'**
  String get actionRequestViewing;

  /// No description provided for @actionBookInspection.
  ///
  /// In en, this message translates to:
  /// **'Book Inspection'**
  String get actionBookInspection;

  /// No description provided for @actionBookService.
  ///
  /// In en, this message translates to:
  /// **'Book Service'**
  String get actionBookService;

  /// No description provided for @actionRequestQuotation.
  ///
  /// In en, this message translates to:
  /// **'Request Quotation'**
  String get actionRequestQuotation;

  /// No description provided for @actionContactSeller.
  ///
  /// In en, this message translates to:
  /// **'Contact Seller'**
  String get actionContactSeller;
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
