import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';

/// Full-width Car Showcase Card matching `Home 6 - Cars and their maintenance.png`.
/// Adapts across 320dp..1024dp viewports, RTL/LTR, and up to 2.0x text scale.
class CarShowcaseCard extends StatelessWidget {
  final ListingItem item;

  const CarShowcaseCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = context.horizontalScreenPadding;
    final attrs = item.attributes;
    final year = attrs['year']?.toString() ?? '';
    final transmission = attrs['transmission']?.toString() ?? '';
    final mileage = attrs['mileage_km'] ?? attrs['mileage'];
    final fuelType =
        attrs['fuel_type']?.toString() ?? attrs['fuelType']?.toString() ?? '';
    final isNew = item.condition.toUpperCase() == 'NEW';

    final badge = year.isNotEmpty
        ? (isNew
              ? (isArabic ? 'زيرو - موديل $year' : 'New - $year')
              : (isArabic ? 'موديل $year' : 'Model $year'))
        : (isNew
              ? (isArabic ? 'جديد' : 'New')
              : (isArabic ? 'مستعمل' : 'Used'));

    final monthly = (item.price / 60).roundToDouble();

    final specs = <(IconData, String)>[
      if (year.isNotEmpty) (Icons.calendar_today_outlined, year),
      if (transmission.isNotEmpty) (Icons.settings_outlined, transmission),
      if (fuelType.isNotEmpty)
        (Icons.local_gas_station_outlined, fuelType)
      else if (mileage != null)
        (Icons.speed_rounded, isArabic ? '$mileage كم' : '$mileage km'),
    ];

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
                              Icons.directions_car_rounded,
                              size: 46,
                            ),
                          ),
                        )
                      else
                        Container(
                          color: DealOneDesignColors.navy.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            size: 46,
                          ),
                        ),
                      PositionedDirectional(
                        top: 10,
                        end: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: DealOneDesignColors.navy.withValues(
                              alpha: 0.9,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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
            const SizedBox(height: 12),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : DealOneDesignColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 14,
                  color: AppColors.textMutedOf(context),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    item.sellerName.isNotEmpty
                        ? item.sellerName
                        : item.localizedLocation(isArabic ? 'ar' : 'en'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: Color(0xFFF59E0B),
                ),
                Text(
                  item.isVerified ? '4.8' : '4.6',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DealOneLivePriceText(
                  listingId: item.id,
                  cachedPrice: item.price,
                  currency: item.currency,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: DealOneDesignColors.amberPrice,
                  ),
                ),
                Text(
                  isArabic
                      ? 'تقسيط ${formatDealOnePrice(monthly, currency: item.currency)}/شهرياً'
                      : '${formatDealOnePrice(monthly, currency: item.currency, isArabic: false)}/mo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ],
            ),
            if (specs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: specs.take(3).map((spec) {
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
                          size: 14,
                          color: isDark
                              ? Colors.white70
                              : DealOneDesignColors.navy,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            spec.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
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
                    isArabic ? 'عرض التفاصيل الكاملة' : 'View Full Details',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => context.push('/listings/${item.id}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isArabic
                      ? 'عرض كل السيارات المتاحة'
                      : 'View All Available Cars',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMutedOf(context),
                    decoration: TextDecoration.underline,
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
