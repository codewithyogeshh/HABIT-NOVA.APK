import 'package:flutter/material.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/notification_service.dart';
import 'package:synvero/core/services/task_service.dart';

/// Tasks screen with real-time push notifications, loud alarms, and dynamic user scheduling.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _selectedFilterIndex = 0; // 0: Today, 1: Upcoming, 2: All
  int _currentTabIndex = 3; // Tasks tab
  List<TaskItem> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    NotificationService.requestPermissions();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final loaded = await TaskService.getTasks();

    if (loaded.isEmpty) {
      // Starter tasks if fresh
      final starters = [
        TaskItem(
          id: 'task-starter-1',
          title: 'Complete assignment',
          time: '10:00 AM',
          priority: 'High',
          isCompleted: false,
        ),
        TaskItem(
          id: 'task-starter-2',
          title: 'Gym workout',
          time: '5:00 PM',
          priority: 'Medium',
          isCompleted: false,
        ),
        TaskItem(
          id: 'task-starter-3',
          title: 'Read book',
          time: '7:00 PM',
          priority: 'Low',
          isCompleted: false,
        ),
      ];
      await TaskService.saveTasks(starters);
      if (mounted) {
        setState(() {
          _tasks = starters;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _tasks = loaded;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleTask(TaskItem task) async {
    await TaskService.toggleTask(task);
    await _loadTasks();
  }

  Future<void> _deleteTask(String id) async {
    await TaskService.deleteTask(id);
    await _loadTasks();
  }

  Future<void> _showAddTaskDialog({bool isForTomorrow = false}) async {
    final titleController = TextEditingController();
    String selectedPriority = 'Medium';
    DateTime selectedDate = isForTomorrow
        ? DateTime.now().add(const Duration(days: 1))
        : DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(
      DateTime.now().add(const Duration(minutes: 30)),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final timeStr = selectedTime.format(context);
          final isToday = selectedDate.year == DateTime.now().year &&
              selectedDate.month == DateTime.now().month &&
              selectedDate.day == DateTime.now().day;
          final isTomorrow = selectedDate.year == DateTime.now().year &&
              selectedDate.month == DateTime.now().month &&
              selectedDate.day == DateTime.now().day + 1;

          final dateStr = isToday
              ? 'Today'
              : (isTomorrow
                  ? 'Tomorrow'
                  : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}');

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(isForTomorrow ? 'Plan Tomorrow Task' : 'Add New Task',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'e.g. Study Java, Gym, Project work',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Date & Time',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Date Selector
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_rounded,
                              size: 16),
                          label: Text(dateStr,
                              style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
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
                      // Time Selector
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.alarm_rounded,
                              size: 18, color: kPrimaryColor),
                          label: Text(timeStr,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimaryColor)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
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
                  const Text('Priority',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                icon: const Icon(Icons.alarm_on_rounded,
                    color: Colors.white, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                label: const Text('Save & Set Alarm',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
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

      final isToday = selectedDate.year == DateTime.now().year &&
          selectedDate.month == DateTime.now().month &&
          selectedDate.day == DateTime.now().day;
      final isTomorrowDate = selectedDate.year == DateTime.now().year &&
          selectedDate.month == DateTime.now().month &&
          selectedDate.day == DateTime.now().day + 1;

      final formattedTime = isToday
          ? selectedTime.format(context)
          : (isTomorrowDate
              ? 'Tomorrow, ${selectedTime.format(context)}'
              : '${selectedDate.day}/${selectedDate.month}, ${selectedTime.format(context)}');

      final newTask = TaskItem(
        id: 'task-custom-${DateTime.now().millisecondsSinceEpoch}',
        title: titleController.text.trim(),
        time: formattedTime,
        priority: selectedPriority,
        isCompleted: false,
        isUpcoming: !isToday,
        scheduledDate: scheduledDateTime,
      );

      await TaskService.addTask(newTask);
      await _loadTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Task saved & Alarm set for $formattedTime 🔔',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _triggerTestNotification() async {
    await NotificationService.showInstantNotification(
      id: 999999,
      title: '🔔 Synvero Alarm Alert Test',
      body: 'Loud alarm with continuous ringing and vibration is active! 🚀',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loud alarm triggered! Check your notification bar 🔔'),
          backgroundColor: kPrimaryColor,
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

    final now = DateTime.now();

    List<TaskItem> displayedTasks;
    if (_selectedFilterIndex == 0) {
      displayedTasks = _tasks.where((t) => !t.isUpcoming).toList();
    } else if (_selectedFilterIndex == 1) {
      displayedTasks = _tasks.where((t) => t.isUpcoming).toList();
    } else {
      displayedTasks = _tasks;
    }

    final upcomingList = _tasks.where((t) {
      if (t.isCompleted) return false;
      if (t.isUpcoming) return true;
      if (t.scheduledDate != null) {
        return t.scheduledDate!.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));
      }
      return false;
    }).toList();

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
          'Tasks',
          style: TextStyle(
            color: kTextColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined,
                color: kPrimaryColor, size: 22),
            tooltip: 'Test Loud Alarm',
            onPressed: _triggerTestNotification,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => _showAddTaskDialog(),
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
                onRefresh: _loadTasks,
                color: kPrimaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Segmented Filter Pills [Today] [Upcoming] [All]
                      Row(
                        children: [
                          _buildFilterPill('Today', 0, isDark, kCardBg, kBorderColor),
                          const SizedBox(width: 8),
                          _buildFilterPill('Upcoming', 1, isDark, kCardBg, kBorderColor),
                          const SizedBox(width: 8),
                          _buildFilterPill('All', 2, isDark, kCardBg, kBorderColor),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Task List
                      if (displayedTasks.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(Icons.checklist_rtl_rounded,
                                    size: 48,
                                    color: kSubtextColor.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedFilterIndex == 1
                                      ? 'No upcoming tasks scheduled!'
                                      : 'No tasks here yet!',
                                  style: TextStyle(
                                      color: kTextColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap "+" above to add your tasks & alarms',
                                  style: TextStyle(color: kSubtextColor, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...displayedTasks.map((task) => _buildTaskCard(
                              task,
                              isDark,
                              kCardBg,
                              kBorderColor,
                              kTextColor,
                              kSubtextColor,
                            )),

                      const SizedBox(height: 24),

                      // Real Dynamic Upcoming Section Header
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
                              'Plan Tomorrow',
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () => _showAddTaskDialog(isForTomorrow: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (upcomingList.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                                'No upcoming schedule for tomorrow',
                                style: TextStyle(
                                  color: kTextColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap "Plan Tomorrow" to add your work and set alarms!',
                                style: TextStyle(color: kSubtextColor, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ...upcomingList.map((task) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: _buildUpcomingCard(
                                task: task,
                                isDark: isDark,
                                cardBg: kCardBg,
                                borderColor: kBorderColor,
                                textColor: kTextColor,
                                subtextColor: kSubtextColor,
                              ),
                            )),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kBottomNavBg,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
            });
            if (index == 0) {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            } else if (index == 1) {
              Navigator.of(context).pushNamed('/habits');
            } else if (index == 2) {
              Navigator.of(context).pushNamed('/timer');
            } else if (index == 4) {
              Navigator.of(context).pushNamed('/profile');
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: kBottomNavBg,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor:
              isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          selectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_rounded), label: 'Habits'),
            BottomNavigationBarItem(
                icon: Icon(Icons.timer_outlined), label: 'Timer'),
            BottomNavigationBarItem(
                icon: Icon(Icons.checklist_rounded), label: 'Tasks'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(
      String label, int index, bool isDark, Color cardBg, Color borderColor) {
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
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : kSecondaryText),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    TaskItem task,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isCompleted
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : borderColor,
          width: task.isCompleted ? 1.4 : 1.0,
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
          // Checkbox
          GestureDetector(
            onTap: () => _toggleTask(task),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: task.isCompleted ? kPrimaryColor : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? kPrimaryColor
                      : (isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1)),
                  width: 1.5,
                ),
              ),
              child: task.isCompleted
                  ? const Center(
                      child:
                          Icon(Icons.check_rounded, color: Colors.white, size: 15),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),

          // Title & Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: task.isCompleted
                        ? (isDark ? const Color(0xFF64748B) : kSecondaryText)
                        : textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.alarm_rounded,
                        size: 13,
                        color: task.isCompleted
                            ? subtextColor.withValues(alpha: 0.5)
                            : const Color(0xFFF59E0B)),
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

          // Priority Badge
          _buildPriorityBadge(task.priority, isDark),
          const SizedBox(width: 8),

          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                size: 18, color: subtextColor.withValues(alpha: 0.6)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _deleteTask(task.id),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority, bool isDark) {
    Color textColor;
    Color bgColor;

    if (priority == 'High') {
      textColor = const Color(0xFFEF4444);
      bgColor = isDark
          ? const Color(0xFFEF4444).withValues(alpha: 0.18)
          : const Color(0xFFFEE2E2);
    } else if (priority == 'Medium') {
      textColor = const Color(0xFFF59E0B);
      bgColor = isDark
          ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
          : const Color(0xFFFEF3C7);
    } else {
      textColor = const Color(0xFF10B981);
      bgColor = isDark
          ? const Color(0xFF10B981).withValues(alpha: 0.18)
          : const Color(0xFFDCFCE7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
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
            onPressed: () => _deleteTask(task.id),
          ),
        ],
      ),
    );
  }
}
