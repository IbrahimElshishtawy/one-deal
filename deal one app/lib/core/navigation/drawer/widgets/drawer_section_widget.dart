import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';

/// Reusable titled card section inside the Navigation Drawer.
/// Uses a [Material] surface so nested [ListTile] ink splashes and selection
/// highlights paint properly in Light and Dark themes.
class DrawerSectionWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const DrawerSectionWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, AppSpacing.md, 6),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: DealOneTokens.textSecondaryOf(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: DealOneTokens.textSecondaryOf(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Material(
            color: DealOneTokens.cardSurfaceOf(context),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.lg,
              side: BorderSide(color: DealOneTokens.cardBorderOf(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}
