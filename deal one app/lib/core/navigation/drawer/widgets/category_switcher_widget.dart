import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/navigation/drawer/models/drawer_item_config.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_section_widget.dart';

/// Displays the 6 Deal One categories + Main Hub switcher inside the Drawer,
/// highlighting the currently active section.
class CategorySwitcherWidget extends StatelessWidget {
  final String activeCategorySlug;
  final List<DrawerCategoryEntry> categories;
  final bool isArabic;
  final ValueChanged<DrawerCategoryEntry> onCategorySelected;
  final VoidCallback onMainHubSelected;

  const CategorySwitcherWidget({
    super.key,
    required this.activeCategorySlug,
    required this.categories,
    required this.isArabic,
    required this.onCategorySelected,
    required this.onMainHubSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DrawerSectionWidget(
      key: const Key('drawer_category_switcher_section'),
      title: isArabic ? 'الأقسام' : 'Categories',
      icon: Icons.grid_view_rounded,
      children: [
        ...categories.map((entry) {
          final isCurrent = entry.slug == activeCategorySlug;
          return ListTile(
            key: Key('drawer_category_${entry.slug}'),
            dense: true,
            selected: isCurrent,
            selectedTileColor: DealOneTokens.navy.withValues(alpha: 0.08),
            leading: Icon(
              entry.icon,
              size: 20,
              color: isCurrent
                  ? DealOneTokens.navy
                  : DealOneTokens.textSecondaryOf(context),
            ),
            title: Text(
              entry.localizedLabel(isArabic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent
                    ? DealOneTokens.navy
                    : DealOneTokens.textPrimaryOf(context),
              ),
            ),
            trailing: isCurrent
                ? const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: DealOneTokens.navy,
                  )
                : null,
            onTap: () => onCategorySelected(entry),
          );
        }),
        ListTile(
          key: const Key('drawer_switch_main_hub'),
          dense: true,
          leading: Icon(
            Icons.home_outlined,
            size: 20,
            color: DealOneTokens.textSecondaryOf(context),
          ),
          title: Text(
            isArabic ? 'الصفحة الرئيسية العامة' : 'Main Hub',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: DealOneTokens.textPrimaryOf(context),
            ),
          ),
          onTap: onMainHubSelected,
        ),
      ],
    );
  }
}
