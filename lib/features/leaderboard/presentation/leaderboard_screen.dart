import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synvero/core/services/avatar_service.dart';
import 'package:synvero/core/services/gamification_service.dart';
import 'package:synvero/core/services/leaderboard_service.dart';
import 'package:synvero/core/services/supabase_service.dart';
import 'package:synvero/core/widgets/celebration_dialog.dart';
import 'package:synvero/core/widgets/user_avatar.dart';

/// HabbitNova Community Leaderboard Screen with 100% REAL users only.
///
/// Displays genuine community member rankings, champions podium,
/// and allows users to share/publish their live XP and streak progress.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedFilter = 0; // 0: This Week, 1: All Time
  bool _isLoading = true;
  bool _isPublishing = false;

  List<LeaderboardEntry> _entries = [];
  int _userXP = 0;
  int _userStreak = 1;
  String _username = 'User';
  String _avatarPath = 'assets/images/avatar_m1.png';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseService.user;
      final currentUserId = user?.id ?? 'guest';
      final prefs = await SharedPreferences.getInstance();

      _userXP = await GamificationService.loadXP(userId: currentUserId);
      _userStreak = prefs.getInt('user_${currentUserId}_streak_days') ??
          prefs.getInt('app_streak_days') ??
          1;

      if (user != null) {
        final metaName = user.userMetadata?['username'] as String?;
        if (metaName != null && metaName.trim().isNotEmpty) {
          _username = metaName.trim();
        } else if (user.email != null && user.email!.trim().isNotEmpty) {
          _username = user.email!.split('@').first.trim();
        } else {
          _username = 'User';
        }
      } else {
        _username = 'User';
      }

      _avatarPath = AvatarService.currentAvatarNotifier.value;

      final data = await LeaderboardService.getLeaderboard(
        currentUsername: _username,
        currentAvatar: _avatarPath,
        currentXP: _userXP,
        currentStreak: _userStreak,
      );

      setState(() {
        _entries = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareMyProgress() async {
    setState(() => _isPublishing = true);
    HapticFeedback.mediumImpact();

    await LeaderboardService.publishUserProgress();

    final newXP = await GamificationService.loadXP();
    setState(() {
      _userXP = newXP;
      _isPublishing = false;
    });

    await _loadData();

    if (mounted) {
      CelebrationDialog.show(
        context,
        title: 'Progress Shared to Leaderboard! 🌟',
        subtitle: 'Your rank has been updated in HabbitNova community! (+25 XP Bonus)',
        streakDays: _userStreak,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kBgColor = isDark ? const Color(0xFF030814) : const Color(0xFFF8FAFC);
    final kCardBg = isDark ? const Color(0xFF071728) : Colors.white;
    final kBorderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);
    final kTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final kSubtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final currentUserRankIndex = _entries.indexWhere((e) => e.isCurrentUser);
    final currentUserRank = currentUserRankIndex >= 0 ? currentUserRankIndex + 1 : 1;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: kTextColor, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Community Leaderboard',
          style: TextStyle(
            color: kTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00E5FF)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active User Progress Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0E223D), Color(0xFF071728)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Avatar
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                                ),
                                child: UserAvatar(
                                  size: 52,
                                  avatarUrl: _avatarPath,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Username & Level
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _username,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Rank #$currentUserRank',
                                            style: const TextStyle(
                                              color: Color(0xFF00E5FF),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '⚡ $_userXP XP • 🔥 $_userStreak-day streak',
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Share My Progress Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isPublishing ? null : _shareMyProgress,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E5FF),
                                foregroundColor: const Color(0xFF030814),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              child: _isPublishing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF030814)),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.rocket_launch_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Share Progress to Leaderboard 🚀',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Community Champions Podium
                    if (_entries.length == 1) ...[
                      Center(
                        child: _buildPodiumSpot(
                          entry: _entries[0],
                          rank: 1,
                          height: 160,
                          crownEmoji: '👑',
                          accentColor: const Color(0xFFFFD700),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else if (_entries.length == 2) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildPodiumSpot(
                            entry: _entries[1],
                            rank: 2,
                            height: 130,
                            crownEmoji: '🥈',
                            accentColor: const Color(0xFFC0C0C0),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 16),
                          _buildPodiumSpot(
                            entry: _entries[0],
                            rank: 1,
                            height: 160,
                            crownEmoji: '👑',
                            accentColor: const Color(0xFFFFD700),
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ] else if (_entries.length >= 3) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // #2 Silver
                          _buildPodiumSpot(
                            entry: _entries[1],
                            rank: 2,
                            height: 130,
                            crownEmoji: '🥈',
                            accentColor: const Color(0xFFC0C0C0),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 12),
                          // #1 Gold
                          _buildPodiumSpot(
                            entry: _entries[0],
                            rank: 1,
                            height: 160,
                            crownEmoji: '👑',
                            accentColor: const Color(0xFFFFD700),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 12),
                          // #3 Bronze
                          _buildPodiumSpot(
                            entry: _entries[2],
                            rank: 3,
                            height: 110,
                            crownEmoji: '🥉',
                            accentColor: const Color(0xFFCD7F32),
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Filter Switcher: [This Week] [All Time]
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Community Rankings',
                          style: TextStyle(
                            color: kTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF071728) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorderColor),
                          ),
                          child: Row(
                            children: [
                              _buildFilterPill('Weekly', 0, isDark),
                              _buildFilterPill('All Time', 1, isDark),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Ranked Member List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        final rank = index + 1;
                        final isMe = entry.isCurrentUser;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.12 : 0.08)
                                : kCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isMe
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
                                  : kBorderColor,
                              width: isMe ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Rank Number
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '#$rank',
                                  style: TextStyle(
                                    color: rank == 1
                                        ? const Color(0xFFFFD700)
                                        : rank == 2
                                            ? const Color(0xFFC0C0C0)
                                            : rank == 3
                                                ? const Color(0xFFCD7F32)
                                                : kSubtextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Avatar
                              UserAvatar(
                                size: 40,
                                avatarUrl: entry.avatarPath,
                              ),
                              const SizedBox(width: 12),

                              // Username & Badge
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          entry.username,
                                          style: TextStyle(
                                            color: kTextColor,
                                            fontSize: 14,
                                            fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'YOU',
                                              style: TextStyle(
                                                color: Color(0xFF00E5FF),
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${entry.badgeTitle} • 🔥 ${entry.streakDays}d streak',
                                      style: TextStyle(
                                        color: kSubtextColor,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // XP Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${entry.xp} XP',
                                  style: const TextStyle(
                                    color: Color(0xFF00E5FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    if (_entries.length <= 2) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF071728) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFF00E5FF), size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Real Community Rankings Active 🛡️',
                                    style: TextStyle(
                                      color: kTextColor,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '100% Real HabitNova users only. You are leading the community! When peers complete habits and share progress, their live rank will appear here.',
                                    style: TextStyle(
                                      color: kSubtextColor,
                                      fontSize: 11.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPodiumSpot({
    required LeaderboardEntry entry,
    required int rank,
    required double height,
    required String crownEmoji,
    required Color accentColor,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(crownEmoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accentColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: UserAvatar(
            size: rank == 1 ? 50 : 42,
            avatarUrl: entry.avatarPath,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          entry.username.split(' ').first,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${entry.xp} XP',
          style: TextStyle(
            color: accentColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 90,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(alpha: isDark ? 0.25 : 0.18),
                accentColor.withValues(alpha: isDark ? 0.08 : 0.04),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: accentColor.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: Text(
            '#$rank',
            style: TextStyle(
              color: accentColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String title, int index, bool isDark) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.2) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF64748B),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
