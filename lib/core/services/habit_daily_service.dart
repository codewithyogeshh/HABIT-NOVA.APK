import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/app_widget_service.dart';

/// Service responsible for managing daily habit states and automatic midnight (12:00 AM) resets.
///
/// Ensures habit completions are date-scoped so every new day starts with a fresh clean slate,
/// preserving streaks and historical logs without requiring manual user intervention.
class HabitDailyService {
  static String getTodayDateStr() {
    return DateTime.now().toIso8601String().split('T').first;
  }

  static String getYesterdayDateStr() {
    return DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T').first;
  }

  static String _habitKey(String userId, String habitId, String dateStr) {
    return 'user_${userId}_habit_${habitId}_completed_$dateStr';
  }

  static String _lastActiveDateKey(String userId) {
    return 'user_${userId}_last_habit_date';
  }

  static String _streakKey(String userId) {
    return 'user_${userId}_streak_days';
  }

  /// Checks if a default/local habit is completed today.
  static Future<bool> isHabitCompletedToday(String userId, String habitId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = getTodayDateStr();
      final todayKey = _habitKey(userId, habitId, todayStr);

      if (prefs.containsKey(todayKey)) {
        return prefs.getBool(todayKey) ?? false;
      }

      // Check if last recorded activity was today.
      final lastDate = prefs.getString(_lastActiveDateKey(userId));
      if (lastDate == todayStr) {
        // If legacy key exists for today, migrate it
        final legacyKey = 'user_${userId}_habit_${habitId}_completed';
        final legacyVal = prefs.getBool(legacyKey) ?? false;
        await prefs.setBool(todayKey, legacyVal);
        return legacyVal;
      }

      // If last activity was before today, today's status is reset (false)
      return false;
    } catch (e) {
      debugPrint('Error checking habit completion: $e');
      return false;
    }
  }

  /// Sets habit completion status for today.
  static Future<void> setHabitCompletedToday(
    String userId,
    String habitId,
    bool isCompleted,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = getTodayDateStr();
      final todayKey = _habitKey(userId, habitId, todayStr);

      await prefs.setBool(todayKey, isCompleted);
      await prefs.setString(_lastActiveDateKey(userId), todayStr);

      // Keep legacy key in sync for backwards compatibility
      final legacyKey = 'user_${userId}_habit_${habitId}_completed';
      await prefs.setBool(legacyKey, isCompleted);

      // Update widget
      AppWidgetService.syncWidget();
    } catch (e) {
      debugPrint('Error setting habit completion: $e');
    }
  }

  /// Checks if midnight has passed since last check.
  /// If a new day has arrived, handles streak maintenance and signals a reset.
  static Future<bool> verifyAndPerformMidnightReset(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = getTodayDateStr();
      final lastDate = prefs.getString(_lastActiveDateKey(userId));

      if (lastDate == null) {
        // First initialization
        await prefs.setString(_lastActiveDateKey(userId), todayStr);
        return false;
      }

      if (lastDate != todayStr) {
        debugPrint('Midnight rollover detected: Last active was $lastDate, today is $todayStr');

        final yesterdayStr = getYesterdayDateStr();

        // If last active date was yesterday, streak is eligible to continue.
        // If last active was older than yesterday, the user missed a day -> reset streak.
        if (lastDate != yesterdayStr) {
          await prefs.setInt(_streakKey(userId), 0);
        }

        // Clean legacy habit completed keys so fallback screens don't read yesterday's state
        final defaultHabitIds = ['def-1', 'def-2', 'def-3', 'def-4', 'def-5'];
        for (final hid in defaultHabitIds) {
          final legacyKey = 'user_${userId}_habit_${hid}_completed';
          await prefs.setBool(legacyKey, false);
        }

        // Update the last active date to today
        await prefs.setString(_lastActiveDateKey(userId), todayStr);
        AppWidgetService.syncWidget();
        return true; // Indicates reset occurred
      }
    } catch (e) {
      debugPrint('Error in verifyAndPerformMidnightReset: $e');
    }
    return false;
  }
}
