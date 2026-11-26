import 'package:flutter/material.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/app_update_service.dart';

/// Shows the "update available" card on top of the app whenever
/// [AppUpdateService.availableUpdate] has a newer build.
///
/// Rendered inside `MaterialApp.builder` so it also appears over the splash
/// screen and over any route, without depending on a Navigator.
class AppUpdateOverlay extends StatefulWidget {
  const AppUpdateOverlay({super.key});

  @override
  State<AppUpdateOverlay> createState() => _AppUpdateOverlayState();
}

class _AppUpdateOverlayState extends State<AppUpdateOverlay> {
  bool _dismissed = false;

  void _later() {
    setState(() => _dismissed = true);
    AppUpdateService.snooze();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUpdateInfo?>(
      valueListenable: AppUpdateService.availableUpdate,
      builder: (BuildContext context, AppUpdateInfo? info, Widget? _) {
        if (info == null || _dismissed) return const SizedBox.shrink();
        return _UpdateCard(
          info: info,
          onLater: info.isMandatory ? null : _later,
        );
      },
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.info, this.onLater});

  final AppUpdateInfo info;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.66),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.32),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.24),
                        blurRadius: 44,
                        spreadRadius: -6,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          height: 66,
                          width: 66,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[kNeonCyan, kPrimaryColor],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: kNeonCyan.withValues(alpha: 0.35),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.rocket_launch_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          info.isMandatory
                              ? 'Update required'
                              : 'Update available',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'A newer, faster version of HabitNova is ready.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: scheme.primary.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Text(
                            'v${info.latestVersion}  •  build ${info.latestBuild}',
                            style: textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      if (info.notes.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 20),
                        ...info.notes.map(
                          (String note) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 17,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(note, style: textTheme.bodyMedium),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        'You are on v${info.currentVersion} (build ${info.currentBuild}).',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => AppUpdateService.openDownload(info),
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: const Text('Update now'),
                        ),
                      ),
                      if (onLater != null)
                        Center(
                          child: TextButton(
                            onPressed: onLater,
                            child: const Text('Later'),
                          ),
                        )
                      else
                        const SizedBox(height: 6),
                      Center(
                        child: Text(
                          'Your habits, streak and data stay safe — the app updates in place.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
