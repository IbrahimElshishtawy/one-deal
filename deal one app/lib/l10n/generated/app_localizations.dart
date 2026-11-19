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

  /// No description provided for @brandNameAr.
  ///
  /// In en, this message translates to:
  /// **'Deal One'**
  String get brandNameAr;

  /// No description provided for @brandNameEn.
  ///
  /// In en, this message translates to:
  /// **'DEAL ONE'**
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
