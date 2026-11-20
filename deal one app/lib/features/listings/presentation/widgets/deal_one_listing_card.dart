import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';

String formatEgpPrice(double price, {bool isArabic = true}) {
  final formatted = NumberFormat('#,##0', 'en_US').format(price.round());
  return isArabic ? '$formatted ج.م' : 'EGP $formatted';
}

class DealOneListingCard extends ConsumerWidget {
  final ListingItem item;
  final bool compact;

  const DealOneListingCard({
    super.key,
    required this.item,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Watch favorites state so heart icon updates reactively
    ref.watch(favoritesProvider);
    final favoritesNotifier = ref.read(favoritesProvider.notifier);
    final isFav = favoritesNotifier.isFavorited(item.id);

    final categoryLabel = isArabic
        ? (item.categoryNameAr.isNotEmpty ? item.categoryNameAr : item.categoryNameEn)
        : (item.categoryNameEn.isNotEmpty ? item.categoryNameEn : item.categoryNameAr);
    final locationLabel = item.localizedLocation(isArabic ? 'ar' : 'en');

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
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
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image + Category Badge + Favorite Heart
              Expanded(
                flex: compact ? 11 : 12,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _ListingImage(url: item.primaryImageUrl),
                        // Category Pill Overlay (top start)
                        if (categoryLabel.isNotEmpty)
                          PositionedDirectional(
                            top: 8,
                            start: 8,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 120),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: DealOneDesignColors.navy.withValues(
                                  alpha: 0.88,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                categoryLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        // Featured Pill (bottom start)
                        if (item.isFeatured)
                          PositionedDirectional(
                            bottom: 8,
                            start: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: DealOneDesignColors.priceAmber,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    isArabic ? 'مميز' : 'Featured',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Favorite Toggle (top end)
                        PositionedDirectional(
                          top: 6,
                          end: 6,
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () =>
                                  favoritesNotifier.toggleFavorite(item.id),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  isFav
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 17,
                                  color: isFav
                                      ? AppColors.error
                                      : DealOneDesignColors.navy,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Details Section
              Expanded(
                flex: compact ? 10 : 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : DealOneDesignColors.navy,
                          ),
                        ),
                      ),
                      if (locationLabel.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppColors.textMutedOf(context),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMutedOf(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatEgpPrice(item.price, isArabic: isArabic),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: DealOneDesignColors.priceAmber,
                              ),
                            ),
                          ),
                          if (item.isVerified)
                            const Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: Color(0xFF2563EB),
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

class _ListingImage extends StatelessWidget {
  final String? url;

  const _ListingImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: AppColors.surfaceSecondaryOf(context),
        child: Center(
          child: Icon(
            Icons.photo_outlined,
            size: 36,
            color: AppColors.textMutedOf(context),
          ),
        ),
      );
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColors.surfaceSecondaryOf(context),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.surfaceSecondaryOf(context),
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 30,
            color: AppColors.textMutedOf(context),
          ),
        ),
      ),
    );
  }
}
