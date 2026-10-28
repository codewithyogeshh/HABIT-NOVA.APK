import 'package:flutter/material.dart';

/// Custom painter for the layered mountain landscape shown at the bottom
/// of the Synvero Login screen.
class MountainPainter extends CustomPainter {
  const MountainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1: Distant background mountains (very pale ice blue)
    final backPaint = Paint()
      ..color = const Color(0xFFE6EEFC)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

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

    // Layer 2: Middle mountain ridge (soft sky blue)
    final midPaint = Paint()
      ..color = const Color(0xFFBFD7FA)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

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

    // Layer 3: Central prominent mountain peak (light periwinkle blue)
    final peakPaint = Paint()
      ..color = const Color(0xFFA1C5F7)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final peakPath = Path()
      ..moveTo(w * 0.12, h)
      ..lineTo(w * 0.42, h * 0.46)
      ..lineTo(w * 0.50, h * 0.40)
      ..lineTo(w * 0.74, h * 0.72)
      ..lineTo(w, h * 0.56)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(peakPath, peakPaint);

    // Layer 4: Foreground left & right slopes (vibrant soft blue)
    final forePaint = Paint()
      ..color = const Color(0xFF7FAFF2)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

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

    // Subtle gradient overlay for smooth depth fade
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.transparent,
          const Color(0xFF639BF0).withValues(alpha: 0.2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget that renders the layered mountain landscape illustration.
class MountainIllustration extends StatelessWidget {
  final double height;

  const MountainIllustration({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: const CustomPaint(
          painter: MountainPainter(),
        ),
      ),
    );
  }
}
