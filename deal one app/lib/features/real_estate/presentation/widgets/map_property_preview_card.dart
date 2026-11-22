import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/shared/widgets/app_network_image.dart';

/// Animated bottom property preview card matching `Map View.png`.
class MapPropertyPreviewCard extends StatelessWidget {
  final ListingItem property;
  final VoidCallback onOpenDetails;
  final VoidCallback onContactSeller;
  final VoidCallback? onClose;

  const MapPropertyPreviewCard({
    super.key,
    required this.property,
    required this.onOpenDetails,
    required this.onContactSeller,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isRent = property.listingKind.toLowerCase() == 'rent' ||
        property.categorySlug.contains('rent');
    final rooms = property.attributes['rooms'];
    final baths = property.attributes['baths'];
    final area =
        property.attributes['area_sqm'] ?? property.attributes['land_area_sqm'];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: DealOneTokens.cardDecoration(
        context,
        borderRadius: AppRadii.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onOpenDetails,
                child: AppNetworkImage(
                  imageUrl: property.primaryImageUrl,
                  width: context.isSmallPhone ? 74 : 86,
                  height: context.isSmallPhone ? 74 : 86,
                  borderRadius: AppRadii.md,
                  fallbackIcon: Icons.home_work_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: DealOneTokens.amberTintOf(context),
                            borderRadius: AppRadii.full,
                          ),
                          child: Text(
                            isRent
                                ? (isArabic ? 'للإيجار الفوري' : 'For Rent')
                                : (isArabic ? 'للبيع' : 'For Sale'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: DealOneTokens.amber,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (onClose != null)
                          InkWell(
                            onTap: onClose,
                            borderRadius: AppRadii.full,
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: DealOneTokens.textSecondaryOf(context),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: DealOneTokens.amber,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.localizedLocation(isArabic ? 'ar' : 'en'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: DealOneTokens.textSecondaryOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Price + Specs Highlight Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: DealOneTokens.softTileBgOf(context),
              borderRadius: AppRadii.md,
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  formatDealOnePrice(
                    property.price,
                    currency: property.currency,
                    isArabic: isArabic,
                    unitSuffix: isRent ? (isArabic ? 'شهرياً' : 'mo') : null,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: DealOneTokens.amber,
                  ),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    if (rooms != null)
                      _MiniSpec(icon: Icons.bed_outlined, label: '$rooms'),
                    if (baths != null)
                      _MiniSpec(icon: Icons.bathtub_outlined, label: '$baths'),
                    if (area != null)
                      _MiniSpec(
                        icon: Icons.square_foot_rounded,
                        label: isArabic ? '$area م²' : '$area m²',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Action Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DealOneTokens.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 44),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.md,
                    ),
                  ),
                  onPressed: onContactSeller,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                  label: Text(
                    isArabic ? 'تحدث مع المعلن' : 'Chat Seller',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DealOneTokens.softTileBgOf(context),
                    foregroundColor: DealOneTokens.textPrimaryOf(context),
                    elevation: 0,
                    minimumSize: const Size(0, 44),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.md,
                    ),
                  ),
                  onPressed: onOpenDetails,
                  icon: const Icon(Icons.near_me_outlined, size: 17),
                  label: Text(
                    isArabic ? 'التفاصيل' : 'Details',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSpec extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniSpec({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: DealOneTokens.textPrimaryOf(context)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }
}
