import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/navigation/config/section_navigation_config.dart';
import 'package:market_space/core/navigation/config/section_navigation_registry.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:market_space/features/activity_hub/application/providers/cart_provider.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';

/// Feature flag / backend support provider for V1 Saved Cart.
/// Confirmed supported by Backend `CartController` (`/api/v1/cart`, V1_SAVED_BASKET).
final cartFeatureSupportedProvider = Provider<bool>((ref) => true);

/// Single source of truth for the current user's verified capabilities.
/// Automatically updates when session changes, account is activated/deactivated,
/// or the user switches between multi-tenant accounts — with zero logout required.
final accountCapabilitiesProvider = Provider<AccountCapabilities>((ref) {
  final session = ref.watch(sessionProvider);
  final cartSupported = ref.watch(cartFeatureSupportedProvider);

  if (!session.isAuthenticated) {
    return AccountCapabilities.guest(isCartSupported: cartSupported);
  }

  final accountsAsync = ref.watch(myAccountsProvider);
  final selectedAccount = ref.watch(activeAccountProvider);

  // While initial account verification data is loading (and no cached value exists),
  // expose `isLoading = true` so the navigation bar renders a clean loading slot
  // instead of flickering Favorites -> My Listings.
  if (accountsAsync.isLoading && !accountsAsync.hasValue) {
    return AccountCapabilities.loading(isCartSupported: cartSupported);
  }

  final accounts = accountsAsync.valueOrNull ?? const [];
  final effectiveSelected = selectedAccount != null &&
          accounts.any((a) => a.id == selectedAccount.id)
      ? accounts.firstWhere((a) => a.id == selectedAccount.id)
      : (accounts.isNotEmpty ? accounts.first : null);

  return AccountCapabilities(
    isAuthenticated: true,
    isLoading: false,
    activeAccount: effectiveSelected,
    accounts: accounts,
    isCartSupported: cartSupported,
  );
});

/// Resolves the dynamic, role-aware [SectionNavigationConfig] for a category slug.
final sectionNavigationConfigProvider =
    Provider.family<SectionNavigationConfig, String>((ref, sectionId) {
  final capabilities = ref.watch(accountCapabilitiesProvider);
  return SectionNavigationRegistry.resolveConfig(sectionId, capabilities);
});

/// Total unread chat messages count across active conversations for badge display.
final unreadChatCountProvider = Provider<int>((ref) {
  final session = ref.watch(sessionProvider);
  if (!session.isAuthenticated) return 0;
  final conversations = ref.watch(conversationsListProvider).valueOrNull;
  if (conversations == null || conversations.isEmpty) return 0;
  return conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
});

/// Category-aware badge count resolver for navigation items (`chat_unread`, `cart_count`).
final navigationBadgeCountProvider =
    Provider.family<int, String?>((ref, badgeKey) {
  if (badgeKey == null || badgeKey.isEmpty) return 0;
  switch (badgeKey) {
    case 'chat_unread':
      return ref.watch(unreadChatCountProvider);
    case 'cart_count':
      try {
        return ref.watch(cartSummaryProvider).totalQuantity;
      } catch (_) {
        return 0;
      }
    default:
      return 0;
  }
});
