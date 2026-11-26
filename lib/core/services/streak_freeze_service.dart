import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/gamification_service.dart';

/// Result of trying to buy a streak freeze with XP.
enum FreezePurchaseResult { success, insufficientXP, atCapacity, error }

/// Owns the "Streak Freeze" inventory for a user.
///
/// Rules:
///  - One freeze is granted free every calendar week (Monday based).
///  - At most [maxFreezes] freezes can be stored at a time.
///  - Extra freezes can be bought for [freezeCostXP] XP. Buying only ever
///    *spends* XP, so it can never be used to farm points.
///  - A freeze is consumed automatically for every whole day that was missed,
///    which keeps the streak alive. A gap is only covered when enough freezes
///    exist for the whole gap, so a single freeze is never silently wasted.
///
/// The service is intentionally independent from [HabitDailyService] (which
/// depends on it) to keep the import graph acyclic.
class StreakFreezeService {
  StreakFreezeService._();

  /// Free freezes granted at the start of each week.
  static const int weeklyFreeFreezes = 1;

  /// How many freezes can be banked at once.
  static const int maxFreezes = 3;

  /// XP price of one purchased freeze.
  static const int freezeCostXP = 100;

  /// Frozen dates kept for history (older entries are trimmed).
  static const int _maxFrozenHistory = 60;

  static String _countKey(String userId) => 'user_${userId}_streak_freezes_v1';
  static String _weekKey(String userId) =>
      'user_${userId}_streak_freeze_week_v1';
  static String _frozenDatesKey(String userId) =>
      'user_${userId}_streak_frozen_dates_v1';
  static String _streakLastDateKey(String userId) =>
      'user_${userId}_streak_last_date_v1';
  static String _streakKey(String userId) => 'user_${userId}_streak_days';

  /// `yyyy-MM-dd` for the local calendar day of [date].
  static String formatDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

  /// Monday of the week containing [now], used as the weekly grant key.
  static String weekKeyFor(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    return formatDate(
      DateTime(day.year, day.month, day.day - (day.weekday - 1)),
    );
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Grants this week's free freeze once. Safe to call on every app open.
  ///
  /// Returns true only when a freeze was actually added.
  static Future<bool> grantWeeklyFreezeIfDue({
    String? userId,
    DateTime? now,
  }) async {
    final uid = userId ?? GamificationService.currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final weekKey = weekKeyFor(now ?? DateTime.now());
      if (prefs.getString(_weekKey(uid)) == weekKey) return false;

      // Mark the week as handled even at capacity, so the user doesn't get a
      // second grant later in the same week after spending a freeze.
      await prefs.setString(_weekKey(uid), weekKey);

      final current = prefs.getInt(_countKey(uid)) ?? 0;
      if (current >= maxFreezes) return false;

      final next = (current + weeklyFreeFreezes).clamp(0, maxFreezes);
      await prefs.setInt(_countKey(uid), next);
      return next > current;
    } catch (e) {
      debugPrint('StreakFreezeService.grantWeeklyFreezeIfDue error: $e');
      return false;
    }
  }

