import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';

/// Dedicated Sign Out action tile rendered only for authenticated sessions.
class DrawerLogoutWidget extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onLogout;

  const DrawerLogoutWidget({
    super.key,
    required this.isArabic,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const Key('drawer_account_logout'),
      dense: true,
      minVerticalPadding: 10,
      leading: const Icon(
        Icons.logout_rounded,
        size: 20,
        color: DealOneTokens.dangerRed,
      ),
      title: Text(
        isArabic ? 'تسجيل الخروج' : 'Sign Out',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: DealOneTokens.dangerRed,
        ),
      ),
      onTap: onLogout,
    );
  }
}
