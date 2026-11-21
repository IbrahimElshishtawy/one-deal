import 'package:flutter/material.dart';

import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/core/storage/storage_keys.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  final PreferencesService preferencesService;

  ThemeController({
    required this.preferencesService,
    ThemeMode initialThemeMode = ThemeMode.system,
  }) : super(initialThemeMode);

  Future<void> loadSavedTheme() async {
    final savedMode = await preferencesService.getString(StorageKeys.themeMode);
    if (savedMode != null) {
      value = switch (savedMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    }
  }

  Future<void> setThemeMode(ThemeMode newMode) async {
    if (value == newMode) return;
    value = newMode;
    final modeString = switch (newMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await preferencesService.setString(StorageKeys.themeMode, modeString);
  }

  Future<void> toggleTheme() async {
    final nextMode = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}
