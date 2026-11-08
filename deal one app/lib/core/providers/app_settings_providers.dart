import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_keys.dart';
import 'core_providers.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final prefs = ref.watch(preferencesServiceProvider);
    final savedCode = prefs.getString(StorageKeys.languageCode);
    if (savedCode != null && savedCode.isNotEmpty) {
      return Locale(savedCode);
    }
    return const Locale('ar');
  }

  Future<void> setLocale(Locale newLocale) async {
    state = newLocale;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setString(StorageKeys.languageCode, newLocale.languageCode);
  }
}

final appLocaleProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(preferencesServiceProvider);
    final savedMode = prefs.getString(StorageKeys.themeMode);
    if (savedMode == 'dark') return ThemeMode.dark;
    if (savedMode == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setString(StorageKeys.themeMode, mode.name);
  }
}

final appThemeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});
