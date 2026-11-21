import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/features/activity_hub/application/providers/cart_provider.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';

/// Appliances & Decor Product Card matching
/// `Home 3 - Electrical appliances and decor.png`:
/// - Image with `الأكثر مبيعاً` top-right and brand (`TOSHIBA` / `DeLonghi`) top-left.
/// - Title + short spec subtitle.
/// - Price row with amber live price on right + strikethrough old price on left.
/// - Monthly installment line (`قسط من ... ج.م / شهر`).
/// - Dark navy `أضف للسلة` button with basket-plus icon.
class ApplianceProductCard extends ConsumerWidget {
  final ListingItem item;

  const ApplianceProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = item.attributes['brand']?.toString() ?? 'TOSHIBA';
    final monthly = (item.price / 24).roundToDouble();
    final oldPrice = (item.price * 1.12).roundToDouble();

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
              // Proportional Product Image with Brand / Best Seller Overlay
              Expanded(
                flex: 9,
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
                              child: const Icon(Icons.kitchen_outlined),
                            ),
                          )
                        else
                          Container(
                            color: DealOneDesignColors.navy.withValues(
                              alpha: 0.1,
                            ),
                            child: const Icon(Icons.kitchen_outlined),
                          ),
                        PositionedDirectional(
                          top: 6,
                          start: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isArabic ? 'الأكثر مبيعاً' : 'Best Seller',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (brand.isNotEmpty)
                          PositionedDirectional(
                            top: 6,
                            end: 6,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 88),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                brand,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
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
                flex: 12,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
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
                      Flexible(
                        child: Text(
                          item.description.isNotEmpty
                              ? item.description
                              : (isArabic
                                    ? item.categoryNameAr
                                    : item.categoryNameEn),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                      ),
                      // Price Row: Amber Live Price + Strikethrough Old Price
                      Row(
                        children: [
                          Expanded(
                            child: DealOneLivePriceText(
                              listingId: item.id,
                              cachedPrice: item.price,
                              currency: item.currency,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                color: DealOneDesignColors.amberPrice,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              formatDealOnePrice(
                                oldPrice,
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
                          ),
                        ],
                      ),
                      Flexible(
                        child: Text(
                          isArabic
                              ? 'قسط من ${formatDealOnePrice(monthly, currency: item.currency)} / شهر'
                              : 'From ${formatDealOnePrice(monthly, currency: item.currency, isArabic: false)} / mo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 32),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DealOneDesignColors.navy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              final added = await ref
                                  .read(cartProvider.notifier)
                                  .addListingToCart(item);
                              if (added && context.mounted) {
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
                            icon: const Icon(
                              Icons.shopping_basket_outlined,
                              size: 14,
                            ),
                            label: Text(
                              isArabic ? 'أضف للسلة' : 'Add to Basket',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
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
