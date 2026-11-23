import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/navigation/drawer/models/drawer_item_config.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_badge_widget.dart';

/// Reusable single Drawer navigation row with accessible tap target,
/// RTL/LTR directional chevron, and isolated live badge updates.
class DrawerItemWidget extends StatelessWidget {
  final DrawerItemConfig item;
  final bool isArabic;
  final VoidCallback onTap;

  const DrawerItemWidget({
    super.key,
    required this.item,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chevron = Icon(
      isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
      size: 18,
      color: DealOneTokens.textSecondaryOf(context),
    );

    final hasBadgeSource = item.badgeProvider != null ||
        (item.badgeKey != null && item.badgeKey!.isNotEmpty);

    return ListTile(
      key: Key('drawer_item_${item.id}'),
      dense: true,
      minVerticalPadding: 10,
      leading: Icon(
        item.icon,
        size: 20,
        color: DealOneTokens.navy,
      ),
      title: Text(
        item.localizedLabel(isArabic),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: DealOneTokens.textPrimaryOf(context),
        ),
      ),
      trailing: hasBadgeSource
          ? DrawerBadgeWidget(
              itemId: item.id,
              badgeProvider: item.badgeProvider,
              badgeKey: item.badgeKey,
              fallbackTrailing: chevron,
            )
          : chevron,
      onTap: onTap,
    );
  }
}
