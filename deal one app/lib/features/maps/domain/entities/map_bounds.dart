import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Represents a geographic bounding box corresponding to the visible map viewport.
class MapBoundingBox {
  final double south;
  final double west;
  final double north;
  final double east;

  const MapBoundingBox({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  LatLng get center => LatLng((south + north) / 2.0, (west + east) / 2.0);

  /// Approximate search radius in km covering the viewport from center to corner.
  double get radiusKm {
    final km = haversineDistanceKm(center, LatLng(north, east));
    return km.clamp(1.0, 150.0);
  }

  bool contains(double lat, double lng, {double paddingFraction = 0.05}) {
    final latPad = (north - south).abs() * paddingFraction;
    final lngPad = (east - west).abs() * paddingFraction;
    return lat >= (south - latPad) &&
        lat <= (north + latPad) &&
        lng >= (west - lngPad) &&
        lng <= (east + lngPad);
  }

  /// Returns true if [other] represents a meaningful viewport shift worth re-querying.
  bool hasMovedSignificantlyFrom(MapBoundingBox? other) {
    if (other == null) return true;
    final movedKm = haversineDistanceKm(center, other.center);
    final viewportSpanKm = math.max(1.0, radiusKm);
    final radiusRatio = (radiusKm - other.radiusKm).abs() / viewportSpanKm;
    return movedKm >= viewportSpanKm * 0.28 || radiusRatio >= 0.35;
  }
}

/// Computes great-circle distance in kilometers between two coordinates.
double haversineDistanceKm(LatLng a, LatLng b) {
  const earthRadiusKm = 6371.0;
  final dLat = _degToRad(b.latitude - a.latitude);
  final dLng = _degToRad(b.longitude - a.longitude);
  final sinLat = math.sin(dLat / 2);
  final sinLng = math.sin(dLng / 2);
  final h =
      sinLat * sinLat +
      math.cos(_degToRad(a.latitude)) *
          math.cos(_degToRad(b.latitude)) *
          sinLng *
          sinLng;
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(math.max(0.0, 1 - h)));
  return earthRadiusKm * c;
}

double _degToRad(double degrees) => degrees * (math.pi / 180.0);
