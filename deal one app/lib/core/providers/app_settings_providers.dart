import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_keys.dart';
import 'core_providers.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadSaved();
    return const Locale('ar');
  }

  Future<void> _loadSaved() async {
    final prefs = ref.read(preferencesServiceProvider);
    final savedCode = await prefs.getString(StorageKeys.languageCode);
    if (savedCode != null && savedCode.isNotEmpty) {
      state = Locale(savedCode);
    }
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
    _loadSaved();
    return ThemeMode.system;
  }

  Future<void> _loadSaved() async {
    final prefs = ref.read(preferencesServiceProvider);
    final savedMode = await prefs.getString(StorageKeys.themeMode);
    if (savedMode == 'dark') {
      state = ThemeMode.dark;
    } else if (savedMode == 'light') {
      state = ThemeMode.light;
    }
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
