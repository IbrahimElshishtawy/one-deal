import 'package:flutter/material.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../categories/domain/entities/category_entity.dart';

/// Maps a backend category slug to its dedicated Section Home route.
String sectionRouteForSlug(String slug) {
  final normalized = slug.trim().toLowerCase().replaceAll('_', '-');
  if (normalized.contains('real-estate') ||
      normalized.contains('apartment') ||
      normalized.contains('villa') ||
      normalized.contains('land')) {
    return RouteNames.realEstate;
  }
  if (normalized.contains('appliance') ||
      normalized.contains('decor') ||
      normalized.contains('furniture')) {
    return RouteNames.homeAppliances;
  }
  if (normalized.contains('service') || normalized.contains('engineering')) {
    return RouteNames.homeServices;
  }
  if (normalized.contains('building') ||
      normalized.contains('material') ||
      normalized.contains('construction') ||
      normalized.contains('steel') ||
      normalized.contains('cement')) {
    return RouteNames.buildingMaterials;
  }
  if (normalized.contains('car') ||
      normalized.contains('auto') ||
      normalized.contains('motor')) {
    return RouteNames.cars;
  }
  if (normalized.contains('fashion') ||
      normalized.contains('cloth') ||
      normalized.contains('shoe') ||
      normalized.contains('watch')) {
    return RouteNames.fashion;
  }
  return RouteNames.search;
}

IconData iconForSectionSlug(String slug) {
  final s = slug.toLowerCase();
  if (s.contains('real')) return Icons.home_work_rounded;
  if (s.contains('appliance') || s.contains('decor')) return Icons.chair_rounded;
  if (s.contains('service') || s.contains('engineering')) {
    return Icons.handyman_rounded;
  }
  if (s.contains('building') || s.contains('material') || s.contains('construct')) {
    return Icons.engineering_rounded;
  }
  if (s.contains('car') || s.contains('auto')) return Icons.directions_car_rounded;
  if (s.contains('fashion') || s.contains('cloth')) {
    return Icons.shopping_bag_rounded;
  }
  return Icons.category_rounded;
}

/// Responsive Main Categories Grid matching `Home 1 - Main Hub.png`.
/// Adapts column count (1–4 columns) and tile height to available width
/// and system text scale up to 2.0x without overflow.
class MainHubCategoriesGrid extends StatelessWidget {
  final List<CategoryItem> categories;
  final ValueChanged<CategoryItem> onCategoryTap;

  const MainHubCategoriesGrid({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = context.horizontalScreenPadding;
    final display = categories.take(6).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: context.responsiveCategoryGridDelegate(
              baseMainAxisExtent: 54,
              extraExtentPerTextScaleUnit: 32,
              availableWidth: constraints.maxWidth,
            ),
            itemCount: display.length,
            itemBuilder: (context, index) {
              final cat = display[index];
              return Material(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => onCategoryTap(cat),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: DealOneDesignColors.navy,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            iconForSectionSlug(cat.slug),
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isArabic ? cat.nameAr : cat.nameEn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : DealOneDesignColors.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
