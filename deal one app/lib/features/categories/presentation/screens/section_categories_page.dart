import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/navigation/config/section_navigation_registry.dart';
import 'package:market_space/core/navigation/presentation/widgets/deal_one_section_bottom_nav.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/categories/domain/entities/category_entity.dart';
import 'package:market_space/features/categories/presentation/providers/categories_providers.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';
import 'package:market_space/features/search/data/dto/search_dto.dart';
import 'package:market_space/features/search/presentation/providers/search_providers.dart';

/// Category-scoped subcategory browser for sections whose navigation bar
/// includes a dedicated `Categories` tab (Building Materials, Appliances & Decor,
/// Fashion & Accessories). Backed by real `GET /api/v1/categories/:slug`.
class SectionCategoriesPage extends ConsumerWidget {
  final String categorySlug;

  const SectionCategoriesPage({
    super.key,
    required this.categorySlug,
  });

  String _sectionTitle(String slug, bool isArabic) {
    switch (MapCategoryRegistry.normalizeSlug(slug)) {
      case MapCategoryRegistry.buildingMaterialsSlug:
        return isArabic
            ? 'أقسام مواد البناء والكهرباء'
            : 'Building Materials Categories';
      case MapCategoryRegistry.homeAppliancesSlug:
        return isArabic
            ? 'أقسام الأجهزة والديكور'
            : 'Appliances & Decor Categories';
      case MapCategoryRegistry.fashionSlug:
        return isArabic
            ? 'أقسام الأزياء والإكسسوارات'
            : 'Fashion & Accessories Categories';
      default:
        return isArabic ? 'الأقسام الفرعية' : 'Categories';
    }
  }

  void _openCategorySearch(
    BuildContext context,
    WidgetRef ref,
    String targetSlug,
  ) {
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(searchActiveQueryDtoProvider.notifier).state = SearchQueryDto(
      categorySlug: targetSlug,
    );
    context.push(RouteNames.search);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedSlug = MapCategoryRegistry.normalizeSlug(categorySlug);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;
    final categoryAsync = ref.watch(categoryBySlugProvider(normalizedSlug));

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      extendBody: true,
      bottomNavigationBar: DealOneSectionBottomNav(
        sectionId: normalizedSlug,
        activeTabId: SectionNavigationRegistry.categoriesTabId,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DealOneSubPageHeader(
              title: _sectionTitle(normalizedSlug, isArabic),
              showBackButton: Navigator.of(context).canPop(),
            ),
            Expanded(
              child: categoryAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
                error: (err, _) => DealOneErrorStateView(
                  error: err,
                  onRetry: () =>
                      ref.invalidate(categoryBySlugProvider(normalizedSlug)),
                ),
                data: (category) {
                  final children = category.subcategories;
                  return RefreshIndicator(
                    color: DealOneTokens.navy,
                    onRefresh: () async {
                      ref.invalidate(categoryBySlugProvider(normalizedSlug));
                    },
                    child: ListView(
                      key: PageStorageKey<String>(
                        'section_categories_scroll_$normalizedSlug',
                      ),
                      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 110),
                      children: [
                        _AllCategoryBannerCard(
                          category: category,
                          isArabic: isArabic,
                          onTap: () => _openCategorySearch(
                            context,
                            ref,
                            normalizedSlug,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (children.isEmpty)
                          DealOneEmptyStateView(
                            icon: Icons.category_outlined,
                            title: isArabic
                                ? 'لا توجد أقسام فرعية حالياً'
                                : 'No subcategories available yet',
                            description: isArabic
                                ? 'يمكنك تصفح جميع إعلانات القسم مباشرة.'
                                : 'You can browse all listings in this section directly.',
                            actionLabel: isArabic
                                ? 'تصفح القسم'
                                : 'Browse Section',
                            onAction: () => _openCategorySearch(
                              context,
                              ref,
                              normalizedSlug,
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: children.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: context.isTablet ? 3 : 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.45,
                            ),
                            itemBuilder: (context, index) {
                              final sub = children[index];
                              return _SubcategoryTile(
                                category: sub,
                                isArabic: isArabic,
                                onTap: () => _openCategorySearch(
                                  context,
                                  ref,
                                  sub.slug.isNotEmpty
                                      ? sub.slug
                                      : normalizedSlug,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllCategoryBannerCard extends StatelessWidget {
  final CategoryItem category;
  final bool isArabic;
  final VoidCallback onTap;

  const _AllCategoryBannerCard({
    required this.category,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DealOneTokens.navy,
      borderRadius: AppRadii.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lg,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: AppRadii.md,
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'تصفح كل ${category.nameAr}'
                          : 'Browse All ${category.nameEn}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'عرض كافة الإعلانات والمنتجات المتاحة'
                          : 'View all available listings and products',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isArabic
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubcategoryTile extends StatelessWidget {
  final CategoryItem category;
  final bool isArabic;
  final VoidCallback onTap;

  const _SubcategoryTile({
    required this.category,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DealOneTokens.cardSurfaceOf(context),
      borderRadius: AppRadii.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lg,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: AppRadii.lg,
            border: Border.all(color: DealOneTokens.cardBorderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.category_rounded,
                color: DealOneTokens.navy,
                size: 22,
              ),
              Text(
                isArabic ? category.nameAr : category.nameEn,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: DealOneTokens.textPrimaryOf(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
