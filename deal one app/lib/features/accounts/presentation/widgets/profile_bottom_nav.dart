import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/navigation/config/deal_one_navigation_routes.dart';
import 'package:market_space/core/navigation/models/navigation_item.dart';
import 'package:market_space/core/navigation/presentation/widgets/deal_one_bottom_navigation.dart';

/// Backward-compatible wrapper around [DealOneBottomNavigation] used when
/// [ProfileScreen] is rendered standalone (outside [DealOneNavigationShell]).
class ProfileBottomNav extends StatelessWidget {
  final int activeIndex;

  const ProfileBottomNav({super.key, this.activeIndex = 3});

  @override
  Widget build(BuildContext context) {
    return DealOneBottomNavigation(
      activeIndex: activeIndex,
      onTabSelected: (index) {
        if (index == activeIndex) return;
        final route = DealOneNavigationRoutes.routeForTab(
          DealOneNavTab.fromIndex(index),
        );
        final router = GoRouter.maybeOf(context);
        router?.go(route);
      },
    );
  }
}
