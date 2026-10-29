import 'dart:convert';
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
      final prefs = await SharedPreferences.getInstance();

      // 1. Resolve live Username
      String username = 'Yogesh';
      try {
        final user = SupabaseService.user;
        if (user != null) {
          final meta = user.userMetadata?['username'] as String?;
          if (meta != null && meta.trim().isNotEmpty) {
            username = meta.trim();
          } else if (user.email != null && user.email!.isNotEmpty) {
            username = user.email!.split('@').first;
          }
        } else {
          final savedName = prefs.getString('saved_username');
          if (savedName != null && savedName.trim().isNotEmpty) {
            username = savedName.trim();
          }
        }
      } catch (_) {}

      // Capitalize first letter
      if (username.isNotEmpty) {
        username = username[0].toUpperCase() + username.substring(1);
      }

      // 2. Load active tasks
      final tasks = await TaskService.getTasks();
      final todayTasks = tasks.where((t) => !t.isUpcoming).toList();
      final tasksTotal = todayTasks.length;
      final tasksDone = todayTasks.where((t) => t.isCompleted).length;

      final tasksList = todayTasks.take(4).map((t) => {
        'title': t.title,
        'done': t.isCompleted,
      }).toList();

      // Fallback sample tasks if none exist
      if (tasksList.isEmpty) {
        tasksList.addAll([
          {'title': 'Complete Project', 'done': false},
          {'title': 'Learn Java', 'done': false},
          {'title': 'Design Portfolio', 'done': false},
          {'title': 'Workout Plan', 'done': false},
        ]);
      }
      final tasksJson = jsonEncode(tasksList);

      // 3. Load habits
      int habitsTotal = 0;
      int habitsDone = 0;
      int maxStreak = 0;
      final List<Map<String, dynamic>> habitsList = [];

      try {
        final currentUserId = SupabaseService.user?.id ?? 'guest';
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

                final isDone = todayStatus[h.id] ?? false;
                habitsList.add({
                  'title': h.name,
                  'icon': _getHabitEmoji(h.name),
                  'done': isDone,
                });
              }
              loadedFromSupabase = true;
            }
          } catch (e) {
            debugPrint('Supabase habits unavailable, falling back to local: $e');
          }
        }

        if (!loadedFromSupabase) {
          final defaultDefs = [
            {'id': 'def-1', 'title': 'Drink Water', 'icon': '💧'},
            {'id': 'def-2', 'title': 'Workout', 'icon': '🏋️'},
            {'id': 'def-3', 'title': 'Read Book', 'icon': '📖'},
            {'id': 'def-4', 'title': 'Meditate', 'icon': '🧘'},
            {'id': 'def-5', 'title': 'Sleep Early', 'icon': '🌙'},
          ];
          habitsTotal = defaultDefs.length;

          for (final def in defaultDefs) {
            final key = 'user_${currentUserId}_habit_${def['id']}_completed';
            final isDone = prefs.getBool(key) ?? false;
            if (isDone) habitsDone++;

            habitsList.add({
              'title': def['title'] as String,
              'icon': def['icon'] as String,
              'done': isDone,
            });
          }
          final savedStreak = prefs.getInt('user_${currentUserId}_streak_days');
          maxStreak = savedStreak ?? (habitsDone > 0 ? 1 : 0);
        }
      } catch (e) {
        debugPrint('AppWidgetService habit loading error: $e');
      }

      final habitsJson = jsonEncode(habitsList.take(5).toList());

      // 4. Counts & Text
      final habitsCountStr = habitsTotal > 0 ? '$habitsDone of $habitsTotal' : '5 of 5';
      final tasksCountStr = tasksTotal > 0 ? '$tasksDone of $tasksTotal' : '2 of 4';
      final streakStr = '${maxStreak > 0 ? maxStreak : 1}d';

      // 5. Dynamic Banner Quotes
      String bannerTitle = "You're doing great!";
      String bannerSubtitle = "Discipline today builds the freedom of tomorrow.";

      final totalItems = habitsTotal + tasksTotal;
      final completedItems = habitsDone + tasksDone;

      if (totalItems > 0 && completedItems == totalItems) {
        bannerTitle = "You're extraordinary!";
        bannerSubtitle = "All goals crushed today! Consistency is your superpower.";
      } else if (completedItems > 0) {
        bannerTitle = "You're doing great!";
        bannerSubtitle = "Discipline today builds the freedom of tomorrow.";
      } else {
        bannerTitle = "Ready to Conquer Today?";
        bannerSubtitle = "Small steps every day lead to massive transformations.";
      }

      await _channel.invokeMethod('updateWidgetData', {
        'username': username,
        'streak': streakStr,
        'habitsCount': habitsCountStr,
        'habitsTotal': habitsTotal > 0 ? habitsTotal : 5,
        'habitsDone': habitsDone,
        'habitsJson': habitsJson,

        'tasksCount': tasksCountStr,
        'tasksTotal': tasksTotal > 0 ? tasksTotal : 4,
        'tasksDone': tasksDone,
        'tasksJson': tasksJson,

        'bannerTitle': bannerTitle,
        'bannerSubtitle': bannerSubtitle,
      });

      debugPrint('AppWidgetService: synced live widget for $username -> Habits: $habitsCountStr, Tasks: $tasksCountStr');
    } catch (e) {
      debugPrint('AppWidgetService.syncWidget error: $e');
    }
  }

  static String _getHabitEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('water') || lower.contains('drink')) return '💧';
    if (lower.contains('work') || lower.contains('gym') || lower.contains('exercise')) return '🏋️';
    if (lower.contains('read') || lower.contains('book') || lower.contains('study')) return '📖';
    if (lower.contains('meditat') || lower.contains('mind')) return '🧘';
    if (lower.contains('sleep') || lower.contains('bed')) return '🌙';
    if (lower.contains('walk') || lower.contains('run')) return '🏃';
    return '🌿';
  }
}
