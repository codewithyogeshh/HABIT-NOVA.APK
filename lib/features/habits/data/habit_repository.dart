import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import 'models/habit_model.dart';
import 'models/habit_completion_model.dart';

/// HabitRepository — clean interface for habit operations.
///
/// This repository wraps the SupabaseService and provides a stable API
/// for the presentation layer. It handles error mapping and returns
/// typed results instead of throwing exceptions.
class HabitRepository {
  /// Get the current authenticated user ID.
  String? get _currentUserId => SupabaseService.user?.id;

  /// Check if user is authenticated.
  bool get _isAuthenticated => SupabaseService.isAuthenticated;

  /// Throw if not authenticated.
  void _requireAuth() {
    if (!_isAuthenticated || _currentUserId == null) {
      throw HabitException('User not authenticated');
    }
  }

  // =========================================================================
  // Habit CRUD
  // =========================================================================

  /// Fetch all active (non-archived) habits for the current user.
  Future<List<Habit>> getHabits({bool includeArchived = false}) async {
    _requireAuth();

    try {
      final query = SupabaseService.client
          .from('habits')
          .select()
          .eq('user_id', _currentUserId!);

      if (!includeArchived) {
        query.eq('archived', false);
      }

      final response = await query.order('created_at', ascending: true);

      return (response as List)
          .map((e) => Habit.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } on PostgrestException catch (e) {
      throw HabitException('Failed to fetch habits: ${e.message}');
    } catch (e) {
      throw HabitException('Failed to fetch habits: ${e.toString()}');
    }
  }

  /// Fetch a single habit by ID (must belong to current user).
  Future<Habit?> getHabit(String habitId) async {
    _requireAuth();

    try {
      final response = await SupabaseService.client
          .from('habits')
          .select()
          .eq('id', habitId)
          .eq('user_id', _currentUserId!)
          .maybeSingle();

      if (response == null) return null;
      return Habit.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw HabitException('Failed to fetch habit: ${e.message}');
    } catch (e) {
      throw HabitException('Failed to fetch habit: ${e.toString()}');
    }
  }

  /// Create a new habit for the current user.
  Future<Habit> createHabit({
    required String name,
    String? description,
    String? color,
    String? icon,
  }) async {
    _requireAuth();

    try {
      final response = await SupabaseService.client
          .from('habits')
          .insert({
            'user_id': _currentUserId!,
            'name': name,
            'description': description,
            'color': color ?? '#4361EE',
            'icon': icon ?? 'track_changes',
            'archived': false,
          })
          .select()
          .single();

      return Habit.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw HabitException('Failed to create habit: ${e.message}');
    } catch (e) {
      throw HabitException('Failed to create habit: ${e.toString()}');
    }
  }

  /// Update an existing habit (must belong to current user).
  Future<Habit> updateHabit({
    required String habitId,
    String? name,
    String? description,
    String? color,
    String? icon,
    bool? archived,
  }) async {
    _requireAuth();

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (color != null) updates['color'] = color;
      if (icon != null) updates['icon'] = icon;
      if (archived != null) updates['archived'] = archived;

      if (updates.isEmpty) {
        final habit = await getHabit(habitId);
        if (habit == null) throw HabitException('Habit not found');
        return habit;
      }

      final response = await SupabaseService.client
          .from('habits')
          .update(updates)
          .eq('id', habitId)
          .eq('user_id', _currentUserId!)
          .select()
          .single();

      return Habit.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw HabitException('Failed to update habit: ${e.message}');
    } catch (e) {
      throw HabitException('Failed to update habit: ${e.toString()}');
    }
  }

  /// Archive (soft delete) a habit.
  Future<void> archiveHabit(String habitId) async {
    await updateHabit(habitId: habitId, archived: true);
  }

  /// Delete a habit permanently (hard delete).
  Future<void> deleteHabit(String habitId) async {
    _requireAuth();

    try {
      await SupabaseService.client
          .from('habits')
          .delete()
          .eq('id', habitId)
          .eq('user_id', _currentUserId!);
    } on PostgrestException catch (e) {
      throw HabitException('Failed to delete habit: ${e.message}');
    } catch (e) {
      throw HabitException('Failed to delete habit: ${e.toString()}');
    }
  }

