import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/cart/cart_variant_picker_sheet.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';

/// Fashion Brand Product Card matching `الأكثر مبيعاً من أشهر الماركات`
/// in `Home 7 - Fashion and Accessories.png`.
/// Uses proportional flex layout so it never overflows on 320dp or 2.0x text scale.
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
              Expanded(
                flex: 10,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
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
                              constraints: const BoxConstraints(maxWidth: 92),
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
              ),
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : DealOneDesignColors.navy,
                          ),
                        ),
                      ),
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
                          Flexible(
                            child: Text(
                              '(${item.viewsCount})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textMutedOf(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DealOneLivePriceText(
                                  listingId: item.id,
                                  cachedPrice: item.price,
                                  currency: item.currency,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: DealOneDesignColors.amberPrice,
                                  ),
                                ),
                                Text(
                                  formatDealOnePrice(
                                    (item.price * 1.25).roundToDouble(),
                                    currency: item.currency,
                                    isArabic: isArabic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMutedOf(context),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final added = await CartVariantPickerSheet.show(
                                context,
                                listing: item,
                                requireSizeAndColor: true,
                              );
                              if (added == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isArabic
                                          ? 'تمت الإضافة إلى سلة التسوق'
                                          : 'Added to shopping cart',
                                    ),
                                    action: SnackBarAction(
                                      label: isArabic ? 'عرض' : 'View',
                                      onPressed: () =>
                                          context.push(RouteNames.activityHub),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
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
