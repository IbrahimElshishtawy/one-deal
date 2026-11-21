// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'package:market_space/l10n/app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Market Space';

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
}
