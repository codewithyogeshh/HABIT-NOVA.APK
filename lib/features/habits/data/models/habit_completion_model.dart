/// Represents a daily completion record for a habit.
///
/// Mirrors the `habit_completions` table in Supabase with Row Level Security (RLS).
/// The unique constraint on (habit_id, completed_at) prevents duplicate completions
/// for the same habit on the same date.
class HabitCompletion {
  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completedAt,
    required this.createdAt,
  });

  /// Unique completion record identifier (UUID from Supabase).
  final String id;

  /// References habits(id).
  final String habitId;

  /// Owner of the completion — references auth.users(id).
  final String userId;

  /// Local calendar date the habit was completed (no time component).
  final DateTime completedAt;

  /// When the completion record was created.
  final DateTime createdAt;

  /// Create a [HabitCompletion] from a Supabase row map.
  factory HabitCompletion.fromMap(Map<String, dynamic> map) {
    return HabitCompletion(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      userId: map['user_id'] as String,
      completedAt: DateTime.parse(map['completed_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert this [HabitCompletion] to a Supabase row map for insert.
  Map<String, dynamic> toMap() {
    return {
      'habit_id': habitId,
      'user_id': userId,
      'completed_at': completedAt.toIso8601String().split('T').first,
    };
  }

  /// Create a copy of this completion with the given fields replaced.
  HabitCompletion copyWith({
    String? id,
    String? habitId,
    String? userId,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return HabitCompletion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}