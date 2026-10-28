import 'package:flutter/material.dart';
import 'package:synvero/app/theme/app_colors.dart';

/// Custom painter for the 3-petal Synvero sprout emblem.
class SynveroIconPainter extends CustomPainter {
  final Color color;

  const SynveroIconPainter({this.color = kPrimaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // 1. Center Leaf (tilted slightly, upright droplet-leaf)
    final centerPath = Path();
    centerPath.moveTo(w * 0.50, h * 0.90);
    centerPath.cubicTo(
      w * 0.35,
      h * 0.55,
      w * 0.36,
      h * 0.22,
      w * 0.50,
      h * 0.05,
    );
    centerPath.cubicTo(
      w * 0.64,
      h * 0.22,
      w * 0.65,
      h * 0.55,
      w * 0.50,
      h * 0.90,
    );
    centerPath.close();
    canvas.drawPath(centerPath, paint);

    // 2. Left Leaf (spreading outward to the left)
    final leftPath = Path();
    leftPath.moveTo(w * 0.45, h * 0.80);
    leftPath.cubicTo(
      w * 0.25,
      h * 0.75,
      w * 0.05,
      h * 0.55,
      w * 0.08,
      h * 0.32,
    );
    leftPath.cubicTo(
      w * 0.25,
      h * 0.34,
      w * 0.42,
      h * 0.50,
      w * 0.45,
      h * 0.80,
    );
    leftPath.close();
    canvas.drawPath(leftPath, paint);

    // 3. Right Leaf (spreading outward to the right)
    final rightPath = Path();
    rightPath.moveTo(w * 0.55, h * 0.80);
    rightPath.cubicTo(
      w * 0.75,
      h * 0.75,
      w * 0.95,
      h * 0.55,
      w * 0.92,
      h * 0.32,
    );
    rightPath.cubicTo(
      w * 0.75,
      h * 0.34,
      w * 0.58,
      h * 0.50,
      w * 0.55,
      h * 0.80,
    );
    rightPath.close();
    canvas.drawPath(rightPath, paint);
  }

  @override
  bool shouldRepaint(covariant SynveroIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// The official Synvero branding logo with the 3-petal sprout emblem,
/// brand title, and tagline.
class SynveroLogo extends StatelessWidget {
  final double iconSize;
  final bool showTagline;
  final double titleFontSize;
  final double taglineFontSize;
  final CrossAxisAlignment alignment;
  final Color? color;

  const SynveroLogo({
    super.key,
    this.iconSize = 48,
    this.showTagline = true,
    this.titleFontSize = 28,
    this.taglineFontSize = 13,
    this.alignment = CrossAxisAlignment.center,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final brandColor = color ?? kPrimaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        CustomPaint(
          size: Size(iconSize, iconSize),
          painter: SynveroIconPainter(color: brandColor),
        ),
        const SizedBox(height: 12),
        Text(
          'Synvero',
          style: TextStyle(
            color: kDarkText,
            fontSize: titleFontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Everything Working in Sync.',
            style: TextStyle(
              color: kSecondaryText,
              fontSize: taglineFontSize,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
