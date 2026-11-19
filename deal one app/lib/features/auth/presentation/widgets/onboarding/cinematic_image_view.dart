import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../animations/onboarding_motion_controller.dart';
import '../../theme/auth_design_tokens.dart';
import 'onboarding_slide_data.dart';

/// Renders a single onboarding image asset with GPU-efficient cinematic motion:
/// - Slow Ken Burns scale (`1.03` -> `1.095`) and directional pan.
/// - Real-time cross-fade & subtle horizontal parallax driven by `pageOffset`.
/// - Respects [reducedMotion] (`MediaQuery.disableAnimationsOf`).
class CinematicImageView extends StatelessWidget {
  final OnboardingSlideData slide;
  final int index;
  final double pageOffset;
  final bool isActive;
  final Animation<double> kenBurnsAnimation;
  final OnboardingMotionConfig config;
  final bool reducedMotion;

  const CinematicImageView({
    super.key,
    required this.slide,
    required this.index,
    required this.pageOffset,
    required this.isActive,
    required this.kenBurnsAnimation,
    required this.config,
    required this.reducedMotion,
  });

  @override
  Widget build(BuildContext context) {
    final distance = (pageOffset - index).clamp(-1.0, 1.0);
    final visibility = (1.0 - distance.abs()).clamp(0.0, 1.0);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final parallaxDirection = isRtl ? -1.0 : 1.0;

    // Avoid painting completely off-screen slides.
    if (visibility <= 0.001) {
      return const SizedBox.shrink();
    }

    final imageChild = Image.asset(
      slide.artworkAssetPath,
      fit: BoxFit.cover,
      alignment: slide.focalAlignment,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFBFD7ED),
              Color(0xFF476985),
              AuthDesignTokens.onboardingScrimBottom,
            ],
          ),
        ),
      ),
    );

    if (reducedMotion) {
      return RepaintBoundary(
        child: Opacity(opacity: visibility, child: imageChild),
      );
    }

    return RepaintBoundary(
      child: Opacity(
        opacity: Curves.easeOut.transform(visibility),
        child: AnimatedBuilder(
          animation: kenBurnsAnimation,
          child: imageChild,
          builder: (context, child) {
            final t = isActive ? kenBurnsAnimation.value : 0.0;
            final scale =
                lerpDouble(
                  config.kenBurnsBeginScale,
                  config.kenBurnsEndScale,
                  t,
                ) ??
                config.kenBurnsBeginScale;
            final pan =
                Offset.lerp(
                  slide.kenBurnsBeginOffset,
                  slide.kenBurnsEndOffset,
                  t,
                ) ??
                Offset.zero;
            final parallaxX =
                -distance * config.parallaxFactor * parallaxDirection;

            return Transform.translate(
              offset: Offset(pan.dx + parallaxX, pan.dy),
              child: Transform.scale(
                scale: scale,
                alignment: slide.focalAlignment,
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}
