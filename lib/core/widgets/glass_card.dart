import 'dart:ui';
import 'package:flutter/material.dart';

/// Apple-style frosted glassmorphic card with gradient borders & specular edge.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.borderGradient,
    this.backgroundColor,
    this.shadowColor,
    this.blurSigma = 12.0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Gradient? borderGradient;
  final Color? backgroundColor;
  final Color? shadowColor;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = backgroundColor ??
        (isDark
            ? const Color(0xFF071728).withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.85));

    final defaultBorder = borderGradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF00E5FF).withValues(alpha: 0.35),
                  const Color(0xFF0E3D48).withValues(alpha: 0.25),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                ]
              : [
                  Colors.white.withValues(alpha: 0.9),
                  const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                ],
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: defaultBorder,
            boxShadow: [
              BoxShadow(
                color: (shadowColor ?? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)))
                    .withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.2), // Border thickness
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: defaultBg,
              borderRadius: BorderRadius.circular(borderRadius - 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

