import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';

/// Dedicated Settings, Language, and Theme trigger tile inside Account Management.
class DrawerSettingsWidget extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onTap;

  const DrawerSettingsWidget({
    super.key,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const Key('drawer_item_drawer_account_settings'),
      dense: true,
      minVerticalPadding: 10,
      leading: const Icon(
        Icons.settings_outlined,
        size: 20,
        color: DealOneTokens.navy,
      ),
      title: Text(
        isArabic ? 'الإعدادات واللغة والمظهر' : 'Settings, Language & Theme',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: DealOneTokens.textPrimaryOf(context),
        ),
      ),
      trailing: Icon(
        isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
        size: 18,
        color: DealOneTokens.textSecondaryOf(context),
      ),
      onTap: onTap,
    );
  }
}
