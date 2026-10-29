import 'package:flutter/material.dart';

/// Model representing a user's streak tier, badge, title, and visual styling.
class StreakBadge {
  final String title;
  final String emoji;
  final Color color;
  final Color glowColor;
  final String description;
  final int minDays;
  final int? nextMilestoneDays;

  const StreakBadge({
    required this.title,
    required this.emoji,
    required this.color,
    required this.glowColor,
    required this.description,
    required this.minDays,
    this.nextMilestoneDays,
  });
}

/// Service to calculate and provide streak ranks, milestones, and badges for HabbitNova users.
class StreakBadgeService {
  static StreakBadge getBadge(int streakDays) {
    if (streakDays >= 60) {
      return const StreakBadge(
        title: 'Nova Grandmaster',
        emoji: '🌌',
        color: Color(0xFFEC4899),
        glowColor: Color(0xFFF43F5E),
        description: 'Elite top 1% discipline tier. Unstoppable legend.',
        minDays: 60,
        nextMilestoneDays: null,
      );
    } else if (streakDays >= 30) {
      return const StreakBadge(
        title: 'Habit Legend',
        emoji: '👑',
        color: Color(0xFFA855F7),
        glowColor: Color(0xFF8B5CF6),
        description: '30+ days of unbreakable mastery!',
        minDays: 30,
        nextMilestoneDays: 60,
      );
    } else if (streakDays >= 14) {
      return const StreakBadge(
        title: 'Momentum Master',
        emoji: '💎',
        color: Color(0xFF00F0FF),
        glowColor: Color(0xFF0284C7),
        description: '2 weeks of pure daily focus & momentum.',
        minDays: 14,
        nextMilestoneDays: 30,
      );
    } else if (streakDays >= 7) {
      return const StreakBadge(
        title: '7-Day Champion',
        emoji: '🌟',
        color: Color(0xFF10B981),
        glowColor: Color(0xFF059669),
        description: '1 full week completed! You have built a solid foundation.',
        minDays: 7,
        nextMilestoneDays: 14,
      );
    } else if (streakDays >= 3) {
      return const StreakBadge(
        title: 'Habit Builder',
        emoji: '🔥',
        color: Color(0xFFF59E0B),
        glowColor: Color(0xFFD97706),
        description: '3+ days streak! Consistency is taking firm shape.',
        minDays: 3,
        nextMilestoneDays: 7,
      );
    } else if (streakDays >= 1) {
      return const StreakBadge(
        title: 'Active Starter',
        emoji: '⚡',
        color: Color(0xFF38BDF8),
        glowColor: Color(0xFF0284C7),
        description: 'You took action today! Keep the momentum alive.',
        minDays: 1,
        nextMilestoneDays: 3,
      );
    } else {
      return const StreakBadge(
        title: 'Novice Explorer',
        emoji: '🌱',
        color: Color(0xFF94A3B8),
        glowColor: Color(0xFF475569),
        description: 'Complete your first habit today to spark your streak!',
        minDays: 0,
        nextMilestoneDays: 1,
      );
    }
  }

  /// List of all tier ranks for the Rank Roadmap dialog
  static const List<StreakBadge> allTiers = [
    StreakBadge(
      title: 'Novice Explorer',
      emoji: '🌱',
      color: Color(0xFF94A3B8),
      glowColor: Color(0xFF475569),
      description: 'Day 0 • Begin your journey',
      minDays: 0,
      nextMilestoneDays: 1,
    ),
    StreakBadge(
      title: 'Active Starter',
      emoji: '⚡',
      color: Color(0xFF38BDF8),
      glowColor: Color(0xFF0284C7),
      description: 'Day 1 - 2 • First spark of discipline',
      minDays: 1,
      nextMilestoneDays: 3,
    ),
    StreakBadge(
      title: 'Habit Builder',
      emoji: '🔥',
      color: Color(0xFFF59E0B),
      glowColor: Color(0xFFD97706),
      description: 'Day 3 - 6 • Consistency taking shape',
      minDays: 3,
      nextMilestoneDays: 7,
    ),
    StreakBadge(
      title: '7-Day Champion',
      emoji: '🌟',
      color: Color(0xFF10B981),
      glowColor: Color(0xFF059669),
      description: 'Day 7 - 13 • 1 full week completed',
      minDays: 7,
      nextMilestoneDays: 14,
    ),
    StreakBadge(
      title: 'Momentum Master',
      emoji: '💎',
      color: Color(0xFF00F0FF),
      glowColor: Color(0xFF0284C7),
      description: 'Day 14 - 29 • Unstoppable habit routine',
      minDays: 14,
      nextMilestoneDays: 30,
    ),
    StreakBadge(
      title: 'Habit Legend',
      emoji: '👑',
      color: Color(0xFFA855F7),
      glowColor: Color(0xFF8B5CF6),
      description: 'Day 30 - 59 • 1 month of elite mastery',
      minDays: 30,
      nextMilestoneDays: 60,
    ),
    StreakBadge(
      title: 'Nova Grandmaster',
      emoji: '🌌',
      color: Color(0xFFEC4899),
      glowColor: Color(0xFFF43F5E),
      description: 'Day 60+ • Highest pinnacle of human discipline',
      minDays: 60,
      nextMilestoneDays: null,
    ),
  ];
}
