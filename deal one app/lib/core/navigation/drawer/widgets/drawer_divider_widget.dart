import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_spacing.dart';

/// Consistent horizontal divider separating Drawer sections.
class DrawerDividerWidget extends StatelessWidget {
  const DrawerDividerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Divider(
        height: 1,
        thickness: 1,
        color: DealOneTokens.cardBorderOf(context),
      ),
    );
  }
}
