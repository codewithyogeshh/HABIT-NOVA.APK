import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/notification_service.dart';
import 'package:synvero/core/services/supabase_service.dart';

/// Task item model with scheduling and persistence.
class TaskItem {
  final String id;
  String title;
  String time;
  String priority; // 'High', 'Medium', 'Low'
  bool isCompleted;
  bool isUpcoming;
  DateTime? scheduledDate;

  TaskItem({
    required this.id,
    required this.title,
    required this.time,
    required this.priority,
    this.isCompleted = false,
    this.isUpcoming = false,
    this.scheduledDate,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'time': time,
        'priority': priority,
        'isCompleted': isCompleted,
        'isUpcoming': isUpcoming,
        'scheduledDate': scheduledDate?.toIso8601String(),
      };

  factory TaskItem.fromMap(Map<String, dynamic> map) => TaskItem(
        id: map['id'] as String,
        title: map['title'] as String,
        time: map['time'] as String,
        priority: map['priority'] as String? ?? 'Medium',
        isCompleted: map['isCompleted'] as bool? ?? false,
        isUpcoming: map['isUpcoming'] as bool? ?? false,
        scheduledDate: map['scheduledDate'] != null
            ? DateTime.tryParse(map['scheduledDate'] as String)
            : null,
      );
}

/// Unified service for managing tasks, upcoming schedules, alarms, and 5-min reminders.
class TaskService {
  static const String _storageKey = 'synvero_user_tasks_v3';

  static String get _userId => SupabaseService.user?.id ?? 'guest';

  /// Loads all saved tasks for the current user.
  static Future<List<TaskItem>> getTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_userId}_$_storageKey';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => TaskItem.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
    return [];
  }

  /// Saves the complete list of tasks to SharedPreferences.
  static Future<void> saveTasks(List<TaskItem> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_userId}_$_storageKey';
      final encoded = jsonEncode(tasks.map((t) => t.toMap()).toList());
      await prefs.setString(key, encoded);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  /// Adds a new task and schedules both:
  /// 1. An exact loud ringing alarm at task time.
  /// 2. A 5-minute advance reminder notification.
  static Future<void> addTask(TaskItem task) async {
    final tasks = await getTasks();
    tasks.insert(0, task);
    await saveTasks(tasks);

    if (task.scheduledDate != null &&
        task.scheduledDate!.isAfter(DateTime.now())) {
      final notifId = task.id.hashCode & 0x7fffffff;

      // 1. Exact Alarm at task time
      await NotificationService.scheduleTaskAlarm(
        id: notifId,
        title: '🚨 Task Alarm: ${task.title}',
        body: 'वेळ झाली! It\'s ${task.time} - Time to complete: ${task.title}',
        scheduledDate: task.scheduledDate!,
      );

      // 2. Advance reminder 5 minutes before
      final reminderTime =
          task.scheduledDate!.subtract(const Duration(minutes: 5));
      if (reminderTime.isAfter(DateTime.now())) {
        await NotificationService.scheduleAdvanceReminder(
          id: (notifId + 1000000) & 0x7fffffff,
          title: '⏳ 5-Min Reminder: ${task.title}',
          body: '${task.title} ची वेळ ५ मिनिटांत (${task.time}) होणार आहे!',
          scheduledDate: reminderTime,
        );
      }
    }
  }

  /// Toggles task completion and cancels/reschedules alarms.
  static Future<void> toggleTask(TaskItem task) async {
    final tasks = await getTasks();
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      tasks[idx].isCompleted = !tasks[idx].isCompleted;
      final notifId = task.id.hashCode & 0x7fffffff;

      if (tasks[idx].isCompleted) {
        await NotificationService.cancelTaskAlarms(notifId);
      } else if (tasks[idx].scheduledDate != null &&
          tasks[idx].scheduledDate!.isAfter(DateTime.now())) {
        // Reschedule exact alarm
        await NotificationService.scheduleTaskAlarm(
          id: notifId,
          title: '🚨 Task Alarm: ${task.title}',
          body: 'वेळ झाली! It\'s ${task.time} - Time to complete: ${task.title}',
          scheduledDate: tasks[idx].scheduledDate!,
        );

        // Reschedule 5-min reminder
        final reminderTime =
            tasks[idx].scheduledDate!.subtract(const Duration(minutes: 5));
        if (reminderTime.isAfter(DateTime.now())) {
          await NotificationService.scheduleAdvanceReminder(
            id: (notifId + 1000000) & 0x7fffffff,
            title: '⏳ 5-Min Reminder: ${task.title}',
            body: '${task.title} ची वेळ ५ मिनिटांत (${task.time}) होणार आहे!',
            scheduledDate: reminderTime,
          );
        }
      }
      await saveTasks(tasks);
    }
  }

  /// Deletes a task and cancels its alarm and reminder.
  static Future<void> deleteTask(String id) async {
    final tasks = await getTasks();
    tasks.removeWhere((t) => t.id == id);
    await saveTasks(tasks);
    await NotificationService.cancelTaskAlarms(id.hashCode & 0x7fffffff);
  }

  /// Returns upcoming tasks (scheduled for tomorrow or marked upcoming).
  static Future<List<TaskItem>> getUpcomingTasks() async {
    final tasks = await getTasks();
    final now = DateTime.now();
    return tasks.where((t) {
      if (t.isCompleted) return false;
      if (t.isUpcoming) return true;
      if (t.scheduledDate != null) {
        return t.scheduledDate!.isAfter(
            DateTime(now.year, now.month, now.day, 23, 59, 59));
      }
      return false;
    }).toList();
  }
}
