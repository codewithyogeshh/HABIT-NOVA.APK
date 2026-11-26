import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/app_widget_service.dart';
import 'package:synvero/core/services/squad_service.dart';
import 'package:synvero/core/services/streak_freeze_service.dart';
import 'package:synvero/core/services/streak_risk_service.dart';

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

  static String _completedAtKey(String userId, String habitId) {
    return 'user_${userId}_habit_${habitId}_completed_at';
  }

  /// How long a completed habit stays locked from being un-ticked.
  static const Duration completionLockDuration = Duration(hours: 24);

  /// When the habit was ticked (null when never completed / already undone).
  static Future<DateTime?> habitCompletedAt(String userId, String habitId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_completedAtKey(userId, habitId));
      return raw == null ? null : DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  /// True when the habit was completed less than [completionLockDuration] ago.
  ///
  /// While locked the check can't be removed, so a user cannot un-tick and
  /// re-tick to farm XP from the same completion.
  static Future<bool> isHabitLocked(String userId, String habitId) async {
    final completedAt = await habitCompletedAt(userId, habitId);
    if (completedAt != null) {
      return DateTime.now().difference(completedAt) < completionLockDuration;
    }
    // Habits completed before this lock existed carry no timestamp; a
    // completion recorded for today still counts as "within 24 hours".
    return isHabitCompletedToday(userId, habitId);
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

      // Remember the exact completion moment so unticking can be locked for 24h.
      if (isCompleted) {
        await prefs.setString(
          _completedAtKey(userId, habitId),
          DateTime.now().toIso8601String(),
        );
        // Count today once towards the streak (idempotent per day).
        await StreakFreezeService.recordCompletionDay(userId: userId);
        // Learn when this user actually finishes so the nudge lands at their
        // own time rather than a fixed hour.
        await StreakRiskReminderService.recordCompletionMoment(userId: userId);
      } else {
        await prefs.remove(_completedAtKey(userId, habitId));
      }

      // Keep legacy key in sync for backwards compatibility
      final legacyKey = 'user_${userId}_habit_${habitId}_completed';
      await prefs.setBool(legacyKey, isCompleted);

      // Update widget
      AppWidgetService.syncWidget();

      // Realtime cloud sync for squads
      SquadService.syncMyLiveProgressToAllSquads();
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

        // Bank this week's free freeze before the missed days are evaluated.
        await StreakFreezeService.grantWeeklyFreezeIfDue(userId: userId);

        // A missed day is first covered by a banked freeze. The streak only
        // breaks when the whole gap cannot be covered, so one freeze is never
        // silently wasted on a longer absence.
        final missedDays =
            await StreakFreezeService.missedDays(userId: userId);
        final coveredDays = missedDays > 0
            ? await StreakFreezeService.applyMissedDayFreeze(userId: userId)
            : 0;

        if (missedDays > 0 && coveredDays == 0) {
          await prefs.setInt(_streakKey(userId), 0);
          await prefs.setInt('app_streak_days', 0);
        } else if (coveredDays > 0) {
          // The frozen days count as active, so the same gap is not charged
          // again on the next rollover.
          await prefs.setString(_lastActiveDateKey(userId), yesterdayStr);
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
