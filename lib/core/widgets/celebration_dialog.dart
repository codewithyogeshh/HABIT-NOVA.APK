import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive celebration overlay with animated confetti and glowing checkmark
/// triggered whenever a user completes any habit or task in HabbitNova.
class CelebrationDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final int streakDays;

  const CelebrationDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.streakDays,
  });

  /// Displays the celebration dialog with haptic feedback
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int streakDays,
  }) {
    HapticFeedback.heavyImpact();
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => CelebrationDialog(
        title: title,
        subtitle: subtitle,
        streakDays: streakDays,
      ),
    );
  }

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Auto-dismiss after 2.3 seconds
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Animated burst particles behind the card
                  ...List.generate(12, (index) {
                    final angle = (index * 2 * math.pi) / 12;
                    final colors = [
                      const Color(0xFF00F0FF),
                      const Color(0xFF10B981),
                      const Color(0xFFF59E0B),
                      const Color(0xFF8B5CF6),
                    ];
                    final color = colors[index % colors.length];

                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final dist = 100 * _controller.value;
                        final x = math.cos(angle) * dist;
                        final y = math.sin(angle) * dist;
                        final particleOpacity = (1.0 - _controller.value).clamp(0.0, 1.0);

                        return Transform.translate(
                          offset: Offset(x, y),
                          child: Opacity(
                            opacity: particleOpacity,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  // Central Celebration Glass Card
                  Container(
                    width: 310,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                    decoration: BoxDecoration(
                      color: const Color(0xFF071728),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.8),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                          blurRadius: 36,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Glowing Bouncing Trophy / Checkmark
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0284C7), Color(0xFF0D9488)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 6),

                        // Subtitle
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            color: Color(0xFF00F0FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Streak Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF030814),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF0E3D48)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.streakDays} Day Streak Kept Alive!',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Motivational Micro-quote
                        const Text(
                          '"Consistency is your superpower!"',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
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
