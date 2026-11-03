import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:synvero/core/services/gamification_service.dart';
import 'package:synvero/core/services/language_service.dart';
import 'package:synvero/core/services/leaderboard_service.dart';
import 'package:synvero/core/services/supabase_service.dart';

class SquadMember {
  final String id;
  final String name;
  final String avatar;
  final int streakDays;
  final int studyMinutesToday;
  final int screenTimeMinutesToday;
  final int completedHabitsCount;
  final int xp;
  final bool isLeader;
  final bool isMVP;
  final bool isSlacker;

  const SquadMember({
    required this.id,
    required this.name,
    required this.avatar,
    required this.streakDays,
    required this.studyMinutesToday,
    required this.screenTimeMinutesToday,
    required this.completedHabitsCount,
    this.xp = 0,
    this.isLeader = false,
    this.isMVP = false,
    this.isSlacker = false,
  });

  SquadMember copyWith({
    String? id,
    String? name,
    String? avatar,
    int? streakDays,
    int? studyMinutesToday,
    int? screenTimeMinutesToday,
    int? completedHabitsCount,
    int? xp,
    bool? isLeader,
    bool? isMVP,
    bool? isSlacker,
  }) {
    return SquadMember(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      streakDays: streakDays ?? this.streakDays,
      studyMinutesToday: studyMinutesToday ?? this.studyMinutesToday,
      screenTimeMinutesToday: screenTimeMinutesToday ?? this.screenTimeMinutesToday,
      completedHabitsCount: completedHabitsCount ?? this.completedHabitsCount,
      xp: xp ?? this.xp,
      isLeader: isLeader ?? this.isLeader,
      isMVP: isMVP ?? this.isMVP,
      isSlacker: isSlacker ?? this.isSlacker,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'streakDays': streakDays,
        'studyMinutesToday': studyMinutesToday,
        'screenTimeMinutesToday': screenTimeMinutesToday,
        'completedHabitsCount': completedHabitsCount,
        'xp': xp,
        'isLeader': isLeader,
        'isMVP': isMVP,
        'isSlacker': isSlacker,
      };

  factory SquadMember.fromJson(Map<String, dynamic> json) => SquadMember(
        id: json['id'] as String? ?? 'member-${Random().nextInt(9999)}',
        name: json['name'] as String? ?? 'User',
        avatar: json['avatar'] as String? ?? '🦁',
        streakDays: json['streakDays'] as int? ?? 1,
        studyMinutesToday: json['studyMinutesToday'] as int? ?? 0,
        screenTimeMinutesToday: json['screenTimeMinutesToday'] as int? ?? 0,
        completedHabitsCount: json['completedHabitsCount'] as int? ?? 0,
        xp: json['xp'] as int? ?? 0,
        isLeader: json['isLeader'] as bool? ?? false,
        isMVP: json['isMVP'] as bool? ?? false,
        isSlacker: json['isSlacker'] as bool? ?? false,
      );
}

class Squad {
  final String id;
  final String name;
  final String code;
  final String category;
  final String motto;
  final String leaderId;
  final String leaderName;
  final DateTime createdAt;
  final List<SquadMember> members;

