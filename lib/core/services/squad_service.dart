import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:synvero/core/services/supabase_service.dart';

class SquadMember {
  final String id;
  final String name;
  final String avatar;
  final int streakDays;
  final int studyMinutesToday;
  final int screenTimeMinutesToday;
  final int completedHabitsCount;
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
        'isLeader': isLeader,
        'isMVP': isMVP,
        'isSlacker': isSlacker,
      };

  factory SquadMember.fromJson(Map<String, dynamic> json) => SquadMember(
        id: json['id'] as String? ?? 'member-${Random().nextInt(9999)}',
        name: json['name'] as String? ?? 'Aspirant',
        avatar: json['avatar'] as String? ?? '🦊',
        streakDays: json['streakDays'] as int? ?? 0,
        studyMinutesToday: json['studyMinutesToday'] as int? ?? 0,
        screenTimeMinutesToday: json['screenTimeMinutesToday'] as int? ?? 0,
        completedHabitsCount: json['completedHabitsCount'] as int? ?? 0,
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
      category: json['category'] as String? ?? 'General',
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
  static const String _kSquadsPrefKey = 'habit_nova_user_squads_v2';

  /// Generates a randomized 6-character squad code (e.g. "NOVA84")
  static String generateSquadCode([String prefix = 'NOVA']) {
    final random = Random();
    final num = random.nextInt(900) + 100; // 3 digits
    return '$prefix$num';
  }

  /// Calculates MVP and Slacker tags among squad members dynamically.
  static List<SquadMember> computeMemberBadges(List<SquadMember> members) {
    if (members.isEmpty) return members;
    if (members.length == 1) {
      return [members.first.copyWith(isMVP: true, isSlacker: false)];
    }

    // MVP = Highest study minutes + completed habits
    int maxScore = -1;
    String mvpId = '';

    // Slacker = Highest screen time and lowest habits completed
    int worstScore = -999999;
    String slackerId = '';

    for (final m in members) {
      final score = (m.studyMinutesToday * 2) + (m.completedHabitsCount * 30) + m.streakDays;
      if (score > maxScore) {
        maxScore = score;
        mvpId = m.id;
      }

      // Negative weighting for high phone screen time
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

  /// Loads all user squads (including default community squads if none stored)
  static Future<List<Squad>> getSquads() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSquadsPrefKey);

    if (raw == null || raw.trim().isEmpty) {
      final initial = _getDefaultSquads();
      await _saveSquads(initial);
      return initial;
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
      debugPrint('SquadService.getSquads decode error: $e');
      final fallback = _getDefaultSquads();
      return fallback;
    }
  }

  /// Saves the updated squads list
  static Future<void> _saveSquads(List<Squad> squads) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(squads.map((s) => s.toJson()).toList());
    await prefs.setString(_kSquadsPrefKey, encoded);
  }

  /// Creates a new Squad and sets the current user as the Leader
  static Future<Squad> createSquad({
    required String name,
    required String category,
    required String motto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = SupabaseService.user?.id ?? 'user-me';
    final currentUserName = prefs.getString('user_name') ?? 'Yogesh';
    final currentStreak = prefs.getInt('user_${currentUserId}_streak_days') ?? 3;

    final code = generateSquadCode(
      category.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '').takeChars(4),
    );

    final me = SquadMember(
      id: currentUserId,
      name: currentUserName,
      avatar: '👑',
      streakDays: currentStreak,
      studyMinutesToday: 90,
      screenTimeMinutesToday: 75,
      completedHabitsCount: 3,
      isLeader: true,
      isMVP: true,
      isSlacker: false,
    );

    final newSquad = Squad(
      id: 'squad-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      code: code,
      category: category,
      motto: motto.isNotEmpty ? motto : 'Consistency is our superpower.',
      leaderId: currentUserId,
      leaderName: currentUserName,
      createdAt: DateTime.now(),
      members: [me],
    );

    final all = await getSquads();
    all.insert(0, newSquad);
    await _saveSquads(all);
    return newSquad;
  }

  /// Joins an existing squad using a 6-character Code
  static Future<Squad?> joinSquad(String code) async {
    final cleanCode = code.trim().toUpperCase();
    final all = await getSquads();

    // Check if already in squad with this code
    for (final s in all) {
      if (s.code.toUpperCase() == cleanCode) {
        return s;
      }
    }

    // Try finding in community squads pool or generate one
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = SupabaseService.user?.id ?? 'user-me';
    final currentUserName = prefs.getString('user_name') ?? 'Yogesh';
    final currentStreak = prefs.getInt('user_${currentUserId}_streak_days') ?? 2;

    final me = SquadMember(
      id: currentUserId,
      name: currentUserName,
      avatar: '⚡',
      streakDays: currentStreak,
      studyMinutesToday: 45,
      screenTimeMinutesToday: 95,
      completedHabitsCount: 2,
      isLeader: false,
    );

    // Create a squad for this code with interesting peers
    final joinedSquad = Squad(
      id: 'squad-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Battle Squad ($cleanCode)',
      code: cleanCode,
      category: 'Challenge',
      motto: 'United we grind, together we shine.',
      leaderId: 'peer-lead',
      leaderName: 'Aarav (Lead)',
      createdAt: DateTime.now(),
      members: computeMemberBadges([
        const SquadMember(
          id: 'peer-1',
          name: 'Aarav Sharma',
          avatar: '🦁',
          streakDays: 14,
          studyMinutesToday: 180,
          screenTimeMinutesToday: 40,
          completedHabitsCount: 5,
          isLeader: true,
        ),
        me,
        const SquadMember(
          id: 'peer-2',
          name: 'Snehal Patil',
          avatar: '🐯',
          streakDays: 8,
          studyMinutesToday: 60,
          screenTimeMinutesToday: 180,
          completedHabitsCount: 1,
        ),
      ]),
    );

    all.add(joinedSquad);
    await _saveSquads(all);
    return joinedSquad;
  }

  /// Generates the viral WhatsApp invite message and opens WhatsApp directly
  static Future<bool> inviteViaWhatsApp(Squad squad) async {
    final message = '''⚔️ *Habit-Nova Habit Battle: Join My Squad!* ⚔️

मी *${squad.name}* (${squad.category}) स्क्वॉड बनवला आहे!
तुझ्यात हिंमत असेल तर माझ्यासोबत 7-Day Habit & Focus Battle मध्ये ये! बघू कोणाचा Streak टिकतो आणि कोण MVP बनतो! 👑

🚀 *Squad Code:* *${squad.code}*
📲 *Download & Join Habit-Nova:*
https://habitnova.app/join?code=${squad.code}

#HabitNova #FocusBattle #Consistency''';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUri = Uri.parse('whatsapp://send?text=$encodedMessage');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // Fallback to web WhatsApp or generic share
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

  /// Default engaging community squads
  static List<Squad> _getDefaultSquads() {
    return [
      Squad(
        id: 'squad-mpsc-warriors',
        name: '⚔️ MPSC & UPSC Warriors',
        code: 'MPSC26',
        category: 'Study & Exams',
        motto: 'कष्ट इतके शांतपणे करा की यश आपोआप आवाज करेल!',
        leaderId: 'peer-omkar',
        leaderName: 'Omkar Jadhav',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        members: computeMemberBadges([
          const SquadMember(
            id: 'peer-omkar',
            name: 'Omkar Jadhav',
            avatar: '🎯',
            streakDays: 21,
            studyMinutesToday: 310,
            screenTimeMinutesToday: 35,
            completedHabitsCount: 5,
            isLeader: true,
          ),
          const SquadMember(
            id: 'user-me',
            name: 'Yogesh (You)',
            avatar: '👑',
            streakDays: 7,
            studyMinutesToday: 180,
            screenTimeMinutesToday: 85,
            completedHabitsCount: 4,
          ),
          const SquadMember(
            id: 'peer-snehal',
            name: 'Snehal Deshmukh',
            avatar: '🌸',
            streakDays: 12,
            studyMinutesToday: 140,
            screenTimeMinutesToday: 120,
            completedHabitsCount: 3,
          ),
          const SquadMember(
            id: 'peer-rohit',
            name: 'Rohit Pawar',
            avatar: '😴',
            streakDays: 2,
            studyMinutesToday: 20,
            screenTimeMinutesToday: 260,
            completedHabitsCount: 1,
          ),
        ]),
      ),
      Squad(
        id: 'squad-coding-titans',
        name: '💻 100 Days of Code',
        code: 'CODE99',
        category: 'Coding & Tech',
        motto: 'Eat. Sleep. Code. Repeat.',
        leaderId: 'peer-aditya',
        leaderName: 'Aditya K',
        createdAt: DateTime.now().subtract(const Duration(days: 9)),
        members: computeMemberBadges([
          const SquadMember(
            id: 'peer-aditya',
            name: 'Aditya K',
            avatar: '⚡',
            streakDays: 34,
            studyMinutesToday: 240,
            screenTimeMinutesToday: 55,
            completedHabitsCount: 5,
            isLeader: true,
          ),
          const SquadMember(
            id: 'user-me',
            name: 'Yogesh (You)',
            avatar: '👑',
            streakDays: 7,
            studyMinutesToday: 120,
            screenTimeMinutesToday: 90,
            completedHabitsCount: 4,
          ),
          const SquadMember(
            id: 'peer-pranav',
            name: 'Pranav M',
            avatar: '🎮',
            streakDays: 1,
            studyMinutesToday: 15,
            screenTimeMinutesToday: 280,
            completedHabitsCount: 0,
          ),
        ]),
      ),
    ];
  }
}

extension _StringExt on String {
  String takeChars(int n) {
    if (length <= n) return this;
    return substring(0, n);
  }
}

