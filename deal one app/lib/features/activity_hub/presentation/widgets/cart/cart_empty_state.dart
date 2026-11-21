import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_empty_widget.dart';

class CartEmptyState extends StatelessWidget {
  const CartEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return ActivityEmptyWidget(
      title: l10n.cartEmptyTitle,
      message: l10n.cartEmptyMessage,
      icon: Icons.shopping_basket_outlined,
      actionLabel: l10n.cartExploreProducts,
      onActionTap: () => context.go(RouteNames.root),
    );
  }
}
