import 'package:flutter/material.dart';
import 'package:synvero/core/widgets/user_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/app_widget_service.dart';
import 'package:synvero/core/services/supabase_service.dart';
import 'package:synvero/features/auth/data/auth_repository.dart';

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

class _DashboardScreenState extends State<DashboardScreen> {
  final _authRepository = AuthRepository();
  String? _username;
  bool _isLoading = true;
  int _currentTabIndex = 0;
  int _completedHabitsCount = 0;
  int _studyMinutes = 0;
  int _tasksDoneCount = 0;
  int _tasksTotalCount = 4;
  int _streakDays = 0;
  final Map<String, bool> _habitCompletionMap = {};

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
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = SupabaseService.user;
      final currentUserId = user?.id ?? 'guest';

      final prefs = await SharedPreferences.getInstance();

      // 1. Calculate real completed habits count (strictly 0 for new user, no dummy completions)
      int completed = 0;
      final defaultHabitIds = ['def-1', 'def-2', 'def-3', 'def-4', 'def-5'];
      _habitCompletionMap.clear();
      for (final id in defaultHabitIds) {
        final key = 'user_${currentUserId}_habit_${id}_completed';
        final isDone = prefs.getBool(key) ?? false;
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

      // 5. Load user's actual profile/username without dummy fallback
      if (user != null) {
        final metaUsername = user.userMetadata?['username'] as String?;
        if (metaUsername != null && metaUsername.isNotEmpty) {
          _username = metaUsername;
        } else {
          try {
            final profile = await _authRepository.getProfile(userId: user.id);
            _username = profile['username'] as String?;
          } catch (_) {}
        }
        if ((_username == null || _username!.isEmpty) && user.email != null && user.email!.isNotEmpty) {
          _username = user.email!.split('@').first;
        }
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_${currentUserId}_habit_${habitId}_completed', newStatus);
      await prefs.setInt('user_${currentUserId}_streak_days', _streakDays);
      AppWidgetService.syncWidget();
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? '$habitName completed! 🎉' : '$habitName marked pending'),
          backgroundColor: newStatus ? const Color(0xFF10B981) : const Color(0xFF64748B),
          duration: const Duration(seconds: 2),
        ),
      );
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

    return Scaffold(
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
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Small steps\ncreate big results',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Build better habits,\nreach your goals.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.flag_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Today's Progress Section Title
                      Text(
                        "Today's Progress",
                        style: TextStyle(
                          color: kTextColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
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

                      // Quick Action 4 Icon Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          _buildQuickActionButton(
                            icon: Icons.auto_awesome_rounded,
                            label: 'AI Assistant',
                            color: const Color(0xFF6366F1),
                            bgColor: const Color(0xFFE0E7FF),
                            isDark: isDark,
                            onTap: () {
                              Navigator.of(context).pushNamed('/ai_assistant');
                            },
                          ),
                        ],
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
    );
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
              border: Border.all(color: isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, color: color, size: 28),
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
