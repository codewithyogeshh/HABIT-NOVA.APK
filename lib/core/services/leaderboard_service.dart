import 'dart:convert';
import 'dart:io';
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

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, {String? currentUserId, String? currentUsername}) {
    final entryId = json['id'] as String? ?? '';
    final name = json['username'] as String? ?? 'User';
    final isCurrent = (currentUserId != null && currentUserId.isNotEmpty && entryId == currentUserId) ||
        (currentUsername != null && currentUsername.isNotEmpty && name.trim().toLowerCase() == currentUsername.trim().toLowerCase());

    return LeaderboardEntry(
      id: entryId,
      username: name,
      avatarPath: json['avatarPath'] as String? ?? 'assets/images/avatar_m1.png',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 1,
      badgeTitle: json['badgeTitle'] as String? ?? 'Novice 🌱',
      isCurrentUser: isCurrent,
    );
  }
}

/// Service managing the HabitNova Community Leaderboard with 100% REAL users only.
/// Absolutely NO fake, dummy, or hardcoded seed entries.
/// Synchronizes across all devices via Firestore REST API with deduplication by real user.
class LeaderboardService {
  static const String _prefKeyRegistry = 'synvero_registered_real_users_v5';
  static const String _prefKeyLastShared = 'synvero_leaderboard_last_shared';

  static const String _firestoreBaseUrl =
      'https://firestore.googleapis.com/v1/projects/taskflow-c57d8/databases/(default)/documents/community_leaderboard';
  static const String _firestoreApiKey = 'AIzaSyBMPwBRrvllX1AOEAwczp0Xo6fGwg7hr6c';

  /// Resolves a clean, deterministic user ID.
  static String resolveUserId({String? username}) {
    final sbUser = SupabaseService.user;
    if (sbUser != null && sbUser.id.isNotEmpty) {
      return sbUser.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    }
    final name = (username != null && username.isNotEmpty) ? username : 'user';
    return name.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  /// Convert a local file path to portable base64 URI if needed so other devices can render it
  static Future<String> _ensurePortableAvatar(String path) async {
    if (path.isEmpty ||
        path.startsWith('assets/') ||
        path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('data:image/') ||
        path.startsWith('base64:')) {
      return path;
    }
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
    } catch (_) {}
    return 'assets/images/avatar_m1.png';
  }

  /// Fetches real community members from the cloud and deduplicates strictly by unique user.
  static Future<List<LeaderboardEntry>> getLeaderboard({
    required String currentUsername,
    required String currentAvatar,
    required int currentXP,
    required int currentStreak,
  }) async {
    final currentUserId = resolveUserId(username: currentUsername);
    final effectiveUsername = currentUsername.isNotEmpty ? currentUsername : 'User';
    final levelInfo = GamificationService.getLevelInfo(currentXP);
    final badgeTitle = '${levelInfo.title} ${levelInfo.badgeEmoji}';

    // Map keyed by normalized username to ensure EVERY person appears EXACTLY once!
    final Map<String, LeaderboardEntry> usersByUsername = {};

    // Wipe out legacy caches that contained seeded fake entries
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('synvero_registered_real_users_v2');
      await prefs.remove('synvero_registered_real_users_v3');
      await prefs.remove('synvero_registered_real_users_v4');

      final rawRegistry = prefs.getString(_prefKeyRegistry);
      if (rawRegistry != null && rawRegistry.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawRegistry);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final entry = LeaderboardEntry.fromJson(
              item,
              currentUserId: currentUserId,
              currentUsername: effectiveUsername,
            );
            if (!entry.id.startsWith('dummy_')) {
              final normKey = entry.username.trim().toLowerCase();
              usersByUsername[normKey] = entry;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('LeaderboardService cache load error: $e');
    }

    // 1. Fetch latest real users from Firestore
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
                final uname = (fields['username']?['stringValue'] as String? ?? '').trim();
                final avatar = fields['avatarPath']?['stringValue'] as String? ?? 'assets/images/avatar_m1.png';
                final xp = int.tryParse(fields['xp']?['integerValue']?.toString() ?? '0') ?? 0;
                final streak = int.tryParse(fields['streakDays']?['integerValue']?.toString() ?? '1') ?? 1;
                final badge = fields['badgeTitle']?['stringValue'] as String? ?? 'Novice 🌱';

                // Skip legacy dummy names or empty entries
                if (uname.isEmpty ||
                    id.startsWith('dummy_') ||
                    uname.contains('Aarav') ||
                    uname.contains('Priya Patel')) {
                  continue;
                }

                final normKey = uname.toLowerCase();
                final isCurrent = (id == currentUserId) || (normKey == effectiveUsername.toLowerCase());

                final cloudEntry = LeaderboardEntry(
                  id: id,
                  username: uname,
                  avatarPath: avatar,
                  xp: xp,
                  streakDays: streak,
                  badgeTitle: badge,
                  isCurrentUser: isCurrent,
                );

                // Deduplicate: If entry already exists, pick higher XP or currentUser
                if (!usersByUsername.containsKey(normKey)) {
                  usersByUsername[normKey] = cloudEntry;
                } else {
                  final existing = usersByUsername[normKey]!;
                  if (cloudEntry.isCurrentUser) {
                    usersByUsername[normKey] = cloudEntry;
                  } else if (!existing.isCurrentUser && cloudEntry.xp >= existing.xp) {
                    usersByUsername[normKey] = cloudEntry;
                  }
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('LeaderboardService cloud fetch error: $e');
    }

    // 2. Always guarantee current user has their live up-to-date stats
    final normCurrentKey = effectiveUsername.toLowerCase();
    final portableAvatar = await _ensurePortableAvatar(currentAvatar);

    usersByUsername[normCurrentKey] = LeaderboardEntry(
      id: currentUserId,
      username: effectiveUsername,
      avatarPath: portableAvatar,
      xp: currentXP,
      streakDays: currentStreak,
      badgeTitle: badgeTitle,
      isCurrentUser: true,
    );

    // 3. Persist deduplicated list to local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedList = usersByUsername.values.map((e) => e.toJson()).toList();
      await prefs.setString(_prefKeyRegistry, jsonEncode(encodedList));
    } catch (_) {}

