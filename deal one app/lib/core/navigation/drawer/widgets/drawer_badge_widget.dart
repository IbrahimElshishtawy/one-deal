import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/navigation/drawer/providers/drawer_badge_providers.dart';
import 'package:market_space/core/theme/app_radii.dart';

/// Isolated badge consumer widget so badge count updates rebuild ONLY this
/// small pill rather than the entire Navigation Drawer.
class DrawerBadgeWidget extends ConsumerWidget {
  final String itemId;
  final ProviderListenable<int>? badgeProvider;
  final String? badgeKey;
  final Widget fallbackTrailing;

  const DrawerBadgeWidget({
    super.key,
    required this.itemId,
    this.badgeProvider,
    this.badgeKey,
    required this.fallbackTrailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count;
    if (badgeProvider != null) {
      int resolved = 0;
      try {
        resolved = ref.watch(badgeProvider!);
      } catch (_) {
        resolved = 0;
      }
      count = resolved;
    } else if (badgeKey != null && badgeKey!.isNotEmpty) {
      count = ref.watch(drawerBadgeCountProvider(badgeKey));
    } else {
      count = 0;
    }

    if (count <= 0) {
      return fallbackTrailing;
    }

    return Container(
      key: Key('drawer_badge_$itemId'),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: AppRadii.full,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
