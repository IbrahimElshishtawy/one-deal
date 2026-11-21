import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/activity_hub/application/providers/activity_hub_provider.dart';
import 'package:market_space/features/activity_hub/application/providers/bookings_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/presentation/utils/activity_hub_l10n.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/activity_filter_bar.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/bookings/booking_card.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/bookings/booking_empty_state.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_backend_notice_banner.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_error_widget.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_loading_widget.dart';

class BookingsTabView extends ConsumerWidget {
  const BookingsTabView({super.key});

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
  ) async {
    final l10n = AppLocalization.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.bookingsCancelConfirmTitle),
        content: Text(l10n.bookingsCancelConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(bookingsProvider.notifier).cancelBooking(bookingId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalization.of(context);
    final state = ref.watch(bookingsProvider);
    final query = ref
        .watch(activityHubControllerProvider.select((s) => s.searchQuery))
        .trim()
        .toLowerCase();
    final hPad = context.horizontalScreenPadding;

    final filterOptions = <ActivityFilterOption<BookingCategory?>>[
      ActivityFilterOption(value: null, label: l10n.activityFilterAll),
      ...BookingCategory.values.map(
        (cat) => ActivityFilterOption(
          value: cat,
          label: ActivityHubL10n.bookingCategoryLabel(context, cat),
        ),
      ),
    ];

    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        ActivityFilterBar<BookingCategory?>(
          options: filterOptions,
          selectedValue: state.selectedCategory,
          onSelected: (cat) =>
              ref.read(bookingsProvider.notifier).setCategoryFilter(cat),
        ),
        if (!state.isBackendSupported) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, AppSpacing.sm, hPad, 0),
            child: ActivityBackendNoticeBanner(
              message: l10n.activityBackendPendingNotice,
            ),
          ),
        ],
        Expanded(
          child: state.items.when(
            loading: () => const ActivityLoadingWidget(),
            error: (err, _) => ActivityErrorWidget(
              error: err,
              onRetry: () => ref.read(bookingsProvider.notifier).loadBookings(),
            ),
            data: (bookings) {
              final filtered = bookings.where((b) {
                if (state.selectedCategory != null &&
                    b.category != state.selectedCategory) {
                  return false;
                }
                if (query.isNotEmpty) {
                  return b.title.toLowerCase().contains(query) ||
                      b.providerName.toLowerCase().contains(query) ||
                      b.address.toLowerCase().contains(query);
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(bookingsProvider.notifier)
                      .loadBookings(refresh: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 40),
                      BookingEmptyState(),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref
                    .read(bookingsProvider.notifier)
                    .loadBookings(refresh: true),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    AppSpacing.md,
                    hPad,
                    AppSpacing.xxl,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final booking = filtered[index];
                    return BookingCard(
                      booking: booking,
                      onViewListingTap: booking.listingId != null
                          ? () => context.push('/listings/${booking.listingId}')
                          : null,
                      onContactTap: booking.listingId != null
                          ? () => context.push('/listings/${booking.listingId}')
                          : null,
                      onCancelTap: booking.canCancel
                          ? () => _confirmCancel(context, ref, booking.id)
                          : null,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