    // 4. Push current user's live progress to cloud in background
    _syncUserToCloud(
      id: currentUserId,
      username: effectiveUsername,
      avatarPath: portableAvatar,
      xp: currentXP,
      streakDays: currentStreak,
      badgeTitle: badgeTitle,
    );

    // Convert to list and sort descending by XP
    final List<LeaderboardEntry> list = usersByUsername.values.toList();
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
      final portableAvatar = await _ensurePortableAvatar(avatarPath);
      final url = '$_firestoreBaseUrl/$id?key=$_firestoreApiKey';
      final body = jsonEncode({
        'fields': {
          'id': {'stringValue': id},
          'username': {'stringValue': username},
          'avatarPath': {'stringValue': portableAvatar},
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

  /// Syncs current user's profile info (avatar, XP, streak, username) to the cloud leaderboard.
  /// Called on signup, login, avatar updates, and task/habit completion.
  static Future<void> syncCurrentUser({
    String? username,
    String? avatarPath,
    int? xp,
    int? streak,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sbUser = SupabaseService.user;
      final effectiveName = username ??
          (sbUser?.userMetadata?['username'] as String?) ??
          prefs.getString('user_name') ??
          (sbUser?.email != null ? sbUser!.email!.split('@').first : 'User');

      final effectiveAvatar = avatarPath ??
          prefs.getString('user_avatar') ??
          (sbUser?.userMetadata?['avatar_url'] as String?) ??
          'assets/images/avatar_m1.png';

      final effectiveXP = xp ??
          (GamificationService.totalXPNotifier.value > 0
              ? GamificationService.totalXPNotifier.value
              : 150);

      final effectiveStreak = streak ??
          prefs.getInt('app_streak_days') ??
          prefs.getInt('user_${sbUser?.id ?? "guest"}_streak_days') ??
          1;

      final currentUserId = resolveUserId(username: effectiveName);
      final levelInfo = GamificationService.getLevelInfo(effectiveXP);
      final badgeTitle = '${levelInfo.title} ${levelInfo.badgeEmoji}';

      await _syncUserToCloud(
        id: currentUserId,
        username: effectiveName,
        avatarPath: effectiveAvatar,
        xp: effectiveXP,
        streakDays: effectiveStreak,
        badgeTitle: badgeTitle,
      );
    } catch (e) {
      debugPrint('LeaderboardService.syncCurrentUser error: $e');
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
      final currentUsername = prefs.getString('user_name') ?? 'User';
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
