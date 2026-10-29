import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/supabase_service.dart';
import 'package:synvero/core/services/task_service.dart';
import 'package:synvero/features/habits/data/habit_repository.dart';

/// Service syncing live user task and habit progress to the Android Home Screen Widget.
class AppWidgetService {
  static const MethodChannel _channel = MethodChannel('com.example.synvero/widget');

  /// Reads current user tasks and habits, calculates live completion progress,
  /// and updates all instances of the HabbitNova Android Home Screen Widget.
  static Future<void> syncWidget() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      // 1. Load active tasks
      final tasks = await TaskService.getTasks();
      final todayTasks = tasks.where((t) => !t.isUpcoming).toList();
      final tasksTotal = todayTasks.length;
      final tasksDone = todayTasks.where((t) => t.isCompleted).length;

      // 2. Load habits
      int habitsTotal = 0;
      int habitsDone = 0;
      int maxStreak = 0;

      try {
        final currentUserId = SupabaseService.user?.id ?? 'guest';
        final prefs = await SharedPreferences.getInstance();

        bool loadedFromSupabase = false;
        if (SupabaseService.user != null) {
          try {
            final habitRepo = HabitRepository();
            final habits = await habitRepo.getHabits();
            if (habits.isNotEmpty) {
              habitsTotal = habits.length;
              final todayStatus = await habitRepo.getTodaysCompletionStatus();
              habitsDone = todayStatus.values.where((done) => done).length;
              for (final h in habits) {
                try {
                  final s = await habitRepo.calculateStreak(h.id);
                  if (s > maxStreak) maxStreak = s;
                } catch (_) {}
              }
              loadedFromSupabase = true;
            }
          } catch (e) {
            debugPrint('Supabase habits unavailable, falling back to local: $e');
          }
        }

        if (!loadedFromSupabase) {
          // Local/guest default habits
          final defaultHabitIds = ['def-1', 'def-2', 'def-3', 'def-4', 'def-5'];
          habitsTotal = defaultHabitIds.length;
          for (final id in defaultHabitIds) {
            final key = 'user_${currentUserId}_habit_${id}_completed';
            if (prefs.getBool(key) ?? false) {
              habitsDone++;
            }
          }
          final savedStreak = prefs.getInt('user_${currentUserId}_streak_days');
          maxStreak = savedStreak ?? (habitsDone > 0 ? 1 : 0);
        }
      } catch (e) {
        debugPrint('AppWidgetService habit loading error: $e');
      }

      final total = tasksTotal + habitsTotal;
      final completed = tasksDone + habitsDone;
      final pct = total > 0 ? ((completed / total) * 100).round() : 0;

      final streakBadge = maxStreak > 0
          ? '🔥 $maxStreak-Day Streak'
          : (completed > 0 ? '⚡ $completed Done' : '⚡ Get Started');

      final label = habitsTotal > 0 && tasksTotal > 0
          ? "Today's Progress"
          : (tasksTotal > 0 ? "Today's Tasks" : "Today's Habits");

      final countText = total > 0 ? '$completed of $total Done' : 'No items yet';

      await _channel.invokeMethod('updateWidgetData', {
        'title': 'HabbitNova',
        'streak': streakBadge,
        'label': label,
        'countText': countText,
        'percentageText': '$pct%',
      });
      debugPrint('AppWidgetService: synced live progress -> $countText ($pct%)');
    } catch (e) {
      debugPrint('AppWidgetService.syncWidget error: $e');
    }
  }
}
