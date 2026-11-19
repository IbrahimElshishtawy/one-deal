import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/deal_one_section_chrome.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../listings/domain/entities/listing_entity.dart';

/// Fashion Brand Product Card matching `الأكثر مبيعاً من أشهر الماركات`
/// in `Home 7 - Fashion and Accessories.png`.
class FashionBrandCard extends ConsumerWidget {
  final ListingItem item;

  const FashionBrandCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favIds = ref.watch(favoriteIdsProvider);
    final isFav = favIds.contains(item.id);
    final brand = item.attributes['brand']?.toString() ??
        (isArabic ? item.categoryNameAr : item.categoryNameEn);

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/listings/${item.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 118,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item.primaryImageUrl != null &&
                          item.primaryImageUrl!.isNotEmpty)
                        Image.network(
                          item.primaryImageUrl!,
                          fit: BoxFit.cover,
                          cacheWidth: 420,
                          errorBuilder: (_, _, _) => Container(
                            color: DealOneDesignColors.navy.withValues(
                              alpha: 0.1,
                            ),
                            child: const Icon(Icons.checkroom_rounded),
                          ),
                        )
                      else
                        Container(
                          color: DealOneDesignColors.navy.withValues(
                            alpha: 0.1,
                          ),
                          child: const Icon(Icons.checkroom_rounded),
                        ),
                      // Favorite heart top-start
                      PositionedDirectional(
                        top: 8,
                        start: 8,
                        child: GestureDetector(
                          onTap: () => ref
                              .read(favoritesControllerProvider.notifier)
                              .toggleFavorite(item.id),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 17,
                              color: isFav
                                  ? Colors.redAccent
                                  : DealOneDesignColors.navy,
                            ),
                          ),
                        ),
                      ),
                      if (brand.isNotEmpty)
                        PositionedDirectional(
                          top: 8,
                          end: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              brand,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: DealOneDesignColors.navy,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : DealOneDesignColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.isVerified ? '4.8' : '4.6',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '(${item.viewsCount})',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMutedOf(context),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: DealOneLivePriceText(
                              listingId: item.id,
                              cachedPrice: item.price,
                              currency: item.currency,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: DealOneDesignColors.amberPrice,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(favoritesControllerProvider.notifier)
                                  .toggleFavorite(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isArabic
                                        ? 'تمت الإضافة للسلة والمفضلة'
                                        : 'Added to bag & favorites',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: DealOneDesignColors.navy,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
