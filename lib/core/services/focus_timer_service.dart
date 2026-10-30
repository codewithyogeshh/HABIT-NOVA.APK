import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/focus_sound_service.dart';
import 'package:synvero/core/services/gamification_service.dart';
import 'package:synvero/core/services/notification_service.dart';
import 'package:synvero/core/services/supabase_service.dart';

/// Global background focus timer service.
///
/// Keeps track of the active study countdown, session modes,
/// and ongoing notification in the Android status bar and notification drawer.
class FocusTimerService {
  static final FocusTimerService instance = FocusTimerService._internal();

  FocusTimerService._internal() {
    _init();
  }

  // Notifiers
  final ValueNotifier<bool> isRunningNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> remainingSecondsNotifier = ValueNotifier<int>(25 * 60);
  final ValueNotifier<int> totalSecondsNotifier = ValueNotifier<int>(25 * 60);
  final ValueNotifier<int> selectedModeIndexNotifier = ValueNotifier<int>(0); // 0: Focus, 1: Short, 2: Long
  final ValueNotifier<int> completedSessionsNotifier = ValueNotifier<int>(0);

  int customFocusMinutes = 25;
  int customShortBreakMinutes = 5;
  int customLongBreakMinutes = 15;

  Timer? _timer;
  int _notificationSyncCounter = 0;

  String get _currentUserId => SupabaseService.user?.id ?? 'guest';

  void _init() {
    FocusSoundService.currentSoundIdNotifier.addListener(_onSoundChanged);
    loadPreferences();
  }

  void _onSoundChanged() {
    syncNotification();
  }

  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = 'user_${_currentUserId}_timer_completed_sessions';
      completedSessionsNotifier.value = prefs.getInt(sessionKey) ?? 0;

      final focusKey = 'user_${_currentUserId}_focus_duration_mins';
      final shortKey = 'user_${_currentUserId}_short_break_mins';
      final longKey = 'user_${_currentUserId}_long_break_mins';

      final savedFocus = prefs.getInt(focusKey);
      final savedShort = prefs.getInt(shortKey);
      final savedLong = prefs.getInt(longKey);

      if (savedFocus != null && savedFocus > 0) customFocusMinutes = savedFocus;
      if (savedShort != null && savedShort > 0) customShortBreakMinutes = savedShort;
      if (savedLong != null && savedLong > 0) customLongBreakMinutes = savedLong;

      if (!isRunningNotifier.value) {
        _resetToMode(selectedModeIndexNotifier.value);
      }
    } catch (_) {}
  }

  void _resetToMode(int modeIndex) {
    selectedModeIndexNotifier.value = modeIndex;
    int secs;
    if (modeIndex == 0) {
      secs = customFocusMinutes * 60;
    } else if (modeIndex == 1) {
      secs = customShortBreakMinutes * 60;
    } else {
      secs = customLongBreakMinutes * 60;
    }
    totalSecondsNotifier.value = secs;
    remainingSecondsNotifier.value = secs;
  }

  void setMode(int modeIndex) {
    if (isRunningNotifier.value) {
      _timer?.cancel();
      _timer = null;
      isRunningNotifier.value = false;
    }
    _resetToMode(modeIndex);
    syncNotification();
  }

  Future<void> setFocusDuration(int minutes) async {
    if (minutes < 1) minutes = 1;
    if (minutes > 180) minutes = 180;
    _timer?.cancel();
    _timer = null;
    isRunningNotifier.value = false;
    customFocusMinutes = minutes;
    if (selectedModeIndexNotifier.value == 0) {
      totalSecondsNotifier.value = minutes * 60;
      remainingSecondsNotifier.value = totalSecondsNotifier.value;
    }
    syncNotification();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_${_currentUserId}_focus_duration_mins', minutes);
    } catch (_) {}
  }

  void toggleTimer() {
    if (isRunningNotifier.value) {
      // Pause
      _timer?.cancel();
      _timer = null;
      isRunningNotifier.value = false;
      syncNotification();
    } else {
      // Start / Resume
      isRunningNotifier.value = true;
      _timer?.cancel();
      _notificationSyncCounter = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
      syncNotification(immediate: true);
    }
  }

  void resetTimer() {
    _timer?.cancel();
    _timer = null;
    isRunningNotifier.value = false;
    _resetToMode(selectedModeIndexNotifier.value);
    syncNotification();
  }

  void _tick(Timer timer) {
    if (remainingSecondsNotifier.value > 0) {
      remainingSecondsNotifier.value--;
      _notificationSyncCounter++;
      // Sync notification every 5 seconds or when final 10 seconds
      if (_notificationSyncCounter >= 5 || remainingSecondsNotifier.value <= 10) {
        _notificationSyncCounter = 0;
        syncNotification();
      }
    } else {
      timer.cancel();
      _timer = null;
      isRunningNotifier.value = false;
      _handleCompletion();
    }
  }

  Future<void> _handleCompletion() async {
    final mode = selectedModeIndexNotifier.value;
    if (mode == 0) {
      completedSessionsNotifier.value++;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_${_currentUserId}_timer_completed_sessions', completedSessionsNotifier.value);
        await GamificationService.addXP(GamificationService.xpPerStudyTimer, reason: 'Completed Focus Session');
        await GamificationService.unlockBadge('focus_titan');
      } catch (_) {}
    }

    // Show completion notification
    final title = mode == 0 ? '🎉 Focus Session Complete!' : '✨ Break Completed!';
    final body = mode == 0 ? 'Great job! +100 XP earned. Take a well-deserved break.' : 'Ready to start another focus session?';
    await NotificationService.showFocusCompletionNotification(title: title, body: body);

    // If focus sound is still playing, transition ongoing notification to sound only
    final activeSoundId = FocusSoundService.currentSoundIdNotifier.value;
    if (activeSoundId != null) {
      syncNotification();
    }
  }

  /// Synchronizes the ongoing background notification with current timer & sound state
  void syncNotification({bool immediate = false}) {
    final isRunning = isRunningNotifier.value;
    final activeSoundId = FocusSoundService.currentSoundIdNotifier.value;

    FocusSoundOption? activeSound;
    if (activeSoundId != null) {
      try {
        activeSound = FocusSoundService.options.firstWhere(
          (s) => s.id == activeSoundId,
          orElse: () => FocusSoundService.options.first,
        );
      } catch (_) {}
    }

    if (isRunning) {
      final mode = selectedModeIndexNotifier.value;
      final timeStr = formatTime(remainingSecondsNotifier.value);
      final String title;
      if (mode == 0) {
        title = '⏱️ Focus Session Active ($timeStr)';
      } else if (mode == 1) {
        title = '☕ Short Break ($timeStr)';
      } else {
        title = '🌿 Long Break ($timeStr)';
      }

      final String body;
      if (activeSound != null) {
        body = '🎧 Playing ${activeSound.name} • Tap to return to app';
      } else {
        body = 'Stay focused on your goals • Tap to return to app';
      }

      NotificationService.showFocusNotification(
        title: title,
        body: body,
        ongoing: true,
      );
    } else if (activeSound != null) {
      // Sound is playing without active timer
      NotificationService.showFocusNotification(
        title: '🎧 Focus Ambient Sound Active',
        body: 'Playing ${activeSound.name} in background • Tap to control',
        ongoing: true,
      );
    } else {
      // Neither timer is running nor sound is playing
      NotificationService.cancelFocusNotification();
    }
  }

  static String formatTime(int totalSecs) {
    final minutes = totalSecs ~/ 60;
    final seconds = totalSecs % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

