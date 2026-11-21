import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:market_space/features/activity_hub/application/providers/bookings_provider.dart';
import 'package:market_space/features/activity_hub/application/providers/cart_provider.dart';
import 'package:market_space/features/activity_hub/application/providers/rfq_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';

class ActivityHubUiState {
  final ActivityHubTab selectedTab;
  final String searchQuery;

  const ActivityHubUiState({
    this.selectedTab = ActivityHubTab.cart,
    this.searchQuery = '',
  });

  ActivityHubUiState copyWith({
    ActivityHubTab? selectedTab,
    String? searchQuery,
  }) {
    return ActivityHubUiState(
      selectedTab: selectedTab ?? this.selectedTab,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ActivityHubController extends StateNotifier<ActivityHubUiState> {
  ActivityHubController([ActivityHubTab initialTab = ActivityHubTab.cart])
    : super(ActivityHubUiState(selectedTab: initialTab));

  void selectTab(ActivityHubTab tab) {
    if (state.selectedTab == tab) return;
    state = state.copyWith(selectedTab: tab);
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    if (state.searchQuery.isEmpty) return;
    state = state.copyWith(searchQuery: '');
  }
}

final activityHubControllerProvider =
    StateNotifierProvider<ActivityHubController, ActivityHubUiState>((ref) {
      return ActivityHubController();
    });

class ActivityHubSummaryCounts {
  final int cartCount;
  final int bookingsCount;
  final int rfqCount;
  final int favoritesCount;

  const ActivityHubSummaryCounts({
    this.cartCount = 0,
    this.bookingsCount = 0,
    this.rfqCount = 0,
    this.favoritesCount = 0,
  });
}

final activityHubSummaryProvider = Provider<ActivityHubSummaryCounts>((ref) {
  final cartCount = ref.watch(cartSummaryProvider).totalQuantity;
  final bookingsCount =
      ref.watch(bookingsProvider).items.valueOrNull?.length ?? 0;
  final rfqCount = ref.watch(rfqProvider).items.valueOrNull?.length ?? 0;
  final favoritesCount = ref.watch(favoritesProvider).valueOrNull?.length ?? 0;

  return ActivityHubSummaryCounts(
    cartCount: cartCount,
    bookingsCount: bookingsCount,
    rfqCount: rfqCount,
    favoritesCount: favoritesCount,
  );
});
