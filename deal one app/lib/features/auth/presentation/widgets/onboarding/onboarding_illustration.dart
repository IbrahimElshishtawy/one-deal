import 'package:flutter/material.dart';

import 'package:market_space/features/auth/presentation/theme/auth_design_tokens.dart';
import 'package:market_space/features/auth/presentation/widgets/onboarding/onboarding_slide_data.dart';

/// Full-bleed illustrated backdrop for the 3 Deal One onboarding screens,
/// depicting Real Estate & Cars, Home Services & Construction/Electrical,
/// and Fashion, Decor & Appliances with a bottom dark scrim for crisp copy.
class OnboardingIllustration extends StatelessWidget {
  final OnboardingSlideData slide;

  const OnboardingIllustration({super.key, required this.slide});

  @override
  Widget build(BuildContext context) {
    final isDark = AuthDesignTokens.isDark(context);
    final skyTop = isDark
        ? AuthDesignTokens.onboardingSkyDarkTop
        : AuthDesignTokens.onboardingSkyLightTop;
    final skyBottom = isDark
        ? AuthDesignTokens.onboardingSkyDarkBottom
        : AuthDesignTokens.onboardingSkyLightBottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Sky gradient base
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [skyTop, skyBottom],
            ),
          ),
        ),

        // Cityscape & curved road vector layer
        CustomPaint(
          painter: _OnboardingScenePainter(
            type: slide.illustrationType,
            isDark: isDark,
          ),
        ),

        // Thematic focal badge clusters positioned along the S-curve journey
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 56, bottom: 210),
            child: _ThematicOverlayLayer(
              type: slide.illustrationType,
              isDark: isDark,
            ),
          ),
        ),

        // Bottom dark gradient scrim matching Figma reference overlays
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.42, 0.68, 0.86, 1.0],
              colors: [
                Colors.transparent,
                Colors.transparent,
                AuthDesignTokens.onboardingScrimDark.withValues(alpha: 0.62),
                AuthDesignTokens.onboardingScrimDark.withValues(alpha: 0.90),
                AuthDesignTokens.onboardingScrimDark,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ThematicOverlayLayer extends StatelessWidget {
  final OnboardingIllustrationType type;
  final bool isDark;

  const _ThematicOverlayLayer({required this.type, required this.isDark});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case OnboardingIllustrationType.realEstateAndCars:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SceneIconCluster(
              isDark: isDark,
              primaryIcon: Icons.apartment_rounded,
              secondaryIcon: Icons.home_work_rounded,
              accentColor: const Color(0xFF2B6CB0),
              alignment: AlignmentDirectional.centerStart,
            ),
            _SceneIconCluster(
              isDark: isDark,
              primaryIcon: Icons.vpn_key_rounded,
              secondaryIcon: Icons.handshake_rounded,
              accentColor: const Color(0xFFD97706),
              alignment: Alignment.center,
            ),
            _SceneIconCluster(
              isDark: isDark,
              primaryIcon: Icons.directions_car_filled_rounded,
              secondaryIcon: Icons.build_circle_outlined,
              accentColor: const Color(0xFF0F766E),
              alignment: AlignmentDirectional.centerEnd,
            ),
          ],
        );
      case OnboardingIllustrationType.homeServicesAndMaterials:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SceneIconCluster(
              isDark: isDark,
              primaryIcon: Icons.architecture_rounded,
              secondaryIcon: Icons.engineering_rounded,
              accentColor: const Color(0xFF2563EB),
              alignment: AlignmentDirectional.centerStart,
            ),
            _SceneIconCluster(
              isDark: isDark,
              primaryIcon: Icons.construction_rounded,
              secondaryIcon: Icons.handyman_rounded,
              accentColor: const Color(0xFFB45309),
              alignment: Alignment.center,
            ),
            _SceneIconCluster(
              isDark: isDark,
              primaryIcon: Icons.electrical_services_rounded,
              secondaryIcon: Icons.lightbulb_outline_rounded,
              accentColor: const Color(0xFF0284C7),
              alignment: AlignmentDirectional.centerEnd,
            ),
          ],
        );
      case OnboardingIllustrationType.fashionAndDecor:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SceneIconCluster(
              isDark: isDark,
              primaryIcon: Icons.checkroom_rounded,
              secondaryIcon: Icons.chair_rounded,
              accentColor: const Color(0xFF7C3AED),
              alignment: AlignmentDirectional.centerStart,
            ),
            _SceneIconCluster(
              isDark: isDark,
              primaryIcon: Icons.forum_rounded,
              secondaryIcon: Icons.verified_user_rounded,
              accentColor: const Color(0xFF0D9488),
              alignment: Alignment.center,
            ),
            _SceneIconCluster(
              isDark: isDark,
              primaryIcon: Icons.tv_rounded,
              secondaryIcon: Icons.coffee_maker_outlined,
              accentColor: const Color(0xFF1D4ED8),
              alignment: AlignmentDirectional.centerEnd,
            ),
          ],
        );
    }
  }
}

