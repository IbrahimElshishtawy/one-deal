import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/deal_one_section_chrome.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../listings/domain/entities/listing_entity.dart';

/// Construction & Electrical Material Card matching
/// `Home 5 - Construction and Electrical Materials.png`.
/// Uses proportional flex layout so it never overflows on 320dp or 2.0x text scale.
class ConstructionMaterialCard extends ConsumerWidget {
  final ListingItem item;

  const ConstructionMaterialCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unit = item.attributes['unit_of_measure']?.toString();
    final badgeText = isArabic ? item.categoryNameAr : item.categoryNameEn;

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
                              child: const Icon(Icons.construction_rounded),
                            ),
                          )
                        else
                          Container(
                            color: DealOneDesignColors.navy.withValues(
                              alpha: 0.1,
                            ),
                            child: const Icon(Icons.construction_rounded),
                          ),
                        PositionedDirectional(
                          top: 8,
                          start: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  item.isVerified ? '4.8' : '4.6',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (badgeText.isNotEmpty)
                          PositionedDirectional(
                            top: 8,
                            end: 8,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 96),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: DealOneDesignColors.navy.withValues(
                                  alpha: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                badgeText,
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
                      Flexible(
                        child: Text(
                          item.description.isNotEmpty
                              ? item.description
                              : item.sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: DealOneLivePriceText(
                              listingId: item.id,
                              cachedPrice: item.price,
                              currency: item.currency,
                              unitSuffix: unit,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: DealOneDesignColors.amberPrice,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Material(
                            color: DealOneDesignColors.navy,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () {
                                ref
                                    .read(favoritesControllerProvider.notifier)
                                    .toggleFavorite(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isArabic
                                          ? 'تمت الإضافة لقائمة الطلبات'
                                          : 'Added to order list',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: const SizedBox(
                                width: 30,
                                height: 30,
                                child: Icon(
                                  Icons.add_shopping_cart_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
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
