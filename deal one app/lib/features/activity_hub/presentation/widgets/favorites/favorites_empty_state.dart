import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_empty_widget.dart';

class FavoritesEmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback? onResetFilters;

  const FavoritesEmptyState({
    super.key,
    this.isFiltered = false,
    this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    if (isFiltered) {
      return ActivityEmptyWidget(
        title: l10n.favoritesSearchEmptyTitle,
        message: l10n.favoritesSearchEmptyMessage,
        icon: Icons.search_off_rounded,
        actionLabel: l10n.activityFilterAll,
        onActionTap: onResetFilters,
      );
    }

    return ActivityEmptyWidget(
      title: l10n.favoritesEmptyTitle,
      message: l10n.favoritesEmptyMessage,
      icon: Icons.favorite_border_rounded,
      actionLabel: l10n.favoritesExploreAction,
      onActionTap: () => context.go(RouteNames.root),
    );
  }
}
