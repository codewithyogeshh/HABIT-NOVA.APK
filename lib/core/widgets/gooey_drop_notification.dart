import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Semantic types for Gooey Drop Notifications
enum GooeyNotificationType {
  streak, // Fire orange / amber
  reward, // Bright gold / credits
  habit, // Emerald / teal
  focus, // Electric cyan
  reminder, // Purple / violet
}

/// Gooey Drop Notification System.
///
/// Animation Choreography:
/// 1. Drop Detachment: A glowing molten viscous droplet detaches from the top notch/island.
/// 2. Fluid Fall & Elongation: Accelerates downwards while stretching vertically (`scaleY: 1.5, scaleX: 0.75`).
/// 3. Impact & Splat: Hits the landing spot, squashing flat (`scaleY: 0.45, scaleX: 1.7`) with tactile impact.
/// 4. Melt & Spread: The squashed droplet fluidly melts and spreads outwards into a full frosted-glass toast!
/// 5. Content Reveal: Fluid specular gloss sweeps across the top edge and content smoothly settles into place.
class GooeyNotification {
  static OverlayEntry? _activeEntry;
  static Timer? _autoDismissTimer;

  /// Shows a Gooey Drop notification anywhere across the app.
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    IconData? icon,
    GooeyNotificationType type = GooeyNotificationType.focus,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    HapticFeedback.mediumImpact();

    _dismissCurrent();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (ctx) => _GooeyDropNotificationWidget(
        title: title,
        message: message,
        icon: icon ?? _getDefaultIcon(type),
        type: type,
        onTap: () {
          _dismissCurrent();
          onTap?.call();
        },
        onDismiss: () => _dismissCurrent(),
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);

    _autoDismissTimer = Timer(duration, () {
      _dismissCurrent();
    });
  }

  static void _dismissCurrent() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    if (_activeEntry != null) {
      _activeEntry?.remove();
      _activeEntry = null;
    }
  }

  static IconData _getDefaultIcon(GooeyNotificationType type) {
    switch (type) {
      case GooeyNotificationType.streak:
        return Icons.local_fire_department_rounded;
      case GooeyNotificationType.reward:
        return Icons.monetization_on_rounded;
      case GooeyNotificationType.habit:
        return Icons.check_circle_rounded;
      case GooeyNotificationType.focus:
        return Icons.bolt_rounded;
      case GooeyNotificationType.reminder:
        return Icons.notifications_active_rounded;
    }
  }
}

