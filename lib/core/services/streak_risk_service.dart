import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/gamification_service.dart';
import 'package:synvero/core/services/language_service.dart';
import 'package:synvero/core/services/notification_service.dart';

/// A concrete decision to nudge the user before their streak breaks.
class StreakRiskPlan {
  const StreakRiskPlan({
    required this.fireAt,
    required this.remainingHabits,
    required this.streakDays,
  });

  /// Moment the reminder should fire.
  final DateTime fireAt;

  /// Habits still pending when the plan was made.
  final int remainingHabits;

  /// Streak length being protected.
  final int streakDays;
}

/// Schedules at most one "your streak is at risk" nudge per day, timed from the
/// hour at which the user usually finishes their habits.
///
/// The service only *reads* completion state: it never marks a habit done, never
/// grants XP and never touches the 24h lock, so it can't interfere with the
/// anti-farming rules.
class StreakRiskReminderService {
  StreakRiskReminderService._();

  /// Fixed notification id so a re-plan replaces the previous nudge.
  static const int notificationId = 9200;

  /// How many learned completion days are kept.
  static const int maxSamples = 30;

  /// Used until enough history exists.
  static const int defaultHour = 20;

  /// Reminders stay inside waking hours.
  static const int earliestHour = 9;
  static const int latestHour = 22;

  /// If the usual time already passed, nudge this long from now instead.
  static const Duration lateGrace = Duration(minutes: 45);

  static String _samplesKey(String userId) =>
      'user_${userId}_streak_risk_hours_v1';
  static String _lastRemindedKey(String userId) =>
      'user_${userId}_streak_risk_last_reminded_v1';

  static String formatDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

  /// Remembers the hour at which the user actually completed a habit.
  ///
  /// One sample per calendar day is enough to learn a routine: completing five
  /// habits in the evening should not outweigh five days of evening finishes.
  static Future<void> recordCompletionMoment({
    String? userId,
    DateTime? now,
  }) async {
    final uid = userId ?? GamificationService.currentUserId;
    final moment = now ?? DateTime.now();
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = formatDate(moment);
      final entries = prefs.getStringList(_samplesKey(uid)) ?? <String>[];

      entries.removeWhere((e) => e.startsWith('$dateStr:'));
      entries.add('$dateStr:${moment.hour}');

      if (entries.length > maxSamples) {
        entries.removeRange(0, entries.length - maxSamples);
      }
      await prefs.setStringList(_samplesKey(uid), entries);
    } catch (e) {
      debugPrint('StreakRiskReminderService.recordCompletionMoment error: $e');
    }
  }

  /// Learned completion hours, oldest first.
  static Future<List<int>> completionHours({String? userId}) async {
    final uid = userId ?? GamificationService.currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = prefs.getStringList(_samplesKey(uid)) ?? <String>[];
      return entries
          .map((e) => int.tryParse(e.split(':').last))
          .whereType<int>()
          .where((h) => h >= 0 && h <= 23)
          .toList();
    } catch (_) {
      return <int>[];
    }
  }

  /// Median completion hour, clamped to a sensible waking window.
  static int typicalCompletionHour(List<int> samples) {
    if (samples.isEmpty) return defaultHour;
    final sorted = List<int>.from(samples)..sort();
    final median = sorted[sorted.length ~/ 2];
    return median.clamp(earliestHour, latestHour);
  }

  /// Decides whether a nudge is worth scheduling.
  ///
  /// Returns null when there is nothing to protect (no streak, everything done,
  /// already nudged today) or when the useful window has closed.
  static StreakRiskPlan? planFor({
    required int remainingHabits,
    required int streakDays,
    required DateTime now,
    required List<int> samples,
    String? alreadyRemindedOn,
  }) {
    if (remainingHabits <= 0) return null;
    if (streakDays <= 0) return null;

    final today = formatDate(now);
    if (alreadyRemindedOn == today) return null;

    final hour = typicalCompletionHour(samples);
    var fireAt = DateTime(now.year, now.month, now.day, hour);

    // Usual time has passed: one short grace nudge instead of nothing.
    if (!fireAt.isAfter(now)) {
      fireAt = now.add(lateGrace);
      final cutoff = DateTime(now.year, now.month, now.day, 23, 15);
      if (fireAt.isAfter(cutoff)) return null;
    }

    return StreakRiskPlan(
      fireAt: fireAt,
      remainingHabits: remainingHabits,
      streakDays: streakDays,
    );
  }

  /// Re-plans today's nudge and hands it to the OS scheduler.
  ///
  /// Safe to call on every app open and after every habit toggle; it always
  /// cancels the previous plan first so only one nudge can ever be pending.
  static Future<void> refreshForToday({
    String? userId,
    required int remainingHabits,
    required int streakDays,
    DateTime? now,
  }) async {
    final uid = userId ?? GamificationService.currentUserId;
    final moment = now ?? DateTime.now();
    try {
      await NotificationService.cancelHabitReminder(notificationId);

      final prefs = await SharedPreferences.getInstance();
      final samples = await completionHours(userId: uid);
      final plan = planFor(
        remainingHabits: remainingHabits,
        streakDays: streakDays,
        now: moment,
        samples: samples,
        alreadyRemindedOn: prefs.getString(_lastRemindedKey(uid)),
      );
      if (plan == null) return;

      final copy = _copyFor(plan, LanguageService.currentLanguageCode);
      await NotificationService.scheduleHabitReminder(
        id: notificationId,
        title: copy.title,
        body: copy.body,
        scheduledDate: plan.fireAt,
      );
      await prefs.setString(_lastRemindedKey(uid), formatDate(moment));
    } catch (e) {
      debugPrint('StreakRiskReminderService.refreshForToday error: $e');
    }
  }

  /// Drops the pending nudge (e.g. after the user completes everything).
  static Future<void> cancel() async {
    try {
      await NotificationService.cancelHabitReminder(notificationId);
    } catch (e) {
      debugPrint('StreakRiskReminderService.cancel error: $e');
    }
  }

  static _ReminderCopy _copyFor(StreakRiskPlan plan, String lang) {
    final days = plan.streakDays;
    final left = plan.remainingHabits;
    if (lang == LanguageService.marathi) {
      return _ReminderCopy(
        title: '🔥 स्ट्रिक धोक्यात आहे!',
        body:
            '$days दिवसांची स्ट्रिक आज तुटू शकते. $left हॅबिट्स शिल्लक — फक्त १ टॅप करा.',
      );
    }
    if (lang == LanguageService.hindi) {
      return _ReminderCopy(
        title: '🔥 स्ट्रीक खतरे में है!',
        body:
            '$days दिन की स्ट्रीक आज टूट सकती है। $left आदतें बाकी हैं — बस 1 टैप करें।',
      );
    }
    return _ReminderCopy(
      title: '🔥 Streak at risk!',
      body:
          'Your $days-day streak ends tonight. $left habit${left == 1 ? '' : 's'} left — one tap keeps it alive.',
    );
  }
}

class _ReminderCopy {
  const _ReminderCopy({required this.title, required this.body});

  final String title;
  final String body;
}