  // =========================================================================
  // Habit Completion Operations
  // =========================================================================

  /// Check if a habit is completed for a specific date.
  Future<bool> isCompleted(String habitId, DateTime date) async {
    _requireAuth();

    try {
      final dateStr = date.toIso8601String().split('T').first;
      final response = await SupabaseService.client
          .from('habit_completions')
          .select('id')
          .eq('habit_id', habitId)
          .eq('user_id', _currentUserId!)
          .eq('completed_at', dateStr)
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (e) {
      throw HabitException('Failed to check completion: ${e.message}');
    } catch (e) {
      throw HabitException('Failed to check completion: ${e.toString()}');
    }
  }

  /// Mark a habit as completed for a specific date.
  ///
  /// Returns the created completion record, or throws if already completed
  /// (due to the unique constraint on habit_id + completed_at).
  Future<HabitCompletion> completeHabit(String habitId, DateTime date) async {
    _requireAuth();

    try {
      final dateStr = date.toIso8601String().split('T').first;
      final response = await SupabaseService.client
          .from('habit_completions')
          .insert({
            'habit_id': habitId,
            'user_id': _currentUserId!,
            'completed_at': dateStr,
          })
          .select()
          .single();

      return HabitCompletion.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique constraint violation - already completed
        throw HabitException('Habit already completed for this date');
      }
      throw HabitException('Failed to complete habit: ${e.message}');
    } catch (e) {
      throw HabitException('Failed to complete habit: ${e.toString()}');
    }
  }

  /// Remove a completion record for a habit on a specific date.
  Future<void> uncompleteHabit(String habitId, DateTime date) async {
    _requireAuth();

    try {
      final dateStr = date.toIso8601String().split('T').first;
      await SupabaseService.client
          .from('habit_completions')
          .delete()
          .eq('habit_id', habitId)
          .eq('user_id', _currentUserId!)
          .eq('completed_at', dateStr);
    } on PostgrestException catch (e) {
      throw HabitException('Failed to uncomplete habit: ${e.message}');
    } catch (e) {
      throw HabitException('Failed to uncomplete habit: ${e.toString()}');
    }
  }

  /// Toggle completion status for a habit on a specific date.
  Future<bool> toggleCompletion(String habitId, DateTime date) async {
    final completed = await isCompleted(habitId, date);
    if (completed) {
      await uncompleteHabit(habitId, date);
      return false;
    } else {
      await completeHabit(habitId, date);
      return true;
    }
  }

