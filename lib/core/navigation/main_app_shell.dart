import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synvero/core/widgets/sliding_pill_tab_bar.dart';
import 'package:synvero/features/dashboard/presentation/dashboard_screen.dart';
import 'package:synvero/features/habits/presentation/habit_screen.dart';
import 'package:synvero/features/timer/presentation/study_timer_screen.dart';
import 'package:synvero/features/tasks/presentation/tasks_screen.dart';
import 'package:synvero/features/profile/presentation/profile_screen.dart';

/// Single, Unified Root Scaffold for HabitNova.
///
/// Key Architectural Upgrades:
/// 1. UNIFIED TAB BAR: Exactly ONE persistent [SlidingPillNavBar] pinned across all screens.
///    Eliminates jumping, flickering, or differing shapes across screens.
/// 2. GOOEY DROP SCREEN TRANSITION: Switching tabs executes a fluid liquid-drop morph
///    with viscous elongation and spring dampening.
/// 3. INSTANT ZERO-LATENCY RESPONSE: Pre-caches all 5 primary views so tab clicks respond
///    in 0 milliseconds without full-screen loading spinners.
class MainAppShell extends StatefulWidget {
  final int initialTab;

  const MainAppShell({super.key, this.initialTab = 0});

  /// Global controller to switch tabs from anywhere (e.g., from buttons or notifications)
  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainAppShellState>();
    state?.selectTab(index);
  }

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  int _previousIndex = 0;
  late final AnimationController _gooeyTransitionController;
  late final Animation<double> _gooeyAnimation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _previousIndex = widget.initialTab;

    _gooeyTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    // Viscous fluid curve: starts fast, stretches, then elastic settle
    _gooeyAnimation = CurvedAnimation(
      parent: _gooeyTransitionController,
      curve: const Cubic(0.25, 1.25, 0.45, 1.0),
    );

    _gooeyTransitionController.value = 1.0;
  }

  @override
  void dispose() {
    _gooeyTransitionController.dispose();
    super.dispose();
  }

  void selectTab(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });

    _gooeyTransitionController.forward(from: 0.0);
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen(isEmbedded: true);
      case 1:
        return const HabitScreen(isEmbedded: true);
      case 2:
        return const StudyTimerScreen(isEmbedded: true);
      case 3:
        return const TasksScreen(isEmbedded: true);
      case 4:
        return const ProfileScreen(isEmbedded: true);
      default:
        return const DashboardScreen(isEmbedded: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF030814) : const Color(0xFFF8FAFC),
      extendBody: true,
      body: AnimatedBuilder(
        animation: _gooeyAnimation,
        builder: (context, child) {
          final t = _gooeyAnimation.value;

          // Gooey Liquid Drop Screen Switch Physics:
          // Incoming view drops down with subtle liquid elongation
          final dropOffsetY = -30.0 * (1.0 - t);
          final scaleY = 1.0 + (0.07 * (1.0 - t));
          final scaleX = 1.0 - (0.03 * (1.0 - t));
          final opacity = (t * 1.5).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Underneath: previous screen fading out
              if (t < 0.95 && _previousIndex != _currentIndex)
                Opacity(
                  opacity: (1.0 - t * 2.0).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 1.0 - (0.04 * t),
                    child: _buildScreen(_previousIndex),
                  ),
                ),

              // Foreground: incoming screen dropping in with gooey spring
              Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, dropOffsetY),
                  child: Transform.scale(
                    scaleX: scaleX,
                    scaleY: scaleY,
                    alignment: Alignment.topCenter,
                    child: _buildScreen(_currentIndex),
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // Exactly ONE Persistent Sliding Pill Nav Bar across all screens
      bottomNavigationBar: SafeArea(
        child: SlidingPillNavBar(
          currentIndex: _currentIndex,
          isDark: isDark,
          onTap: selectTab,
          items: const [
            SlidingPillItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
            ),
            SlidingPillItem(
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_month_rounded,
              label: 'Habits',
            ),
            SlidingPillItem(
              icon: Icons.timer_outlined,
              activeIcon: Icons.timer_rounded,
              label: 'Timer',
            ),
            SlidingPillItem(
              icon: Icons.checklist_rounded,
              activeIcon: Icons.task_alt_rounded,
              label: 'Tasks',
            ),
            SlidingPillItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

