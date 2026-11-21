import 'package:flutter/material.dart';

import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';
import 'package:market_space/features/activity_hub/presentation/utils/activity_hub_l10n.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/activity_filter_bar.dart';

class FavoritesCategoryFilter extends StatelessWidget {
  final MarketplaceSectorCategory selectedCategory;
  final ValueChanged<MarketplaceSectorCategory> onSelected;

  const FavoritesCategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = MarketplaceSectorCategory.values
        .map(
          (cat) => ActivityFilterOption<MarketplaceSectorCategory>(
            value: cat,
            label: ActivityHubL10n.sectorLabel(context, cat),
          ),
        )
        .toList();

    return ActivityFilterBar<MarketplaceSectorCategory>(
      options: options,
      selectedValue: selectedCategory,
      onSelected: onSelected,
    );
  }
}
