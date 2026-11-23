import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:market_space/features/maps/domain/entities/location_permission_state.dart';

/// Result returned by [MapLocationService.requestCurrentLocation].
class MapLocationRequestResult {
  final MapLocationPermissionStatus status;
  final LatLng? coordinates;
  final String? messageAr;
  final String? messageEn;

  const MapLocationRequestResult({
    required this.status,
    this.coordinates,
    this.messageAr,
    this.messageEn,
  });
}

/// Abstract location provider so location permission handling is cleanly
/// isolated, testable, and never blocks the app if permission is denied or
/// platform location services are unavailable.
abstract class MapLocationService {
  Future<MapLocationRequestResult> requestCurrentLocation();
}

/// Default platform-safe implementation.
/// Attempts an optional platform method channel (`com.dealone.marketspace/location`)
/// if registered on the host platform, and gracefully degrades to `unavailable`
/// without crashing or fabricating mock GPS coordinates.
class PlatformMapLocationService implements MapLocationService {
  static const MethodChannel _channel = MethodChannel(
    'com.dealone.marketspace/location',
  );

  const PlatformMapLocationService();

  @override
  Future<MapLocationRequestResult> requestCurrentLocation() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getCurrentLocation',
      );
      if (result == null) {
        return const MapLocationRequestResult(
          status: MapLocationPermissionStatus.denied,
          messageAr: 'تم رفض صلاحية الموقع. يمكنك تصفح الخريطة والبحث يدوياً.',
          messageEn:
              'Location permission denied. You can still browse and search manually.',
        );
      }
      final granted = result['granted'] == true;
      final lat = (result['latitude'] as num?)?.toDouble();
      final lng = (result['longitude'] as num?)?.toDouble();
      if (granted && lat != null && lng != null) {
        return MapLocationRequestResult(
          status: MapLocationPermissionStatus.granted,
          coordinates: LatLng(lat, lng),
        );
      }
      return const MapLocationRequestResult(
        status: MapLocationPermissionStatus.denied,
        messageAr: 'تم رفض صلاحية الموقع. يمكنك تصفح الخريطة والبحث يدوياً.',
        messageEn:
            'Location permission denied. You can still browse and search manually.',
      );
    } on MissingPluginException {
      return const MapLocationRequestResult(
        status: MapLocationPermissionStatus.unavailable,
        messageAr:
            'خدمة تحديد الموقع غير مفعلة على هذا الجهاز حالياً — يمكنك تصفح الخريطة والبحث يدوياً.',
        messageEn:
            'Location service is unavailable on this device — you can browse and search manually.',
      );
    } on PlatformException {
      return const MapLocationRequestResult(
        status: MapLocationPermissionStatus.denied,
        messageAr: 'تعذر الوصول إلى موقعك الحالي. يمكنك استخدام البحث اليدوي.',
        messageEn:
            'Could not access your current location. You can continue with manual search.',
      );
    }
  }
}

final mapLocationServiceProvider = Provider<MapLocationService>((ref) {
  return const PlatformMapLocationService();
});
