import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:market_space/features/maps/domain/entities/map_place_entity.dart';

/// Represents either a single marker or a spatial cluster of multiple places.
class MapMarkerCluster {
  final String id;
  final LatLng center;
  final List<MapPlaceEntity> places;

  const MapMarkerCluster({
    required this.id,
    required this.center,
    required this.places,
  });

  bool get isCluster => places.length > 1;
  int get count => places.length;
  MapPlaceEntity get primaryPlace => places.first;
}

/// Lightweight, deterministic spatial grid clustering engine for map markers.
/// Clusters nearby pins when zoom is low or marker density is high, keeping
/// rendering smooth even with hundreds of locations.
class MapClusterEngine {
  const MapClusterEngine._();

  static List<MapMarkerCluster> cluster({
    required List<MapPlaceEntity> places,
    required double zoom,
    int minCountForClustering = 12,
    double maxClusterZoom = 15.2,
  }) {
    final mappable = places.where((p) => p.hasCoordinates).toList();
    if (mappable.isEmpty) return const [];

    if (zoom >= maxClusterZoom || mappable.length < minCountForClustering) {
      return mappable
          .map(
            (p) => MapMarkerCluster(
              id: p.id,
              center: p.point!,
              places: [p],
            ),
          )
          .toList(growable: false);
    }

    // Grid cell size in degrees decreases exponentially as zoom increases.
    final cellDegrees = 360.0 / math.pow(2.0, zoom + 1.8);
    final buckets = <String, List<MapPlaceEntity>>{};

    for (final place in mappable) {
      final row = (place.latitude! / cellDegrees).floor();
      final col = (place.longitude! / cellDegrees).floor();
      final key = '$row:$col';
      buckets.putIfAbsent(key, () => <MapPlaceEntity>[]).add(place);
    }

    final clusters = <MapMarkerCluster>[];
    for (final entry in buckets.entries) {
      final group = entry.value;
      if (group.length == 1) {
        final single = group.first;
        clusters.add(
          MapMarkerCluster(
            id: single.id,
            center: single.point!,
            places: group,
          ),
        );
      } else {
        var sumLat = 0.0;
        var sumLng = 0.0;
        for (final item in group) {
          sumLat += item.latitude!;
          sumLng += item.longitude!;
        }
        clusters.add(
          MapMarkerCluster(
            id: 'cluster_${entry.key}_${group.length}',
            center: LatLng(sumLat / group.length, sumLng / group.length),
            places: group,
          ),
        );
      }
    }

    return clusters;
  }
}
