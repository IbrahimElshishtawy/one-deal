import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_empty_widget.dart';

class BookingEmptyState extends StatelessWidget {
  const BookingEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return ActivityEmptyWidget(
      title: l10n.bookingsEmptyTitle,
      message: l10n.bookingsEmptyMessage,
      icon: Icons.calendar_month_outlined,
      actionLabel: l10n.favoritesExploreAction,
      onActionTap: () => context.go(RouteNames.homeServices),
    );
  }
}
