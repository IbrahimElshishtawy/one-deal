import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/deal_one_section_chrome.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../listings/domain/entities/listing_entity.dart';

/// Full-width Property Card matching `Home 2 - Real Estate and Land.png`.
/// Adapts across 320dp..1024dp viewports, RTL/LTR, and up to 2.0x text scale.
class RealEstatePropertyCard extends ConsumerWidget {
  final ListingItem item;

  const RealEstatePropertyCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = context.horizontalScreenPadding;
    final favIds = ref.watch(favoriteIdsProvider);
    final isFav = favIds.contains(item.id);

    final isRent = item.listingKind.toLowerCase() == 'rent' ||
        item.categorySlug.contains('rent');
    final badgeLabel = isRent
        ? (isArabic ? 'للإيجار' : 'For Rent')
        : (isArabic ? 'للبيع' : 'For Sale');
    final unitSuffix = isRent ? (isArabic ? 'شهرياً' : 'mo') : null;

    final attrs = item.attributes;
    final rooms = attrs['rooms'];
    final baths = attrs['baths'];
    final areaSqm = attrs['area_sqm'] ?? attrs['land_area_sqm'];
    final finishing = attrs['finishing']?.toString();
    final floor = attrs['floor'];

    final specs = <(IconData, String)>[
      if (rooms != null)
        (Icons.bed_outlined, isArabic ? '$rooms غرف' : '$rooms Rooms'),
      if (finishing != null && finishing.isNotEmpty)
        (Icons.brush_outlined, finishing),
      if (floor != null)
        (Icons.apartment_rounded, isArabic ? 'الدور $floor' : 'Floor $floor'),
      if (areaSqm != null)
        (Icons.open_in_full_rounded, isArabic ? '$areaSqm م²' : '$areaSqm m²'),
      if (baths != null)
        (Icons.bathtub_outlined, isArabic ? '$baths حمام' : '$baths Baths'),
    ];

    final mediaCount = item.media.isEmpty ? 1 : item.media.length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Hero Photo with Sale/Rent Pill, Favorite, and 1/N Counter
            GestureDetector(
              onTap: () => context.push('/listings/${item.id}'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 176,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item.primaryImageUrl != null &&
                          item.primaryImageUrl!.isNotEmpty)
                        Image.network(
                          item.primaryImageUrl!,
                          fit: BoxFit.cover,
                          cacheWidth: 800,
                          errorBuilder: (_, _, _) => Container(
                            color: DealOneDesignColors.navy.withValues(
                              alpha: 0.12,
                            ),
                            child: const Icon(
                              Icons.home_work_outlined,
                              size: 42,
                              color: DealOneDesignColors.navy,
                            ),
                          ),
                        )
                      else
                        Container(
                          color: DealOneDesignColors.navy.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.home_work_outlined,
                            size: 42,
                            color: DealOneDesignColors.navy,
                          ),
                        ),
                      PositionedDirectional(
                        top: 10,
                        start: 10,
                        child: GestureDetector(
                          onTap: () => ref
                              .read(favoritesControllerProvider.notifier)
                              .toggleFavorite(item.id),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.38),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFav ? Colors.redAccent : Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: 10,
                        end: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: DealOneDesignColors.navy.withValues(
                              alpha: 0.9,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            badgeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        bottom: 10,
                        start: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.photo_camera_outlined,
                                color: Colors.white,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '1 / $mediaCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
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
            ),

            const SizedBox(height: 12),

            // Title & Location
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : DealOneDesignColors.navy,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.localizedLocation(isArabic ? 'ar' : 'en'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMutedOf(context),
              ),
            ),
            const SizedBox(height: 8),

            // Live Price
            DealOneLivePriceText(
              listingId: item.id,
              cachedPrice: item.price,
              currency: item.currency,
              unitSuffix: unitSuffix,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: DealOneDesignColors.amberPrice,
              ),
            ),

            // Property Spec Pills
            if (specs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: specs.map((spec) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          spec.$1,
                          size: 15,
                          color: isDark
                              ? Colors.white70
                              : DealOneDesignColors.navy,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            spec.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : DealOneDesignColors.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),

            // Full-width Details CTA Button
            SizedBox(
              width: double.infinity,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DealOneDesignColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.push('/listings/${item.id}'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    isArabic ? 'التفاصيل' : 'View Details',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
