import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/gamification_service.dart';
import 'package:synvero/core/services/supabase_service.dart';

/// Leaderboard member model representing a real registered HabitNova user.
class LeaderboardEntry {
  final String id;
  final String username;
  final String avatarPath;
  final int xp;
  final int streakDays;
  final String badgeTitle;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.id,
    required this.username,
    required this.avatarPath,
    required this.xp,
    required this.streakDays,
    required this.badgeTitle,
    this.isCurrentUser = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatarPath': avatarPath,
    'xp': xp,
    'streakDays': streakDays,
    'badgeTitle': badgeTitle,
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final entryId = json['id'] as String? ?? '';
    return LeaderboardEntry(
      id: entryId,
      username: json['username'] as String? ?? 'User',
      avatarPath: json['avatarPath'] as String? ?? 'assets/images/avatar_m1.png',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 1,
      badgeTitle: json['badgeTitle'] as String? ?? 'Novice 🌱',
      isCurrentUser: currentUserId != null && (entryId == currentUserId),
    );
  }
}

/// Service managing the HabitNova Community Leaderboard with 100% REAL users only.
/// Synchronizes across all devices via Firestore REST API with local offline caching.
class LeaderboardService {
  static const String _prefKeyRegistry = 'synvero_registered_real_users_v3';
  static const String _prefKeyLastShared = 'synvero_leaderboard_last_shared';

  static const String _firestoreBaseUrl =
      'https://firestore.googleapis.com/v1/projects/taskflow-c57d8/databases/(default)/documents/community_leaderboard';
  static const String _firestoreApiKey = 'AIzaSyBMPwBRrvllX1AOEAwczp0Xo6fGwg7hr6c';

  /// Seed initial real registered friends so everyone sees each other immediately.
  static final List<LeaderboardEntry> _baselineSeed = [
    const LeaderboardEntry(
      id: 'yogeshh',
      username: 'Yogeshh',
      avatarPath: 'assets/images/avatar_m1.png',
      xp: 2500,
      streakDays: 5,
      badgeTitle: 'Habit Pro 👑',
    ),
    const LeaderboardEntry(
      id: 'aditya',
      username: 'Aditya',
      avatarPath: 'assets/images/avatar_m1.png',
      xp: 215,
      streakDays: 2,
      badgeTitle: 'Apprentice ⚡',
    ),
    const LeaderboardEntry(
      id: 'sam',
      username: 'sam',
      avatarPath: 'assets/images/avatar_m1.png',
      xp: 150,
      streakDays: 1,
      badgeTitle: 'Novice 🌱',
    ),
  ];

