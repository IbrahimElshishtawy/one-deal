import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Visual transition presets for Deal One navigation.
enum CinematicTransitionStyle {
  /// Horizontal RTL-aware depth parallax + scale + fade glide.
  glide,

  /// Celebratory depth-zoom + upward float reveal (e.g. Verification Success).
  reveal,

  /// Gentle vertical lift + fade (e.g. Legal / Modal-like pages).
  verticalLift,
}

/// Centralized cinematic page transition builder for [GoRouter].
class AppPageTransitions {
  AppPageTransitions._();

  static const Cubic _cinematicCurve = Cubic(0.22, 1.0, 0.36, 1.0);
  static const Cubic _revealCurve = Cubic(0.16, 1.0, 0.30, 1.0);

  static CustomTransitionPage<T> buildCinematicPage<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    CinematicTransitionStyle style = CinematicTransitionStyle.glide,
  }) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      return CustomTransitionPage<T>(
        key: state.pageKey,
        name: state.name ?? state.uri.path,
        child: child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (_, _, _, page) => page,
      );
    }

    final forwardDuration = switch (style) {
      CinematicTransitionStyle.glide => const Duration(milliseconds: 450),
      CinematicTransitionStyle.reveal => const Duration(milliseconds: 520),
      CinematicTransitionStyle.verticalLift => const Duration(
        milliseconds: 420,
      ),
    };

    const reverseDuration = Duration(milliseconds: 350);

    return CustomTransitionPage<T>(
      key: state.pageKey,
      name: state.name ?? state.uri.path,
      child: child,
      transitionDuration: forwardDuration,
      reverseTransitionDuration: reverseDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, page) {
        final isRtl = Directionality.of(context) == TextDirection.rtl;

        switch (style) {
          case CinematicTransitionStyle.glide:
            return _buildGlideTransition(
              isRtl: isRtl,
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: page,
            );
          case CinematicTransitionStyle.reveal:
            return _buildRevealTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: page,
            );
          case CinematicTransitionStyle.verticalLift:
            return _buildVerticalLiftTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: page,
            );
        }
      },
    );
  }

  static Widget _buildGlideTransition({
    required bool isRtl,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    final primaryCurved = CurvedAnimation(
      parent: animation,
      curve: _cinematicCurve,
      reverseCurve: Curves.easeInCubic,
    );
    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: _cinematicCurve,
      reverseCurve: Curves.easeInCubic,
    );

    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
    );

    // RTL pages enter from the left (-X) and exit to the right (+X), mirroring LTR.
    final enterOffset = isRtl ? const Offset(-0.08, 0) : const Offset(0.08, 0);
    final exitOffset = isRtl ? const Offset(0.05, 0) : const Offset(-0.05, 0);

    final incomingSlide = Tween<Offset>(
      begin: enterOffset,
      end: Offset.zero,
    ).animate(primaryCurved);
    final incomingScale = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(primaryCurved);

    final outgoingSlide = Tween<Offset>(
      begin: Offset.zero,
      end: exitOffset,
    ).animate(secondaryCurved);
    final outgoingScale = Tween<double>(
      begin: 1.0,
      end: 0.965,
    ).animate(secondaryCurved);
    final outgoingFade = Tween<double>(
      begin: 1.0,
      end: 0.84,
    ).animate(secondaryCurved);

    return SlideTransition(
      position: outgoingSlide,
      child: ScaleTransition(
        scale: outgoingScale,
        child: FadeTransition(
          opacity: outgoingFade,
          child: FadeTransition(
            opacity: fadeIn,
            child: SlideTransition(
              position: incomingSlide,
              child: ScaleTransition(scale: incomingScale, child: child),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildRevealTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: _revealCurve,
      reverseCurve: Curves.easeInCubic,
    );
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.68, curve: Curves.easeOut),
    );
    final scale = Tween<double>(begin: 0.91, end: 1.0).animate(curved);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(curved);

    final outgoingFade = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: outgoingFade,
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: ScaleTransition(scale: scale, child: child),
        ),
      ),
    );
  }

  static Widget _buildVerticalLiftTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: _cinematicCurve,
      reverseCurve: Curves.easeInCubic,
    );
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.72, curve: Curves.easeOut),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.065),
      end: Offset.zero,
    ).animate(curved);
    final scale = Tween<double>(begin: 0.975, end: 1.0).animate(curved);

    final outgoingScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: _cinematicCurve),
    );

    return ScaleTransition(
      scale: outgoingScale,
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: ScaleTransition(scale: scale, child: child),
        ),
      ),
    );
  }
}
