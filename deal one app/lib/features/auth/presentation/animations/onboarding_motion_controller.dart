import 'package:flutter/material.dart';

/// Configurable motion constants for the Deal One cinematic onboarding flow.
class OnboardingMotionConfig {
  final Duration kenBurnsDuration;
  final Duration textEntranceDuration;
  final Duration pageTransitionDuration;
  final Curve kenBurnsCurve;
  final Curve pageTransitionCurve;
  final double kenBurnsBeginScale;
  final double kenBurnsEndScale;
  final double parallaxFactor;

  const OnboardingMotionConfig({
    this.kenBurnsDuration = const Duration(milliseconds: 7500),
    this.textEntranceDuration = const Duration(milliseconds: 520),
    this.pageTransitionDuration = const Duration(milliseconds: 480),
    this.kenBurnsCurve = Curves.easeInOutSine,
    this.pageTransitionCurve = const Cubic(0.22, 1.0, 0.36, 1.0),
    this.kenBurnsBeginScale = 1.03,
    this.kenBurnsEndScale = 1.075,
    this.parallaxFactor = 32.0,
  });
}

/// Coordinates all native Flutter animations for the cinematic onboarding flow:
/// - Slow Ken Burns zoom & pan per active slide.
/// - Staggered fade + upward slide entrance for subtitle, title, and description.
/// - Automatic reduced-motion compliance via [MediaQuery.disableAnimationsOf].
class OnboardingMotionController {
  final OnboardingMotionConfig config;
  late final AnimationController kenBurnsController;
  late final AnimationController textController;

  late final Animation<double> kenBurnsProgress;
  late final Animation<double> subtitleFade;
  late final Animation<Offset> subtitleSlide;
  late final Animation<double> titleFade;
  late final Animation<Offset> titleSlide;
  late final Animation<double> descriptionFade;
  late final Animation<Offset> descriptionSlide;

  bool _reducedMotion = false;
  bool _isDisposed = false;

  OnboardingMotionController({
    required TickerProvider vsync,
    this.config = const OnboardingMotionConfig(),
  }) {
    kenBurnsController = AnimationController(
      vsync: vsync,
      duration: config.kenBurnsDuration,
    );
    textController = AnimationController(
      vsync: vsync,
      duration: config.textEntranceDuration,
    );

    kenBurnsProgress = CurvedAnimation(
      parent: kenBurnsController,
      curve: config.kenBurnsCurve,
    );

    subtitleFade = CurvedAnimation(
      parent: textController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero).animate(
          CurvedAnimation(
            parent: textController,
            curve: const Interval(0.0, 0.60, curve: Curves.easeOutCubic),
          ),
        );

    titleFade = CurvedAnimation(
      parent: textController,
      curve: const Interval(0.12, 0.72, curve: Curves.easeOut),
    );
    titleSlide =
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
          CurvedAnimation(
            parent: textController,
            curve: const Interval(0.12, 0.76, curve: Curves.easeOutCubic),
          ),
        );

    descriptionFade = CurvedAnimation(
      parent: textController,
      curve: const Interval(0.28, 1.0, curve: Curves.easeOut),
    );
    descriptionSlide =
        Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero).animate(
          CurvedAnimation(
            parent: textController,
            curve: const Interval(0.28, 1.0, curve: Curves.easeOutCubic),
          ),
        );
  }

  bool get reducedMotion => _reducedMotion;

  /// Updates reduced-motion preference from [MediaQuery.disableAnimationsOf].
  void setReducedMotion(bool enabled) {
    if (_isDisposed) return;
    if (_reducedMotion == enabled) return;
    _reducedMotion = enabled;
    if (enabled) {
      kenBurnsController.stop();
      kenBurnsController.value = 0.0;
      textController.stop();
      textController.value = 1.0;
    } else {
      playSlideEntrance();
    }
  }

  /// Restarts the Ken Burns sweep and staggered text entrance cleanly for a
  /// newly active slide. Safe against rapid swiping (cancels prior motion).
  void playSlideEntrance() {
    if (_isDisposed) return;
    if (_reducedMotion) {
      kenBurnsController.value = 0.0;
      textController.value = 1.0;
      return;
    }
    kenBurnsController
      ..stop()
      ..value = 0.0
      ..forward();
    textController
      ..stop()
      ..value = 0.0
      ..forward();
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    kenBurnsController.dispose();
    textController.dispose();
  }
}
