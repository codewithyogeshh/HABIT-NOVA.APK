import 'package:synvero/core/widgets/celebration_dialog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/app_widget_service.dart';
import 'package:synvero/core/services/supabase_service.dart';
import 'package:synvero/core/services/task_service.dart';
import 'package:synvero/features/habits/data/habit_repository.dart';
import 'package:synvero/features/habits/data/models/habit_model.dart';

/// Habit Tracker screen with real user-created upcoming schedules.
class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final _repository = HabitRepository();
  List<Habit> _habits = [];
  Map<String, bool> _todayCompletion = {};
  List<TaskItem> _upcomingTasks = [];
  bool _isLoading = true;
  int _selectedFilterIndex = 0; // 0: Today, 1: Weekly, 2: Monthly
  int _currentTabIndex = 1; // Habits tab

  // Built-in starter habits matching mockup when DB is fresh
  final List<Map<String, dynamic>> _defaultHabits = [
    {
      'id': 'def-1',
      'name': 'Workout',
      'subtitle': '0/1 completed',
      'icon': Icons.fitness_center_rounded,
      'color': const Color(0xFF10B981),
      'bgColor': const Color(0xFFD1FAE5),
      'completed': false,
    },
    {
      'id': 'def-2',
      'name': 'Read a book',
      'subtitle': '0/1 completed',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFF8B5CF6),
      'bgColor': const Color(0xFFEDE9FE),
      'completed': false,
    },
    {
      'id': 'def-3',
      'name': 'Drink water',
      'subtitle': '0/8 glasses',
      'icon': Icons.water_drop_rounded,
      'color': const Color(0xFF3B66FF),
      'bgColor': const Color(0xFFDBEAFE),
      'completed': false,
    },
    {
      'id': 'def-4',
      'name': 'Meditate',
      'subtitle': '0/1 completed',
      'icon': Icons.self_improvement_rounded,
      'color': const Color(0xFF6366F1),
      'bgColor': const Color(0xFFE0E7FF),
      'completed': false,
    },
    {
      'id': 'def-5',
      'name': 'Study',
      'subtitle': '0/2 completed',
      'icon': Icons.school_rounded,
      'color': const Color(0xFF0284C7),
      'bgColor': const Color(0xFFE0F2FE),
      'completed': false,
    },
  ];

  String _getHabitSubtitle(String id, bool isCompleted) {
    if (id == 'def-3') {
      return isCompleted ? '8/8 glasses' : '0/8 glasses';
    } else if (id == 'def-5') {
      return isCompleted ? '2/2 completed' : '0/2 completed';
    }
    return isCompleted ? '1/1 completed' : '0/1 completed';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String get _currentUserId => SupabaseService.user?.id ?? 'guest';

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final habit in _defaultHabits) {
        final key = 'user_${_currentUserId}_habit_${habit['id']}_completed';
        final isDone = prefs.getBool(key) ?? false;
        habit['completed'] = isDone;
        habit['subtitle'] = _getHabitSubtitle(habit['id'] as String, isDone);
      }

      final habits = await _repository.getHabits(includeArchived: false);
      final todayStatus = await _repository.getTodaysCompletionStatus();
      final upcoming = await TaskService.getUpcomingTasks();

      if (mounted) {
        setState(() {
          _habits = habits;
          _todayCompletion = todayStatus;
          _upcomingTasks = upcoming;
          _isLoading = false;
        });
      }
    } catch (e) {
      final upcoming = await TaskService.getUpcomingTasks();
      if (mounted) {
        setState(() {
          _upcomingTasks = upcoming;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleCompletion(String habitId, bool isRealDb) async {
    bool becameCompleted = false;
    String habitName = 'Habit';

    if (isRealDb) {
      final isCurrentlyCompleted = _todayCompletion[habitId] ?? false;
      becameCompleted = !isCurrentlyCompleted;
      try {
        if (isCurrentlyCompleted) {
          await _repository.uncompleteHabit(habitId, DateTime.now());
        } else {
          await _repository.completeHabit(habitId, DateTime.now());
        }
        final status = await _repository.getTodaysCompletionStatus();
        if (mounted) {
          setState(() {
            _todayCompletion = status;
          });
        }
      } catch (_) {}
    } else {
      // Toggle for default fallback habits
      final habit = _defaultHabits.firstWhere((h) => h['id'] == habitId);
      final newStatus = !(habit['completed'] as bool);
      becameCompleted = newStatus;
      habitName = habit['name'] as String? ?? 'Habit';
      setState(() {
        habit['completed'] = newStatus;
        habit['subtitle'] = _getHabitSubtitle(habitId, newStatus);
      });
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('user_${_currentUserId}_habit_${habitId}_completed', newStatus);
      } catch (_) {}
    }

    if (becameCompleted && mounted) {
      final doneCount = isRealDb
          ? _todayCompletion.values.where((v) => v).length
          : _defaultHabits.where((h) => h['completed'] == true).length;
      CelebrationDialog.show(
        context,
        title: 'Habit Completed! 🎉',
        subtitle: habitName,
        streakDays: doneCount > 0 ? 1 : 0,
      );
    }

    // Update live progress on Android Home Widget
    AppWidgetService.syncWidget();
  }

  Future<void> _showAddScheduleDialog() async {
    final titleController = TextEditingController();
    String selectedPriority = 'Medium';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1)); // Default tomorrow
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isTomorrow = selectedDate.year == DateTime.now().year &&
              selectedDate.month == DateTime.now().month &&
              selectedDate.day == DateTime.now().day + 1;
          final dateStr = isTomorrow
              ? 'Tomorrow'
              : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
          final timeStr = selectedTime.format(context);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Add Upcoming Schedule', style: TextStyle(fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Task / Schedule Title',
                      hintText: 'e.g. Project presentation, Meeting',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Date & Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text(dateStr, style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.alarm_rounded, size: 18, color: kPrimaryColor),
                          label: Text(timeStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimaryColor)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                              initialEntryMode: TimePickerEntryMode.dialOnly,
                              builder: (pickerContext, child) {
                                return MediaQuery(
                                  data: MediaQuery.of(pickerContext).copyWith(
                                    viewInsets: EdgeInsets.zero,
                                  ),
                                  child: Theme(
                                    data: Theme.of(pickerContext).copyWith(
                                      inputDecorationTheme: const InputDecorationTheme(
                                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    child: child ?? const SizedBox(),
                                  ),
                                );
                              },
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedTime = picked;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['High', 'Medium', 'Low'].map((p) {
                      final isSel = selectedPriority == p;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(p),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                selectedPriority = p;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                label: const Text('Save & Set Alarm', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      if (!mounted) return;
      final scheduledDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      final isTomorrow = selectedDate.year == DateTime.now().year &&
          selectedDate.month == DateTime.now().month &&
          selectedDate.day == DateTime.now().day + 1;

      final formattedTime = isTomorrow
          ? 'Tomorrow, ${selectedTime.format(context)}'
          : '${selectedDate.day}/${selectedDate.month}, ${selectedTime.format(context)}';

      final newTask = TaskItem(
        id: 'task-custom-${DateTime.now().millisecondsSinceEpoch}',
        title: titleController.text.trim(),
        time: formattedTime,
        priority: selectedPriority,
        isCompleted: false,
        isUpcoming: true,
        scheduledDate: scheduledDateTime,
      );

      await TaskService.addTask(newTask);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upcoming schedule added for $formattedTime ⏰'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Habit', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Habit Name',
                hintText: 'e.g. Morning Yoga, Read 10 pages',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g. Before 8 AM',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add Habit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        await _repository.createHabit(
          name: nameController.text.trim(),
          description: descController.text.trim().isEmpty ? null : descController.text.trim(),
          color: '#3B66FF',
          icon: 'task_alt',
        );
        await _loadData();
      } catch (_) {
        setState(() {
          _defaultHabits.insert(0, {
            'id': 'local-${DateTime.now().millisecondsSinceEpoch}',
            'name': nameController.text.trim(),
            'subtitle': '0/1 completed',
            'icon': Icons.star_rounded,
            'color': kPrimaryColor,
            'bgColor': const Color(0xFFDBEAFE),
            'completed': false,
          });
        });
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

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: kTextColor, size: 22),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          },
        ),
        title: Text(
          'Habits',
          style: TextStyle(
            color: kTextColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _showCreateDialog,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: kPrimaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeframe Filter Pills [Today] [Weekly] [Monthly]
                      Row(
                        children: [
                          _buildFilterPill('Today', 0, isDark, kCardBg, kBorderColor),
                          const SizedBox(width: 8),
                          _buildFilterPill('Weekly', 1, isDark, kCardBg, kBorderColor),
                          const SizedBox(width: 8),
                          _buildFilterPill('Monthly', 2, isDark, kCardBg, kBorderColor),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Habits List
                      if (_habits.isNotEmpty) ...[
                        ..._habits.map((habit) {
                          final isCompleted = _todayCompletion[habit.id] ?? false;
                          return _buildHabitCard(
                            id: habit.id,
                            name: habit.name,
                            subtitle: isCompleted ? 'Completed today' : 'Tap to mark done',
                            icon: Icons.check_circle_outline_rounded,
                            color: kPrimaryColor,
                            bgColor: const Color(0xFFDBEAFE),
                            isCompleted: isCompleted,
                            isRealDb: true,
                            isDark: isDark,
                            cardBg: kCardBg,
                            borderColor: kBorderColor,
                            textColor: kTextColor,
                            subtextColor: kSubtextColor,
                          );
                        }),
                      ] else ...[
                        ..._defaultHabits.map((habit) {
                          return _buildHabitCard(
                            id: habit['id'] as String,
                            name: habit['name'] as String,
                            subtitle: habit['subtitle'] as String,
                            icon: habit['icon'] as IconData,
                            color: habit['color'] as Color,
                            bgColor: habit['bgColor'] as Color,
                            isCompleted: habit['completed'] as bool,
                            isRealDb: false,
                            isDark: isDark,
                            cardBg: kCardBg,
                            borderColor: kBorderColor,
                            textColor: kTextColor,
                            subtextColor: kSubtextColor,
                          );
                        }),
                      ],

                      const SizedBox(height: 24),

                      // Real Upcoming Section Header with Add Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Upcoming Schedule',
                            style: TextStyle(
                              color: kTextColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 16, color: kPrimaryColor),
                            label: const Text(
                              'Add Schedule',
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: _showAddScheduleDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Real User-Added Upcoming Tasks List
                      if (_upcomingTasks.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                          decoration: BoxDecoration(
                            color: kCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kBorderColor),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.event_note_rounded,
                                  size: 34, color: kSubtextColor.withValues(alpha: 0.5)),
                              const SizedBox(height: 8),
                              Text(
                                'No upcoming tasks scheduled',
                                style: TextStyle(
                                  color: kTextColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap "+ Add Schedule" to set tomorrow\'s tasks & alarms!',
                                style: TextStyle(color: kSubtextColor, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ..._upcomingTasks.map(
                          (task) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: _buildUpcomingCard(
                              task: task,
                              isDark: isDark,
                              cardBg: kCardBg,
                              borderColor: kBorderColor,
                              textColor: kTextColor,
                              subtextColor: kSubtextColor,
                            ),
                          ),
                        ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kBottomNavBg,
          border: Border(top: BorderSide(color: kBorderColor, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
            });
            if (index == 0) {
              Navigator.of(context).pushReplacementNamed('/dashboard');
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
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Habits'),
            BottomNavigationBarItem(icon: Icon(Icons.timer_outlined), label: 'Timer'),
            BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, int index, bool isDark, Color cardBg, Color borderColor) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kPrimaryColor : borderColor,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : kSecondaryText),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHabitCard({
    required String id,
    required String name,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isCompleted,
    required bool isRealDb,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    final displaySubtitle = _getHabitSubtitle(id, isCompleted);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : borderColor,
          width: isCompleted ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleCompletion(id, isRealDb),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? color.withValues(alpha: 0.15) : bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displaySubtitle,
                        style: TextStyle(
                          color: isCompleted ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF10B981)) : subtextColor,
                          fontSize: 12,
                          fontWeight: isCompleted ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? const Color(0xFF10B981) : Colors.transparent,
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                      width: 1.5,
                    ),
                  ),
                  child: isCompleted
                      ? const Center(
                          child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingCard({
    required TaskItem task,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    Color priorityColor;
    if (task.priority == 'High') {
      priorityColor = const Color(0xFFEF4444);
    } else if (task.priority == 'Low') {
      priorityColor = const Color(0xFF10B981);
    } else {
      priorityColor = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.event_available_rounded, color: priorityColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.alarm_rounded, size: 13, color: priorityColor),
                    const SizedBox(width: 4),
                    Text(
                      task.time,
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: subtextColor),
            onPressed: () async {
              await TaskService.deleteTask(task.id);
              await _loadData();
            },
          ),
        ],
      ),
    );
  }
}