class _GooeyDropNotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final GooeyNotificationType type;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _GooeyDropNotificationWidget({
    required this.title,
    required this.message,
    required this.icon,
    required this.type,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_GooeyDropNotificationWidget> createState() =>
      _GooeyDropNotificationWidgetState();
}

class _GooeyDropNotificationWidgetState
    extends State<_GooeyDropNotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Staged animation intervals for "Fall -> Splat -> Melt & Spread -> Settle"
  late final Animation<double> _fallAnimation;
  late final Animation<double> _splatAnimation;
  late final Animation<double> _spreadAnimation;
  late final Animation<double> _contentAnimation;

  bool _isExiting = false;
  double _dragOffsetY = 0.0;
  bool _hasFiredImpactHaptic = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );

    // 1. Fall (0.00 -> 0.35)
    _fallAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.35, curve: Curves.easeInQuad),
    );

    // 2. Splat & Impact (0.35 -> 0.48)
    _splatAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.48, curve: Curves.easeInOutCubic),
    );

    // 3. Melt & Spread into full Toast (0.46 -> 0.82)
    _spreadAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.46, 0.82, curve: Cubic(0.18, 1.0, 0.28, 1.0)),
    );

    // 4. Content Reveal (0.65 -> 1.00)
    _contentAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.00, curve: Curves.easeOutCubic),
    );

    _controller.addListener(() {
      if (_controller.value >= 0.36 && !_hasFiredImpactHaptic && !_isExiting) {
        _hasFiredImpactHaptic = true;
        HapticFeedback.lightImpact();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismissWithAnimation() {
    if (_isExiting) return;
    _isExiting = true;
    HapticFeedback.lightImpact();
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  Color _getPrimaryColor() {
    switch (widget.type) {
      case GooeyNotificationType.streak:
        return const Color(0xFFFF5722);
      case GooeyNotificationType.reward:
        return const Color(0xFFFFD700);
      case GooeyNotificationType.habit:
        return const Color(0xFF10B981);
      case GooeyNotificationType.focus:
        return const Color(0xFF00E5FF);
      case GooeyNotificationType.reminder:
        return const Color(0xFFA855F7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor();
    final topPadding = MediaQuery.of(context).padding.top;
    final restingTop = topPadding + 10.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final targetToastWidth = screenWidth - 32.0;
    const targetToastHeight = 66.0;

    const initialDropSize = 34.0;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final fallT = _fallAnimation.value;
            final splatT = _splatAnimation.value;
            final spreadT = _spreadAnimation.value;
            final contentT = _contentAnimation.value;

            // --- Y Position Computation ---
            // From -45 (above screen / notch) down to restingTop
            final dropY = lerpDouble(-45.0, restingTop, fallT)! + _dragOffsetY;

            // --- Molten Droplet Geometry & Morph ---
            // When falling: droplet stretches along Y axis (elongates)
            // At impact: squashes flat along Y axis, expands along X axis
            // When spreading: smoothly morphs from squashed droplet into full toast!
            double currentWidth;
            double currentHeight;
            double currentRadius;

            if (t <= 0.48) {
              // Droplet falling and impacting
              final stretchY = lerpDouble(1.0, 1.48, fallT)!;
              final thinX = lerpDouble(1.0, 0.72, fallT)!;

              final impactSquashY = lerpDouble(1.0, 0.45, splatT)!;
              final impactExpandX = lerpDouble(1.0, 1.75, splatT)!;

              currentWidth = initialDropSize * thinX * impactExpandX;
              currentHeight = initialDropSize * stretchY * impactSquashY;
              currentRadius = currentHeight / 2;
            } else {
              // Melting & spreading out into toast
              final squashedWidth = initialDropSize * 0.72 * 1.75; // ~43dp
              final squashedHeight = initialDropSize * 1.48 * 0.45; // ~23dp

              currentWidth = lerpDouble(squashedWidth, targetToastWidth, spreadT)!;
              currentHeight = lerpDouble(squashedHeight, targetToastHeight, spreadT)!;
              currentRadius = lerpDouble(squashedHeight / 2, 24.0, spreadT)!;
            }

            final isToastMelted = spreadT > 0.40;

            return Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: EdgeInsets.only(top: dropY),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // --- Molten Liquid Stem Painter (Trailing trail from notch) ---
                    if (fallT > 0.05 && fallT < 0.95 && !_isExiting)
                      Positioned(
                        top: -restingTop - 20,
                        left: 0,
                        right: 0,
                        height: restingTop + 25,
                        child: CustomPaint(
                          painter: _ViscousStemPainter(
                            progress: fallT,
                            color: primaryColor,
                          ),
                        ),
                      ),

                    // --- The Morphing Droplet / Toast ---
                    GestureDetector(
                      onVerticalDragUpdate: (details) {
                        if (details.primaryDelta != null && details.primaryDelta! < 0) {
                          setState(() {
                            _dragOffsetY += details.primaryDelta!;
                          });
                          if (_dragOffsetY < -30) {
                            _dismissWithAnimation();
                          }
                        }
                      },
                      onVerticalDragEnd: (_) {
                        if (_dragOffsetY < -15) {
                          _dismissWithAnimation();
                        } else {
                          setState(() => _dragOffsetY = 0.0);
                        }
                      },
                      onTap: isToastMelted ? widget.onTap : null,
                      child: Container(
                        width: currentWidth,
                        height: currentHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(currentRadius),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(
                                alpha: lerpDouble(0.40, 0.22, spreadT)!,
                              ),
                              blurRadius: lerpDouble(14.0, 26.0, spreadT)!,
                              spreadRadius: lerpDouble(2.0, 1.0, spreadT)!,
                              offset: Offset(0, lerpDouble(3.0, 8.0, spreadT)!),
                            ),
                            if (isToastMelted)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45 * spreadT),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(currentRadius),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 20 * spreadT.clamp(0.01, 1.0),
                              sigmaY: 20 * spreadT.clamp(0.01, 1.0),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                  primaryColor.withValues(alpha: 0.85),
                                  const Color(0xFF071424).withValues(alpha: 0.92),
                                  spreadT,
                                ),
                                borderRadius: BorderRadius.circular(currentRadius),
                                border: Border.all(
                                  color: primaryColor.withValues(
                                    alpha: lerpDouble(0.85, 0.55, spreadT)!,
                                  ),
                                  width: lerpDouble(1.8, 1.3, spreadT)!,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Molten Droplet Center Glow (Fades as it spreads)
                                  if (spreadT < 0.6)
                                    Center(
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(
                                            alpha: (1.0 - spreadT / 0.6) * 0.7,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Top Liquid Specular Arc (Surface tension gloss)
                                  if (spreadT > 0.3)
                                    Positioned(
                                      top: 0,
                                      left: 20,
                                      right: 20,
                                      height: 1.5,
                                      child: Opacity(
                                        opacity: spreadT,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white.withValues(alpha: 0.0),
                                                Colors.white.withValues(alpha: 0.8),
                                                Colors.white.withValues(alpha: 0.0),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Inner Toast Content (Revealed as droplet melts & spreads)
                                  if (contentT > 0.05)
                                    Opacity(
                                      opacity: contentT,
                                      child: Transform.translate(
                                        offset: Offset(0, 6.0 * (1.0 - contentT)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 11),
                                          child: Row(
                                            children: [
                                              // Liquid Icon Pod
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      primaryColor.withValues(alpha: 0.35),
                                                      primaryColor.withValues(alpha: 0.12),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: primaryColor.withValues(alpha: 0.65),
                                                    width: 1.4,
                                                  ),
                                                ),
                                                child: Icon(
                                                  widget.icon,
                                                  color: primaryColor,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),

                                              // Titles & Microcopy
                                              Expanded(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            widget.title,
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w800,
                                                              letterSpacing: -0.2,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 6, vertical: 1.5),
                                                          decoration: BoxDecoration(
                                                            color: primaryColor.withValues(alpha: 0.16),
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: Border.all(
                                                              color: primaryColor.withValues(alpha: 0.35),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            'NOW',
                                                            style: TextStyle(
                                                              color: primaryColor,
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.w800,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      widget.message,
                                                      style: TextStyle(
                                                        color: Colors.white.withValues(alpha: 0.82),
                                                        fontSize: 12,
                                                        height: 1.25,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(width: 6),

                                              // Close pill
                                              GestureDetector(
                                                onTap: _dismissWithAnimation,
                                                behavior: HitTestBehavior.opaque,
                                                child: Container(
                                                  padding: const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.08),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.close_rounded,
                                                    size: 13,
                                                    color: Colors.white.withValues(alpha: 0.6),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter rendering the falling molten droplet stem connecting to the notch
class _ViscousStemPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ViscousStemPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress > 0.85) return;

    final normT = (progress / 0.85).clamp(0.0, 1.0);
    final opacity = (1.0 - normT) * 0.50;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final topWidth = 36.0 * (1.0 - normT * 0.65);
    final pinchWidth = 8.0 * (1.0 - normT);
    final currentY = size.height * normT;

    final path = Path();
    path.moveTo(centerX - topWidth / 2, 0);
    path.cubicTo(
      centerX - topWidth * 0.35,
      currentY * 0.25,
      centerX - pinchWidth / 2,
      currentY * 0.70,
      centerX - pinchWidth / 2,
      currentY,
    );
    path.lineTo(centerX + pinchWidth / 2, currentY);
    path.cubicTo(
      centerX + pinchWidth / 2,
      currentY * 0.70,
      centerX + topWidth * 0.35,
      currentY * 0.25,
      centerX + topWidth / 2,
      0,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ViscousStemPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
