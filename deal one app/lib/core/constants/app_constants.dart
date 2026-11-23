class AppConstants {
  static const String appName = 'DealOne';
  static const String logoAssetPath = 'assets/image/logo.png';
  static const String defaultLocaleLanguageCode = 'ar';
  static const String defaultLocaleCountryCode = 'EG';
  static const String fallbackLocaleLanguageCode = 'en';
  static const String fallbackLocaleCountryCode = 'US';

  static const String egyptCountryDialCode = '+20';
  static const String egyptianPhoneRegexPattern =
      r'^\+20(10|11|12|15)[0-9]{8}$';

  static const int defaultPaginationPageSize = 20;
  static const int maxOtpLength = 6;
  static const int defaultNetworkRetryAttempts = 3;

  static const Duration splashDelayDuration = Duration(milliseconds: 1200);
  static const Duration toastDisplayDuration = Duration(seconds: 3);
  static const Duration debouncedSearchDuration = Duration(milliseconds: 400);
}
