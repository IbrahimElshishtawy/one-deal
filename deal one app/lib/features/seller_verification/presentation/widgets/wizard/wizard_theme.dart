import 'package:flutter/material.dart';
import 'package:market_space/core/theme/app_colors.dart';

/// Shared adaptive colors and decorations for the 3-step Seller Verification Wizard.
/// Light theme matches the uploaded white/navy/soft-blue design pixel-for-pixel;
/// Dark theme seamlessly adapts every surface, border, and tint.
class WizardTheme {
  WizardTheme._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color pageBg(BuildContext context) =>
      isDark(context) ? AppColors.darkBackground : const Color(0xFFF8FAFC);

  static Color cardBg(BuildContext context) =>
      isDark(context) ? AppColors.darkSurface : Colors.white;

  static Color elevatedCardBg(BuildContext context) =>
      isDark(context) ? AppColors.darkSurfaceElevated : const Color(0xFFF4F7FC);

  static Color primaryNavy(BuildContext context) =>
      isDark(context) ? const Color(0xFF2563EB) : const Color(0xFF162447);

  static Color primaryButtonBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E3A6E) : const Color(0xFF162447);

  static Color primaryInk(BuildContext context) =>
      isDark(context) ? AppColors.darkTextPrimary : const Color(0xFF162447);

  static Color secondaryInk(BuildContext context) =>
      isDark(context) ? AppColors.darkTextSecondary : const Color(0xFF64748B);

  static Color hintInk(BuildContext context) =>
      isDark(context) ? AppColors.darkTextMuted : const Color(0xFF94A3B8);

  static Color softBlueBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A253A) : const Color(0xFFEEF3FA);

  static Color softBlueCircleBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF24344E) : const Color(0xFFE7EEF8);

  static Color softBlueBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF2E4266) : const Color(0xFFDCE6F4);

  static Color border(BuildContext context) =>
      isDark(context) ? AppColors.darkBorder : const Color(0xFFE2E8F0);

  static Color dashedBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

  static Color progressTrack(BuildContext context) =>
      isDark(context) ? const Color(0xFF2A3241) : const Color(0xFFE2E8F0);

  static Color success(BuildContext context) =>
      isDark(context) ? AppColors.darkSuccess : const Color(0xFF16A34A);

  static Color successSoft(BuildContext context) =>
      isDark(context) ? const Color(0xFF0C2E1B) : const Color(0xFFECFDF3);

  static Color danger(BuildContext context) =>
      isDark(context) ? AppColors.darkError : const Color(0xFFDC2626);

  static Color dangerSoft(BuildContext context) =>
      isDark(context) ? const Color(0xFF3A1215) : const Color(0xFFFEF2F2);

  static List<BoxShadow> inputShadow(BuildContext context) {
    if (isDark(context)) return const [];
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ];
  }
}

/// Custom painter rendering crisp dashed rounded borders for upload zones.
class DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;
  final double radius;

  const DashedRRectPainter({
    required this.color,
    this.strokeWidth = 1.4,
    this.dashLength = 6.0,
    this.dashGap = 5.0,
    this.radius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.radius != radius;
  }
}
