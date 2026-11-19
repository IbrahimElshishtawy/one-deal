import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_keys.dart';
import 'core_providers.dart';

class LocaleNotifier extends Notifier<Locale> {
  bool _userUpdated = false;

  @override
  Locale build() {
    _userUpdated = false;
    _loadSaved();
    return const Locale('ar');
  }

  Future<void> _loadSaved() async {
    final prefs = ref.read(preferencesServiceProvider);
    final savedCode = await prefs.getString(StorageKeys.languageCode);
    if (_userUpdated) return;
    if (savedCode != null && savedCode.isNotEmpty) {
      state = Locale(savedCode);
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    _userUpdated = true;
    state = newLocale;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setString(StorageKeys.languageCode, newLocale.languageCode);
  }
}

final appLocaleProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  bool _userUpdated = false;

  @override
  ThemeMode build() {
    _userUpdated = false;
    _loadSaved();
    return ThemeMode.system;
  }

  Future<void> _loadSaved() async {
    final prefs = ref.read(preferencesServiceProvider);
    final savedMode = await prefs.getString(StorageKeys.themeMode);
    if (_userUpdated) return;
    if (savedMode == 'dark') {
      state = ThemeMode.dark;
    } else if (savedMode == 'light') {
      state = ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _userUpdated = true;
    state = mode;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setString(StorageKeys.themeMode, mode.name);
  }
}

final appThemeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});
