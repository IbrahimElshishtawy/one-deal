import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

class _SpecCardData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SpecCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

/// 3-column specifications grid matching `Real Estate Details.png`.
class RealEstateSpecsGrid extends StatelessWidget {
  final Map<String, dynamic> attributes;

  const RealEstateSpecsGrid({super.key, required this.attributes});

  List<_SpecCardData> _buildSpecs(bool isArabic) {
    final result = <_SpecCardData>[];
    for (final entry in attributes.entries) {
      if (entry.value == null || entry.value.toString().trim().isEmpty) {
        continue;
      }
      final key = entry.key.toLowerCase();
      final valStr = entry.value is bool
          ? (entry.value == true
              ? (isArabic ? 'متوفر' : 'Yes')
              : (isArabic ? 'غير متوفر' : 'No'))
          : entry.value.toString();

      final meta = switch (key) {
        'rooms' => (
            icon: Icons.bed_outlined,
            title: isArabic ? '$valStr غرف' : '$valStr Rooms',
            subtitle: isArabic ? 'غرف النوم' : 'Bedrooms',
          ),
        'baths' => (
            icon: Icons.bathtub_outlined,
            title: isArabic ? '$valStr حمام' : '$valStr Baths',
            subtitle: isArabic ? 'الحمامات' : 'Bathrooms',
          ),
        'area_sqm' || 'land_area_sqm' => (
            icon: Icons.square_foot_rounded,
            title: isArabic ? '$valStr م²' : '$valStr m²',
            subtitle: isArabic ? 'صافي المساحة' : 'Net Area',
          ),
        'finishing' => (
            icon: Icons.auto_awesome_outlined,
            title: valStr,
            subtitle: isArabic ? 'التشطيب' : 'Finishing',
          ),
        'floor' => (
            icon: Icons.apartment_rounded,
            title: isArabic ? 'الدور $valStr' : 'Floor $valStr',
            subtitle: isArabic ? 'الطابق' : 'Level',
          ),
        'view' || 'direction' => (
            icon: Icons.explore_outlined,
            title: valStr,
            subtitle: isArabic ? 'الإطلالة' : 'Orientation',
          ),
        'elevator' || 'elevators' => (
            icon: Icons.elevator_outlined,
            title: valStr,
            subtitle: isArabic ? 'المصاعد' : 'Elevators',
          ),
        'gas' || 'utilities' => (
            icon: Icons.local_fire_department_outlined,
            title: valStr,
            subtitle: isArabic ? 'المرافق' : 'Utilities',
          ),
        'parking' || 'garage' => (
            icon: Icons.local_parking_rounded,
            title: valStr,
            subtitle: isArabic ? 'جراج خاص' : 'Parking',
          ),
        'furnished' => (
            icon: Icons.chair_outlined,
            title: valStr,
            subtitle: isArabic ? 'الفرش' : 'Furnished',
          ),
        _ => (
            icon: Icons.check_circle_outline_rounded,
            title: valStr,
            subtitle: key.replaceAll('_', ' '),
          ),
      };

      result.add(
        _SpecCardData(
          icon: meta.icon,
          title: meta.title,
          subtitle: meta.subtitle,
        ),
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final specs = _buildSpecs(isArabic);
    if (specs.isEmpty) return const SizedBox.shrink();

    final cols = (context.isSmallPhone || context.effectiveTextScale >= 1.55)
        ? 2
        : (context.isTablet ? 4 : 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 19,
              color: DealOneTokens.textPrimaryOf(context),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isArabic ? 'المواصفات الرئيسية' : 'Key Specifications',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: DealOneTokens.textPrimaryOf(context),
                ),
              ),
            ),
            Text(
              isArabic
                  ? '${specs.length} خصائص متوفرة'
                  : '${specs.length} specs',
              style: TextStyle(
                fontSize: 12,
                color: DealOneTokens.textSecondaryOf(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: specs.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            mainAxisExtent:
                104 + ((context.effectiveTextScale - 1.0).clamp(0.0, 1.0) * 34),
          ),
          itemBuilder: (context, index) {
            final spec = specs[index];
            return Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: DealOneTokens.cardDecoration(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: DealOneTokens.softTileBgOf(context),
                      borderRadius: AppRadii.sm,
                    ),
                    child: Icon(
                      spec.icon,
                      size: 18,
                      color: DealOneTokens.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    spec.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: DealOneTokens.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    spec.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: DealOneTokens.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
