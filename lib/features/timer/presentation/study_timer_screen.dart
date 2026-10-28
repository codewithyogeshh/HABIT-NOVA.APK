import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/supabase_service.dart';

/// Study Timer screen.
///
/// Implements Screen 5 from the Synvero master design mockup:
/// - Dark midnight/deep navy theme (#0A1124)
/// - Top Bar: Back arrow, "Study Timer" title, settings gear icon
/// - Segmented session selector: [Pomodoro] [Short Break] [Long Break]
/// - User-configurable Focus Duration:
///   - Quick preset duration chips: [15 min] [25 min] [30 min] [45 min] [60 min] [Custom]
///   - Tap-to-edit on the time ring
///   - Settings sheet with stepper, slider & presets
///   - SharedPreferences user-scoped persistence
/// - Glowing circular countdown progress ring
/// - Big circular play/pause/reset control buttons
/// - Daily focus stats row: "Today's Sessions" | "Total Study Time"
/// - Bottom Navigation Bar (dark styled)
class StudyTimerScreen extends StatefulWidget {
  const StudyTimerScreen({super.key});

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen> {
  int _selectedModeIndex = 0; // 0: Pomodoro, 1: Short Break, 2: Long Break

  // User-configurable durations (in minutes)
  int _customFocusMinutes = 25;
  int _customShortBreakMinutes = 5;
  int _customLongBreakMinutes = 15;

  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  int _completedSessions = 0;
  final int _targetSessions = 4;
  int _currentTabIndex = 2; // Timer tab

  String get _currentUserId => SupabaseService.user?.id ?? 'guest';

  @override
  void initState() {
    super.initState();
    _totalSeconds = _customFocusMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load session count (strictly 0 by default for all users until completed)
      final sessionKey = 'user_${_currentUserId}_timer_completed_sessions';
      _completedSessions = prefs.getInt(sessionKey) ?? 0;

      // Load custom durations
      final focusKey = 'user_${_currentUserId}_focus_duration_mins';
      final shortKey = 'user_${_currentUserId}_short_break_mins';
      final longKey = 'user_${_currentUserId}_long_break_mins';

      final savedFocus = prefs.getInt(focusKey);
      final savedShort = prefs.getInt(shortKey);
      final savedLong = prefs.getInt(longKey);

      setState(() {
        if (savedFocus != null && savedFocus > 0) _customFocusMinutes = savedFocus;
        if (savedShort != null && savedShort > 0) _customShortBreakMinutes = savedShort;
        if (savedLong != null && savedLong > 0) _customLongBreakMinutes = savedLong;
        _resetToMode(_selectedModeIndex);
      });
    } catch (_) {}
  }

