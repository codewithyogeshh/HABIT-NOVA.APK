import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Item definition for [SlidingPillNavBar] and [SlidingPillSegmentedBar]
class SlidingPillItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? badge;

  const SlidingPillItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badge,
  });
}

/// Production-grade Floating Bottom Navigation Bar with a fluid, liquid-spring Sliding Pill indicator.
///
/// Motion Engineering:
/// - Velocity-aware horizontal slide with elastic squish/stretch (`scaleX: 1.12, scaleY: 0.94` in transit).
/// - Apple-style spring curve settling cleanly without harsh linear stops.
/// - Frosted glass backdrop with cyan/electric blue ambient glow.
/// - Tactile haptic feedback on pointer-down.
class SlidingPillNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<SlidingPillItem> items;
  final bool isDark;

  const SlidingPillNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.isDark = true,
  });

  @override
  State<SlidingPillNavBar> createState() => _SlidingPillNavBarState();
}

class _SlidingPillNavBarState extends State<SlidingPillNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _slideAnimation;
  double _previousPosition = 0.0;
  double _targetPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _previousPosition = widget.currentIndex.toDouble();
    _targetPosition = widget.currentIndex.toDouble();
    _slideAnimation = Tween<double>(
      begin: _previousPosition,
      end: _targetPosition,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.22, 1.0, 0.36, 1.0), // Snappy Apple-style spring
      ),
    );
  }

  @override
  void didUpdateWidget(SlidingPillNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousPosition = _slideAnimation.value;
      _targetPosition = widget.currentIndex.toDouble();
      _slideAnimation = Tween<double>(
        begin: _previousPosition,
        end: _targetPosition,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Cubic(0.22, 1.0, 0.36, 1.0),
        ),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final count = widget.items.length;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF071728).withValues(alpha: 0.88)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.24)
                    : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / count;
                final pillHeight = constraints.maxHeight;

                return Stack(
                  children: [
                    // --- Animated Sliding Pill Indicator ---
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final currentVal = _slideAnimation.value;
                        final leftPos = currentVal * itemWidth;

                        // Stretch factor based on animation progress: peaks at t=0.5
                        final progress = _controller.value;
                        final stretch = (progress < 0.5
                                ? progress * 2
                                : (1.0 - progress) * 2) *
                            0.12;

                        return Positioned(
                          left: leftPos,
                          top: 0,
                          width: itemWidth,
                          height: pillHeight,
                          child: Transform.scale(
                            scaleX: 1.0 + stretch,
                            scaleY: 1.0 - (stretch * 0.5),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          const Color(0xFF00E5FF)
                                              .withValues(alpha: 0.22),
                                          const Color(0xFF3B82F6)
                                              .withValues(alpha: 0.18),
                                        ]
                                      : [
                                          const Color(0xFF00E5FF)
                                              .withValues(alpha: 0.15),
                                          const Color(0xFF0284C7)
                                              .withValues(alpha: 0.10),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFF00E5FF)
                                      .withValues(alpha: 0.45),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF)
                                        .withValues(alpha: 0.20),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // --- Interactive Nav Tabs ---
                    Row(
                      children: List.generate(count, (index) {
                        final item = widget.items[index];
                        final isSelected = widget.currentIndex == index;

                        return Expanded(
                          child: _SlidingPillTabButton(
                            item: item,
                            isSelected: isSelected,
                            isDark: isDark,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onTap(index);
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SlidingPillTabButton extends StatefulWidget {
  final SlidingPillItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SlidingPillTabButton({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SlidingPillTabButton> createState() => _SlidingPillTabButtonState();
}

class _SlidingPillTabButtonState extends State<_SlidingPillTabButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isDark = widget.isDark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : (isSelected ? 1.05 : 1.0),
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutQuad,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isSelected
                        ? (widget.item.activeIcon ?? widget.item.icon)
                        : widget.item.icon,
                    size: isSelected ? 22 : 20,
                    color: isSelected
                        ? const Color(0xFF00E5FF)
                        : (isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8)),
                  ),
                ),
                if (widget.item.badge != null)
                  Positioned(
                    top: -2,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.item.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8)),
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: isSelected ? 0.2 : 0.0,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented Tab Bar with a fluid Sliding Pill indicator.
/// Perfect for 2-4 items (e.g. Screen Time vs Data Usage).
class SlidingPillSegmentedBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<SlidingPillItem> tabs;
  final bool isDark;
  final double height;

  const SlidingPillSegmentedBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.tabs,
    this.isDark = true,
    this.height = 46,
  });

  @override
  State<SlidingPillSegmentedBar> createState() => _SlidingPillSegmentedBarState();
}

class _SlidingPillSegmentedBarState extends State<SlidingPillSegmentedBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _slideAnimation;
  double _prevIndex = 0.0;
  double _targetIndex = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _prevIndex = widget.selectedIndex.toDouble();
    _targetIndex = widget.selectedIndex.toDouble();
    _slideAnimation = Tween<double>(begin: _prevIndex, end: _targetIndex)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
    ));
  }

  @override
  void didUpdateWidget(SlidingPillSegmentedBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _prevIndex = _slideAnimation.value;
      _targetIndex = widget.selectedIndex.toDouble();
      _slideAnimation = Tween<double>(begin: _prevIndex, end: _targetIndex)
          .animate(CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.22, 1.0, 0.36, 1.0),
      ));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final count = widget.tabs.length;

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF030D1A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / count;
          final tabHeight = constraints.maxHeight;

          return Stack(
            children: [
              // Sliding Pill Indicator
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final cur = _slideAnimation.value;
                  final left = cur * tabWidth;
                  final progress = _controller.value;
                  final stretch = (progress < 0.5 ? progress * 2 : (1.0 - progress) * 2) * 0.10;

                  return Positioned(
                    left: left,
                    top: 0,
                    width: tabWidth,
                    height: tabHeight,
                    child: Transform.scale(
                      scaleX: 1.0 + stretch,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.20),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Tab Buttons
              Row(
                children: List.generate(count, (index) {
                  final tab = widget.tabs[index];
                  final isSelected = widget.selectedIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onTabSelected(index);
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tab.icon,
                              size: 16,
                              color: isSelected
                                  ? const Color(0xFF00E5FF)
                                  : (isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tab.label,
                              style: TextStyle(
                                color: isSelected
                                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                    : (isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B)),
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

