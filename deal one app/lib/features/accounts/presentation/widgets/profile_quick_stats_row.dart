import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

class ProfileStatItem {
  final String label;
  final IconData icon;
  final int count;
  final bool highlightBadge;
  final VoidCallback onTap;

  const ProfileStatItem({
    required this.label,
    required this.icon,
    required this.count,
    required this.onTap,
    this.highlightBadge = true,
  });
}

/// 3-column quick stats row matching `Profile.png`:
/// Active Viewings, Favorites, Conversations with real badge counts.
class ProfileQuickStatsRow extends StatelessWidget {
  final List<ProfileStatItem> items;

  const ProfileQuickStatsRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final gap = context.isSmallPhone ? AppSpacing.sm : AppSpacing.md;
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: _ProfileStatTile(item: items[i])),
        ],
      ],
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  final ProfileStatItem item;

  const _ProfileStatTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: AppRadii.lg,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: DealOneTokens.cardDecoration(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (item.count > 0)
                PositionedDirectional(
                  top: -2,
                  end: 0,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 22,
                      minHeight: 22,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: item.highlightBadge
                          ? DealOneTokens.amberTintOf(context)
                          : DealOneTokens.softTileBgOf(context),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      item.count > 99 ? '99+' : '${item.count}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: item.highlightBadge
                            ? DealOneTokens.amber
                            : DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 6),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: DealOneTokens.softTileBgOf(context),
                        borderRadius: AppRadii.md,
                      ),
                      child: Icon(
                        item.icon,
                        size: 22,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.isSmallPhone ? 11.5 : 12.5,
                        fontWeight: FontWeight.w700,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
