import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Crisp Vector Painter for Official Google "G" Logo
class GoogleLogoPainter extends CustomPainter {
  const GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double radius = width / 2;
    final center = Offset(radius, radius);

    // Paint blue (for horizontal bar)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    // Ring stroke width
    final strokeWidth = width * 0.22;
    final ringRadius = radius - strokeWidth / 2;
    final ringRect = Rect.fromCircle(center: center, radius: ringRadius);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Red: top
    arcPaint.color = const Color(0xFFEA4335);
    canvas.drawArc(ringRect, -math.pi * 0.75, math.pi * 0.5, false, arcPaint);

    // Blue: top-right to mid-right
    arcPaint.color = const Color(0xFF4285F4);
    canvas.drawArc(ringRect, -math.pi * 0.25, math.pi * 0.45, false, arcPaint);

    // Green: bottom
    arcPaint.color = const Color(0xFF34A853);
    canvas.drawArc(ringRect, math.pi * 0.2, math.pi * 0.55, false, arcPaint);

    // Yellow: bottom-left to mid-left
    arcPaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(ringRect, math.pi * 0.75, math.pi * 0.5, false, arcPaint);

    // Horizontal bar of the "G" in Blue
    final barRect = Rect.fromLTWH(
      center.dx - width * 0.04,
      center.dy - strokeWidth / 2,
      radius + width * 0.04 - strokeWidth / 2 + 1,
      strokeWidth,
    );
    canvas.drawRect(barRect, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(
        painter: GoogleLogoPainter(),
      ),
    );
  }
}

class AppleLogo extends StatelessWidget {
  final double size;
  final Color color;

  const AppleLogo({super.key, this.size = 20, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.apple,
      size: size,
      color: color,
    );
  }
}
