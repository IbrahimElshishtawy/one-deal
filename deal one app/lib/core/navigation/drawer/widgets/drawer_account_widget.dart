import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/drawer/models/drawer_item_config.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_item_widget.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_section_widget.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_settings_widget.dart';

/// Account Management Drawer section composing Profile, Edit Account,
/// Notifications, Messages (when not in Bottom Nav), and [DrawerSettingsWidget].
class DrawerAccountWidget extends StatelessWidget {
  final List<DrawerItemConfig> items;
  final bool isArabic;
  final ValueChanged<DrawerItemConfig> onItemTap;
  final VoidCallback onSettingsTap;

  const DrawerAccountWidget({
    super.key,
    required this.items,
    required this.isArabic,
    required this.onItemTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return DrawerSectionWidget(
      key: const Key('drawer_account_management_section'),
      title: isArabic ? 'إدارة الحساب' : 'Account Management',
      icon: Icons.shield_outlined,
      children: [
        ...items
            .where((item) => item.action != DrawerItemAction.openSettingsSheet)
            .map(
              (item) => DrawerItemWidget(
                item: item,
                isArabic: isArabic,
                onTap: () => onItemTap(item),
              ),
            ),
        DrawerSettingsWidget(
          isArabic: isArabic,
          onTap: onSettingsTap,
        ),
      ],
    );
  }
}
