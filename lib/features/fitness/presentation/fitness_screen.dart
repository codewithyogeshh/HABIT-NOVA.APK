import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/supabase_service.dart';

/// Exercise item representation.
class ExerciseItem {
  final String title;
  final String detail;
  final IconData icon;
  bool isCompleted;

  ExerciseItem({
    required this.title,
    required this.detail,
    required this.icon,
    this.isCompleted = false,
  });
}

/// Fitness Plan screen.
///
/// Implements Screen 10 from the Synvero master design mockup:
/// - Header: Back arrow, "Fitness Plan" title
/// - Header Overview: "Your Personalized Workout", "Beginner • 45 min • 4 Days/Week"
/// - Workout Section: "Day 1 - Upper Body"
/// - Exercise Cards:
///   - Push-ups (3 sets • 10 reps)
///   - Dumbbell Rows (3 sets • 12 reps)
///   - Shoulder Press (3 sets • 10 reps)
///   - Plank (3 sets • 30 seconds)
/// - Primary Action Button: "View Full Plan"
/// - Tip Banner: "Stay consistent and maintain good form. Rest for 60-90 seconds between sets."
/// - Bottom Navigation Bar
class FitnessScreen extends StatefulWidget {
  const FitnessScreen({super.key});

  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen> {
  int _currentTabIndex = 0; // Accessible from Home / Profile

  final List<ExerciseItem> _exercises = [
    ExerciseItem(
      title: 'Push-ups',
      detail: '3 sets • 10 reps',
      icon: Icons.fitness_center_rounded,
      isCompleted: true,
    ),
    ExerciseItem(
      title: 'Dumbbell Rows',
      detail: '3 sets • 12 reps',
      icon: Icons.fitness_center_rounded,
      isCompleted: true,
    ),
    ExerciseItem(
      title: 'Shoulder Press',
      detail: '3 sets • 10 reps',
      icon: Icons.sports_gymnastics_rounded,
      isCompleted: false,
    ),
    ExerciseItem(
      title: 'Plank',
      detail: '3 sets • 30 seconds',
      icon: Icons.timer_outlined,
      isCompleted: false,
    ),
  ];

  String get _currentUserId => SupabaseService.user?.id ?? 'guest';

  @override
  void initState() {
    super.initState();
    _loadSavedExerciseStates();
  }

  Future<void> _loadSavedExerciseStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        for (final ex in _exercises) {
          final key = 'user_${_currentUserId}_exercise_${ex.title}_completed';
          if (prefs.containsKey(key)) {
            ex.isCompleted = prefs.getBool(key) ?? false;
          } else {
            // Fresh account starts with clean slate (0 completed)
            ex.isCompleted = (ex.title == 'Push-ups' || ex.title == 'Dumbbell Rows') && _currentUserId == 'guest';
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _toggleExercise(ExerciseItem ex) async {
    final newStatus = !ex.isCompleted;
    setState(() {
      ex.isCompleted = newStatus;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_${_currentUserId}_exercise_${ex.title}_completed', newStatus);
    } catch (_) {}
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentTabIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/dashboard');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/habits');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/timer');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/tasks');
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kBgColor = isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC);
    final kCardBg = isDark ? const Color(0xFF131D31) : Colors.white;
    final kDarkNavy = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final kSecondaryText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final kBorderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final kBottomNavBg = isDark ? const Color(0xFF0D1424) : Colors.white;

    final completedCount = _exercises.where((e) => e.isCompleted).length;

    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Back Arrow, Title, Nutrition shortcut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: kDarkNavy, size: 22),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacementNamed('/dashboard');
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                    'Fitness Plan',
                    style: TextStyle(
                      color: kDarkNavy,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.restaurant_menu_rounded, color: kDarkNavy, size: 22),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/nutrition');
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Overview Section
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2D48) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFF2563EB),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Personalized Workout',
                            style: TextStyle(
                              color: kDarkNavy,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Beginner • 45 min • 4 Days/Week',
                            style: TextStyle(
                              color: kSecondaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Day Section Title & Progress Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Day 1 - Upper Body',
                    style: TextStyle(
                      color: kDarkNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$completedCount/${_exercises.length} Done',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Exercises List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exercises.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ex = _exercises[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ex.isCompleted
                            ? const Color(0xFF10B981).withValues(alpha: 0.3)
                            : kBorderColor,
                        width: ex.isCompleted ? 1.4 : 1.0,
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
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: ex.isCompleted
                                ? (isDark ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFFD1FAE5))
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            ex.icon,
                            color: ex.isCompleted
                                ? const Color(0xFF10B981)
                                : const Color(0xFF3B66FF),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.title,
                                style: TextStyle(
                                  color: kDarkNavy,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ex.detail,
                                style: TextStyle(
                                  color: kSecondaryText,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Checkbox toggle
                        InkWell(
                          onTap: () => _toggleExercise(ex),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ex.isCompleted
                                  ? const Color(0xFF10B981)
                                  : Colors.transparent,
                              border: Border.all(
                                color: ex.isCompleted
                                    ? const Color(0xFF10B981)
                                    : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                width: 2,
                              ),
                            ),
                            child: ex.isCompleted
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Primary Action Button: "View Full Plan"
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    _showFullPlanModal(isDark, kCardBg, kDarkNavy, kSecondaryText);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'View Full Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tip Banner Card (Amber / Warm Yellow)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E2211) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? const Color(0xFF5A3E15) : const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Stay consistent and maintain good form. Rest for 60-90 seconds between sets.',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
            ],
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
          onTap: _onBottomNavTapped,
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
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void _showFullPlanModal(bool isDark, Color cardBg, Color textColor, Color subtextColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '4-Week Workout Program',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Mon: Upper Body Strength\n• Tue: Core & Mobility\n• Thu: Lower Body Power\n• Fri: Full Body Conditioning',
              style: TextStyle(
                color: subtextColor,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Got it', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
