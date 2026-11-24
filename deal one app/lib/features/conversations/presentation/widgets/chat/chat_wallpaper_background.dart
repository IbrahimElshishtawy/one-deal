import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Telegram-inspired gradient & geometric doodle wallpaper container.
class ChatWallpaperBackground extends StatelessWidget {
  final ChatWallpaperPreset wallpaper;
  final Widget child;

  const ChatWallpaperBackground({
    super.key,
    required this.wallpaper,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final colors = wallpaper.gradientColors(isDark);

    return DecoratedBox(
      key: ValueKey('chat_wallpaper_${wallpaper.name}'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: wallpaper.hasPattern
          ? CustomPaint(
              painter: _TelegramPatternPainter(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.045)
                    : const Color(0xFF1B2B48).withValues(alpha: 0.055),
              ),
              child: child,
            )
          : child,
    );
  }
}

class _TelegramPatternPainter extends CustomPainter {
  final Color color;

  const _TelegramPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    const spacing = 64.0;
    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final offsetX = col * spacing + (row.isOdd ? spacing * 0.5 : 0);
        final offsetY = row * spacing;
        final variant = (row * 3 + col) % 4;
        final center = Offset(offsetX, offsetY);

        switch (variant) {
          case 0:
            // Mini chat bubble motif
            final rect = RRect.fromRectAndRadius(
              Rect.fromCenter(center: center, width: 16, height: 12),
              const Radius.circular(5),
            );
            canvas.drawRRect(rect, strokePaint);
          case 1:
            // Subtle diamond
            final path = Path()
              ..moveTo(center.dx, center.dy - 7)
              ..lineTo(center.dx + 7, center.dy)
              ..lineTo(center.dx, center.dy + 7)
              ..lineTo(center.dx - 7, center.dy)
              ..close();
            canvas.drawPath(path, strokePaint);
          case 2:
            // Circle ring
            canvas.drawCircle(center, 6, strokePaint);
          default:
            // Four-point star
            const r = 7.0;
            for (var i = 0; i < 4; i++) {
              final angle = i * math.pi / 4;
              canvas.drawLine(
                Offset(
                  center.dx + math.cos(angle) * r,
                  center.dy + math.sin(angle) * r,
                ),
                Offset(
                  center.dx - math.cos(angle) * r,
                  center.dy - math.sin(angle) * r,
                ),
                strokePaint,
              );
            }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TelegramPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
