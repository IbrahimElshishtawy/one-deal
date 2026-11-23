import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_logo.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_logout_widget.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';

/// Drawer footer displaying the Sign Out action (when authenticated)
/// and Deal One platform branding.
class DrawerFooterWidget extends StatelessWidget {
  final bool isAuthenticated;
  final bool isArabic;
  final VoidCallback onLogout;

  const DrawerFooterWidget({
    super.key,
    required this.isAuthenticated,
    required this.isArabic,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('drawer_footer_widget'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAuthenticated) ...[
            Material(
              color: DealOneTokens.cardSurfaceOf(context),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.lg,
                side: BorderSide(color: DealOneTokens.cardBorderOf(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: DrawerLogoutWidget(
                isArabic: isArabic,
                onLogout: onLogout,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DealOneLogo(
                  key: Key('drawer_footer_brand_logo'),
                  height: 44,
                  showDarkModeGlow: true,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isArabic
                      ? 'DealOne — السوق الموحّد'
                      : 'DealOne — Unified Marketplace',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: DealOneTokens.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
