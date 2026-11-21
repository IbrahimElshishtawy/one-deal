import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/activity_hub/application/providers/activity_hub_provider.dart';
import 'package:market_space/features/activity_hub/application/providers/cart_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/cart_item_entity.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/cart/cart_empty_state.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/cart/cart_item_card.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/cart/cart_price_summary.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_error_widget.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_loading_widget.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';

class CartTabView extends ConsumerWidget {
  const CartTabView({super.key});

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    CartItemEntity item,
  ) async {
    final l10n = AppLocalization.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.cartRemoveConfirmTitle),
        content: Text(l10n.cartRemoveConfirmMessage(item.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.cartRemoveItem),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(cartProvider.notifier).removeItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cartRemovedSuccess)),
        );
      }
    }
  }

  Future<void> _saveForLater(
    BuildContext context,
    WidgetRef ref,
    CartItemEntity item,
  ) async {
    final l10n = AppLocalization.of(context);
    final favNotifier = ref.read(favoritesProvider.notifier);
    if (!favNotifier.isFavorited(item.listingId)) {
      await favNotifier.toggleFavorite(item.listingId);
    }
    await ref.read(cartProvider.notifier).removeItem(item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cartSavedForLaterSuccess)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final summary = ref.watch(cartSummaryProvider);
    final query = ref
        .watch(activityHubControllerProvider.select((s) => s.searchQuery))
        .trim()
        .toLowerCase();
    final hPad = context.horizontalScreenPadding;

    return cartState.items.when(
      loading: () => const ActivityLoadingWidget(),
      error: (err, _) => ActivityErrorWidget(
        error: err,
        onRetry: () => ref.read(cartProvider.notifier).loadCart(),
      ),
      data: (items) {
        final filtered = query.isEmpty
            ? items
            : items
                  .where(
                    (e) =>
                        e.title.toLowerCase().contains(query) ||
                        e.sellerName.toLowerCase().contains(query),
                  )
                  .toList();

        if (filtered.isEmpty) {
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(cartProvider.notifier).loadCart(refresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 60),
                CartEmptyState(),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(cartProvider.notifier).loadCart(refresh: true),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    AppSpacing.md,
                    hPad,
                    AppSpacing.lg,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return CartItemCard(
                      item: item,
                      isMutating: cartState.isMutating,
                      onTap: () => context.push('/listings/${item.listingId}'),
                      onIncrement: () => ref
                          .read(cartProvider.notifier)
                          .updateQuantity(item.id, item.quantity + 1),
                      onDecrement: () => ref
                          .read(cartProvider.notifier)
                          .updateQuantity(item.id, item.quantity - 1),
                      onRemove: () => _confirmRemove(context, ref, item),
                      onSaveForLater: () => _saveForLater(context, ref, item),
                    );
                  },
                ),
              ),
            ),
            CartPriceSummary(
              summary: summary,
              onCheckoutPressed: () {
                // V1 operates on direct seller contact; open first item's listing
                // for contact reveal rather than faking a payment checkout.
                context.push('/listings/${filtered.first.listingId}');
              },
            ),
          ],
        );
      },
    );
  }
}
