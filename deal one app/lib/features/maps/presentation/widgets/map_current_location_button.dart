import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/maps/domain/entities/location_permission_state.dart';

/// Vertical map action stack: Current Location button, Recenter, and Zoom +/-.
class MapCurrentLocationControls extends StatelessWidget {
  final MapLocationPermissionStatus locationStatus;
  final VoidCallback onMyLocationTap;
  final VoidCallback onRecenterTap;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapCurrentLocationControls({
    super.key,
    required this.locationStatus,
    required this.onMyLocationTap,
    required this.onRecenterTap,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    final isRequesting =
        locationStatus == MapLocationPermissionStatus.requesting;
    final isGranted = locationStatus == MapLocationPermissionStatus.granted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlButton(
          key: const Key('map_current_location_btn'),
          onTap: isRequesting ? null : onMyLocationTap,
          child: isRequesting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isGranted
                      ? Icons.my_location_rounded
                      : Icons.location_searching_rounded,
                  size: 20,
                  color: isGranted
                      ? const Color(0xFF2563EB)
                      : DealOneTokens.textPrimaryOf(context),
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ControlButton(
          key: const Key('map_recenter_btn'),
          onTap: onRecenterTap,
          child: Icon(
            Icons.center_focus_strong_outlined,
            size: 20,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: DealOneTokens.cardDecoration(
            context,
            borderRadius: AppRadii.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                key: const Key('map_zoom_in_btn'),
                onTap: onZoomIn,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 1,
                color: DealOneTokens.cardBorderOf(context),
              ),
              InkWell(
                key: const Key('map_zoom_out_btn'),
                onTap: onZoomOut,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.remove_rounded,
                    size: 20,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _ControlButton({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DealOneTokens.cardSurfaceOf(context),
      borderRadius: AppRadii.md,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          width: 42,
          height: 42,
          decoration: DealOneTokens.cardDecoration(
            context,
            borderRadius: AppRadii.md,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
