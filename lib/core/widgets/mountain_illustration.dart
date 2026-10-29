import 'package:flutter/material.dart';

/// Custom painter for the layered mountain landscape shown at the bottom
/// of the Synvero Login screen. Supports both light and glowing bioluminescent dark mode.
class MountainPainter extends CustomPainter {
  final bool isDark;

  const MountainPainter({this.isDark = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (isDark) {
      _paintBioluminescentDark(canvas, size, w, h);
    } else {
      _paintLight(canvas, size, w, h);
    }
  }

  void _paintBioluminescentDark(Canvas canvas, Size size, double w, double h) {
    // Layer 1: Distant dark mountains with subtle teal rim
    final backFill = Paint()
      ..color = const Color(0xFF041422)
      ..style = PaintingStyle.fill;
    final backStroke = Paint()
      ..color = const Color(0xFF0D9488).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final backPath = Path()
      ..moveTo(0, h * 0.55)
      ..lineTo(w * 0.18, h * 0.35)
      ..lineTo(w * 0.35, h * 0.52)
      ..lineTo(w * 0.52, h * 0.28)
      ..lineTo(w * 0.68, h * 0.48)
      ..lineTo(w * 0.85, h * 0.22)
      ..lineTo(w, h * 0.45);

    final backFillPath = Path.from(backPath)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(backFillPath, backFill);
    canvas.drawPath(backPath, backStroke);

    // Layer 2: Middle mountain ridge with bright cyan contour
    final midFill = Paint()
      ..color = const Color(0xFF061D30)
      ..style = PaintingStyle.fill;
    final midStroke = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final midPath = Path()
      ..moveTo(0, h * 0.68)
      ..lineTo(w * 0.24, h * 0.42)
      ..lineTo(w * 0.46, h * 0.65)
      ..lineTo(w * 0.64, h * 0.38)
      ..lineTo(w * 0.82, h * 0.58)
      ..lineTo(w, h * 0.48);

    final midFillPath = Path.from(midPath)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(midFillPath, midFill);
    canvas.drawPath(midPath, midStroke);

    // Layer 3: Central prominent mountain peak with glowing electric cyan ridge
    final peakFill = Paint()
      ..color = const Color(0xFF082740)
      ..style = PaintingStyle.fill;
    final peakStroke = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final peakPath = Path()
      ..moveTo(w * 0.12, h)
      ..lineTo(w * 0.42, h * 0.46)
      ..lineTo(w * 0.50, h * 0.40)
      ..lineTo(w * 0.74, h * 0.72)
      ..lineTo(w, h * 0.56);

    final peakFillPath = Path.from(peakPath)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(peakFillPath, peakFill);
    canvas.drawPath(peakPath, peakStroke);

    // Layer 4: Foreground slopes with vibrant neon cyan top edge
    final foreFill = Paint()
      ..color = const Color(0xFF0A304E)
      ..style = PaintingStyle.fill;
    final foreStroke = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final forePath = Path()
      ..moveTo(0, h * 0.78)
      ..lineTo(w * 0.28, h * 0.56)
      ..lineTo(w * 0.52, h * 0.82)
      ..lineTo(w * 0.80, h * 0.52)
      ..lineTo(w, h * 0.74);

    final foreFillPath = Path.from(forePath)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(foreFillPath, foreFill);
    canvas.drawPath(forePath, foreStroke);

    // Soft gradient aura at the base
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.08),
          const Color(0xFF0284C7).withValues(alpha: 0.2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), gradientPaint);
  }

  void _paintLight(Canvas canvas, Size size, double w, double h) {
    final backPaint = Paint()
      ..color = const Color(0xFFE6EEFC)
      ..style = PaintingStyle.fill;
    final backPath = Path()
      ..moveTo(0, h * 0.55)
      ..lineTo(w * 0.18, h * 0.35)
      ..lineTo(w * 0.35, h * 0.52)
      ..lineTo(w * 0.52, h * 0.28)
      ..lineTo(w * 0.68, h * 0.48)
      ..lineTo(w * 0.85, h * 0.22)
      ..lineTo(w, h * 0.45)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(backPath, backPaint);

    final midPaint = Paint()
      ..color = const Color(0xFFBFD7FA)
      ..style = PaintingStyle.fill;
    final midPath = Path()
      ..moveTo(0, h * 0.68)
      ..lineTo(w * 0.24, h * 0.42)
      ..lineTo(w * 0.46, h * 0.65)
      ..lineTo(w * 0.64, h * 0.38)
      ..lineTo(w * 0.82, h * 0.58)
      ..lineTo(w, h * 0.48)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(midPath, midPaint);

    final peakPaint = Paint()
      ..color = const Color(0xFFA1C5F7)
      ..style = PaintingStyle.fill;
    final peakPath = Path()
      ..moveTo(w * 0.12, h)
      ..lineTo(w * 0.42, h * 0.46)
      ..lineTo(w * 0.50, h * 0.40)
      ..lineTo(w * 0.74, h * 0.72)
      ..lineTo(w, h * 0.56)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(peakPath, peakPaint);

    final forePaint = Paint()
      ..color = const Color(0xFF7FAFF2)
      ..style = PaintingStyle.fill;
    final forePath = Path()
      ..moveTo(0, h * 0.78)
      ..lineTo(w * 0.28, h * 0.56)
      ..lineTo(w * 0.52, h * 0.82)
      ..lineTo(w * 0.80, h * 0.52)
      ..lineTo(w, h * 0.74)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(forePath, forePaint);
  }

  @override
  bool shouldRepaint(covariant MountainPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Responsive widget that wraps the [MountainPainter].
class MountainIllustration extends StatelessWidget {
  final double height;
  final bool? isDark;

  const MountainIllustration({
    super.key,
    this.height = 140,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: MountainPainter(isDark: effectiveDark),
        size: Size(double.infinity, height),
      ),
    );
  }
}
