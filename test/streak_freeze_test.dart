import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/gamification_service.dart';
import 'package:synvero/core/services/habit_daily_service.dart';
import 'package:synvero/core/services/streak_freeze_service.dart';

/// Streak Freeze rules:
///  - 1 free freeze per week, max 3 banked
///  - extras cost 100 XP (XP is only ever spent, never earned, by a purchase)
///  - a missed day is covered automatically when the whole gap fits the bank
///  - completing habits still can't farm XP or streak via un-tick + re-tick
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String uid = 'guest';

  String countKey() => 'user_${uid}_streak_freezes_v1';
  String weekKey() => 'user_${uid}_streak_freeze_week_v1';
  String frozenKey() => 'user_${uid}_streak_frozen_dates_v1';
  String lastStreakKey() => 'user_${uid}_streak_last_date_v1';
  String streakKey() => 'user_${uid}_streak_days';
  String xpKey() => 'user_${uid}_gamification_xp_v1';

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await GamificationService.loadXP(); // resets notifier to the 150 starter XP
  });

  group('weekly free freeze', () {
    test('banks exactly one freeze the first time a week is seen', () async {
      final DateTime now = DateTime(2026, 11, 26, 10); // Thursday

      expect(await StreakFreezeService.availableFreezes(now: now), 1);
      // Same week, different day: no second grant.
      expect(
        await StreakFreezeService.availableFreezes(
          now: now.add(const Duration(days: 1)),
        ),
        1,
      );
    });

    test('grants again in the following week', () async {
      final DateTime now = DateTime(2026, 11, 26);

      await StreakFreezeService.availableFreezes(now: now);
      final int nextWeek = await StreakFreezeService.availableFreezes(
        now: now.add(const Duration(days: 7)),
      );

      expect(nextWeek, 2);
    });

    test('never banks more than maxFreezes', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{countKey(): 3});

      final int available = await StreakFreezeService.availableFreezes(
        now: DateTime(2026, 11, 26),
      );

      expect(available, StreakFreezeService.maxFreezes);
    });
  });

  group('XP purchase', () {
    test('spends exactly freezeCostXP and banks one freeze', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{xpKey(): 300});
      await GamificationService.loadXP();

      final FreezePurchaseResult result =
          await StreakFreezeService.purchaseFreeze();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(result, FreezePurchaseResult.success);
      expect(prefs.getInt(xpKey()), 300 - StreakFreezeService.freezeCostXP);
      expect(
        GamificationService.totalXPNotifier.value,
        300 - StreakFreezeService.freezeCostXP,
      );
      expect(prefs.getInt(countKey()), 1);
    });

    test('refuses when the XP balance is too low', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{xpKey(): 50});
      await GamificationService.loadXP();

      final FreezePurchaseResult result =
          await StreakFreezeService.purchaseFreeze();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(result, FreezePurchaseResult.insufficientXP);
      expect(prefs.getInt(xpKey()), 50);
      expect(prefs.getInt(countKey()) ?? 0, 0);
    });

    test('refuses when the bank is already full', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        xpKey(): 1000,
        countKey(): StreakFreezeService.maxFreezes,
      });
      await GamificationService.loadXP();

      final FreezePurchaseResult result =
          await StreakFreezeService.purchaseFreeze();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(result, FreezePurchaseResult.atCapacity);
      expect(prefs.getInt(xpKey()), 1000);
      expect(prefs.getInt(countKey()), StreakFreezeService.maxFreezes);
    });

    test('purchasing lowers XP instead of awarding it', () async {
      // 150 starter XP can afford exactly one freeze and leaves 50.
      final FreezePurchaseResult result =
          await StreakFreezeService.purchaseFreeze();

      expect(result, FreezePurchaseResult.success);
      expect(GamificationService.totalXPNotifier.value, 50);
      // A second purchase must fail: nothing here can be farmed.
      expect(
        await StreakFreezeService.purchaseFreeze(),
        FreezePurchaseResult.insufficientXP,
      );
    });
  });

  group('missed day recovery', () {
    test('covers a single missed day and keeps the streak', () async {
      final DateTime now = DateTime(2026, 11, 26);
      SharedPreferences.setMockInitialValues(<String, Object>{
        streakKey(): 5,
        lastStreakKey(): '2026-11-24',
        countKey(): 1,
      });

      expect(await StreakFreezeService.missedDays(now: now), 1);
      expect(await StreakFreezeService.applyMissedDayFreeze(now: now), 1);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(countKey()), 0);
      expect(prefs.getInt(streakKey()), 5);
      expect(prefs.getString(lastStreakKey()), '2026-11-25');
      expect(prefs.getStringList(frozenKey()), ['2026-11-25']);
    });

    test('does not spend anything on a gap it cannot fully cover', () async {
      final DateTime now = DateTime(2026, 11, 26);
      SharedPreferences.setMockInitialValues(<String, Object>{
        streakKey(): 9,
        lastStreakKey(): '2026-11-22', // missing 23, 24, 25 = 3 days
        countKey(): 2,
      });

      expect(await StreakFreezeService.missedDays(now: now), 3);
      expect(await StreakFreezeService.applyMissedDayFreeze(now: now), 0);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(countKey()), 2);
      expect(prefs.getString(lastStreakKey()), '2026-11-22');
      expect(prefs.getStringList(frozenKey()), isNull);
    });

    test('does nothing when yesterday was completed', () async {
      final DateTime now = DateTime(2026, 11, 26);
      SharedPreferences.setMockInitialValues(<String, Object>{
        streakKey(): 5,
        lastStreakKey(): '2026-11-25',
        countKey(): 1,
      });

      expect(await StreakFreezeService.missedDays(now: now), 0);
      expect(await StreakFreezeService.applyMissedDayFreeze(now: now), 0);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(countKey()), 1);
    });

    test(
      'falls back to the legacy last habit date for older accounts',
      () async {
        final DateTime now = DateTime(2026, 11, 26);
        SharedPreferences.setMockInitialValues(<String, Object>{
          streakKey(): 4,
          'user_${uid}_last_habit_date': '2026-11-24',
          countKey(): 1,
        });

        expect(await StreakFreezeService.applyMissedDayFreeze(now: now), 1);

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(lastStreakKey()), '2026-11-25');
        expect(prefs.getInt(countKey()), 0);
      },
    );
  });

  group('streak recording', () {
    test('the first completed day starts the streak at 1', () async {
      final DateTime now = DateTime(2026, 11, 26);

      expect(await StreakFreezeService.recordCompletionDay(now: now), 1);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(streakKey()), 1);
      expect(prefs.getString(lastStreakKey()), '2026-11-26');
    });

    test('extra completions on the same day do not grow the streak', () async {
      final DateTime now = DateTime(2026, 11, 26);

      expect(await StreakFreezeService.recordCompletionDay(now: now), 1);
      expect(await StreakFreezeService.recordCompletionDay(now: now), 1);
      expect(
        await StreakFreezeService.recordCompletionDay(
          now: now.add(const Duration(hours: 8)),
        ),
        1,
      );
    });

    test('completing the next day grows the streak', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        streakKey(): 3,
        lastStreakKey(): '2026-11-25',
      });

      final int streak = await StreakFreezeService.recordCompletionDay(
        now: DateTime(2026, 11, 26),
      );

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(streak, 4);
      expect(prefs.getInt(streakKey()), 4);
    });

    test('an uncovered gap restarts the streak at 1', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        streakKey(): 9,
        lastStreakKey(): '2026-11-20',
      });

      final int streak = await StreakFreezeService.recordCompletionDay(
        now: DateTime(2026, 11, 26),
      );

      expect(streak, 1);
    });

    test('a freeze-covered gap continues the streak', () async {
      final DateTime now = DateTime(2026, 11, 26);
      SharedPreferences.setMockInitialValues(<String, Object>{
        streakKey(): 5,
        lastStreakKey(): '2026-11-24',
        countKey(): 1,
      });

      expect(await StreakFreezeService.applyMissedDayFreeze(now: now), 1);
      expect(await StreakFreezeService.recordCompletionDay(now: now), 6);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(countKey()), 0);
      expect(prefs.getStringList(frozenKey()), ['2026-11-25']);
    });
  });

  group('24h lock and addXPOnce stay consistent', () {
    test(
      're-ticking the same habit today adds neither XP nor streak',
      () async {
        await HabitDailyService.setHabitCompletedToday(uid, 'habit-1', true);
        expect(await StreakFreezeService.currentStreak(), 1);

        final String actionKey =
            'habit_habit-1_${HabitDailyService.getTodayDateStr()}';
        expect(
          await GamificationService.addXPOnce(
            actionKey: actionKey,
            amount: GamificationService.xpPerHabit,
            reason: 'Completed Habit',
          ),
          isTrue,
        );
        expect(
          await GamificationService.addXPOnce(
            actionKey: actionKey,
            amount: GamificationService.xpPerHabit,
            reason: 'Completed Habit',
          ),
          isFalse,
        );

        // Simulates the habit being written again after the 24h lock expired.
        await HabitDailyService.setHabitCompletedToday(uid, 'habit-1', true);

        expect(await StreakFreezeService.currentStreak(), 1);
        expect(
          GamificationService.totalXPNotifier.value,
          150 + GamificationService.xpPerHabit,
        );
      },
    );

    test(
      'midnight rollover spends a freeze to keep the streak alive',
      () async {
        final DateTime now = DateTime.now();
        final String twoDaysAgo = StreakFreezeService.formatDate(
          now.subtract(const Duration(days: 2)),
        );
        final String yesterday = StreakFreezeService.formatDate(
          now.subtract(const Duration(days: 1)),
        );

        SharedPreferences.setMockInitialValues(<String, Object>{
          'user_${uid}_last_habit_date': twoDaysAgo,
          lastStreakKey(): twoDaysAgo,
          streakKey(): 4,
          countKey(): 1,
          // Current week already granted, so only the banked freeze is used.
          weekKey(): StreakFreezeService.weekKeyFor(now),
        });

        final bool reset =
            await HabitDailyService.verifyAndPerformMidnightReset(uid);

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(reset, isTrue);
        expect(prefs.getInt(streakKey()), 4);
        expect(prefs.getInt(countKey()), 0);
        expect(prefs.getStringList(frozenKey()), [yesterday]);
        expect(await StreakFreezeService.currentStreak(), 4);
      },
    );

    test(
      'midnight rollover resets the streak when nothing is banked',
      () async {
        final DateTime now = DateTime.now();
        final String twoDaysAgo = StreakFreezeService.formatDate(
          now.subtract(const Duration(days: 2)),
        );

        SharedPreferences.setMockInitialValues(<String, Object>{
          'user_${uid}_last_habit_date': twoDaysAgo,
          lastStreakKey(): twoDaysAgo,
          streakKey(): 4,
          countKey(): 0,
          weekKey(): StreakFreezeService.weekKeyFor(now),
        });

        await HabitDailyService.verifyAndPerformMidnightReset(uid);

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt(streakKey()), 0);
        expect(prefs.getStringList(frozenKey()), isNull);
        expect(await StreakFreezeService.currentStreak(), 0);
      },
    );
  });
}
