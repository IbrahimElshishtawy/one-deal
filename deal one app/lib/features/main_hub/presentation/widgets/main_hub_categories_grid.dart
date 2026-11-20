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
  if (s.contains('appliance') || s.contains('decor')) {
    return Icons.weekend_rounded;
  }
  if (s.contains('service') || s.contains('engineering')) {
    return Icons.handyman_rounded;
  }
  if (s.contains('building') ||
      s.contains('material') ||
      s.contains('construct')) {
    return Icons.engineering_rounded;
  }
  if (s.contains('car') || s.contains('auto')) {
    return Icons.directions_car_filled_rounded;
  }
  if (s.contains('fashion') || s.contains('cloth')) {
    return Icons.shopping_bag_rounded;
  }
  return Icons.category_rounded;
}

/// Returns the exact design label from `Home 1 - Main Hub.png` for each canonical section slug.
String designLabelArForSlug(String slug, String fallbackAr) {
  final s = slug.toLowerCase();
  if (s.contains('real')) return 'عقارات وأراضٍ';
  if (s.contains('appliance') || s.contains('decor')) return 'أجهزة وديكور';
  if (s.contains('service')) return 'خدمات وهندسة';
  if (s.contains('building') || s.contains('material')) {
    return 'مواد بناء وكهرباء';
  }
  if (s.contains('car')) return 'سيارات وصيانة';
  if (s.contains('fashion')) return 'أزياء وإكسسوارات';
  return fallbackAr;
}

int _designOrderForSlug(String slug) {
  final s = slug.toLowerCase();
  if (s.contains('real')) return 0; // Row 1 Right
  if (s.contains('appliance') || s.contains('decor')) return 1; // Row 1 Left
  if (s.contains('service')) return 2; // Row 2 Right
  if (s.contains('building') || s.contains('material')) return 3; // Row 2 Left
  if (s.contains('car')) return 4; // Row 3 Right
  if (s.contains('fashion')) return 5; // Row 3 Left
  return 99;
}

/// Responsive Main Categories Grid matching `Home 1 - Main Hub.png` 2x3 visual order.
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
    final sorted = List<CategoryItem>.from(categories)
      ..sort(
        (a, b) =>
            _designOrderForSlug(a.slug).compareTo(_designOrderForSlug(b.slug)),
      );
    final display = sorted.take(6).toList();

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
              final label = isArabic
                  ? designLabelArForSlug(cat.slug, cat.nameAr)
                  : cat.nameEn;

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
                            label,
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
