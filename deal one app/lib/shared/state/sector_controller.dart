import 'package:flutter/material.dart';

import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/core/storage/storage_keys.dart';
import 'package:market_space/shared/models/market_sector.dart';

/// Manages and persists the active market sector in Bazar Jo.
class SectorController extends ValueNotifier<MarketSector> {
  final PreferencesService preferencesService;

  SectorController({
    required this.preferencesService,
    MarketSector initialSector = MarketSector.realEstate,
  }) : super(initialSector);

  Future<void> loadSavedSector() async {
    final savedKey = await preferencesService.getString(
      StorageKeys.selectedSector,
    );
    if (savedKey != null) {
      value = MarketSector.fromKey(savedKey);
    }
  }

  Future<void> setSector(MarketSector newSector) async {
    if (value == newSector) return;
    value = newSector;
    await preferencesService.setString(
      StorageKeys.selectedSector,
      newSector.key,
    );
  }
}