  const Squad({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.motto,
    required this.leaderId,
    required this.leaderName,
    required this.createdAt,
    required this.members,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'category': category,
        'motto': motto,
        'leaderId': leaderId,
        'leaderName': leaderName,
        'createdAt': createdAt.toIso8601String(),
        'members': members.map((m) => m.toJson()).toList(),
      };

  factory Squad.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? [];
    return Squad(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      category: json['category'] as String? ?? 'General Focus',
      motto: json['motto'] as String? ?? 'Consistency breeds champions.',
      leaderId: json['leaderId'] as String? ?? '',
      leaderName: json['leaderName'] as String? ?? 'Captain',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      members: rawMembers
          .map((m) => SquadMember.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SquadService {
  static const String _kSquadsPrefKey = 'habit_nova_user_squads_v4';

  static const String _firestoreBaseUrl =
      'https://firestore.googleapis.com/v1/projects/taskflow-c57d8/databases/(default)/documents/community_leaderboard';
  static const String _firestoreApiKey = 'AIzaSyBMPwBRrvllX1AOEAwczp0Xo6fGwg7hr6c';

  /// Generates a clean 6-character squad code (e.g. "NOVA84" or "MPSC26")
  static String generateSquadCode([String prefix = 'NOVA']) {
    final random = Random();
    final cleanPrefix = prefix.replaceAll(RegExp(r'[^A-Z]'), '');
    final effectivePrefix = cleanPrefix.length >= 3 ? cleanPrefix.substring(0, 3) : 'NOVA';
    final num = random.nextInt(900) + 100;
    return '$effectivePrefix$num';
  }

  /// Calculates MVP and Slacker tags among squad members dynamically.
  static List<SquadMember> computeMemberBadges(List<SquadMember> members) {
    if (members.isEmpty) return members;
    if (members.length == 1) {
      return [members.first.copyWith(isMVP: true, isSlacker: false)];
    }

    int maxScore = -1;
    String mvpId = '';

    int worstScore = -999999;
    String slackerId = '';

    for (final m in members) {
      final score = (m.studyMinutesToday * 2) + (m.completedHabitsCount * 30) + m.streakDays;
      if (score > maxScore) {
        maxScore = score;
        mvpId = m.id;
      }

      final slackScore = (m.screenTimeMinutesToday * 3) - (m.studyMinutesToday * 2) - (m.completedHabitsCount * 40);
      if (slackScore > worstScore) {
        worstScore = slackScore;
        slackerId = m.id;
      }
    }

    return members.map((m) {
      final isMVP = m.id == mvpId;
      final isSlacker = !isMVP && (m.id == slackerId);
      return m.copyWith(isMVP: isMVP, isSlacker: isSlacker);
    }).toList();
  }

  /// Resolves the current logged in user's live profile & stats.
  static Future<SquadMember> _resolveCurrentUserMember({bool isLeader = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final sbUser = SupabaseService.user;

    final currentUserId = LeaderboardService.resolveUserId(
      username: prefs.getString('user_name'),
    );

    final currentUserName = prefs.getString('user_name') ??
        (sbUser?.userMetadata?['username'] as String?) ??
        (sbUser?.email != null ? sbUser!.email!.split('@').first : 'User');

    final avatar = prefs.getString('user_avatar') ?? 'assets/images/avatar_m1.png';
    final streak = prefs.getInt('app_streak_days') ??
        prefs.getInt('user_${sbUser?.id ?? "guest"}_streak_days') ??
        1;

    final xp = GamificationService.totalXPNotifier.value > 0
        ? GamificationService.totalXPNotifier.value
        : 150;

    // Load today's live study minutes
    final studyMinutes = prefs.getInt('today_study_minutes') ??
        prefs.getInt('focus_timer_minutes_today') ??
        0;

    // Load today's screen time minutes (from usage stats if available)
    final screenTimeMinutes = prefs.getInt('today_screen_time_minutes') ?? 0;

    // Count today's completed habits
    int completedHabits = 0;
    for (int i = 1; i <= 5; i++) {
      final isDone = prefs.getBool('flutter.user_${sbUser?.id ?? "guest"}_habit_def-${i}_completed') ??
          prefs.getBool('user_${sbUser?.id ?? "guest"}_habit_def-${i}_completed') ??
          false;
      if (isDone) completedHabits++;
    }

    return SquadMember(
      id: currentUserId,
      name: currentUserName,
      avatar: avatar,
      streakDays: streak,
      studyMinutesToday: studyMinutes,
      screenTimeMinutesToday: screenTimeMinutes,
      completedHabitsCount: completedHabits,
      xp: xp,
      isLeader: isLeader,
    );
  }

  /// Loads all user squads. If no squads exist, returns empty list.
  /// (Strictly NO fake or dummy squads!)
  static Future<List<Squad>> getSquads() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSquadsPrefKey);

    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      final squads = list.map((item) => Squad.fromJson(item as Map<String, dynamic>)).toList();
      return squads.map((s) {
        return Squad(
          id: s.id,
          name: s.name,
          code: s.code,
          category: s.category,
          motto: s.motto,
          leaderId: s.leaderId,
          leaderName: s.leaderName,
          createdAt: s.createdAt,
          members: computeMemberBadges(s.members),
        );
      }).toList();
    } catch (e) {
      debugPrint('SquadService.getSquads error: $e');
      return [];
    }
  }

  /// Saves the updated squads list locally
  static Future<void> _saveSquads(List<Squad> squads) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(squads.map((s) => s.toJson()).toList());
    await prefs.setString(_kSquadsPrefKey, encoded);
  }

  /// Creates a new Squad with the real logged-in user as Leader,
  /// and syncs squad metadata and membership to Cloud Firestore.
  static Future<Squad> createSquad({
    required String name,
    required String category,
    required String motto,
  }) async {
    final me = await _resolveCurrentUserMember(isLeader: true);

    String prefix = 'NOVA';
    if (category.toLowerCase().contains('study') || category.toLowerCase().contains('exam')) {
      prefix = 'STUD';
    } else if (category.toLowerCase().contains('code')) {
      prefix = 'CODE';
    } else if (category.toLowerCase().contains('fit')) {
      prefix = 'FITN';
    }
    final code = generateSquadCode(prefix);

    final newSquad = Squad(
      id: 'squad-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      code: code,
      category: category,
      motto: motto.isNotEmpty ? motto : 'Consistency breeds champions.',
      leaderId: me.id,
      leaderName: me.name,
      createdAt: DateTime.now(),
      members: [me.copyWith(isMVP: true)],
    );

    final all = await getSquads();
    all.insert(0, newSquad);
    await _saveSquads(all);

    // Push squad header to Cloud Firestore
    _syncSquadHeaderToCloud(newSquad);

    // Push leader's live member progress to Cloud Firestore
    _syncMemberToCloud(code, me);

    return newSquad;
  }

  /// Joins an existing real Squad using a 6-character Code.
  /// Validates against cloud storage so real users on different phones can battle together!
  static Future<Squad?> joinSquad(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return null;

    final all = await getSquads();

    // 1. Check if already joined locally
    for (final s in all) {
      if (s.code.toUpperCase() == cleanCode) {
        return s;
      }
    }

    // 2. Fetch squad definition from Cloud Firestore
    final cloudSquad = await _fetchSquadFromCloud(cleanCode);
    if (cloudSquad == null) {
      debugPrint('Squad $cleanCode not found in cloud');
      return null;
    }

    // 3. Add current real logged-in user to the squad
    final me = await _resolveCurrentUserMember(isLeader: false);

    // Filter out duplicate me if already in list
    final members = cloudSquad.members.where((m) => m.id != me.id).toList();
    members.add(me);

    final updatedSquad = Squad(
      id: cloudSquad.id,
      name: cloudSquad.name,
      code: cloudSquad.code,
      category: cloudSquad.category,
      motto: cloudSquad.motto,
      leaderId: cloudSquad.leaderId,
      leaderName: cloudSquad.leaderName,
      createdAt: cloudSquad.createdAt,
      members: computeMemberBadges(members),
    );

    all.insert(0, updatedSquad);
    await _saveSquads(all);

    // Push current user's live progress to cloud for this squad
    _syncMemberToCloud(cleanCode, me);

    return updatedSquad;
  }

  /// Refreshes all members' live progress for a squad from Cloud Firestore in real time.
  static Future<Squad> refreshSquad(Squad squad) async {
    try {
      final me = await _resolveCurrentUserMember(isLeader: squad.leaderId == (SupabaseService.user?.id ?? ''));
      // Sync my own latest stats first
      await _syncMemberToCloud(squad.code, me);

      // Fetch all real members who joined this squad
      final cloudMembers = await _fetchSquadMembersFromCloud(squad.code);

      // Combine members, ensuring current user is present with latest metrics
      final Map<String, SquadMember> memberMap = {};
      for (final m in cloudMembers) {
        memberMap[m.id] = m;
      }
      memberMap[me.id] = me;

      final updatedMembers = computeMemberBadges(memberMap.values.toList());

      final updatedSquad = Squad(
        id: squad.id,
        name: squad.name,
        code: squad.code,
        category: squad.category,
        motto: squad.motto,
        leaderId: squad.leaderId,
        leaderName: squad.leaderName,
        createdAt: squad.createdAt,
        members: updatedMembers,
      );

      // Update local storage
      final all = await getSquads();
      final index = all.indexWhere((s) => s.code == squad.code);
      if (index >= 0) {
        all[index] = updatedSquad;
      } else {
        all.add(updatedSquad);
      }
      await _saveSquads(all);

      return updatedSquad;
    } catch (e) {
      debugPrint('SquadService.refreshSquad error: $e');
      return squad;
    }
  }

  /// Leaves a squad and updates local cache
  static Future<void> leaveSquad(String code) async {
    final all = await getSquads();
    all.removeWhere((s) => s.code.toUpperCase() == code.trim().toUpperCase());
    await _saveSquads(all);
  }

  /// Cloud Helper: Pushes squad definition to community_leaderboard/squad_{CODE}
  static Future<void> _syncSquadHeaderToCloud(Squad squad) async {
    try {
      final docId = 'squad_${squad.code}';
      final url = '$_firestoreBaseUrl/$docId?key=$_firestoreApiKey';
      final body = jsonEncode({
        'fields': {
          'id': {'stringValue': docId},
          'username': {'stringValue': squad.name},
          'avatarPath': {'stringValue': squad.category},
          'xp': {'integerValue': '0'},
          'streakDays': {'integerValue': '0'},
          'badgeTitle': {'stringValue': 'LD:${squad.leaderName}|MT:${squad.motto}'},
          'updatedAt': {'stringValue': squad.createdAt.toIso8601String()},
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
      debugPrint('_syncSquadHeaderToCloud error: $e');
    }
  }

  /// Cloud Helper: Pushes member's live progress to community_leaderboard/sqm_{CODE}_{userId}
  static Future<void> _syncMemberToCloud(String squadCode, SquadMember member) async {
    try {
      final docId = 'sqm_${squadCode}_${member.id}';
      final url = '$_firestoreBaseUrl/$docId?key=$_firestoreApiKey';

      // Encode study minutes, screen time, habits done, and leader tag inside badgeTitle string
      final encodedMeta =
          'ST:${member.studyMinutesToday}|SC:${member.screenTimeMinutesToday}|HB:${member.completedHabitsCount}|LD:${member.isLeader}';

      final body = jsonEncode({
        'fields': {
          'id': {'stringValue': docId},
          'username': {'stringValue': member.name},
          'avatarPath': {'stringValue': member.avatar},
          'xp': {'integerValue': member.xp.toString()},
          'streakDays': {'integerValue': member.streakDays.toString()},
          'badgeTitle': {'stringValue': encodedMeta},
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
      debugPrint('_syncMemberToCloud error: $e');
    }
  }

  /// Cloud Helper: Fetches squad definition from Cloud Firestore
  static Future<Squad?> _fetchSquadFromCloud(String code) async {
    try {
      final docId = 'squad_$code';
      final url = '$_firestoreBaseUrl/$docId?key=$_firestoreApiKey';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final fields = data['fields'] as Map<String, dynamic>?;
        if (fields != null) {
          final squadName = fields['username']?['stringValue'] as String? ?? 'Squad ($code)';
          final category = fields['avatarPath']?['stringValue'] as String? ?? 'General Focus';
          final badge = fields['badgeTitle']?['stringValue'] as String? ?? '';
          final dateStr = fields['updatedAt']?['stringValue'] as String?;

          String leaderName = 'Captain';
          String motto = 'Consistency breeds champions.';
          if (badge.contains('LD:')) {
            final parts = badge.split('|');
            for (final p in parts) {
              if (p.startsWith('LD:')) leaderName = p.substring(3);
              if (p.startsWith('MT:')) motto = p.substring(3);
            }
          }

          final members = await _fetchSquadMembersFromCloud(code);

          return Squad(
            id: 'squad-$code',
            name: squadName,
            code: code,
            category: category,
            motto: motto,
            leaderId: '',
            leaderName: leaderName,
            createdAt: dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now(),
            members: members,
          );
        }
      }
    } catch (e) {
      debugPrint('_fetchSquadFromCloud error: $e');
    }
    return null;
  }

  /// Cloud Helper: Fetches all members of this squad from Cloud Firestore
  static Future<List<SquadMember>> _fetchSquadMembersFromCloud(String code) async {
    final List<SquadMember> members = [];
    try {
      final url = '$_firestoreBaseUrl?key=$_firestoreApiKey';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final documents = data['documents'] as List<dynamic>?;
        if (documents != null) {
          final prefix = 'sqm_${code}_';
          for (final doc in documents) {
            final fields = doc['fields'] as Map<String, dynamic>?;
            if (fields != null) {
              final id = fields['id']?['stringValue'] as String? ?? '';
              if (id.startsWith(prefix)) {
                final memberUserId = id.substring(prefix.length);
                final uname = fields['username']?['stringValue'] as String? ?? 'Member';
                final avatar = fields['avatarPath']?['stringValue'] as String? ?? '🦁';
                final xp = int.tryParse(fields['xp']?['integerValue']?.toString() ?? '0') ?? 0;
                final streak = int.tryParse(fields['streakDays']?['integerValue']?.toString() ?? '1') ?? 1;
                final badge = fields['badgeTitle']?['stringValue'] as String? ?? '';

                int studyMin = 0;
                int screenMin = 0;
                int habitsDone = 0;
                bool isLeader = false;

                if (badge.contains('ST:')) {
                  final parts = badge.split('|');
                  for (final p in parts) {
                    if (p.startsWith('ST:')) studyMin = int.tryParse(p.substring(3)) ?? 0;
                    if (p.startsWith('SC:')) screenMin = int.tryParse(p.substring(3)) ?? 0;
                    if (p.startsWith('HB:')) habitsDone = int.tryParse(p.substring(3)) ?? 0;
                    if (p.startsWith('LD:')) isLeader = p.substring(3) == 'true';
                  }
                }

                members.add(SquadMember(
                  id: memberUserId,
                  name: uname,
                  avatar: avatar,
                  streakDays: streak,
                  studyMinutesToday: studyMin,
                  screenTimeMinutesToday: screenMin,
                  completedHabitsCount: habitsDone,
                  xp: xp,
                  isLeader: isLeader,
                ));
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('_fetchSquadMembersFromCloud error: $e');
    }
    return members;
  }

  /// Generates the WhatsApp invite message in the user's active language and opens WhatsApp
  static Future<bool> inviteViaWhatsApp(Squad squad) async {
    final lang = LanguageService.currentLanguageCode;
    String message;

    if (lang == LanguageService.marathi) {
      message = '''⚔️ *Habit-Nova हॅबिट बॅटल: माझ्या स्क्वॉडमध्ये सामील व्हा!* ⚔️

मी *${squad.name}* (${squad.category}) स्क्वॉड बनवला आहे!
तुझ्यात हिंमत असेल तर माझ्यासोबत ७ दिवसांच्या हॅबिट आणि फोकस बॅटलमध्ये ये! बघू कोणाचा स्ट्रिक टिकतो आणि कोण MVP बनतो! 👑

🚀 *स्क्वॉड कोड:* *${squad.code}*
📲 *Habit-Nova डाऊनलोड करा व जॉईन व्हा:*
https://habitnova.app/join?code=${squad.code}

#HabitNova #FocusBattle #Consistency''';
    } else if (lang == LanguageService.hindi) {
      message = '''⚔️ *Habit-Nova हैबिट बैटल: मेरे स्क्वाड में शामिल हों!* ⚔️

मैंने *${squad.name}* (${squad.category}) स्क्वाड बनाया है!
अगर आपमें हिम्मत है तो मेरे साथ 7 दिनों की हैबिट और फोकस बैटल में आएं! देखते हैं किसकी स्ट्रीक टिकती है और कौन MVP बनता है! 👑

🚀 *स्क्वाड कोड:* *${squad.code}*
📲 *Habit-Nova डाउनलोड करें और जुड़ें:*
https://habitnova.app/join?code=${squad.code}

#HabitNova #FocusBattle #Consistency''';
    } else {
      message = '''⚔️ *Habit-Nova Habit Battle: Join My Squad!* ⚔️

I have created the *${squad.name}* (${squad.category}) squad!
Challenge accepted? Join me in a 7-day Habit & Focus battle to see who maintains their streak and becomes the MVP! 👑

🚀 *Squad Code:* *${squad.code}*
📲 *Download Habit-Nova & Join:*
https://habitnova.app/join?code=${squad.code}

#HabitNova #FocusBattle #Consistency''';
    }

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUri = Uri.parse('whatsapp://send?text=$encodedMessage');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        final webUri = Uri.parse('https://api.whatsapp.com/send?text=$encodedMessage');
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
          return true;
        }
      }
    } catch (e) {
      debugPrint('inviteViaWhatsApp error: $e');
    }
    return false;
  }
}