  /// Fetch all completions for a habit within a date range.
  Future<List<HabitCompletion>> getCompletionsForHabit(
    String habitId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _requireAuth();

    try {
      var query = SupabaseService.client
          .from('habit_completions')
          .select()
          .eq('habit_id', habitId)
          .eq('user_id', _currentUserId!);

      if (startDate != null) {
        final startStr = startDate.toIso8601String().split('T').first;
        query = query.gte('completed_at', startStr);
      }
      if (endDate != null) {
        final endStr = endDate.toIso8601String().split('T').first;
        query = query.lte('completed_at', endStr);
      }

      final response = await query.order('completed_at', ascending: true);

      return (response as List)
          .map((e) => HabitCompletion.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } on PostgrestException catch (e) {
      throw HabitException('Failed to fetch completions: ${e.message}');
    } catch (e) {
      throw HabitException('Failed to fetch completions: ${e.toString()}');
    }
  }

  /// Fetch all completions for the current user within a date range.
  Future<List<HabitCompletion>> getAllCompletions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _requireAuth();

    try {
      var query = SupabaseService.client
          .from('habit_completions')
          .select()
          .eq('user_id', _currentUserId!);

      if (startDate != null) {
        final startStr = startDate.toIso8601String().split('T').first;
        query = query.gte('completed_at', startStr);
      }
      if (endDate != null) {
        final endStr = endDate.toIso8601String().split('T').first;
        query = query.lte('completed_at', endStr);
      }

      final response = await query.order('completed_at', ascending: true);

      return (response as List)
          .map((e) => HabitCompletion.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } on PostgrestException catch (e) {
      throw HabitException('Failed to fetch completions: ${e.message}');
    } catch (e) {
      throw HabitException('Failed to fetch completions: ${e.toString()}');
    }
  }

  // =========================================================================
  // Streak and Summary Calculations
  // =========================================================================

  /// Calculate the current streak for a habit.
  ///
  /// A streak is the number of consecutive days (including today if completed)
  /// going backwards from the most recent completion date.
  Future<int> calculateStreak(String habitId) async {
    _requireAuth();

    try {
      final completions = await getCompletionsForHabit(habitId);
      if (completions.isEmpty) return 0;

      // Sort by date descending
      completions.sort((a, b) => b.completedAt.compareTo(a.completedAt));

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      int streak = 0;
      DateTime expectedDate = todayDate;

      // Check if completed today
      final completedToday = completions.any((c) =>
          c.completedAt.year == todayDate.year &&
          c.completedAt.month == todayDate.month &&
          c.completedAt.day == todayDate.day);

      if (!completedToday) {
        // If not completed today, check yesterday
        expectedDate = todayDate.subtract(const Duration(days: 1));
      }

      for (final completion in completions) {
        final compDate = DateTime(
          completion.completedAt.year,
          completion.completedAt.month,
          completion.completedAt.day,
        );

        if (compDate == expectedDate) {
          streak++;
          expectedDate = expectedDate.subtract(const Duration(days: 1));
        } else if (compDate.isBefore(expectedDate)) {
          // Gap in streak
          break;
        }
        // If compDate is after expectedDate, it's a future date (shouldn't happen)
        // or we already counted it, so skip
      }

      return streak;
    } on HabitException {
      rethrow;
    } catch (e) {
      throw HabitException('Failed to calculate streak: ${e.toString()}');
    }
  }

  /// Calculate the longest streak for a habit.
  Future<int> calculateLongestStreak(String habitId) async {
    _requireAuth();

    try {
      final completions = await getCompletionsForHabit(habitId);
      if (completions.isEmpty) return 0;

      // Sort by date ascending
      completions.sort((a, b) => a.completedAt.compareTo(b.completedAt));

      int longestStreak = 1;
      int currentStreak = 1;

      for (int i = 1; i < completions.length; i++) {
        final prev = completions[i - 1].completedAt;
        final curr = completions[i].completedAt;

        final prevDate = DateTime(prev.year, prev.month, prev.day);
        final currDate = DateTime(curr.year, curr.month, curr.day);

        if (currDate.difference(prevDate).inDays == 1) {
          currentStreak++;
          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }
        } else {
          currentStreak = 1;
        }
      }

      return longestStreak;
    } on HabitException {
      rethrow;
    } catch (e) {
      throw HabitException('Failed to calculate longest streak: ${e.toString()}');
    }
  }

  /// Get completion count for a habit in the last 7 days (weekly summary).
  Future<int> getWeeklyCompletionCount(String habitId) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 6)); // Last 7 days including today

    final completions = await getCompletionsForHabit(
      habitId,
      startDate: startDate,
      endDate: endDate,
    );

    return completions.length;
  }

  /// Get completion count for a habit in the last 30 days (monthly summary).
  Future<int> getMonthlyCompletionCount(String habitId) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 29)); // Last 30 days including today

    final completions = await getCompletionsForHabit(
      habitId,
      startDate: startDate,
      endDate: endDate,
    );

    return completions.length;
  }

  /// Get today's completion status for all active habits.
  Future<Map<String, bool>> getTodaysCompletionStatus() async {
    _requireAuth();

    try {
      final habits = await getHabits(includeArchived: false);
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T').first;

      final response = await SupabaseService.client
          .from('habit_completions')
          .select('habit_id')
          .eq('user_id', _currentUserId!)
          .eq('completed_at', todayStr);

      final completedHabitIds = (response as List)
          .map((e) => e['habit_id'] as String)
          .toSet();

      return {
        for (final habit in habits) habit.id: completedHabitIds.contains(habit.id)
      };
    } on PostgrestException catch (e) {
      throw HabitException('Failed to fetch today\'s status: ${e.message}');
    } catch (e) {
      throw HabitException('Failed to fetch today\'s status: ${e.toString()}');
    }
  }
}

/// Custom exception for habit operations with user-friendly messages.
class HabitException implements Exception {
  final String message;

  const HabitException(this.message);

  @override
  String toString() => 'HabitException: $message';
}