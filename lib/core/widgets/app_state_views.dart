import 'package:flutter/material.dart';

/// Skeleton placeholder list shown while a screen loads its data.
///
/// A skeleton keeps the layout stable and communicates "content is coming"
/// far better than a bare spinner. The pulse is skipped when the OS asks for
/// reduced motion.
class AppSkeletonList extends StatefulWidget {
  const AppSkeletonList({
    super.key,
    this.itemCount = 5,
    this.showHeader = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  final int itemCount;
  final bool showHeader;
  final EdgeInsetsGeometry padding;

  @override
  State<AppSkeletonList> createState() => _AppSkeletonListState();
}

class _AppSkeletonListState extends State<AppSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      lowerBound: 0.4,
      upperBound: 0.9,
      value: 0.65,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _pulse.stop();
      _pulse.value = 0.7;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color base = scheme.onSurface.withValues(alpha: 0.08);

    Widget bar(double height, double widthFactor) {
      return FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return Semantics(
      label: 'Loading content',
      container: true,
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: _pulse,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: widget.padding,
            children: <Widget>[
              if (widget.showHeader) ...<Widget>[
                bar(24, 0.45),
                const SizedBox(height: 10),
                bar(12, 0.65),
                const SizedBox(height: 22),
              ],
              for (int i = 0; i < widget.itemCount; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.outline),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              bar(13, 0.6),
                              const SizedBox(height: 8),
                              bar(10, 0.35),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Friendly empty state with an optional call to action.
///
/// Announced to screen readers as a status region, because "nothing loaded"
/// is exactly the moment a sighted user gets a visual cue and a screen-reader
/// user would otherwise get silence.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasAction = actionLabel != null && onAction != null;

    return Semantics(
      container: true,
      liveRegion: true,
      label: hasAction ? '$title. $message. $actionLabel' : '$title. $message',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: scheme.primary),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
              if (hasAction) ...<Widget>[
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
