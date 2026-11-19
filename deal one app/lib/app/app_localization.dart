import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';

class AppLocalization {
  static AppLocalizations of(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      throw StateError('AppLocalizations not found in widget context.');
    }
    return localizations;
  }

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      AppLocalizations.localizationsDelegates;

  static const List<Locale> supportedLocales =
      AppLocalizations.supportedLocales;
}
