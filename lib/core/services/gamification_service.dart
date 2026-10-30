import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/supabase_service.dart';

/// Represents a gamification achievement badge in HabbitNova.
class HabbitBadge {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final int requiredCount;
  final Color glowColor;
  final Color cardBorderColor;
  final String category; // 'streak', 'habits', 'focus', 'water', 'tasks'

  const HabbitBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.requiredCount,
    required this.glowColor,
    required this.cardBorderColor,
    required this.category,
  });
}

/// Represents the user's current level info.
class UserLevelInfo {
  final int level;
  final String title;
  final int currentXP;
  final int levelBaseXP;
  final int nextLevelXP;
  final double progress; // 0.0 to 1.0
  final String badgeEmoji;
  final Color levelColor;

  const UserLevelInfo({
    required this.level,
    required this.title,
    required this.currentXP,
    required this.levelBaseXP,
    required this.nextLevelXP,
    required this.progress,
    required this.badgeEmoji,
    required this.levelColor,
  });
}

/// Core Gamification Service managing XP, Levels, and Badges per user account.
class GamificationService {
  static const int xpPerHabit = 50;
  static const int xpPerTask = 30;
  static const int xpPerStudyTimer = 100;
  static const int xpPerWaterGoal = 40;

  static final ValueNotifier<int> totalXPNotifier = ValueNotifier<int>(0);

  static String _xpKey(String userId) => 'user_${userId}_gamification_xp_v1';
  static String _unlockedBadgesKey(String userId) => 'user_${userId}_unlocked_badges_v1';

  static String get _currentUserId => SupabaseService.user?.id ?? 'guest';

  /// All available badges in HabbitNova
  static const List<HabbitBadge> allBadges = [
    HabbitBadge(
      id: 'first_step',
      title: 'First Step',
      description: 'Complete your very first habit in HabbitNova',
      iconEmoji: '🌱',
      requiredCount: 1,
      glowColor: Color(0xFF10B981),
      cardBorderColor: Color(0xFF059669),
      category: 'habits',
    ),
    HabbitBadge(
      id: 'hydration_hero',
      title: 'Hydration Hero',
      description: 'Drink all 8 glasses of water in a day',
      iconEmoji: '💧',
      requiredCount: 8,
      glowColor: Color(0xFF00F0FF),
      cardBorderColor: Color(0xFF0284C7),
      category: 'water',
    ),
    HabbitBadge(
      id: 'task_crusher',
      title: 'Task Crusher',
      description: 'Conquer all daily to-dos and scheduled tasks',
      iconEmoji: '⚡',
      requiredCount: 4,
      glowColor: Color(0xFFF59E0B),
      cardBorderColor: Color(0xFFD97706),
      category: 'tasks',
    ),
    HabbitBadge(
      id: 'focus_titan',
      title: 'Focus Titan',
      description: 'Complete 3+ deep work Pomodoro focus sessions',
      iconEmoji: '⏱️',
      requiredCount: 3,
      glowColor: Color(0xFF8B5CF6),
      cardBorderColor: Color(0xFF7C3AED),
      category: 'focus',
    ),
    HabbitBadge(
      id: 'early_bird',
      title: 'Early Bird',
      description: 'Check off a morning habit before 8:00 AM',
      iconEmoji: '🌅',
      requiredCount: 1,
      glowColor: Color(0xFFF97316),
      cardBorderColor: Color(0xFFEA580C),
      category: 'habits',
    ),
    HabbitBadge(
      id: 'streak_warrior_7',
      title: '7-Day Warrior',
      description: 'Build an unbroken 7-day habit streak',
      iconEmoji: '🔥',
      requiredCount: 7,
      glowColor: Color(0xFFEF4444),
      cardBorderColor: Color(0xFFDC2626),
      category: 'streak',
    ),
    HabbitBadge(
      id: 'streak_legend_30',
      title: 'Habit Legend',
      description: 'Achieve an elite 30-day streak of mastery',
      iconEmoji: '👑',
      requiredCount: 30,
      glowColor: Color(0xFFA855F7),
      cardBorderColor: Color(0xFF9333EA),
      category: 'streak',
    ),
    HabbitBadge(
      id: 'nova_grandmaster',
      title: 'Nova Grandmaster',
      description: 'Reach Level 10 and enter the top 1% discipline tier',
      iconEmoji: '🌌',
      requiredCount: 10,
      glowColor: Color(0xFFEC4899),
      cardBorderColor: Color(0xFFDB2777),
      category: 'streak',
    ),
  ];

  /// Level tier brackets
  static const List<Map<String, dynamic>> _levelTiers = [
    {'level': 1, 'title': 'Novice', 'minXP': 0, 'maxXP': 200, 'emoji': '🌱', 'color': Color(0xFF10B981)},
    {'level': 2, 'title': 'Apprentice', 'minXP': 200, 'maxXP': 500, 'emoji': '⚡', 'color': Color(0xFF00F0FF)},
    {'level': 3, 'title': 'Momentum Builder', 'minXP': 500, 'maxXP': 1000, 'emoji': '💎', 'color': Color(0xFF3B82F6)},
    {'level': 4, 'title': 'Discipline Warrior', 'minXP': 1000, 'maxXP': 2000, 'emoji': '🛡️', 'color': Color(0xFF8B5CF6)},
    {'level': 5, 'title': 'Habit Pro', 'minXP': 2000, 'maxXP': 3500, 'emoji': '🔥', 'color': Color(0xFFF59E0B)},
    {'level': 6, 'title': 'Master Achiever', 'minXP': 3500, 'maxXP': 5500, 'emoji': '🌟', 'color': Color(0xFFF97316)},
    {'level': 7, 'title': 'Focus Titan', 'minXP': 5500, 'maxXP': 8000, 'emoji': '⚔️', 'color': Color(0xFFEF4444)},
    {'level': 8, 'title': 'Zen Master', 'minXP': 8000, 'maxXP': 12000, 'emoji': '🧘', 'color': Color(0xFF06B6D4)},
    {'level': 9, 'title': 'Apex Conqueror', 'minXP': 12000, 'maxXP': 18000, 'emoji': '👑', 'color': Color(0xFFA855F7)},
    {'level': 10, 'title': 'Nova Grandmaster', 'minXP': 18000, 'maxXP': 999999, 'emoji': '🌌', 'color': Color(0xFFEC4899)},
  ];

