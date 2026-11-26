import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/streak_risk_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('typicalCompletionHour', () {
    test('falls back to the evening when there is no history', () {
      expect(StreakRiskReminderService.typicalCompletionHour([]), 20);
    });

    test('uses the median of recorded hours', () {
      expect(
        StreakRiskReminderService.typicalCompletionHour([7, 20, 21]),
        20,
      );
      expect(
        StreakRiskReminderService.typicalCompletionHour([9, 10, 22, 22]),
        22,
      );
    });

    test('clamps night owls and very early risers to waking hours', () {
      expect(StreakRiskReminderService.typicalCompletionHour([1, 2, 3]), 9);
      expect(StreakRiskReminderService.typicalCompletionHour([23, 23]), 22);
    });
  });

  group('planFor', () {
    final now = DateTime(2026, 11, 26, 10, 0);

    StreakRiskPlan? plan({
      int remaining = 2,
      int streak = 5,
      List<int> samples = const [19],
      String? remindedOn,
    }) {
      return StreakRiskReminderService.planFor(
        remainingHabits: remaining,
        streakDays: streak,
        now: now,
        samples: samples,
        alreadyRemindedOn: remindedOn,
      );
    }

    test('schedules at the learned hour on the same day', () {
      final p = plan();
      expect(p, isNotNull);
      expect(p!.fireAt, DateTime(2026, 11, 26, 19));
      expect(p.remainingHabits, 2);
      expect(p.streakDays, 5);
    });

    test('does nothing when every habit is already done', () {
      expect(plan(remaining: 0), isNull);
    });

    test('does nothing when there is no streak to protect', () {
      expect(plan(streak: 0), isNull);
    });

    test('never nags twice in one day', () {
      expect(plan(remindedOn: '2026-11-26'), isNull);
      expect(plan(remindedOn: '2026-11-25'), isNotNull);
    });

    test('uses a short grace nudge once the usual time has passed', () {
      final late = StreakRiskReminderService.planFor(
        remainingHabits: 1,
        streakDays: 9,
        now: DateTime(2026, 11, 26, 20, 0),
        samples: const [18],
      );
      expect(late, isNotNull);
      expect(late!.fireAt, DateTime(2026, 11, 26, 20, 45));
    });

    test('drops the nudge when the day is effectively over', () {
      final tooLate = StreakRiskReminderService.planFor(
        remainingHabits: 1,
        streakDays: 9,
        now: DateTime(2026, 11, 26, 23, 0),
        samples: const [],
      );
      expect(tooLate, isNull);
    });
  });

  group('recordCompletionMoment', () {
    test('keeps one sample per day and stores the latest hour', () async {
      await StreakRiskReminderService.recordCompletionMoment(
        userId: 'u1',
        now: DateTime(2026, 11, 26, 8, 30),
      );
      await StreakRiskReminderService.recordCompletionMoment(
        userId: 'u1',
        now: DateTime(2026, 11, 26, 21, 10),
      );

      final hours = await StreakRiskReminderService.completionHours(
        userId: 'u1',
      );
      expect(hours, [21]);
    });

    test('keeps only the most recent 30 days', () async {
      for (var i = 0; i < 35; i++) {
        await StreakRiskReminderService.recordCompletionMoment(
          userId: 'u2',
          now: DateTime(2026, 1, 1).add(Duration(days: i, hours: 18)),
        );
      }

      final hours = await StreakRiskReminderService.completionHours(
        userId: 'u2',
      );
      expect(hours.length, StreakRiskReminderService.maxSamples);
      expect(hours.every((h) => h == 18), isTrue);
    });
  });
}