  Future<void> _setFocusDuration(int minutes) async {
    if (minutes < 1) minutes = 1;
    if (minutes > 180) minutes = 180;
    _timer?.cancel();
    setState(() {
      _customFocusMinutes = minutes;
      _isRunning = false;
      if (_selectedModeIndex == 0) {
        _totalSeconds = minutes * 60;
        _remainingSeconds = _totalSeconds;
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_${_currentUserId}_focus_duration_mins', minutes);
    } catch (_) {}
  }

  Future<void> _recordCompletedSession() async {
    setState(() {
      _completedSessions++;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_${_currentUserId}_timer_completed_sessions', _completedSessions);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetToMode(int modeIndex) {
    _timer?.cancel();
    _selectedModeIndex = modeIndex;
    _isRunning = false;

    if (modeIndex == 0) {
      _totalSeconds = _customFocusMinutes * 60;
    } else if (modeIndex == 1) {
      _totalSeconds = _customShortBreakMinutes * 60;
    } else {
      _totalSeconds = _customLongBreakMinutes * 60;
    }
    _remainingSeconds = _totalSeconds;
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    } else {
      setState(() {
        _isRunning = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          timer.cancel();
          setState(() {
            _isRunning = false;
            if (_selectedModeIndex == 0) {
              _recordCompletedSession();
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Focus session completed! Great job! 🎉'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      });
    }
  }

  void _resetTimer() {
    _resetToMode(_selectedModeIndex);
    setState(() {});
  }

  String _formatTime(int totalSecs) {
    final minutes = totalSecs ~/ 60;
    final seconds = totalSecs % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showDurationPickerSheet() {
    int tempMinutes = _customFocusMinutes;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1.2)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.timer_rounded, color: Color(0xFF00E5FF), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Set Focus Duration',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Choose how many minutes you want to focus',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Big Display with - / + Stepper Buttons
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141E33),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1E2D48)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (tempMinutes > 5) {
                                setSheetState(() => tempMinutes -= 5);
                              } else if (tempMinutes > 1) {
                                setSheetState(() => tempMinutes -= 1);
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            color: const Color(0xFF00E5FF),
                            iconSize: 34,
                            tooltip: '-5 mins',
                          ),
                          Column(
                            children: [
                              Text(
                                '$tempMinutes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                              const Text(
                                'MINUTES FOCUS',
                                style: TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              if (tempMinutes < 180) {
                                setSheetState(() => tempMinutes += 5);
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            color: const Color(0xFF00E5FF),
                            iconSize: 34,
                            tooltip: '+5 mins',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF00E5FF),
                        inactiveTrackColor: const Color(0xFF1E2D48),
                        thumbColor: const Color(0xFF00E5FF),
                        overlayColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                        trackHeight: 6,
                      ),
                      child: Slider(
                        value: tempMinutes.toDouble().clamp(1.0, 120.0),
                        min: 1,
                        max: 120,
                        divisions: 119,
                        onChanged: (val) {
                          setSheetState(() => tempMinutes = val.round());
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Quick Presets:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Preset Chips Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [15, 20, 25, 30, 45, 60, 90].map((mins) {
                        final isSelected = tempMinutes == mins;
                        return ChoiceChip(
                          label: Text('$mins min'),
                          selected: isSelected,
                          selectedColor: const Color(0xFF00E5FF),
                          backgroundColor: const Color(0xFF141E33),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF0A1124) : Colors.white,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12.5,
                          ),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF1E2D48),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => tempMinutes = mins);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await _setFocusDuration(tempMinutes);
                              _showSnackBar('Focus time set to $tempMinutes minutes! ⏱️');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5FF),
                              foregroundColor: const Color(0xFF0A1124),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Set Focus Time',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF090E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          },
        ),
        title: const Text(
          'Study Timer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF00E5FF), size: 22),
            tooltip: 'Customize Focus Time',
            onPressed: _showDurationPickerSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              // Mode Selector Tabs [Pomodoro] [Short Break] [Long Break]
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF141C2E),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    _buildModeTab('Focus (${_customFocusMinutes}m)', 0),
                    _buildModeTab('Short (5m)', 1),
                    _buildModeTab('Long (15m)', 2),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Quick Focus Presets Chips Row (Only visible when in Focus mode)
              if (_selectedModeIndex == 0) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'Set Time:',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...[15, 25, 30, 45, 60].map((mins) {
                        final isSelected = _customFocusMinutes == mins;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => _setFocusDuration(mins),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                                    : const Color(0xFF141C2E),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF00E5FF)
                                      : const Color(0xFF1E2D48),
                                ),
                              ),
                              child: Text(
                                '$mins min',
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF94A3B8),
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      // Custom chip
                      InkWell(
                        onTap: _showDurationPickerSheet,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141C2E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF2A3854)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.edit_outlined, color: Color(0xFF00E5FF), size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Custom',
                                style: TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                const SizedBox(height: 20),
              ],

              // Glowing Circular Countdown Ring (Tappable to customize time)
              GestureDetector(
                onTap: _isRunning ? null : _showDurationPickerSheet,
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow shadow ring
                      Container(
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                              blurRadius: 36,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      // Background track
                      const SizedBox(
                        width: 210,
                        height: 210,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 8,
                          color: Color(0xFF152238),
                        ),
                      ),
                      // Animated glowing progress ring
                      SizedBox(
                        width: 210,
                        height: 210,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                          color: const Color(0xFF00E5FF),
                        ),
                      ),
                      // Center Time Display
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(_remainingSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedModeIndex == 0
                                    ? 'Focus Time'
                                    : _selectedModeIndex == 1
                                        ? 'Short Break'
                                        : 'Long Break',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (!_isRunning && _selectedModeIndex == 0) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_rounded, color: Color(0xFF00E5FF), size: 13),
                              ],
                            ],
                          ),
                          if (!_isRunning && _selectedModeIndex == 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Tap to change duration',
                                style: TextStyle(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.7),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Play / Pause / Reset Control Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _resetTimer,
                    icon: const Icon(
                      Icons.replay_rounded,
                      color: Color(0xFF94A3B8),
                      size: 26,
                    ),
                    tooltip: 'Reset',
                  ),
                  const SizedBox(width: 20),
                  InkWell(
                    onTap: _toggleTimer,
                    borderRadius: BorderRadius.circular(34),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kPrimaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    onPressed: () {
                      _resetToMode((_selectedModeIndex + 1) % 3);
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: Color(0xFF94A3B8),
                      size: 26,
                    ),
                    tooltip: 'Next session',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Motivational Quote
              const Text(
                '"Stay focused, stay ahead.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Small steps make big progress."',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 24),

              // Daily Focus Stats Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF101728),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF1E2D48)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Sessions",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_completedSessions/$_targetSessions',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: const Color(0xFF1E2D48),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Study Time',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_completedSessions * _customFocusMinutes) ~/ 60}h ${(_completedSessions * _customFocusMinutes) % 60}m',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1424),
          border: Border(top: BorderSide(color: Color(0xFF1A2338), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
            });
            if (index == 0) {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            } else if (index == 1) {
              Navigator.of(context).pushNamed('/habits');
            } else if (index == 3) {
              Navigator.of(context).pushNamed('/tasks');
            } else if (index == 4) {
              Navigator.of(context).pushNamed('/profile');
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0D1424),
          selectedItemColor: const Color(0xFF00E5FF),
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Habits'),
            BottomNavigationBarItem(icon: Icon(Icons.timer_outlined), label: 'Timer'),
            BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(String title, int index) {
    final isSelected = _selectedModeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _resetToMode(index);
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
