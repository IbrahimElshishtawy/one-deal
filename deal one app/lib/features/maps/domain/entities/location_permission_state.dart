import 'package:latlong2/latlong.dart';

/// Represents the current location permission status for the universal map.
enum MapLocationPermissionStatus {
  notRequested,
  requesting,
  granted,
  denied,
  unavailable,
}

class MapUserLocationState {
  final MapLocationPermissionStatus status;
  final LatLng? coordinates;
  final bool userConsentedToShareWithBackend;
  final String? message;

  const MapUserLocationState({
    this.status = MapLocationPermissionStatus.notRequested,
    this.coordinates,
    this.userConsentedToShareWithBackend = false,
    this.message,
  });

  bool get hasLocation =>
      status == MapLocationPermissionStatus.granted && coordinates != null;

  bool get isDeniedOrUnavailable =>
      status == MapLocationPermissionStatus.denied ||
      status == MapLocationPermissionStatus.unavailable;

  MapUserLocationState copyWith({
    MapLocationPermissionStatus? status,
    LatLng? coordinates,
    bool clearCoordinates = false,
    bool? userConsentedToShareWithBackend,
    String? message,
    bool clearMessage = false,
  }) {
    return MapUserLocationState(
      status: status ?? this.status,
      coordinates: clearCoordinates ? null : (coordinates ?? this.coordinates),
      userConsentedToShareWithBackend:
          userConsentedToShareWithBackend ??
          this.userConsentedToShareWithBackend,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