  /// Number of freezes available right now (grants the weekly freeze first).
  static Future<int> availableFreezes({String? userId, DateTime? now}) async {
    final uid = userId ?? GamificationService.currentUserId;
    try {
      await grantWeeklyFreezeIfDue(userId: uid, now: now);
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_countKey(uid)) ?? 0;
    } catch (e) {
      debugPrint('StreakFreezeService.availableFreezes error: $e');
      return 0;
    }
  }

  /// Buys one freeze for [freezeCostXP] XP.
  static Future<FreezePurchaseResult> purchaseFreeze({String? userId}) async {
    final uid = userId ?? GamificationService.currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_countKey(uid)) ?? 0;
      if (current >= maxFreezes) return FreezePurchaseResult.atCapacity;

      final spent = await GamificationService.spendXP(
        freezeCostXP,
        userId: uid,
        reason: 'Bought a Streak Freeze',
      );
      if (!spent) return FreezePurchaseResult.insufficientXP;

      await prefs.setInt(_countKey(uid), current + 1);
      return FreezePurchaseResult.success;
    } catch (e) {
      debugPrint('StreakFreezeService.purchaseFreeze error: $e');
      return FreezePurchaseResult.error;
    }
  }

  /// Number of whole days missed since the last completed day.
  ///
  /// Returns 0 when the streak is 0, the last date is unknown, or nothing was
  /// missed. Used by the midnight rollover to decide whether a freeze is
  /// needed and whether an uncovered gap must break the streak.
  static Future<int> missedDays({String? userId, DateTime? now}) async {
    final uid = userId ?? GamificationService.currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final streak = prefs.getInt(_streakKey(uid)) ?? 0;
      if (streak <= 0) return 0;

      final lastStr =
          prefs.getString(_streakLastDateKey(uid)) ??
          prefs.getString('user_${uid}_last_habit_date');
      final last = _parseDate(lastStr);
      if (last == null) return 0;

      final reference = now ?? DateTime.now();
      final today = DateTime(reference.year, reference.month, reference.day);
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      if (!last.isBefore(yesterday)) return 0;

      return yesterday.difference(last).inDays;
    } catch (e) {
      debugPrint('StreakFreezeService.missedDays error: $e');
      return 0;
    }
  }

  /// Consumes freezes for every whole day missed since the last completed day.
  ///
  /// Returns the number of days covered (0 when nothing was missed or when the
  /// bank doesn't hold enough freezes for the whole gap). On success the streak
  /// is preserved and the last completed day is moved to yesterday, so the same
  /// gap can never be charged twice.
  static Future<int> applyMissedDayFreeze({
    String? userId,
    DateTime? now,
  }) async {
    final uid = userId ?? GamificationService.currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final streak = prefs.getInt(_streakKey(uid)) ?? 0;
      if (streak <= 0) return 0;

      var lastStr = prefs.getString(_streakLastDateKey(uid));
      if (lastStr == null) {
        // Users who built a streak before this feature existed have no
        // dedicated key; fall back to their last habit activity date.
        lastStr = prefs.getString('user_${uid}_last_habit_date');
        if (lastStr != null) {
          await prefs.setString(_streakLastDateKey(uid), lastStr);
        }
      }

      final last = _parseDate(lastStr);
      if (last == null) return 0;

      final today = DateTime(
        (now ?? DateTime.now()).year,
        (now ?? DateTime.now()).month,
        (now ?? DateTime.now()).day,
      );
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      if (!last.isBefore(yesterday)) return 0;

      final missed = yesterday.difference(last).inDays;
      if (missed <= 0) return 0;

      final available = prefs.getInt(_countKey(uid)) ?? 0;
      if (available < missed) return 0;

      final frozen = prefs.getStringList(_frozenDatesKey(uid)) ?? <String>[];
      for (var i = 1; i <= missed; i++) {
        frozen.add(formatDate(DateTime(last.year, last.month, last.day + i)));
      }
      if (frozen.length > _maxFrozenHistory) {
        frozen.removeRange(0, frozen.length - _maxFrozenHistory);
      }

      await prefs.setStringList(_frozenDatesKey(uid), frozen);
      await prefs.setInt(_countKey(uid), available - missed);
      await prefs.setString(_streakLastDateKey(uid), formatDate(yesterday));
      return missed;
    } catch (e) {
      debugPrint('StreakFreezeService.applyMissedDayFreeze error: $e');
      return 0;
    }
  }

  /// Records that today had at least one completed habit.
  ///
  /// Called once per completed habit; extra calls on the same day are no-ops,
  /// so unticking and re-ticking can never inflate the streak. Returns the
  /// resulting streak length.
  static Future<int> recordCompletionDay({
    String? userId,
    DateTime? now,
  }) async {
    final uid = userId ?? GamificationService.currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime(
        (now ?? DateTime.now()).year,
        (now ?? DateTime.now()).month,
        (now ?? DateTime.now()).day,
      );
      final todayStr = formatDate(today);
      final yesterdayStr = formatDate(
        DateTime(today.year, today.month, today.day - 1),
      );

      final streak = prefs.getInt(_streakKey(uid)) ?? 0;
      final lastStr =
          prefs.getString(_streakLastDateKey(uid)) ??
          prefs.getString('user_${uid}_last_habit_date');

      if (lastStr == todayStr) {
        // Already counted today. Repair a missing/inconsistent value only.
        if (streak > 0) return streak;
        await _writeStreak(prefs, uid, 1);
        return 1;
      }

      int nextStreak;
      if (lastStr == yesterdayStr) {
        nextStreak = streak > 0 ? streak + 1 : 1;
      } else if (lastStr == null) {
        // Legacy user: keep the stored streak instead of resetting it.
        nextStreak = streak > 0 ? streak : 1;
      } else {
        nextStreak = 1;
      }

      await prefs.setString(_streakLastDateKey(uid), todayStr);
      await _writeStreak(prefs, uid, nextStreak);
      return nextStreak;
    } catch (e) {
      debugPrint('StreakFreezeService.recordCompletionDay error: $e');
      return 0;
    }
  }

  static Future<void> _writeStreak(
    SharedPreferences prefs,
    String uid,
    int streak,
  ) async {
    await prefs.setInt(_streakKey(uid), streak);
    // Kept in sync for the leaderboard / widget readers.
    await prefs.setInt('app_streak_days', streak);
  }

  static Future<int> currentStreak({String? userId}) async {
    final uid = userId ?? GamificationService.currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_streakKey(uid)) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Dates whose missed day was covered by a freeze, oldest first.
  static Future<List<String>> frozenDates({String? userId}) async {
    final uid = userId ?? GamificationService.currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_frozenDatesKey(uid)) ?? <String>[];
    } catch (_) {
      return <String>[];
    }
  }
}
