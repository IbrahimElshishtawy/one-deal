import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';

class ProfileMenuRowItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
  final Key? tileKey;

  const ProfileMenuRowItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
    this.tileKey,
  });
}

/// Grouped menu card matching `Profile.png` with soft square icons,
/// chevron indicators, divider before logout, and destructive logout row.
class ProfileMenuCard extends StatelessWidget {
  final List<ProfileMenuRowItem> primaryItems;
  final ProfileMenuRowItem? logoutItem;

  const ProfileMenuCard({
    super.key,
    required this.primaryItems,
    this.logoutItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DealOneTokens.cardDecoration(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < primaryItems.length; i++)
            _MenuRow(item: primaryItems[i]),
          if (logoutItem != null) ...[
            Divider(
              height: 1,
              indent: AppSpacing.lg,
              endIndent: AppSpacing.lg,
              color: DealOneTokens.cardBorderOf(context),
            ),
            _MenuRow(item: logoutItem!),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final ProfileMenuRowItem item;

  const _MenuRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.isDestructive
        ? DealOneTokens.dangerRed
        : DealOneTokens.textPrimaryOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: item.tileKey,
        onTap: item.onTap,
        borderRadius: AppRadii.lg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.isDestructive
                      ? DealOneTokens.dangerSoftBg
                      : DealOneTokens.softTileBgOf(context),
                  borderRadius: AppRadii.md,
                ),
                child: Icon(item.icon, size: 20, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              if (!item.isDestructive) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: DealOneTokens.textPrimaryOf(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
