import 'package:flutter/material.dart';

/// Represents a user-defined habit.
///
/// Mirrors the `habits` table in Supabase with Row Level Security (RLS).
class Habit {
  const Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.color,
    this.icon,
    this.archived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique habit identifier (UUID from Supabase).
  final String id;

  /// Owner of the habit — references auth.users(id).
  final String userId;

  /// Habit display name.
  final String name;

  /// Optional habit description.
  final String? description;

  /// Hex color string for UI theming (e.g. '#4361EE').
  final String? color;

  /// Material icon name for UI theming (e.g. 'track_changes').
  final String? icon;

  /// Soft-delete flag — archived habits are hidden from the active view.
  final bool archived;

  /// When the habit was created.
  final DateTime createdAt;

  /// When the habit was last updated.
  final DateTime updatedAt;

  /// Create a [Habit] from a Supabase row map.
  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      archived: (map['archived'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert this [Habit] to a Supabase row map for insert/update.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'archived': archived,
    };
  }

  /// Create a copy of this habit with the given fields replaced.
  Habit copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? color,
    String? icon,
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Parse a hex color string (e.g. '#4361EE') into a [Color].
  Color get parsedColor {
    final hex = (color ?? '#4361EE').replaceFirst('#', '');
    return Color(0xFF000000 | int.parse(hex, radix: 16));
  }

  /// Resolve the icon data from the stored icon name.
  IconData get parsedIcon {
    switch (icon) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'book':
        return Icons.book;
      case 'water_drop':
        return Icons.water_drop;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'directions_run':
        return Icons.directions_run;
      case 'lunch_dining':
        return Icons.lunch_dining;
      case 'bedtime':
        return Icons.bedtime;
      case 'track_changes':
      default:
        return Icons.track_changes;
    }
  }
}