  /// Loads the total XP for the current user
  static Future<int> loadXP({String? userId}) async {
    final uid = userId ?? _currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final xp = prefs.getInt(_xpKey(uid)) ?? 150; // Starter XP
      totalXPNotifier.value = xp;
      return xp;
    } catch (_) {
      return 150;
    }
  }

  /// Adds XP for completing an action and returns if a Level Up occurred
  static Future<bool> addXP(int amount, {String? userId, required String reason}) async {
    final uid = userId ?? _currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentXP = prefs.getInt(_xpKey(uid)) ?? 150;
      final oldLevel = getLevelInfo(currentXP).level;

      final newXP = currentXP + amount;
      await prefs.setInt(_xpKey(uid), newXP);
      totalXPNotifier.value = newXP;

      final newLevel = getLevelInfo(newXP).level;
      final leveledUp = newLevel > oldLevel;

      if (leveledUp && newLevel >= 10) {
        await unlockBadge('nova_grandmaster', userId: uid);
      }

      return leveledUp;
    } catch (e) {
      debugPrint('GamificationService.addXP error: $e');
      return false;
    }
  }

  /// Calculates UserLevelInfo based on total XP
  static UserLevelInfo getLevelInfo(int xp) {
    for (final tier in _levelTiers) {
      final min = tier['minXP'] as int;
      final max = tier['maxXP'] as int;
      if (xp >= min && xp < max) {
        final currentInLevel = xp - min;
        final span = max - min;
        final progress = (currentInLevel / span).clamp(0.0, 1.0);
        return UserLevelInfo(
          level: tier['level'] as int,
          title: tier['title'] as String,
          currentXP: xp,
          levelBaseXP: min,
          nextLevelXP: max,
          progress: progress,
          badgeEmoji: tier['emoji'] as String,
          levelColor: tier['color'] as Color,
        );
      }
    }
    // Level 10 max
    final maxTier = _levelTiers.last;
    return UserLevelInfo(
      level: 10,
      title: 'Nova Grandmaster',
      currentXP: xp,
      levelBaseXP: 18000,
      nextLevelXP: 18000,
      progress: 1.0,
      badgeEmoji: '🌌',
      levelColor: maxTier['color'] as Color,
    );
  }

  /// Get list of unlocked badge IDs for the user
  static Future<Set<String>> getUnlockedBadgeIds({String? userId}) async {
    final uid = userId ?? _currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_unlockedBadgesKey(uid));
      if (list != null) {
        return list.toSet();
      }
    } catch (_) {}
    return {'first_step'}; // Starter unlocked
  }

  /// Unlocks a badge for the user
  static Future<bool> unlockBadge(String badgeId, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_unlockedBadgesKey(uid)) ?? ['first_step'];
      if (!current.contains(badgeId)) {
        current.add(badgeId);
        await prefs.setStringList(_unlockedBadgesKey(uid), current);
        return true; // Newly unlocked
      }
    } catch (_) {}
    return false;
  }

  /// Checks and automatically awards badges based on live user state
  static Future<List<HabbitBadge>> checkAndAwardBadges({
    required int streakDays,
    required int habitsCompletedToday,
    required int waterGlassesToday,
    required int studySessionsToday,
    required int tasksDoneToday,
  }) async {
    final newlyUnlocked = <HabbitBadge>[];

    if (habitsCompletedToday >= 1) {
      if (await unlockBadge('first_step')) {
        newlyUnlocked.add(allBadges.firstWhere((b) => b.id == 'first_step'));
      }
    }
    if (waterGlassesToday >= 8) {
      if (await unlockBadge('hydration_hero')) {
        newlyUnlocked.add(allBadges.firstWhere((b) => b.id == 'hydration_hero'));
      }
    }
    if (tasksDoneToday >= 4) {
      if (await unlockBadge('task_crusher')) {
        newlyUnlocked.add(allBadges.firstWhere((b) => b.id == 'task_crusher'));
      }
    }
    if (studySessionsToday >= 3) {
      if (await unlockBadge('focus_titan')) {
        newlyUnlocked.add(allBadges.firstWhere((b) => b.id == 'focus_titan'));
      }
    }
    if (streakDays >= 7) {
      if (await unlockBadge('streak_warrior_7')) {
        newlyUnlocked.add(allBadges.firstWhere((b) => b.id == 'streak_warrior_7'));
      }
    }
    if (streakDays >= 30) {
      if (await unlockBadge('streak_legend_30')) {
        newlyUnlocked.add(allBadges.firstWhere((b) => b.id == 'streak_legend_30'));
      }
    }

    final now = DateTime.now();
    if (now.hour < 8 && habitsCompletedToday >= 1) {
      if (await unlockBadge('early_bird')) {
        newlyUnlocked.add(allBadges.firstWhere((b) => b.id == 'early_bird'));
      }
    }

    return newlyUnlocked;
  }
}
