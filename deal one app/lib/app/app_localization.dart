import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/generated/app_localizations_ar.dart';
import '../l10n/generated/app_localizations_en.dart';

export '../l10n/generated/app_localizations.dart';

class AppLocalization {
  static AppLocalizations of(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      return localizations;
    }
    // Graceful fallback when widgets are pumped in isolated unit/widget tests
    // without explicit localization delegates.
    final langCode = Localizations.maybeLocaleOf(context)?.languageCode;
    if (langCode == 'en') {
      return AppLocalizationsEn();
    }
    return AppLocalizationsAr();
  }

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      AppLocalizations.localizationsDelegates;

  static const List<Locale> supportedLocales =
      AppLocalizations.supportedLocales;
}
