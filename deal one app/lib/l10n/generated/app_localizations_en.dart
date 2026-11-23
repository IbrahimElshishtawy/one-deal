// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DealOne';

  @override
  String get brandNameAr => 'DealOne';

  @override
  String get brandNameEn => 'DealOne';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get copy => 'Copy';

  @override
  String copiedItem(String label) {
    return '$label copied';
  }

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
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingCreateAccount => 'Create Account';

  @override
  String get onboardingBrowseGuest => 'Browse as Guest';

  @override
  String get onboardingSlide1Title =>
      'A World of Real Estate & Cars in Your Hands';

  @override
  String get onboardingSlide1Description =>
      'Discover the latest offers to buy and sell properties, cars, maintenance services, and spare parts with ease.';

  @override
  String get onboardingSlide2Title => 'Finishing & Home Services Near You';

  @override
  String get onboardingSlide2Description =>
      'Connect with engineering offices and order construction materials and electrical supplies from the nearest suppliers and technicians.';

  @override
  String get onboardingSlide3Title =>
      'Your Style & Home Decor with Direct Contact';

  @override
  String get onboardingSlide3Description =>
      'Browse the latest fashion trends, decor pieces, and home appliances, and contact sellers directly to complete your deals safely and easily.';

  @override
  String get authBrowseAsGuest => 'Browse as Guest';

  @override
  String get authOrContinueWith => 'Or continue with';

  @override
  String get authProviderEmail => 'Email';

  @override
  String get authProviderApple => 'Apple Account';

  @override
  String get authLegalPrefix => 'By continuing, you agree to our ';

  @override
  String get authLegalTerms => 'Terms of Service';

  @override
  String get authLegalAnd => ' and ';

  @override
  String get authLegalPrivacy => 'Privacy Policy';

  @override
  String get authLegalSuffix => '.';

  @override
  String get signUpTitle => 'Create your Deal One account';

  @override
  String get signUpSubtitle =>
      'Find your property, car, and deals in one place.';

  @override
  String get signUpNameHint => 'Enter your name here';

  @override
  String get signUpPhoneHint => '01XXXXXXXXX';

  @override
  String get signUpWhatsappNote =>
      'A verification code will be sent via WhatsApp';

  @override
  String get signUpSubmitButton => 'Send Verification Code';

  @override
  String get signUpAlreadyHaveAccount => 'Already have an account? ';

  @override
  String get signUpGoToLogin => 'Log In';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle =>
      'Enter your WhatsApp number to continue exploring properties and purchases';

  @override
  String get loginSubmitButton => 'Log In';

  @override
  String get loginNoAccount => 'Don\'t have an account? ';

  @override
  String get loginCreateAccountNow => 'Create Account Now';

  @override
  String get otpTitle => 'Enter Verification Code';

  @override
  String otpSubtitle(int length, String phone) {
    return 'Enter the $length-digit code sent to\n[$phone] via WhatsApp';
  }

  @override
  String get otpChangePhone => 'Change Number';

  @override
  String get otpVerifyButton => 'Verify Code';

  @override
  String get otpRetryButton => 'Try Again';

  @override
  String otpRetryWithCooldown(String cooldown) {
    return 'Try Again ($cooldown)';
  }

  @override
  String get otpResendingLabel => 'Sending a new code...';

  @override
  String get otpDidNotReceive => 'Didn\'t receive the code? ';

  @override
  String get otpResendAgain => 'Resend';

  @override
  String otpResendCountdown(String cooldown) {
    return 'Resend $cooldown';
  }

  @override
  String get otpSendingLabel => 'Sending...';

  @override
  String otpExpiryRemaining(String time) {
    return 'Code expires in: $time';
  }

  @override
  String get otpWhatsappHelp => 'Didn\'t receive the code via WhatsApp?';

  @override
  String get otpSupportPrompt => 'Having trouble logging in? Contact Support';

  @override
  String otpResendInCooldown(String cooldown) {
    return 'Send new code in $cooldown';
  }

  @override
  String get otpRequestNewCode => 'Request a new verification code';

  @override
  String get otpResentSuccess => 'A new verification code has been sent';

  @override
  String otpWaitCooldownSms(String cooldown) {
    return 'Please wait $cooldown before resending via SMS';
  }

  @override
  String otpWaitCooldownNewCode(String cooldown) {
    return 'Please wait $cooldown before requesting a new code';
  }

  @override
  String otpSemanticsLabel(int length) {
    return '$length-digit verification code input';
  }

  @override
  String get otpNoActiveSessionTitle => 'No Active Verification Session';

  @override
  String get otpNoActiveSessionSubtitle =>
      'Please enter your phone number first to receive a verification code.';

  @override
  String get otpBackToLogin => 'Back to Log In';

  @override
  String get otpRemainingAttemptsOne =>
      'You have only 1 attempt remaining before temporary lockout';

  @override
  String get otpRemainingAttemptsTwo =>
      'You have only 2 attempts remaining before temporary lockout';

  @override
  String otpRemainingAttemptsMany(int count) {
    return 'You have $count attempts remaining before temporary lockout';
  }

  @override
  String get otpExpiredTitle =>
      'Verification code expired, please request a new code';

  @override
  String get otpExpiredBody =>
      'The security timeout has elapsed to protect your account and transactions. You can generate a new code immediately and continue verification.';

  @override
  String get whatsappFailureTitle => 'Unable to Send via WhatsApp';

  @override
  String get whatsappFailureDefaultSubtitle =>
      'Sorry, this number is not registered on WhatsApp. Please use another method.';

  @override
  String get whatsappFailureSendEmail => 'Send via Email';

  @override
  String get whatsappFailureResendSms => 'Resend via SMS';

  @override
  String get whatsappFailureEditPhone => 'Edit Number';

  @override
  String get whatsappFailureNeedHelp => 'Need help logging in?';

  @override
  String get emailFallbackTitle => 'Email Verification';

  @override
  String get emailFallbackSubtitle =>
      'Enter your email address to check alternative code delivery availability.';

  @override
  String get emailFallbackLabel => 'Email Address';

  @override
  String get emailFallbackSubmit => 'Verify Email Address';

  @override
  String get emailFallbackUnsupported =>
      'Email OTP delivery is not currently available from the server. Please complete verification via SMS on your Egyptian mobile number (+20).';

  @override
  String get supportTitle => 'Technical Support - Deal One';

  @override
  String get supportSubtitle =>
      'If you repeatedly have trouble receiving your verification code, contact our support team or copy the details below:';

  @override
  String get supportEmailTitle => 'Support Email';

  @override
  String get supportHotlineTitle => 'Customer Service';

  @override
  String providerUnavailableTitle(String provider) {
    return 'Sign in with $provider is not enabled yet';
  }

  @override
  String get providerUnavailableBody =>
      'Deal One currently supports secure registration and verification using an Egyptian phone number and one-time verification code (OTP). Please enter your phone number to continue.';

  @override
  String get providerUnavailableButton => 'Got it, continue with phone';

  @override
  String get successTitle => 'Verified Successfully!';

  @override
  String get successSubtitleDefault =>
      'Your account is now ready to use and search for your property and purchases.';

  @override
  String successSubtitleWithName(String name) {
    return 'Welcome, $name\nYour account is now ready to use and search for your property and purchases.';
  }

  @override
  String get successContinueButton => 'Continue to App';

  @override
  String get validationNameRequired => 'Please enter your full name';

  @override
  String get validationNameTooShort =>
      'Full name must be at least 2 characters';

  @override
  String get validationNameTooLong => 'Full name is too long';

  @override
  String get validationNameLetters =>
      'Please enter a valid name containing letters';

  @override
  String get validationPhoneRequired => 'Please enter your phone number';

  @override
  String get validationPhoneInvalid =>
      'Enter a valid Egyptian mobile number (e.g. 01012345678)';

  @override
  String get validationEmailRequired => 'Please enter your email address';

  @override
  String get validationEmailInvalid => 'Invalid email address format';

  @override
  String get validationOtpRequired => 'Please enter the verification code';

  @override
  String validationOtpIncomplete(int length) {
    return 'Please enter the $length-digit verification code';
  }

  @override
  String get validationOtpDigitsOnly =>
      'Verification code must contain digits only';

  @override
  String get authErrorNetwork =>
      'No internet connection. Check your network and try again.';

  @override
  String get authErrorTimeout =>
      'Connection to the server timed out. Please try again.';

  @override
  String get authErrorUnexpectedResponse =>
      'Received an unexpected response from the server. Please try again later.';

  @override
  String get authErrorWhatsappUnavailable =>
      'Sorry, this number is not registered on WhatsApp. Please use another method.';

  @override
  String get authErrorOtpDeliveryFailed =>
      'Unable to send the verification code right now. Please verify your number or try again later.';

  @override
  String get authErrorMaxAttempts =>
      'Maximum verification attempts exceeded (5 attempts). Please request a new verification code.';

  @override
  String get authErrorOtpExpired =>
      'Verification code expired, please request a new code';

  @override
  String get authErrorOtpInvalid =>
      'Incorrect verification code, please check and try again';

  @override
  String get authErrorInvalidRefreshToken =>
      'Your session has expired. Please log in again.';

  @override
  String get authErrorRateLimited =>
      'Too many recent requests. Please wait for the countdown to finish before requesting a new code.';

  @override
  String get authErrorAccountNotFound =>
      'No account was found associated with this number.';

  @override
  String get authErrorExistingAccount =>
      'This phone number is already registered. You can log in directly.';

  @override
  String get authErrorInvalidPhone =>
      'Enter a valid Egyptian mobile number (e.g. 01012345678)';

  @override
  String get authErrorValidation =>
      'Please review the entered information and try again.';

  @override
  String get authErrorAccountSuspended =>
      'This account is currently not authorized to sign in. Please contact support.';

  @override
  String get authErrorUnauthorized =>
      'Session expired or invalid credentials. Please try again.';

  @override
  String get authErrorServer =>
      'An unexpected server error occurred. Please try again later.';

  @override
  String get legalTermsTitle => 'Terms of Service';

  @override
  String get legalPrivacyTitle => 'Privacy Policy';

  @override
  String get legalTermsSection1Title => '1. Using Deal One Platform';

  @override
  String get legalTermsSection1Body =>
      'When using Deal One, you agree to publish accurate listings compliant with the laws of the Arab Republic of Egypt and refrain from impersonation or misleading information.';

  @override
  String get legalTermsSection2Title => '2. Account & Phone Verification';

  @override
  String get legalTermsSection2Body =>
      'Accounts are verified using an active Egyptian mobile number via a one-time password (OTP). You are responsible for keeping your session secure and never sharing verification codes.';

  @override
  String get legalTermsSection3Title => '3. User Transactions';

  @override
  String get legalTermsSection3Body =>
      'Deal One is a classifieds and listing platform connecting buyers and sellers. Always inspect items and verify ownership documents before completing any financial transaction.';

  @override
  String get legalPrivacySection1Title => '1. Data We Collect';

  @override
  String get legalPrivacySection1Body =>
      'We collect only your full name, Egyptian phone number, and listing details you provide to activate your account and enable trusted in-app communication.';

  @override
  String get legalPrivacySection2Title => '2. Token & Session Security';

  @override
  String get legalPrivacySection2Body =>
      'Session tokens (JWT Access & Refresh Tokens) are stored inside encrypted secure storage on your device and are never shared with third parties for marketing.';

  @override
  String get legalPrivacySection3Title => '3. Your Account Rights';

  @override
  String get legalPrivacySection3Body =>
      'You can update your name, log out from all sessions, or request account deletion at any time through account settings or by contacting support.';

  @override
  String get profileTitleGuest => 'My Account';

  @override
  String get profileTitleAuth => 'My Account & Profile';

  @override
  String get profileGuestHeadline =>
      'Sign in to access your listings and messages';

  @override
  String get profileLoginWithPhone => 'Log in with Phone Number';

  @override
  String get profileRegisteredUser => 'Registered User';

  @override
  String get profileIdAvailable => 'ID available';

  @override
  String get profileDailyQuotaTitle => 'Daily Contact Quota (Cairo Time)';

  @override
  String profileDailyQuotaRemaining(int remaining, int limit) {
    return 'Remaining today: $remaining of $limit phone reveals';
  }

  @override
  String get profileDailyQuotaNote =>
      'Quota resets automatically at midnight Cairo time.';

  @override
  String get profileDailyQuotaError => 'Unable to load daily quota details';

  @override
  String get profileAccountsTitle => 'Seller & Showroom Accounts';

  @override
  String get profileAccountsEmpty => 'No additional showroom accounts';

  @override
  String get profileAccountsError => 'Unable to load accounts';

  @override
  String get profileVerified => 'Verified';

  @override
  String get profileUnderReview => 'Under Review';

  @override
  String profileRoleLabel(String role, String status) {
    return 'Role: $role • $status';
  }

  @override
  String get profileLogout => 'Log Out';

  @override
  String get settingsThemeTitle => 'App Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguageTitle => 'App Language';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get activityHubTitle => 'Activity & Commerce Hub';

  @override
  String get activityHubSubtitle =>
      'Manage your cart, bookings, quotations, and favorites';

  @override
  String get activityHubHeaderTooltip => 'Activity & Commerce Hub';

  @override
  String get activityTabCart => 'Cart';

  @override
  String get activityTabBookings => 'Bookings';

  @override
  String get activityTabRfq => 'RFQ';

  @override
  String get activityTabFavorites => 'Favorites';

  @override
  String get activitySearchHint => 'Search your activity...';

  @override
  String get activityFilterAll => 'All';

  @override
  String activitySummaryCartItems(int count) {
    return '$count in cart';
  }

  @override
  String activitySummaryBookings(int count) {
    return '$count bookings';
  }

  @override
  String activitySummaryRfqs(int count) {
    return '$count RFQs';
  }

  @override
  String activitySummaryFavorites(int count) {
    return '$count saved';
  }

  @override
  String get activityBackendPendingNotice =>
      'Live server sync for this section is awaiting backend support.';

  @override
  String get activityAuthRequiredTitle => 'Sign in to sync your activity';

  @override
  String get activityAuthRequiredMessage =>
      'Log in to access your server-synced favorites and account activity.';

  @override
  String get activitySignInAction => 'Sign In';

  @override
  String get cartTitle => 'Shopping Cart';

  @override
  String get cartEmptyTitle => 'Your shopping cart is empty';

  @override
  String get cartEmptyMessage =>
      'Add building materials, appliances, or fashion items to your cart to manage quantities and contact sellers.';

  @override
  String get cartExploreProducts => 'Explore Marketplace';

  @override
  String cartSellerLabel(String seller) {
    return 'Seller: $seller';
  }

  @override
  String get cartUnitPriceLabel => 'Unit Price';

  @override
  String get cartQuantityLabel => 'Quantity';

  @override
  String cartSizeLabel(String size) {
    return 'Size: $size';
  }

  @override
  String cartColorLabel(String color) {
    return 'Color: $color';
  }

  @override
  String get cartRemoveItem => 'Remove';

  @override
  String get cartSaveForLater => 'Save for Later';

  @override
  String get cartSavedForLaterSuccess => 'Saved to your favorites list';

  @override
  String get cartRemovedSuccess => 'Item removed from cart';

  @override
  String get cartAddedSuccess => 'Added to shopping cart';

  @override
  String get cartRemoveConfirmTitle => 'Remove Item';

  @override
  String cartRemoveConfirmMessage(String title) {
    return 'Are you sure you want to remove \"$title\" from your cart?';
  }

  @override
  String get cartClearConfirmTitle => 'Clear Cart';

  @override
  String get cartClearConfirmMessage =>
      'Remove all items from your shopping cart?';

  @override
  String get cartClearAction => 'Clear All';

  @override
  String get cartSubtotalLabel => 'Subtotal';

  @override
  String get cartTotalLabel => 'Estimated Total';

  @override
  String cartItemsCountLabel(int count) {
    return '$count items';
  }

  @override
  String get cartCheckoutAction => 'Proceed / Contact Sellers';

  @override
  String get cartV1CommerceNotice =>
      'Deal One V1 operates on direct seller contact without in-app payment. Use Contact Seller on each item to finalize your deal.';

  @override
  String get cartSelectVariantTitle => 'Select Options';

  @override
  String get cartSelectSize => 'Select Size';

  @override
  String get cartSelectColor => 'Select Color';

  @override
  String get cartAddToCartAction => 'Add to Cart';

  @override
  String get cartQuantityMinError => 'Quantity must be at least 1';

  @override
  String get bookingsTitle => 'Bookings & Appointments';

  @override
  String get bookingsEmptyTitle => 'No bookings or appointments yet';

  @override
  String get bookingsEmptyMessage =>
      'Property viewings, vehicle inspections, and service appointments will appear here once scheduled.';

  @override
  String get bookingsFilterRealEstate => 'Real Estate';

  @override
  String get bookingsFilterCars => 'Cars & Maintenance';

  @override
  String get bookingsFilterServices => 'Services & Engineering';

  @override
  String get bookingsTypePropertyViewing => 'Property Viewing';

  @override
  String get bookingsTypePropertyInspection => 'Property Inspection';

  @override
  String get bookingsTypeAgentContact => 'Agent Contact Request';

  @override
  String get bookingsTypeVehicleInspection => 'Vehicle Inspection';

  @override
  String get bookingsTypeMaintenance => 'Maintenance Booking';

  @override
  String get bookingsTypeServiceCenter => 'Service Center';

  @override
  String get bookingsTypePlumbing => 'Plumbing Service';

  @override
  String get bookingsTypeElectricity => 'Electrical Service';

  @override
  String get bookingsTypeAc => 'AC Service';

  @override
  String get bookingsTypeConstruction => 'Construction Service';

  @override
  String get bookingsTypeEngineering => 'Engineering Service';

  @override
  String get bookingsProviderLabel => 'Provider';

  @override
  String get bookingsDateLabel => 'Date';

  @override
  String get bookingsTimeLabel => 'Time';

  @override
  String get bookingsAddressLabel => 'Address';

  @override
  String bookingsReferenceLabel(String reference) {
    return 'Ref #$reference';
  }

  @override
  String get bookingsStatusPending => 'Pending';

  @override
  String get bookingsStatusConfirmed => 'Confirmed';

  @override
  String get bookingsStatusRejected => 'Rejected';

  @override
  String get bookingsStatusCancelled => 'Cancelled';

  @override
  String get bookingsStatusCompleted => 'Completed';

  @override
  String get bookingsStatusUnknown => 'Unknown';

  @override
  String get bookingsCancelAction => 'Cancel Booking';

  @override
  String get bookingsCancelConfirmTitle => 'Cancel Booking';

  @override
  String get bookingsCancelConfirmMessage =>
      'Are you sure you want to cancel this booking?';

  @override
  String get bookingsContactProviderAction => 'Contact Provider';

  @override
  String get bookingsViewListingAction => 'View Listing';

  @override
  String get bookingsCreateTitle => 'Schedule Appointment';

  @override
  String get bookingsSelectDateHint => 'Select appointment date';

  @override
  String get bookingsSelectTimeHint => 'Select available time';

  @override
  String get bookingsAddressHint => 'Enter service or meeting address';

  @override
  String get bookingsNotesHint => 'Describe your request or notes';

  @override
  String get bookingsSubmitAction => 'Submit Request';

  @override
  String get bookingsValidationDateRequired => 'Please select a date';

  @override
  String get bookingsValidationTimeRequired => 'Please select a time';

  @override
  String get bookingsValidationAddressRequired => 'Please enter an address';

  @override
  String get bookingsBackendUnavailableNotice =>
      'Online booking submission requires backend endpoint support. You can contact the seller directly from the listing.';

  @override
  String get rfqTitle => 'Request for Quotation';

  @override
  String get rfqEmptyTitle => 'No quotation requests yet';

  @override
  String get rfqEmptyMessage =>
      'Submit bulk material requirements and compare supplier quotations here.';

  @override
  String get rfqCreateAction => 'New RFQ';

  @override
  String get rfqCreateTitle => 'Create Quotation Request';

  @override
  String get rfqRequestTitleLabel => 'Project / Request Title';

  @override
  String get rfqRequestTitleHint => 'e.g., Villa Electrical & Cement Supply';

  @override
  String get rfqMaterialsLabel => 'Products / Materials';

  @override
  String get rfqMaterialsHint => 'e.g., Portland Cement, Steel Rebar 12mm';

  @override
  String get rfqQuantityLabel => 'Quantity & Unit';

  @override
  String get rfqQuantityHint => 'e.g., 50 Tons / 200 Units';

  @override
  String get rfqDescriptionLabel => 'Project Description';

  @override
  String get rfqDescriptionHint =>
      'Specify technical requirements and timeline';

  @override
  String get rfqDeliveryLocationLabel => 'Delivery Location';

  @override
  String get rfqDeliveryLocationHint => 'Governorate, City, Site Address';

  @override
  String get rfqAttachmentsNote =>
      'Image attachments are supported once backend media upload for RFQs is enabled.';

  @override
  String get rfqSubmitAction => 'Submit Quotation Request';

  @override
  String rfqReferenceLabel(String reference) {
    return 'RFQ #$reference';
  }

  @override
  String rfqSubmittedDateLabel(String date) {
    return 'Submitted: $date';
  }

  @override
  String rfqItemsCountLabel(int count) {
    return '$count items requested';
  }

  @override
  String rfqQuotationsCountLabel(int count) {
    return '$count quotations received';
  }

  @override
  String rfqLastUpdatedLabel(String date) {
    return 'Updated: $date';
  }

  @override
  String get rfqStatusDraft => 'Draft';

  @override
  String get rfqStatusSubmitted => 'Submitted';

  @override
  String get rfqStatusUnderReview => 'Under Review';

  @override
  String get rfqStatusQuoted => 'Quoted';

  @override
  String get rfqStatusAccepted => 'Accepted';

  @override
  String get rfqStatusRejected => 'Rejected';

  @override
  String get rfqStatusClosed => 'Closed';

  @override
  String get rfqViewQuotationsAction => 'Compare Quotations';

  @override
  String get rfqNoQuotationsYet => 'No supplier quotations received yet.';

  @override
  String get rfqAcceptQuotationAction => 'Accept';

  @override
  String get rfqRejectQuotationAction => 'Reject';

  @override
  String get rfqValidationTitleRequired => 'Please enter a request title';

  @override
  String get rfqValidationMaterialsRequired =>
      'Please specify products or materials';

  @override
  String get rfqValidationQuantityRequired => 'Please specify quantities';

  @override
  String get rfqValidationLocationRequired =>
      'Please specify delivery location';

  @override
  String get rfqBackendUnavailableNotice =>
      'RFQ submission and quotation comparison are awaiting backend API support.';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesEmptyTitle => 'No saved listings yet';

  @override
  String get favoritesEmptyMessage =>
      'Tap the heart icon on any listing across Deal One to save it here.';

  @override
  String get favoritesSearchEmptyTitle => 'No matching favorites';

  @override
  String get favoritesSearchEmptyMessage =>
      'Try clearing your search or selecting a different category.';

  @override
  String get favoritesExploreAction => 'Browse Listings';

  @override
  String get favoritesRemoveAction => 'Remove from Favorites';

  @override
  String get favoritesOpenListingAction => 'View Details';

  @override
  String get favoritesGoToSectionAction => 'Open Section';

  @override
  String get favoritesRemovedSuccess => 'Removed from favorites';

  @override
  String get favoritesSectorRealEstate => 'Real Estate & Land';

  @override
  String get favoritesSectorCars => 'Cars & Maintenance';

  @override
  String get favoritesSectorServices => 'Services & Engineering';

  @override
  String get favoritesSectorBuildingMaterials => 'Building Materials';

  @override
  String get favoritesSectorAppliances => 'Home Appliances & Decor';

  @override
  String get favoritesSectorFashion => 'Fashion & Accessories';

  @override
  String get actionRequestViewing => 'Request Viewing';

  @override
  String get actionBookInspection => 'Book Inspection';

  @override
  String get actionBookService => 'Book Service';

  @override
  String get actionRequestQuotation => 'Request Quotation';

  @override
  String get actionContactSeller => 'Contact Seller';
}
