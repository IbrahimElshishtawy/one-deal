import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/drawer/models/drawer_item_config.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_item_widget.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_section_widget.dart';

/// Help & Legal Drawer section (Terms of Service, Privacy Policy).
class DrawerSupportWidget extends StatelessWidget {
  final List<DrawerItemConfig> items;
  final bool isArabic;
  final ValueChanged<DrawerItemConfig> onItemTap;

  const DrawerSupportWidget({
    super.key,
    required this.items,
    required this.isArabic,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return DrawerSectionWidget(
      key: const Key('drawer_support_legal_section'),
      title: isArabic ? 'المساعدة والسياسات' : 'Help & Legal',
      icon: Icons.help_outline_rounded,
      children: items
          .map(
            (item) => DrawerItemWidget(
              item: item,
              isArabic: isArabic,
              onTap: () => onItemTap(item),
            ),
          )
          .toList(),
    );
  }
}
