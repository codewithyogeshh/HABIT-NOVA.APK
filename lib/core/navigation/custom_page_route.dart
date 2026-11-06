import 'package:flutter/material.dart';

/// Available premium animation archetypes for screen transitions
enum RouteTransitionType {
  habitsRise,
  timerPortal,
  tasksGlide,
  aiElevate,
  statisticsUnfold,
  squadsDoor,
  leaderboardPodium,
  profileSanctuary,
  energyPulse,
  fadeScale,
}

/// Custom Motion Primitives PageRoute implementing spring physics, smooth curves,
/// and unique destination-specific animations with 0 latency.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final RouteTransitionType transitionType;

  SmoothPageRoute({
    required this.child,
    this.transitionType = RouteTransitionType.fadeScale,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            switch (transitionType) {
              case RouteTransitionType.habitsRise:
                final slide = Tween<Offset>(
                  begin: const Offset(0.0, 0.08),
                  end: Offset.zero,
                ).animate(curvedAnimation);
                final scale = Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation);
                final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
                return SlideTransition(
                  position: slide,
                  child: ScaleTransition(
                    scale: scale,
                    child: FadeTransition(opacity: fade, child: child),
                  ),
                );

              case RouteTransitionType.timerPortal:
                final scale = Tween<double>(begin: 0.88, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                    reverseCurve: Curves.easeInCubic,
                  ),
                );
                final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
                return ScaleTransition(
                  scale: scale,
                  child: FadeTransition(opacity: fade, child: child),
                );

              case RouteTransitionType.tasksGlide:
                final slide = Tween<Offset>(
                  begin: const Offset(0.12, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.fastLinearToSlowEaseIn,
                    reverseCurve: Curves.easeInCubic,
                  ),
                );
                final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
                final scale = Tween<double>(begin: 0.97, end: 1.0).animate(curvedAnimation);
                return SlideTransition(
                  position: slide,
                  child: ScaleTransition(
                    scale: scale,
                    child: FadeTransition(opacity: fade, child: child),
                  ),
                );

              case RouteTransitionType.aiElevate:
                final slide = Tween<Offset>(
                  begin: const Offset(0.0, 0.12),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutQuart,
                    reverseCurve: Curves.easeInCubic,
                  ),
                );
                final scale = Tween<double>(begin: 0.94, end: 1.0).animate(curvedAnimation);
                final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
                return SlideTransition(
                  position: slide,
                  child: ScaleTransition(
                    scale: scale,
                    child: FadeTransition(opacity: fade, child: child),
                  ),
                );

              case RouteTransitionType.statisticsUnfold:
                final scale = Tween<double>(begin: 0.90, end: 1.0).animate(curvedAnimation);
                final slide = Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).animate(curvedAnimation);
                final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
                return SlideTransition(
                  position: slide,
                  child: ScaleTransition(
                    scale: scale,
                    alignment: Alignment.bottomCenter,
                    child: FadeTransition(opacity: fade, child: child),
                  ),
                );

              case RouteTransitionType.squadsDoor:
                final slide = Tween<Offset>(
                  begin: const Offset(0.16, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  ),
                );
                final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
                return SlideTransition(
                  position: slide,
                  child: FadeTransition(opacity: fade, child: child),
                );

              case RouteTransitionType.leaderboardPodium:
                final slide = Tween<Offset>(
                  begin: const Offset(0.0, 0.14),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                    reverseCurve: Curves.easeInCubic,
                  ),
                );
                final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
                return SlideTransition(
                  position: slide,
                  child: FadeTransition(opacity: fade, child: child),
                );

              case RouteTransitionType.profileSanctuary:
                final slide = Tween<Offset>(
                  begin: const Offset(0.06, 0.06),
                  end: Offset.zero,
                ).animate(curvedAnimation);
                final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
                return SlideTransition(
                  position: slide,
                  child: FadeTransition(opacity: fade, child: child),
                );

              case RouteTransitionType.energyPulse:
                final scale = Tween<double>(begin: 0.91, end: 1.0).animate(curvedAnimation);
                final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
                return ScaleTransition(
                  scale: scale,
                  child: FadeTransition(opacity: fade, child: child),
                );

              case RouteTransitionType.fadeScale:
                final scale = Tween<double>(begin: 0.94, end: 1.0).animate(curvedAnimation);
                final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
                return ScaleTransition(
                  scale: scale,
                  child: FadeTransition(opacity: fade, child: child),
                );
            }
          },
        );
}

