import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/navigation/drawer/config/category_drawer_registry.dart';
import 'package:market_space/core/navigation/drawer/models/drawer_item_config.dart';
import 'package:market_space/core/navigation/providers/section_navigation_provider.dart';

export 'package:market_space/core/navigation/drawer/providers/drawer_badge_providers.dart';

/// Single unified Riverpod provider resolving the dynamic, capability-filtered
/// [ResolvedDrawerConfig] for a given active category slug.
///
/// Reuses [accountCapabilitiesProvider] so permission logic is never duplicated.
final drawerConfigProvider =
    Provider.family<ResolvedDrawerConfig, String>((ref, categorySlug) {
  final capabilities = ref.watch(accountCapabilitiesProvider);
  return CategoryDrawerRegistry.resolve(categorySlug, capabilities);
});
