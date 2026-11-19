import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';

/// Concentric dashed-ring success emblem matching `Success State Screen.png`.
class SuccessBadgeWidget extends StatelessWidget {
  const SuccessBadgeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 224,
        height: 224,
        child: CustomPaint(
          painter: _ConcentricDashedRingsPainter(
            ringColor: AuthDesignTokens.borderOf(context),
          ),
          child: Center(
            child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                color: AuthDesignTokens.surfaceOf(context),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AuthDesignTokens.navyPrimary.withValues(alpha: 0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 12,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AuthDesignTokens.primaryActionOf(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AuthDesignTokens.successTealDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AuthDesignTokens.primaryActionOf(context),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConcentricDashedRingsPainter extends CustomPainter {
  final Color ringColor;

  const _ConcentricDashedRingsPainter({required this.ringColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    _drawDashedCircle(canvas, center, size.width * 0.48, paint, dashCount: 44);
    _drawDashedCircle(canvas, center, size.width * 0.39, paint, dashCount: 36);
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint, {
    required int dashCount,
  }) {
    final step = (2 * math.pi) / dashCount;
    final sweep = step * 0.45;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, i * step, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConcentricDashedRingsPainter oldDelegate) =>
      oldDelegate.ringColor != ringColor;
}
