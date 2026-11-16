import 'package:flutter/material.dart';

/// Crisp WhatsApp speech-bubble + handset glyph matching `login.png` and `انشاء حساب.png`.
class WhatsAppGlyphIcon extends StatelessWidget {
  final double size;
  final Color color;

  const WhatsAppGlyphIcon({
    super.key,
    this.size = 20,
    this.color = const Color(0xFF64748B),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _WhatsAppPainter(color: color),
    );
  }
}

class _WhatsAppPainter extends CustomPainter {
  final Color color;

  const _WhatsAppPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.52, size.height * 0.48);
    final radius = size.width * 0.42;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Speech bubble circle + tail
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..moveTo(center.dx - radius * 0.65, center.dy + radius * 0.55)
      ..lineTo(size.width * 0.08, size.height * 0.92)
      ..lineTo(center.dx - radius * 0.15, center.dy + radius * 0.88)
      ..close();
    canvas.drawPath(path, fillPaint);

    // Subtle white inner phone handset curve
    final phonePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round;

    final phonePath = Path()
      ..moveTo(center.dx - radius * 0.34, center.dy - radius * 0.28)
      ..quadraticBezierTo(
        center.dx - radius * 0.12,
        center.dy + radius * 0.25,
        center.dx + radius * 0.36,
        center.dy + radius * 0.32,
      );
    canvas.drawPath(phonePath, phonePaint);
  }

  @override
  bool shouldRepaint(covariant _WhatsAppPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Multicolor Gmail "M" mark matching `login.png`, `انشاء حساب.png`, and `whatsapp_delivery_failure_sheet`.
class GmailMarkIcon extends StatelessWidget {
  final double size;

  const GmailMarkIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.78),
      painter: const _GmailPainter(),
    );
  }
}

class _GmailPainter extends CustomPainter {
  const _GmailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = w * 0.18;

    // Left blue pillar
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, h * 0.14, stroke, h * 0.86),
        bottomLeft: Radius.circular(w * 0.08),
      ),
      bluePaint,
    );

    // Right green pillar
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w - stroke, h * 0.14, stroke, h * 0.86),
        bottomRight: Radius.circular(w * 0.08),
      ),
      greenPaint,
    );

    // Left yellow shoulder
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(stroke * 0.5, h * 0.16),
      Offset(w * 0.26, h * 0.34),
      yellowPaint,
    );

    // Red center V
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final redPath = Path()
      ..moveTo(stroke * 0.55, h * 0.18)
      ..lineTo(w * 0.5, h * 0.58)
      ..lineTo(w - stroke * 0.55, h * 0.18);
    canvas.drawPath(redPath, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
