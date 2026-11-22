import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';

/// Floating vertical map controls (My Location, Recenter, Zoom +/-) matching `Map View.png`.
class MapFloatingControls extends StatelessWidget {
  final VoidCallback onMyLocationTap;
  final VoidCallback onRecenterTap;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapFloatingControls({
    super.key,
    required this.onMyLocationTap,
    required this.onRecenterTap,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapControlButton(
          icon: Icons.my_location_rounded,
          onTap: onMyLocationTap,
        ),
        const SizedBox(height: AppSpacing.sm),
        _MapControlButton(
          icon: Icons.center_focus_strong_outlined,
          onTap: onRecenterTap,
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

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapControlButton({required this.icon, required this.onTap});

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
          child: Icon(
            icon,
            size: 20,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
      ),
    );
  }
}
