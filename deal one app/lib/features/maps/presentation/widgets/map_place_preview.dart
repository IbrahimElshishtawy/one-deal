import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';
import 'package:market_space/features/maps/domain/entities/map_place_entity.dart';
import 'package:market_space/shared/widgets/app_network_image.dart';

/// Reusable bottom preview card / sheet for a selected place on the universal
/// category map. Shows image, name, merchant/store badge, address, distance
/// (when available), price, Open Details CTA, and Directions CTA (when
/// coordinates exist).
class MapPlacePreviewCard extends StatelessWidget {
  final MapPlaceEntity place;
  final MapCategoryConfig config;
  final LatLng? userLocation;
  final VoidCallback onOpenDetails;
  final VoidCallback? onDirectionsTap;
  final VoidCallback? onContactSeller;
  final VoidCallback? onClose;

  const MapPlacePreviewCard({
    super.key,
    required this.place,
    required this.config,
    this.userLocation,
    required this.onOpenDetails,
    this.onDirectionsTap,
    this.onContactSeller,
    this.onClose,
  });

  String? _formatDistance(bool isArabic) {
    final km = place.distanceKmFrom(userLocation);
    if (km == null) return null;
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return isArabic ? '$meters م' : '$meters m';
    }
    return isArabic
        ? '${km.toStringAsFixed(1)} كم'
        : '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final distanceLabel = _formatDistance(isArabic);
    final thumbSize = context.isSmallPhone ? 72.0 : 84.0;

    return Container(
      key: Key('map_place_preview_${place.id}'),
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
                  imageUrl: place.imageUrl,
                  width: thumbSize,
                  height: thumbSize,
                  borderRadius: AppRadii.md,
                  fallbackIcon: config.markerIcon,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: config.accentColor.withValues(alpha: 0.12),
                              borderRadius: AppRadii.full,
                            ),
                            child: Text(
                              config.localizedPlaceType(isArabic),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: config.accentColor,
                              ),
                            ),
                          ),
                        ),
                        if (distanceLabel != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: DealOneTokens.softTileBgOf(context),
                              borderRadius: AppRadii.full,
                            ),
                            child: Text(
                              distanceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: DealOneTokens.textPrimaryOf(context),
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (onClose != null)
                          InkWell(
                            onTap: onClose,
                            borderRadius: AppRadii.full,
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: DealOneTokens.textSecondaryOf(context),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      place.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                    if (place.merchantName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            place.isStoreOrBusiness
                                ? Icons.storefront_outlined
                                : Icons.person_outline_rounded,
                            size: 13,
                            color: DealOneTokens.textSecondaryOf(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place.merchantName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: DealOneTokens.textSecondaryOf(context),
                              ),
                            ),
                          ),
                          if (place.isVerified)
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Color(0xFF0F766E),
                            ),
                        ],
                      ),
                    ],
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
                            place.formattedAddress(isArabic),
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
          if (place.price > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: DealOneTokens.softTileBgOf(context),
                borderRadius: AppRadii.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formatDealOnePrice(
                        place.price,
                        currency: place.currency,
                        isArabic: isArabic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: DealOneTokens.amber,
                      ),
                    ),
                  ),
                  if (place.hasCoordinates)
                    Text(
                      isArabic ? 'موقع موثق على الخريطة' : 'Pinned on map',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: DealOneTokens.textSecondaryOf(context),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  key: const Key('map_preview_open_details_btn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DealOneTokens.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.md,
                    ),
                  ),
                  onPressed: onOpenDetails,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(
                    isArabic ? 'فتح التفاصيل' : 'View Details',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (place.hasCoordinates && onDirectionsTap != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    key: const Key('map_preview_directions_btn'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DealOneTokens.textPrimaryOf(context),
                      side: BorderSide(
                        color: DealOneTokens.cardBorderOf(context),
                      ),
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.md,
                      ),
                    ),
                    onPressed: onDirectionsTap,
                    icon: const Icon(Icons.directions_rounded, size: 16),
                    label: Text(
                      isArabic ? 'الاتجاهات' : 'Directions',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ] else if (onContactSeller != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DealOneTokens.textPrimaryOf(context),
                      side: BorderSide(
                        color: DealOneTokens.cardBorderOf(context),
                      ),
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.md,
                      ),
                    ),
                    onPressed: onContactSeller,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                    label: Text(
                      isArabic ? 'تواصل' : 'Chat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