class _SceneIconCluster extends StatelessWidget {
  final bool isDark;
  final IconData primaryIcon;
  final IconData secondaryIcon;
  final Color accentColor;
  final AlignmentGeometry alignment;

  const _SceneIconCluster({
    required this.isDark,
    required this.primaryIcon,
    required this.secondaryIcon,
    required this.accentColor,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final cardSurface = isDark
        ? AuthDesignTokens.darkSurface.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.92);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : accentColor.withValues(alpha: 0.22);

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AuthDesignTokens.navyPrimary.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(primaryIcon, size: 26, color: accentColor),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AuthDesignTokens.navyPrimary.withValues(
                    alpha: isDark ? 0.35 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  secondaryIcon,
                  size: 22,
                  color: isDark
                      ? AuthDesignTokens.darkTextPrimary
                      : AuthDesignTokens.navyPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingScenePainter extends CustomPainter {
  final OnboardingIllustrationType type;
  final bool isDark;

  const _OnboardingScenePainter({required this.type, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final hillPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1A3A36).withValues(alpha: 0.65)
          : const Color(0xFF81C784).withValues(alpha: 0.38);

    // Top-middle organic green lawn behind skyline
    final lawnRect = Rect.fromLTWH(
      -size.width * 0.12,
      size.height * 0.14,
      size.width * 1.24,
      size.height * 0.26,
    );
    canvas.drawOval(lawnRect, hillPaint);

    // Stylized skyline silhouettes at the top
    final buildingPaint = Paint()
      ..color = isDark
          ? const Color(0xFF23395B).withValues(alpha: 0.85)
          : const Color(0xFF90B4D8).withValues(alpha: 0.55);
    final buildingAccent = Paint()
      ..color = isDark
          ? const Color(0xFF2C4A74).withValues(alpha: 0.9)
          : const Color(0xFF5D8AA8).withValues(alpha: 0.45);

    final towers = [
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.12,
        size.width * 0.16,
        size.height * 0.15,
      ),
      Rect.fromLTWH(
        size.width * 0.27,
        size.height * 0.09,
        size.width * 0.14,
        size.height * 0.18,
      ),
      Rect.fromLTWH(
        size.width * 0.56,
        size.height * 0.07,
        size.width * 0.17,
        size.height * 0.21,
      ),
      Rect.fromLTWH(
        size.width * 0.75,
        size.height * 0.11,
        size.width * 0.16,
        size.height * 0.17,
      ),
    ];

    for (var i = 0; i < towers.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(towers[i], const Radius.circular(6)),
        i.isEven ? buildingPaint : buildingAccent,
      );
    }

    // Winding S-curve marketplace road connecting top to bottom
    final roadPath = Path()
      ..moveTo(size.width * 0.52, size.height * 0.24)
      ..cubicTo(
        size.width * 0.92,
        size.height * 0.34,
        size.width * 0.95,
        size.height * 0.50,
        size.width * 0.48,
        size.height * 0.56,
      )
      ..cubicTo(
        size.width * 0.05,
        size.height * 0.62,
        size.width * 0.08,
        size.height * 0.78,
        size.width * 0.55,
        size.height * 0.88,
      );

    final roadOutline = Paint()
      ..color = isDark
          ? const Color(0xFF1F3B52).withValues(alpha: 0.85)
          : const Color(0xFF4A6B82).withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..strokeCap = StrokeCap.round;

    final roadCenter = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.22 : 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(roadPath, roadOutline);
    canvas.drawPath(roadPath, roadCenter);
  }

  @override
  bool shouldRepaint(covariant _OnboardingScenePainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.isDark != isDark;
}
