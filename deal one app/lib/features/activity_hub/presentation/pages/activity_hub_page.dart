import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/activity_hub/application/providers/activity_hub_provider.dart';
import 'package:market_space/features/activity_hub/application/providers/cart_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/activity_hub_header.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/activity_hub_tab_bar.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/activity_search_bar.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/activity_summary_section.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/bookings/bookings_tab_view.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/cart/cart_tab_view.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/favorites/favorites_tab_view.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/rfq/rfq_tab_view.dart';

class ActivityHubPage extends ConsumerStatefulWidget {
  final ActivityHubTab initialTab;

  const ActivityHubPage({
    super.key,
    this.initialTab = ActivityHubTab.cart,
  });

  @override
  ConsumerState<ActivityHubPage> createState() => _ActivityHubPageState();
}

class _ActivityHubPageState extends ConsumerState<ActivityHubPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(activityHubControllerProvider.notifier)
          .selectTab(widget.initialTab);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmClearCart() async {
    final l10n = AppLocalization.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.cartClearConfirmTitle),
        content: Text(l10n.cartClearConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.cartClearAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(cartProvider.notifier).clearCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hubState = ref.watch(activityHubControllerProvider);
    final summary = ref.watch(activityHubSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ActivityHubHeader(
              showClearCart:
                  hubState.selectedTab == ActivityHubTab.cart &&
                  summary.cartCount > 0,
              onClearCartTap: _confirmClearCart,
            ),
            ActivitySummarySection(
              counts: summary,
              onQuickTap: (tab) =>
                  ref.read(activityHubControllerProvider.notifier).selectTab(tab),
            ),
            const SizedBox(height: AppSpacing.sm),
            ActivityHubTabBar(
              selectedTab: hubState.selectedTab,
              onTabSelected: (tab) =>
                  ref.read(activityHubControllerProvider.notifier).selectTab(tab),
              badgeCounts: {
                ActivityHubTab.cart: summary.cartCount,
                ActivityHubTab.bookings: summary.bookingsCount,
                ActivityHubTab.rfq: summary.rfqCount,
                ActivityHubTab.favorites: summary.favoritesCount,
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ActivitySearchBar(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
                ref
                    .read(activityHubControllerProvider.notifier)
                    .setSearchQuery(value);
              },
              onClear: () {
                _searchController.clear();
                setState(() {});
                ref.read(activityHubControllerProvider.notifier).clearSearch();
              },
            ),
            Expanded(
              child: IndexedStack(
                index: hubState.selectedTab.index,
                children: const [
                  CartTabView(key: PageStorageKey('activity_cart_tab')),
                  BookingsTabView(key: PageStorageKey('activity_bookings_tab')),
                  RfqTabView(key: PageStorageKey('activity_rfq_tab')),
                  FavoritesTabView(
                    key: PageStorageKey('activity_favorites_tab'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
