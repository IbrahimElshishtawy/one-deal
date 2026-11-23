import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';
import 'package:market_space/features/maps/domain/entities/map_cluster.dart';
import 'package:market_space/features/maps/domain/entities/map_place_entity.dart';

/// Builds FlutterMap [Marker] lists for:
/// - User current location pulse marker
/// - Clustered marker bubbles (high density / zoomed out)
/// - Category-specific & store-specific markers
class DealOneMapMarkers {
  const DealOneMapMarkers._();

  static List<Marker> buildMarkers({
    required BuildContext context,
    required List<MapMarkerCluster> clusters,
    required MapCategoryConfig defaultConfig,
    required String? selectedPlaceId,
    required bool isArabic,
    required ValueChanged<MapPlaceEntity> onPlaceTap,
    required ValueChanged<MapMarkerCluster> onClusterTap,
    LatLng? userLocation,
  }) {
    final markers = <Marker>[];

    if (userLocation != null) {
      markers.add(
        Marker(
          point: userLocation,
          width: 44,
          height: 44,
          child: const _UserLocationMarker(),
        ),
      );
    }

    for (final cluster in clusters) {
      if (cluster.isCluster) {
        markers.add(
          Marker(
            point: cluster.center,
            width: 52,
            height: 52,
            child: GestureDetector(
              onTap: () => onClusterTap(cluster),
              child: _ClusterBubbleMarker(
                count: cluster.count,
                accentColor: defaultConfig.accentColor,
              ),
            ),
          ),
        );
      } else {
        final place = cluster.primaryPlace;
        final isSelected = selectedPlaceId == place.id;
        final placeConfig = place.categorySlug.isNotEmpty
            ? MapCategoryRegistry.forSlug(place.categorySlug)
            : defaultConfig;

        markers.add(
          Marker(
            point: cluster.center,
            width: isSelected ? 190 : 54,
            height: isSelected ? 96 : 54,
            child: GestureDetector(
              onTap: () => onPlaceTap(place),
              child: _PlacePinMarker(
                place: place,
                config: placeConfig,
                isSelected: isSelected,
                isArabic: isArabic,
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withValues(alpha: 0.22),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x402563EB),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClusterBubbleMarker extends StatelessWidget {
  final int count;
  final Color accentColor;

  const _ClusterBubbleMarker({
    required this.count,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Center(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accentColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: DealOneTokens.cardShadow(context),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PlacePinMarker extends StatelessWidget {
  final MapPlaceEntity place;
  final MapCategoryConfig config;
  final bool isSelected;
  final bool isArabic;

  const _PlacePinMarker({
    required this.place,
    required this.config,
    required this.isSelected,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final pinIcon = place.isStoreOrBusiness
        ? Icons.storefront_rounded
        : config.markerIcon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSelected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: DealOneTokens.navy,
              borderRadius: AppRadii.full,
              boxShadow: DealOneTokens.cardShadow(context),
            ),
            child: Text(
              place.price > 0
                  ? formatDealOnePrice(
                      place.price,
                      currency: place.currency,
                      isArabic: isArabic,
                    )
                  : place.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DealOneTokens.amberWarm,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        Container(
          width: isSelected ? 46 : 38,
          height: isSelected ? 46 : 38,
          decoration: BoxDecoration(
            color: isSelected ? config.accentColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? DealOneTokens.amber : config.accentColor,
              width: 2.5,
            ),
            boxShadow: DealOneTokens.cardShadow(context),
          ),
          child: Icon(
            pinIcon,
            size: isSelected ? 22 : 18,
            color: isSelected ? Colors.white : config.accentColor,
          ),
        ),
      ],
    );
  }
}
