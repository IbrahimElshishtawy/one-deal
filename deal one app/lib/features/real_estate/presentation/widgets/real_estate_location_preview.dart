import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';

/// Map preview card matching `Real Estate Details.png` with "عرض على الخريطة" CTA.
class RealEstateLocationPreview extends StatelessWidget {
  final ListingItem item;
  final VoidCallback onOpenMap;

  const RealEstateLocationPreview({
    super.key,
    required this.item,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hasCoords = item.latitude != null && item.longitude != null;
    final center = hasCoords
        ? LatLng(item.latitude!, item.longitude!)
        : const LatLng(30.7865, 31.0004);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.map_outlined,
              size: 19,
              color: DealOneTokens.textPrimaryOf(context),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isArabic ? 'الموقع الجغرافي' : 'Geographic Location',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: DealOneTokens.textPrimaryOf(context),
                ),
              ),
            ),
            Text(
              isArabic ? 'موقع حيوي متميز' : 'Prime Location',
              style: TextStyle(
                fontSize: 12,
                color: DealOneTokens.textSecondaryOf(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: DealOneTokens.cardDecoration(context),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(
                height: 155,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AbsorbPointer(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: 13.5,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.dealone.marketspace',
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: DealOneTokens.navy,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: const BoxDecoration(
                              color: DealOneTokens.navy,
                              borderRadius: AppRadii.full,
                            ),
                            child: Text(
                              isArabic ? 'موقع العقار' : 'Property Location',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.localizedLocation(isArabic ? 'ar' : 'en'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: DealOneTokens.textPrimaryOf(context),
                            ),
                          ),
                          if (item.governorateNameAr.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.governorateNameAr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: DealOneTokens.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton.icon(
                      key: const Key('real_estate_open_map_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DealOneTokens.navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.md,
                        ),
                      ),
                      onPressed: onOpenMap,
                      icon: const Icon(Icons.map_outlined, size: 17),
                      label: Text(
                        isArabic ? 'عرض على الخريطة' : 'View on Map',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