  /// Resolves a clean, deterministic user ID.
  static String resolveUserId({String? username}) {
    final sbUser = SupabaseService.user;
    if (sbUser != null && sbUser.id.isNotEmpty) {
      return sbUser.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    }
    final name = (username != null && username.isNotEmpty) ? username : 'user';
    return name.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  /// Fetches real community members from the cloud and persistent registry.
  static Future<List<LeaderboardEntry>> getLeaderboard({
    required String currentUsername,
    required String currentAvatar,
    required int currentXP,
    required int currentStreak,
  }) async {
    final currentUserId = resolveUserId(username: currentUsername);
    final effectiveUsername = currentUsername.isNotEmpty ? currentUsername : 'Yogeshh';
    final levelInfo = GamificationService.getLevelInfo(currentXP);
    final badgeTitle = '${levelInfo.title} ${levelInfo.badgeEmoji}';

    final Map<String, LeaderboardEntry> usersMap = {};

    // 1. Seed baseline real registered users
    for (final seed in _baselineSeed) {
      usersMap[seed.id] = seed;
    }

    // 2. Load cached entries from local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawRegistry = prefs.getString(_prefKeyRegistry);
      if (rawRegistry != null && rawRegistry.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawRegistry);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final entry = LeaderboardEntry.fromJson(item, currentUserId: currentUserId);
            if (!entry.id.startsWith('dummy_') &&
                !entry.username.contains('Aarav') &&
                !entry.username.contains('Priya Patel')) {
              usersMap[entry.id] = entry;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('LeaderboardService cache load error: $e');
    }

    // 3. Upsert current live user stats
    usersMap[currentUserId] = LeaderboardEntry(
      id: currentUserId,
      username: effectiveUsername,
      avatarPath: currentAvatar,
      xp: currentXP,
      streakDays: currentStreak,
      badgeTitle: badgeTitle,
      isCurrentUser: true,
    );

    // 4. Try fetching latest cloud leaderboard entries from Firestore
    try {
      final response = await http
          .get(
            Uri.parse('$_firestoreBaseUrl?key=$_firestoreApiKey'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final documents = data['documents'] as List<dynamic>?;
        if (documents != null) {
          for (final doc in documents) {
            try {
              final fields = doc['fields'] as Map<String, dynamic>?;
              if (fields != null) {
                final id = fields['id']?['stringValue'] as String? ?? '';
                final uname = fields['username']?['stringValue'] as String? ?? 'User';
                final avatar = fields['avatarPath']?['stringValue'] as String? ?? 'assets/images/avatar_m1.png';
                final xp = int.tryParse(fields['xp']?['integerValue']?.toString() ?? '0') ?? 0;
                final streak = int.tryParse(fields['streakDays']?['integerValue']?.toString() ?? '1') ?? 1;
                final badge = fields['badgeTitle']?['stringValue'] as String? ?? 'Novice 🌱';

                if (id.isNotEmpty && !id.startsWith('dummy_')) {
                  usersMap[id] = LeaderboardEntry(
                    id: id,
                    username: uname,
                    avatarPath: avatar,
                    xp: xp,
                    streakDays: streak,
                    badgeTitle: badge,
                    isCurrentUser: id == currentUserId,
                  );
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('LeaderboardService cloud fetch error: $e');
    }

    // Re-verify current user in map
    usersMap[currentUserId] = LeaderboardEntry(
      id: currentUserId,
      username: effectiveUsername,
      avatarPath: currentAvatar,
      xp: currentXP,
      streakDays: currentStreak,
      badgeTitle: badgeTitle,
      isCurrentUser: true,
    );

    // 5. Persist latest registry to local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedList = usersMap.values.map((e) => e.toJson()).toList();
      await prefs.setString(_prefKeyRegistry, jsonEncode(encodedList));
    } catch (_) {}

    // 6. Push current user's live progress to cloud in background
    _syncUserToCloud(
      id: currentUserId,
      username: effectiveUsername,
      avatarPath: currentAvatar,
      xp: currentXP,
      streakDays: currentStreak,
      badgeTitle: badgeTitle,
    );

    // Convert map to list and sort descending by XP
    final List<LeaderboardEntry> list = usersMap.values.toList();
    list.sort((a, b) => b.xp.compareTo(a.xp));
    return list;
  }

  /// Pushes user's stats to Firestore community_leaderboard
  static Future<void> _syncUserToCloud({
    required String id,
    required String username,
    required String avatarPath,
    required int xp,
    required int streakDays,
    required String badgeTitle,
  }) async {
    try {
      final url = '$_firestoreBaseUrl/$id?key=$_firestoreApiKey';
      final body = jsonEncode({
        'fields': {
          'id': {'stringValue': id},
          'username': {'stringValue': username},
          'avatarPath': {'stringValue': avatarPath},
          'xp': {'integerValue': xp.toString()},
          'streakDays': {'integerValue': streakDays.toString()},
          'badgeTitle': {'stringValue': badgeTitle},
          'updatedAt': {'stringValue': DateTime.now().toIso8601String()},
        }
      });

      await http
          .patch(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('LeaderboardService _syncUserToCloud error: $e');
    }
  }

  /// Publishes user's latest progress to the HabitNova community leaderboard.
  /// Awards +25 XP bonus for participating!
  static Future<bool> publishUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLastShared, DateTime.now().toIso8601String());

      // Award community sharing bonus
      await GamificationService.addXP(25, reason: 'Shared Progress to Leaderboard');
      await GamificationService.unlockBadge('streak_warrior');

      // Fetch latest stats and immediately sync to cloud
      final currentUsername = prefs.getString('user_name') ?? 'Yogeshh';
      final totalXP = GamificationService.totalXPNotifier.value;
      final streak = prefs.getInt('app_streak_days') ?? 1;
      final avatar = prefs.getString('user_avatar') ?? 'assets/images/avatar_m1.png';
      final currentUserId = resolveUserId(username: currentUsername);
      final levelInfo = GamificationService.getLevelInfo(totalXP);
      final badgeTitle = '${levelInfo.title} ${levelInfo.badgeEmoji}';

      await _syncUserToCloud(
        id: currentUserId,
        username: currentUsername,
        avatarPath: avatar,
        xp: totalXP,
        streakDays: streak,
        badgeTitle: badgeTitle,
      );

      return true;
    } catch (e) {
      debugPrint('LeaderboardService.publishUserProgress error: $e');
      return false;
    }
  }
}
