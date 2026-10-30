import 'dart:async';
import 'package:flutter/services.dart';
import 'package:synvero/core/services/avatar_service.dart';
import 'package:synvero/core/services/habit_daily_service.dart';
import 'package:synvero/core/services/language_service.dart';
import 'package:synvero/core/services/quote_service.dart';
import 'package:synvero/core/services/streak_badge_service.dart';
import 'package:synvero/core/widgets/celebration_dialog.dart';
import 'package:flutter/material.dart';
import 'package:synvero/core/widgets/user_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/app_widget_service.dart';
import 'package:synvero/core/services/supabase_service.dart';
import 'package:synvero/core/services/gamification_service.dart';
import 'package:synvero/features/dashboard/presentation/ai_coach_card.dart';
import 'package:synvero/features/dashboard/presentation/weekly_heatmap_widget.dart';
import 'package:synvero/features/dashboard/presentation/share_story_card_dialog.dart';
import 'package:synvero/features/profile/presentation/badges_showcase_sheet.dart';

/// Home Dashboard screen.
///
/// Implements Screen 3 from the Synvero UI design mockup:
/// - Header: Greeting "Hello, {Username} 👋" + "Keep going! You're doing great!" + profile avatar
/// - Date Pill: e.g. "📅 Tue, 28 Oct 2025"
/// - Hero Gradient Card: "Small steps create big results"
/// - Today's Progress: Circular gauge ("X/5 Habits completed") + Study Time / Tasks / Streak cards
/// - Quick Actions: Habits, Study Timer, Tasks, AI Assistant
/// - Today's Habits: "Read a book" completed card
/// - Lifestyle & Wellness: Nutrition Plan & Fitness Plan cards
/// - Bottom Navigation Bar with 5 tabs: Home, Habits, Timer, Tasks, Profile
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  String? _username;
  bool _isLoading = true;
  int _currentTabIndex = 0;
  int _completedHabitsCount = 0;
  int _studyMinutes = 0;
  int _tasksDoneCount = 0;
  int _tasksTotalCount = 4;
  int _streakDays = 0;
  int _totalXP = 150;
  final Map<String, bool> _habitCompletionMap = {};
  Timer? _midnightCheckTimer;
  String? _lastCheckedDate;

  // Standard starter habits definition
  final List<Map<String, dynamic>> _todayHabitItems = [
    {
      'id': 'def-1',
      'name': 'Workout',
      'target': '1 session',
      'icon': Icons.fitness_center_rounded,
      'color': Color(0xFF10B981),
      'bgColor': Color(0xFFD1FAE5),
    },
    {
      'id': 'def-2',
      'name': 'Read a book',
      'target': '20 pages',
      'icon': Icons.menu_book_rounded,
      'color': Color(0xFF8B5CF6),
      'bgColor': Color(0xFFEDE9FE),
    },
    {
      'id': 'def-3',
      'name': 'Drink water',
      'target': '8 glasses',
      'icon': Icons.water_drop_rounded,
      'color': Color(0xFF3B66FF),
      'bgColor': Color(0xFFDBEAFE),
    },
    {
      'id': 'def-4',
      'name': 'Meditate',
      'target': '10 mins',
      'icon': Icons.self_improvement_rounded,
      'color': Color(0xFF6366F1),
      'bgColor': Color(0xFFE0E7FF),
    },
    {
      'id': 'def-5',
      'name': 'Study',
      'target': '2 hours',
      'icon': Icons.school_rounded,
      'color': Color(0xFF0284C7),
      'bgColor': Color(0xFFE0F2FE),
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastCheckedDate = HabitDailyService.getTodayDateStr();
    _loadProfile();

    // Check every minute for automatic 12:00 AM midnight reset
    _midnightCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final today = HabitDailyService.getTodayDateStr();
      if (_lastCheckedDate != null && _lastCheckedDate != today) {
        _lastCheckedDate = today;
        _loadProfile();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final today = HabitDailyService.getTodayDateStr();
      if (_lastCheckedDate != null && _lastCheckedDate != today) {
        _lastCheckedDate = today;
        _loadProfile();
      }
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = SupabaseService.user;
      final currentUserId = user?.id ?? 'guest';
      await AvatarService.loadForUser(currentUserId);

      // Check and execute midnight habit reset if date changed
      await HabitDailyService.verifyAndPerformMidnightReset(currentUserId);

      final prefs = await SharedPreferences.getInstance();

      // 1. Calculate real completed habits count with date-aware midnight reset
      int completed = 0;
      final defaultHabitIds = ['def-1', 'def-2', 'def-3', 'def-4', 'def-5'];
      _habitCompletionMap.clear();
      for (final id in defaultHabitIds) {
        final isDone = await HabitDailyService.isHabitCompletedToday(currentUserId, id);
        _habitCompletionMap[id] = isDone;
        if (isDone) completed++;
      }
      _completedHabitsCount = completed;

      // 2. Calculate real focus study time
      final sessionCount = prefs.getInt('user_${currentUserId}_timer_completed_sessions') ?? 0;
      final focusMins = prefs.getInt('user_${currentUserId}_focus_duration_mins') ?? 25;
      _studyMinutes = sessionCount * focusMins;

      // 3. Calculate real completed tasks count
      final taskIds = ['task-1', 'task-2', 'task-3', 'task-4'];
      int tasksDone = 0;
      for (final tid in taskIds) {
        final key = 'user_${currentUserId}_task_${tid}_completed';
        if (prefs.getBool(key) ?? false) {
          tasksDone++;
        }
      }
      _tasksDoneCount = tasksDone;
      _tasksTotalCount = taskIds.length;

      // 4. Calculate real streak (0 if user has not completed any habits)
      final savedStreak = prefs.getInt('user_${currentUserId}_streak_days');
      if (savedStreak != null && savedStreak > 0) {
        _streakDays = savedStreak;
      } else {
        _streakDays = completed > 0 ? 1 : 0;
      }

      final xp = await GamificationService.loadXP(userId: currentUserId);
      _totalXP = xp;

      // 5. Load user's actual profile/username without dummy fallback
      if (user != null) {
        final metaUsername = user.userMetadata?['username'] as String?;
        if (metaUsername != null && metaUsername.trim().isNotEmpty) {
          _username = metaUsername.trim();
        } else if (user.email != null && user.email!.trim().isNotEmpty) {
          _username = user.email!.split('@').first.trim();
        } else {
          _username = 'User';
        }
        await prefs.setString('user_name', _username!);
      } else {
        _username = 'User';
      }
    } catch (_) {
      // Graceful fallback
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      AppWidgetService.syncWidget();
    }
  }

  Future<void> _toggleDashboardHabit(String habitId, String habitName) async {
    final user = SupabaseService.user;
    final currentUserId = user?.id ?? 'guest';
    final currentStatus = _habitCompletionMap[habitId] ?? false;
    final newStatus = !currentStatus;

    setState(() {
      _habitCompletionMap[habitId] = newStatus;
      if (newStatus) {
        _completedHabitsCount++;
      } else {
        if (_completedHabitsCount > 0) _completedHabitsCount--;
      }
      _streakDays = _completedHabitsCount > 0 ? 1 : 0;
    });

    try {
      await HabitDailyService.setHabitCompletedToday(currentUserId, habitId, newStatus);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_${currentUserId}_streak_days', _streakDays);
      AppWidgetService.syncWidget();
    } catch (_) {}

    if (mounted) {
      if (newStatus) {
        await GamificationService.addXP(GamificationService.xpPerHabit, reason: 'Completed Habit');
        final currentXP = await GamificationService.loadXP();
        if (mounted) {
          setState(() {
            _totalXP = currentXP;
          });
        }
        await GamificationService.checkAndAwardBadges(
          streakDays: _streakDays,
          habitsCompletedToday: _completedHabitsCount,
          waterGlassesToday: 4,
          studySessionsToday: 0,
          tasksDoneToday: _tasksDoneCount,
        );
        if (mounted) {
          CelebrationDialog.show(
            context,
            title: 'Habit Completed! 🎉',
            subtitle: '$habitName (+50 XP)',
            streakDays: _streakDays,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$habitName marked pending'),
            backgroundColor: const Color(0xFF64748B),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kBgColor = isDark ? const Color(0xFF030814) : const Color(0xFFF8FAFC);
    final kCardBg = isDark ? const Color(0xFF071728) : Colors.white;
    final kTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final kSubtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final kBorderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);
    final kBottomNavBg = isDark ? const Color(0xFF050E1A) : Colors.white;
    final kProgressRingBg = isDark ? const Color(0xFF0A1F30) : const Color(0xFFF1F5F9);

    final streakBadge = StreakBadgeService.getBadge(_streakDays);
    final displayName = _username != null && _username!.isNotEmpty
        ? _capitalize(_username!)
        : 'User';

    final today = DateTime.now();
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateString =
        '${weekdayNames[today.weekday - 1]}, ${today.day} ${monthNames[today.month - 1]} ${today.year}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmationDialog(context);
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              )
            : RefreshIndicator(
                onRefresh: _loadProfile,
                color: kPrimaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Header: User Greeting & Avatar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $displayName 👋',
                                  style: TextStyle(
                                    color: kTextColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Keep going! You're doing great!",
                                  style: TextStyle(
                                    color: kSubtextColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: streakBadge.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: streakBadge.color.withValues(alpha: 0.5), width: 1.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(streakBadge.emoji, style: const TextStyle(fontSize: 12)),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${streakBadge.title} • ${_streakDays}d Streak',
                                        style: TextStyle(
                                          color: streakBadge.color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () {
                                    BadgesShowcaseSheet.show(context, currentXP: _totalXP, streakDays: _streakDays);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.5), width: 1.0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(GamificationService.getLevelInfo(_totalXP).badgeEmoji, style: const TextStyle(fontSize: 12)),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Lvl ${GamificationService.getLevelInfo(_totalXP).level} • ${GamificationService.getLevelInfo(_totalXP).title} ($_totalXP XP) 🏆',
                                          style: const TextStyle(
                                            color: Color(0xFF00F0FF),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          UserAvatar(
                            size: 46,
                            onTap: () {
                              Navigator.of(context).pushNamed('/profile');
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Date Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kCardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kBorderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: Color(0xFF3B66FF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateString,
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Hero Card: Blue Gradient "Small steps create big results"
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0284C7),
                              Color(0xFF0D9488),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ValueListenableBuilder<MotivationalQuote>(
                          valueListenable: QuoteService.currentQuoteNotifier,
                          builder: (context, quote, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'DAILY MOTIVATION ✨',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.95),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    InkWell(
                                      onTap: () {
                                        QuoteService.nextQuote();
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Next Quote',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.95),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '"${quote.text}"',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '— ${quote.author}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 18),

                      // AI Daily Morning Coach Card
                      AICoachCard(
                        username: displayName,
                        streakDays: _streakDays,
                        habitsCompletedToday: _completedHabitsCount,
                        totalHabits: 5,
                        onChatTapped: () {
                          Navigator.of(context).pushNamed('/ai-assistant');
                        },
                      ),

                      const SizedBox(height: 16),

                      // Weekly Consistency Heatmap
                      WeeklyHeatmapWidget(streakDays: _streakDays),

                      const SizedBox(height: 20),

                      // Today's Progress Section Title with Share Story Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Progress",
                            style: TextStyle(
                              color: kTextColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => Navigator.of(context).pushNamed('/leaderboard'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.emoji_events_rounded, size: 12, color: Color(0xFFFFD700)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Ranks',
                                        style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  final quote = QuoteService.currentQuote;
                                  ShareStoryCardDialog.show(
                                    context,
                                    username: displayName,
                                    streakDays: _streakDays,
                                    habitsCompleted: _completedHabitsCount,
                                    totalHabits: 5,
                                    totalXP: _totalXP,
                                    quoteText: quote.text,
                                    quoteAuthor: quote.author,
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.share_rounded, size: 12, color: Color(0xFF00F0FF)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Story',
                                        style: TextStyle(
                                          color: Color(0xFF00F0FF),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Progress Grid (Circular gauge on left + 3 stat rows on right)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kCardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: kBorderColor),
                        ),
                        child: Row(
                          children: [
                            // Circular Progress Ring
                            SizedBox(
                              width: 110,
                              height: 110,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: CircularProgressIndicator(
                                      value: _completedHabitsCount / 5.0,
                                      strokeWidth: 9,
                                      backgroundColor: kProgressRingBg,
                                      valueColor: const AlwaysStoppedAnimation(
                                        Color(0xFF00E5FF),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$_completedHabitsCount/5',
                                        style: TextStyle(
                                          color: kTextColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Habits\ncompleted',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: kSubtextColor,
                                          fontSize: 10,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Right Stats Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStatPill(
                                    icon: Icons.timer_outlined,
                                    iconColor: const Color(0xFF3B66FF),
                                    bgColor: isDark ? const Color(0xFF1E2D48) : const Color(0xFFEEF2FF),
                                    title: 'Study Time',
                                    value: _studyMinutes == 0
                                        ? '0m'
                                        : (_studyMinutes >= 60
                                            ? '${_studyMinutes ~/ 60}h ${_studyMinutes % 60}m'
                                            : '${_studyMinutes}m'),
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildStatPill(
                                    icon: Icons.checklist_rounded,
                                    iconColor: const Color(0xFF10B981),
                                    bgColor: isDark ? const Color(0xFF132E27) : const Color(0xFFD1FAE5),
                                    title: 'Tasks Done',
                                    value: '$_tasksDoneCount/$_tasksTotalCount',
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildStatPill(
                                    icon: Icons.local_fire_department_rounded,
                                    iconColor: const Color(0xFFF59E0B),
                                    bgColor: isDark ? const Color(0xFF332511) : const Color(0xFFFEF3C7),
                                    title: 'Streak',
                                    value: '$_streakDays ${_streakDays == 1 ? "day" : "days"}',
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Quick Actions',
                            style: TextStyle(
                              color: kTextColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/habits');
                            },
                            child: const Text(
                              'View all',
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Quick Actions Scrollable Row (6 Features)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickActionButton(
                              icon: Icons.eco_rounded,
                              label: 'Habits',
                              color: const Color(0xFF10B981),
                              bgColor: const Color(0xFFD1FAE5),
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).pushNamed('/habits').then((_) => _loadProfile());
                              },
                            ),
                            const SizedBox(width: 14),
                            _buildQuickActionButton(
                              icon: Icons.hourglass_top_rounded,
                              label: 'Study Timer',
                              color: const Color(0xFF8B5CF6),
                              bgColor: const Color(0xFFEDE9FE),
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).pushNamed('/timer');
                              },
                            ),
                            const SizedBox(width: 14),
                            _buildQuickActionButton(
                              icon: Icons.checklist_rounded,
                              label: 'Tasks',
                              color: const Color(0xFF3B66FF),
                              bgColor: const Color(0xFFDBEAFE),
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).pushNamed('/tasks');
                              },
                            ),
                            const SizedBox(width: 14),
                            _buildQuickActionButton(
                              icon: Icons.auto_awesome_rounded,
                              label: 'AI Assistant',
                              imageAsset: 'assets/images/ai_assistant_logo.png',
                              color: const Color(0xFF6366F1),
                              bgColor: const Color(0xFFE0E7FF),
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).pushNamed('/ai-assistant');
                              },
                            ),
                            const SizedBox(width: 14),
                            _buildQuickActionButton(
                              icon: Icons.bar_chart_rounded,
                              label: 'Statistics',
                              color: const Color(0xFF00E5FF),
                              bgColor: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).pushNamed('/statistics');
                              },
                            ),
                            const SizedBox(width: 14),
                            _buildQuickActionButton(
                              icon: Icons.emoji_events_rounded,
                              label: 'Leaderboard',
                              color: const Color(0xFFFFD700),
                              bgColor: const Color(0xFFFFD700).withValues(alpha: 0.15),
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).pushNamed('/leaderboard');
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Today's Habits Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Habits",
                            style: TextStyle(
                              color: kTextColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/habits').then((_) => _loadProfile());
                            },
                            child: const Text(
                              'View all',
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Today's Habits List (Dynamic & User-isolated)
                      ..._todayHabitItems.take(3).map((habit) {
                        final habitId = habit['id'] as String;
                        final habitName = habit['name'] as String;
                        final isDone = _habitCompletionMap[habitId] ?? false;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () => _toggleDashboardHabit(habitId, habitName),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: kCardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDone
                                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                      : kBorderColor,
                                  width: isDone ? 1.4 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark ? (habit['color'] as Color).withValues(alpha: 0.15) : habit['bgColor'] as Color,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      habit['icon'] as IconData,
                                      color: habit['color'] as Color,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          habitName,
                                          style: TextStyle(
                                            color: kTextColor,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            decoration: isDone ? TextDecoration.lineThrough : null,
                                            decorationColor: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isDone ? 'Completed' : 'Pending • ${habit['target']}',
                                          style: TextStyle(
                                            color: isDone ? const Color(0xFF10B981) : kSubtextColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Interactive Checkbox
                                  Icon(
                                    isDone
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: isDone
                                        ? const Color(0xFF00E5FF)
                                        : (isDark ? const Color(0xFF0E3D48) : const Color(0xFFCBD5E1)),
                                    size: 26,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 24),

                      // Lifestyle & Wellness Plans Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lifestyle & Wellness',
                            style: TextStyle(
                              color: kTextColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/nutrition');
                            },
                            child: const Text(
                              'View all',
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Nutrition and Fitness 2-Column Cards
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pushNamed('/nutrition');
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: kCardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: kBorderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFD1FAE5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.restaurant_menu_rounded,
                                        color: Color(0xFF10B981),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Nutrition Plan',
                                      style: TextStyle(
                                        color: kTextColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '1,200 kcal plan',
                                      style: TextStyle(
                                        color: kSubtextColor,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pushNamed('/fitness');
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: kCardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: kBorderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.fitness_center_rounded,
                                        color: Color(0xFFF59E0B),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Fitness Plan',
                                      style: TextStyle(
                                        color: kTextColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '4 Days/Week',
                                      style: TextStyle(
                                        color: kSubtextColor,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kBottomNavBg,
          border: Border(
            top: BorderSide(color: kBorderColor, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
            });
            if (index == 1) {
              Navigator.of(context).pushNamed('/habits').then((_) => _loadProfile());
            } else if (index == 2) {
              Navigator.of(context).pushNamed('/timer');
            } else if (index == 3) {
              Navigator.of(context).pushNamed('/tasks');
            } else if (index == 4) {
              Navigator.of(context).pushNamed('/profile');
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: kBottomNavBg,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded),
              label: 'Habits',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined),
              label: 'Timer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist_rounded),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ),
  );
}

  /// Shows confirmation popup when user presses phone back button to prevent accidental exit
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF081220) : Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Exit Shield Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF3B66FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.exit_to_app_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  LanguageService.tr('exit_dialog_title'),
                  style: TextStyle(
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                Text(
                  LanguageService.tr('exit_dialog_msg'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    // Stay button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? const Color(0xFF0E3D48) : const Color(0xFFCBD5E1),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          LanguageService.tr('exit_btn_stay'),
                          style: TextStyle(
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Exit button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          LanguageService.tr('exit_btn_exit'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  Widget _buildStatPill({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : kSecondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? const Color(0xFFF1F5F9) : kDarkText,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required bool isDark,
    required VoidCallback onTap,
    String? imageAsset,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF071728) : bgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: imageAsset != null
                    ? const Color(0xFF00F0FF).withValues(alpha: 0.5)
                    : (isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0)),
              ),
              boxShadow: imageAsset != null
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: imageAsset != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      imageAsset,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFFF1F5F9) : kDarkText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
