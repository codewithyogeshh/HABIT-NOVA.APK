import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synvero/core/services/notification_service.dart';

/// Full-screen animated overlay dialog displayed when an alarm is actively ringing.
/// The alarm cannot be stopped from notifications; the user must enter the app and tap "Turn Off Alarm".
class AlarmRingingDialog extends StatefulWidget {
  final ActiveAlarm alarm;

  const AlarmRingingDialog({
    super.key,
    required this.alarm,
  });

  @override
  State<AlarmRingingDialog> createState() => _AlarmRingingDialogState();
}

class _AlarmRingingDialogState extends State<AlarmRingingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Timer _clockTimer;
  String _currentTimeString = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _updateTimeString();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateTimeString();
    });

    // Ensure native alarm audio and vibration are actively looping
    NotificationService.startNativeAlarm();
    HapticFeedback.heavyImpact();
  }

  void _updateTimeString() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    setState(() {
      _currentTimeString = '$hour:$minute:$second $period';
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleStopAlarm() async {
    HapticFeedback.mediumImpact();
    await NotificationService.stopActiveAlarm(widget.alarm.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Alarm turned off! Stay focused and productive! 🚀'),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent dismissing with back button until turned off
      child: Material(
        color: Colors.black.withValues(alpha: 0.88),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_active_rounded, color: Color(0xFFEF4444), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'ALARM RINGING',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Pulsating Alarm Clock Icon
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                                  blurRadius: 36,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.alarm_on_rounded,
                                color: Colors.white,
                                size: 64,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // Live Digital Clock
                    Text(
                      _currentTimeString,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Task / Habit Name
                    Text(
                      widget.alarm.title,
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      widget.alarm.body.isNotEmpty
                          ? widget.alarm.body
                          : 'Time for your scheduled session. Turn off alarm and begin!',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 36),

                    // Big Stop Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _handleStopAlarm,
                        icon: const Icon(Icons.stop_circle_rounded, size: 24),
                        label: const Text(
                          '🛑 Turn Off Alarm',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: const Color(0xFFEF4444).withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Security notice: Alarms cannot be stopped from notification drawer.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

