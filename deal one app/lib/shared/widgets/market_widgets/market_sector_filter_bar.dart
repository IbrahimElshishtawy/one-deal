import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../models/market_sector.dart';

class MarketSectorFilterBar extends StatelessWidget {
  final MarketSector activeSector;
  final ValueChanged<MarketSector> onSectorChanged;

  const MarketSectorFilterBar({
    super.key,
    required this.activeSector,
    required this.onSectorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompactPhone;
    final horizontalPadding = context.horizontalScreenPadding;

    final chips = [
      _SectorChipData(
        sector: MarketSector.all,
        title: 'الكل',
        icon: Icons.grid_view_rounded,
      ),
      _SectorChipData(
        sector: MarketSector.realEstate,
        title: 'عقارات للبيع',
        icon: Icons.apartment_rounded,
      ),
      _SectorChipData(
        sector: MarketSector.realEstate,
        title: 'عقارات للإيجار',
        icon: Icons.vpn_key_rounded,
      ),
      _SectorChipData(
        sector: MarketSector.buildingMaterials,
        title: 'مُوَن ومواد بناء',
        icon: Icons.handyman_rounded,
      ),
      _SectorChipData(
        sector: MarketSector.services,
        title: 'خدمات ومقاولات',
        icon: Icons.engineering_rounded,
      ),
      _SectorChipData(
        sector: MarketSector.investments,
        title: 'المشروعات والاستثمار',
        icon: Icons.trending_up_rounded,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.xs + 2,
      ),
      child: Row(
        children: chips.map((chip) {
          final isSelected = activeSector == chip.sector;

          return Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: InkWell(
              onTap: () => onSectorChanged(chip.sector),
              borderRadius: AppRadii.full,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 10.0 : 13.0,
                  vertical: isCompact ? 6.0 : 7.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryOf(context)
                      : AppColors.surfaceOf(context),
                  borderRadius: AppRadii.full,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryOf(context)
                        : AppColors.borderOf(context),
                  ),
                  boxShadow: isSelected && !AppColors.isDark(context)
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 6.0,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      chip.icon,
                      size: isCompact ? 15.0 : 17.0,
                      color: isSelected
                          ? AppColors.onPrimaryOf(context)
                          : AppColors.textPrimaryOf(context),
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      chip.title,
                      style: TextStyle(
                        fontSize: isCompact ? 11.5 : 12.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected
                            ? AppColors.onPrimaryOf(context)
                            : AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectorChipData {
  final MarketSector sector;
  final String title;
  final IconData icon;

  const _SectorChipData({
    required this.sector,
    required this.title,
    required this.icon,
  });
}
