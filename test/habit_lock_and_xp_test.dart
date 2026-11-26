import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/gamification_service.dart';
import 'package:synvero/core/services/habit_daily_service.dart';

/// `addXPOnce` and `isHabitLocked` are the two guards that stop a user from
/// un-ticking a completed habit and re-ticking it to farm XP.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String habitId = 'habit-1';
  const int starterXP = 150;

  String completedAtKey(String userId, String id) =>
      'user_${userId}_habit_${id}_completed_at';

  String completedTodayKey(String userId, String id) =>
      'user_${userId}_habit_${id}_completed_${HabitDailyService.getTodayDateStr()}';

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // Resets the static notifier back to the starter XP (150).
    await GamificationService.loadXP();
  });

  group('GamificationService.addXPOnce', () {
    test('awards XP the first time an action key is claimed', () async {
      final bool awarded = await GamificationService.addXPOnce(
        actionKey: 'habit_${habitId}_2026-11-25',
        amount: GamificationService.xpPerHabit,
        reason: 'Completed Habit',
      );

      expect(awarded, isTrue);
      expect(GamificationService.totalXPNotifier.value, starterXP + 50);
    });

    test('does not award XP for the same action key a second time', () async {
      const String key = 'habit_${habitId}_2026-11-25';

      final bool first = await GamificationService.addXPOnce(
        actionKey: key,
        amount: GamificationService.xpPerHabit,
        reason: 'Completed Habit',
      );
      expect(first, isTrue);
      expect(GamificationService.totalXPNotifier.value, starterXP + 50);

      // Un-tick + re-tick must not pay out again.
      final bool second = await GamificationService.addXPOnce(
        actionKey: key,
        amount: GamificationService.xpPerHabit,
        reason: 'Completed Habit',
      );

      expect(second, isFalse);
      expect(GamificationService.totalXPNotifier.value, starterXP + 50);
    });

    test('awards XP again for a different day key', () async {
      await GamificationService.addXPOnce(
        actionKey: 'habit_${habitId}_2026-11-25',
        amount: GamificationService.xpPerHabit,
        reason: 'Completed Habit',
      );

      final bool nextDay = await GamificationService.addXPOnce(
        actionKey: 'habit_${habitId}_2026-11-26',
        amount: GamificationService.xpPerHabit,
        reason: 'Completed Habit',
      );

      expect(nextDay, isTrue);
      expect(GamificationService.totalXPNotifier.value, starterXP + 100);
    });

    test('awards XP for a different habit on the same day', () async {
      await GamificationService.addXPOnce(
        actionKey: 'habit_habit-1_2026-11-25',
        amount: GamificationService.xpPerHabit,
        reason: 'Completed Habit',
      );

      final bool otherHabit = await GamificationService.addXPOnce(
        actionKey: 'habit_habit-2_2026-11-25',
        amount: GamificationService.xpPerHabit,
        reason: 'Completed Habit',
      );

      expect(otherHabit, isTrue);
      expect(GamificationService.totalXPNotifier.value, starterXP + 100);
    });

    test('marks the claim in storage so it survives a notifier reset', () async {
      await GamificationService.addXPOnce(
        actionKey: 'habit_${habitId}_2026-11-25',
        amount: GamificationService.xpPerHabit,
        reason: 'Completed Habit',
      );

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool('user_guest_xp_claimed_habit_${habitId}_2026-11-25'),
        isTrue,
      );

      // A fresh 150-XP load must not allow the same claim again.
      await GamificationService.loadXP();
      final bool replay = await GamificationService.addXPOnce(
        actionKey: 'habit_${habitId}_2026-11-25',
        amount: GamificationService.xpPerHabit,
        reason: 'Completed Habit',
      );

      expect(replay, isFalse);
    });
  });

  group('HabitDailyService.isHabitLocked', () {
    test('locks a habit right after it is completed', () async {
      await HabitDailyService.setHabitCompletedToday('guest', habitId, true);

      expect(await HabitDailyService.isHabitLocked('guest', habitId), isTrue);
      expect(
        await HabitDailyService.habitCompletedAt('guest', habitId),
        isNotNull,
      );
    });

    test('stays locked 23 hours after completion', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        completedAtKey('guest', habitId): DateTime.now()
            .subtract(const Duration(hours: 23))
            .toIso8601String(),
      });

      expect(await HabitDailyService.isHabitLocked('guest', habitId), isTrue);
    });

    test('unlocks once 24 hours have passed', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        completedAtKey('guest', habitId): DateTime.now()
            .subtract(const Duration(hours: 24, minutes: 1))
            .toIso8601String(),
      });

      expect(await HabitDailyService.isHabitLocked('guest', habitId), isFalse);
    });

    test('locks a legacy completion from today that has no timestamp',
        () async {
      // Habit was ticked before the lock existed: only the date-scoped flag
      // exists, there is no `_completed_at` value.
      SharedPreferences.setMockInitialValues(<String, Object>{
        completedTodayKey('guest', habitId): true,
      });

      expect(await HabitDailyService.habitCompletedAt('guest', habitId), isNull);
      expect(await HabitDailyService.isHabitLocked('guest', habitId), isTrue);
    });

    test('does not lock a habit that was never completed', () async {
      expect(await HabitDailyService.isHabitLocked('guest', habitId), isFalse);
    });

    test('un-ticking clears the timestamp so the habit unlocks again',
        () async {
      await HabitDailyService.setHabitCompletedToday('guest', habitId, true);
      expect(await HabitDailyService.isHabitLocked('guest', habitId), isTrue);

      await HabitDailyService.setHabitCompletedToday('guest', habitId, false);

      expect(await HabitDailyService.habitCompletedAt('guest', habitId), isNull);
      expect(await HabitDailyService.isHabitLocked('guest', habitId), isFalse);
    });

    test('locks per habit, not per user', () async {
      await HabitDailyService.setHabitCompletedToday('guest', habitId, true);

      expect(await HabitDailyService.isHabitLocked('guest', habitId), isTrue);
      expect(
        await HabitDailyService.isHabitLocked('guest', 'habit-2'),
        isFalse,
      );
    });
  });
}
