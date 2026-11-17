import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../models/market_sector.dart';

class MarketCategoryGrid extends StatelessWidget {
  final ValueChanged<MarketSector>? onSelectSector;

  const MarketCategoryGrid({super.key, this.onSelectSector});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = context.horizontalScreenPadding;
    final isCompact = context.isCompactPhone;

    final categories = [
      _CategoryCardData(
        title: 'عقارات للبيع',
        subtitles: 'شقق • فلل • أراضي',
        icon: Icons.real_estate_agent_rounded,
        iconColor: AppColors.textPrimaryOf(context),
        backgroundColor: AppColors.secondaryTintOf(context),
        sector: MarketSector.realEstate,
      ),
      _CategoryCardData(
        title: 'عقارات للإيجار',
        subtitles: 'شهري • سنوي • مفروش',
        icon: Icons.vpn_key_rounded,
        iconColor: AppColors.errorOf(context),
        backgroundColor: AppColors.errorTintOf(context),
        sector: MarketSector.realEstate,
      ),
      _CategoryCardData(
        title: 'مُوَن وبناء',
        subtitles: 'أسمنت • حديد • بلاط',
        icon: Icons.view_in_ar_rounded,
        iconColor: AppColors.textPrimaryOf(context),
        backgroundColor: AppColors.tertiaryTintOf(context),
        sector: MarketSector.buildingMaterials,
      ),
      _CategoryCardData(
        title: 'خدمات وصيانة',
        subtitles: 'تشطيب • سباكة • نقل',
        icon: Icons.engineering_rounded,
        iconColor: AppColors.infoOf(context),
        backgroundColor: AppColors.infoTintOf(context),
        sector: MarketSector.services,
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (int i = 0; i < categories.length; i++) ...[
            if (i > 0) SizedBox(width: isCompact ? 6.0 : 8.0),
            Expanded(
              child: _buildCategoryCard(context, categories[i], isCompact),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    _CategoryCardData data,
    bool isCompact,
  ) {
    return InkWell(
      onTap: () => onSelectSector?.call(data.sector),
      borderRadius: AppRadii.lg,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 4.0 : 6.0,
          vertical: isCompact ? 10.0 : 12.0,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: AppRadii.lg,
          border: Border.all(color: AppColors.borderOf(context)),
          boxShadow: AppColors.isDark(context)
              ? const []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            Container(
              width: isCompact ? 38.0 : 44.0,
              height: isCompact ? 38.0 : 44.0,
              decoration: BoxDecoration(
                color: data.backgroundColor,
                borderRadius: AppRadii.md,
              ),
              child: Icon(
                data.icon,
                size: isCompact ? 20.0 : 24.0,
                color: data.iconColor,
              ),
            ),
            const SizedBox(height: 7.0),
            // Title
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isCompact ? 11.0 : 12.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ),
            const SizedBox(height: 3.0),
            // Subtitle
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data.subtitles,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isCompact ? 8.0 : 9.5,
                  fontWeight: FontWeight.w500,
                  color: data.iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCardData {
  final String title;
  final String subtitles;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final MarketSector sector;

  const _CategoryCardData({
    required this.title,
    required this.subtitles,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.sector,
  });
}
