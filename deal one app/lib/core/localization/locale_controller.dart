import 'package:flutter/material.dart';

import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/core/storage/storage_keys.dart';
import 'package:market_space/core/localization/supported_locales.dart';

class LocaleController extends ValueNotifier<Locale> {
  final PreferencesService preferencesService;

  LocaleController({
    required this.preferencesService,
    Locale initialLocale = SupportedLocales.arabic,
  }) : super(initialLocale);

  Future<void> loadSavedLocale() async {
    final savedCode = await preferencesService.getString(
      StorageKeys.languageCode,
    );
    if (savedCode != null) {
      value = SupportedLocales.fromLanguageCode(savedCode);
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (value == newLocale) return;
    value = newLocale;
    await preferencesService.setString(
      StorageKeys.languageCode,
      newLocale.languageCode,
    );
  }

  Future<void> toggleLocale() async {
    final nextLocale = value.languageCode == 'ar'
        ? SupportedLocales.english
        : SupportedLocales.arabic;
    await setLocale(nextLocale);
  }
}
