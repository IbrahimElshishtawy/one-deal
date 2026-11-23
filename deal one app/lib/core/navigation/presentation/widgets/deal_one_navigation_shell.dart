import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/navigation/models/navigation_item.dart';
import 'package:market_space/core/navigation/presentation/widgets/deal_one_bottom_navigation.dart';
import 'package:market_space/features/activity_hub/application/providers/activity_hub_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';

/// Inherited marker indicating that descendant pages are hosted inside
/// [DealOneNavigationShell] and should not render their own duplicate bottom bar.
class DealOneNavigationShellScope extends InheritedWidget {
  final int activeIndex;

  const DealOneNavigationShellScope({
    super.key,
    required this.activeIndex,
    required super.child,
  });

  static DealOneNavigationShellScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DealOneNavigationShellScope>();
  }

  static bool isInsideShell(BuildContext context) => maybeOf(context) != null;

  @override
  bool updateShouldNotify(DealOneNavigationShellScope oldWidget) {
    return activeIndex != oldWidget.activeIndex;
  }
}

/// Root navigation shell hosting the 4 primary tabs of Deal One
/// (Home, Favorites, Orders, Profile) via GoRouter's [StatefulNavigationShell].
///
/// - Preserves per-tab widget state and scroll positions via IndexedStack.
/// - Synchronizes active tab with GoRouter location & deep links.
/// - Handles Android back button cleanly (non-home tabs return to Home first).
/// - Hides the floating navigation bar automatically when the soft keyboard opens.
class DealOneNavigationShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const DealOneNavigationShell({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<DealOneNavigationShell> createState() =>
      _DealOneNavigationShellState();
}

class _DealOneNavigationShellState
    extends ConsumerState<DealOneNavigationShell> {
  ActivityHubTab _lastOrdersTab = ActivityHubTab.cart;
  int? _lastSyncedBranchIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncActivityHubTabForBranch(widget.navigationShell.currentIndex);
    });
  }

  @override
  void didUpdateWidget(covariant DealOneNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIndex = widget.navigationShell.currentIndex;
    if (currentIndex != _lastSyncedBranchIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncActivityHubTabForBranch(currentIndex);
      });
    }
  }

  void _syncActivityHubTabForBranch(int branchIndex) {
    _lastSyncedBranchIndex = branchIndex;
    final currentTab = ref.read(activityHubControllerProvider).selectedTab;
    if (currentTab != ActivityHubTab.favorites) {
      _lastOrdersTab = currentTab;
    }

    if (branchIndex == DealOneNavTab.favorites.index) {
      if (currentTab != ActivityHubTab.favorites) {
        ref
            .read(activityHubControllerProvider.notifier)
            .selectTab(ActivityHubTab.favorites);
      }
    } else if (branchIndex == DealOneNavTab.orders.index) {
      final uri = GoRouterState.of(context).uri;
      final tabParam = uri.queryParameters['tab'];
      final targetTab = tabParam != null
          ? ActivityHubTab.fromQuery(tabParam)
          : (currentTab == ActivityHubTab.favorites
              ? _lastOrdersTab
              : currentTab);
      if (currentTab != targetTab) {
        ref.read(activityHubControllerProvider.notifier).selectTab(targetTab);
      }
    }
  }

  void _handleTabSelected(int index) {
    // Tapping the already-active tab is a no-op (prevents unnecessary reload/flicker).
    if (index == widget.navigationShell.currentIndex) {
      return;
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = widget.navigationShell.currentIndex;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return PopScope(
      canPop: activeIndex == DealOneNavTab.home.index,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && activeIndex != DealOneNavTab.home.index) {
          widget.navigationShell.goBranch(DealOneNavTab.home.index);
        }
      },
      child: DealOneNavigationShellScope(
        activeIndex: activeIndex,
        child: Scaffold(
          backgroundColor: DealOneTokens.pageBgOf(context),
          body: widget.navigationShell,
          bottomNavigationBar: isKeyboardOpen
              ? const SizedBox.shrink()
              : DealOneBottomNavigation(
                  activeIndex: activeIndex,
                  onTabSelected: _handleTabSelected,
                ),
        ),
      ),
    );
  }
}
