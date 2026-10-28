import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/supabase_service.dart';

/// Meal item model for nutrition plan.
class MealItem {
  final String title;
  final String description;
  final int calories;
  final String iconEmoji;
  final Color badgeColor;
  final Color badgeBg;
  bool isLogged;

  MealItem({
    required this.title,
    required this.description,
    required this.calories,
    required this.iconEmoji,
    required this.badgeColor,
    required this.badgeBg,
    this.isLogged = false,
  });
}

/// Nutrition Plan screen.
///
/// Implements Screen 9 from the Synvero master design mockup:
/// - Header: Back arrow, "Nutrition Plan" title
/// - Section: "Today's Meal Plan"
/// - Meal Cards:
///   - Breakfast: "Oats with fruits & nuts (350 kcal)"
///   - Lunch: "Grilled chicken, quinoa, vegetables (450 kcal)"
///   - Dinner: "Mixed vegetables, dal, brown rice (400 kcal)"
/// - Macro & Calorie Intake overview card
/// - Tips banner: "Drink plenty of water, eat whole foods, and avoid processed snacks."
/// - Bottom Navigation Bar
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  int _currentTabIndex = 0; // Accessible from Home / Lifestyle

  final List<MealItem> _meals = [
    MealItem(
      title: 'Breakfast',
      description: 'Oats with fruits & nuts',
      calories: 350,
      iconEmoji: '🥣',
      badgeColor: const Color(0xFFF59E0B),
      badgeBg: const Color(0xFFFEF3C7),
      isLogged: true,
    ),
    MealItem(
      title: 'Lunch',
      description: 'Grilled chicken, quinoa, vegetables',
      calories: 450,
      iconEmoji: '🥗',
      badgeColor: const Color(0xFF10B981),
      badgeBg: const Color(0xFFD1FAE5),
      isLogged: true,
    ),
    MealItem(
      title: 'Dinner',
      description: 'Mixed vegetables, dal, brown rice',
      calories: 400,
      iconEmoji: '🍛',
      badgeColor: const Color(0xFF6366F1),
      badgeBg: const Color(0xFFE0E7FF),
      isLogged: false,
    ),
  ];

  String get _currentUserId => SupabaseService.user?.id ?? 'guest';

  @override
  void initState() {
    super.initState();
    _loadMealStates();
  }

  Future<void> _loadMealStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        for (final meal in _meals) {
          final key = 'user_${_currentUserId}_meal_${meal.title}_logged';
          if (prefs.containsKey(key)) {
            meal.isLogged = prefs.getBool(key) ?? false;
          } else {
            meal.isLogged = (meal.title == 'Breakfast' || meal.title == 'Lunch') && _currentUserId == 'guest';
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _toggleMeal(MealItem meal) async {
    final newStatus = !meal.isLogged;
    setState(() {
      meal.isLogged = newStatus;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_${_currentUserId}_meal_${meal.title}_logged', newStatus);
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

    final totalCalories = _meals.fold<int>(0, (sum, m) => sum + m.calories);
    final loggedCalories = _meals
        .where((m) => m.isLogged)
        .fold<int>(0, (sum, m) => sum + m.calories);

    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Back Arrow, Title, More Info
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
                    'Nutrition Plan',
                    style: TextStyle(
                      color: kDarkNavy,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.fitness_center_rounded, color: kDarkNavy, size: 22),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/fitness');
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Calorie & Macro Target Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daily Nutrition Target',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$loggedCalories / $totalCalories kcal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: totalCalories > 0 ? loggedCalories / totalCalories : 0.0,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMacroItem('Carbs', '140g', '52%'),
                        _buildMacroItem('Protein', '85g', '28%'),
                        _buildMacroItem('Fats', '35g', '20%'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section Header: Today's Meal Plan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Meal Plan",
                    style: TextStyle(
                      color: kDarkNavy,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddMealDialog,
                    icon: const Icon(Icons.add_rounded, size: 16, color: kPrimaryColor),
                    label: const Text(
                      'Add Meal',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Meal Cards List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _meals.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final meal = _meals[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: meal.isLogged
                            ? const Color(0xFF10B981).withValues(alpha: 0.3)
                            : kBorderColor,
                        width: meal.isLogged ? 1.4 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Food Icon Container
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark ? meal.badgeColor.withValues(alpha: 0.15) : meal.badgeBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              meal.iconEmoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title, Description, Calories
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.title,
                                style: TextStyle(
                                  color: kDarkNavy,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                meal.description,
                                style: TextStyle(
                                  color: kSecondaryText,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '(${meal.calories} kcal)',
                                style: TextStyle(
                                  color: meal.badgeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Checkmark toggle
                        InkWell(
                          onTap: () => _toggleMeal(meal),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: meal.isLogged
                                  ? const Color(0xFF10B981)
                                  : Colors.transparent,
                              border: Border.all(
                                color: meal.isLogged
                                    ? const Color(0xFF10B981)
                                    : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                width: 2,
                              ),
                            ),
                            child: meal.isLogged
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Tips Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF132238) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tips',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Drink plenty of water, eat whole foods, and avoid processed snacks.',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
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

  Widget _buildMacroItem(String name, String amount, String percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($percent)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddMealDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final calController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Add Meal', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Meal Name (e.g., Snack)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description (e.g., Almonds & Apple)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: calController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calories (kcal)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final desc = descController.text.trim();
              final cals = int.tryParse(calController.text.trim()) ?? 200;
              if (title.isNotEmpty) {
                setState(() {
                  _meals.add(
                    MealItem(
                      title: title,
                      description: desc.isNotEmpty ? desc : 'Healthy meal',
                      calories: cals,
                      iconEmoji: '🍎',
                      badgeColor: const Color(0xFF3B66FF),
                      badgeBg: const Color(0xFFEFF6FF),
                      isLogged: false,
                    ),
                  );
                });
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
