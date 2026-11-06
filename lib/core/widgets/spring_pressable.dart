import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apple-grade spring pressable widget.
///
/// Implements Emil Kowalski & Apple Design principles:
/// 1. Responds instantly on pointer-down (scale: 0.96).
/// 2. Fires tactile haptic feedback (HapticFeedback.lightImpact) immediately.
/// 3. Springs back smoothly with velocity-aware bounce on release.
class SpringPressable extends StatefulWidget {
  const SpringPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.96,
    this.enableHaptic = true,
    this.duration = const Duration(milliseconds: 140),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final bool enableHaptic;
  final Duration duration;

  @override
  State<SpringPressable> createState() => _SpringPressableState();
}

class _SpringPressableState extends State<SpringPressable> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuad,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

