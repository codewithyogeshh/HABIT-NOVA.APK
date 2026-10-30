import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/supabase_service.dart';

/// Weekly consistency row widget showing 7 days (M, T, W, T, F, S, S)
/// with glowing bioluminescent status indicators.
class WeeklyHeatmapWidget extends StatefulWidget {
  final int streakDays;

  const WeeklyHeatmapWidget({super.key, required this.streakDays});

  @override
  State<WeeklyHeatmapWidget> createState() => _WeeklyHeatmapWidgetState();
}

class _WeeklyHeatmapWidgetState extends State<WeeklyHeatmapWidget> {
  final List<bool> _weekDaysCompleted = [true, true, true, false, false, false, false];

  String get _currentUserId => SupabaseService.user?.id ?? 'guest';

  @override
  void initState() {
    super.initState();
    _loadWeekProgress();
  }

  Future<void> _loadWeekProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      // Monday = 1, Sunday = 7
      final currentWeekday = now.weekday; // 1 to 7

      final updated = List<bool>.generate(7, (index) {
        final dayOffset = index + 1 - currentWeekday;
        final date = now.add(Duration(days: dayOffset));
        final dateStr = date.toIso8601String().split('T').first;
        final key = 'user_${_currentUserId}_completed_all_$dateStr';

        if (prefs.containsKey(key)) {
          return prefs.getBool(key) ?? false;
        }

        // Demo fallback: if within streak range in past days, mark true
        if (dayOffset <= 0 && dayOffset > -widget.streakDays) {
          return true;
        }
        return false;
      });

      if (mounted) {
        setState(() {
          for (int i = 0; i < 7; i++) {
            _weekDaysCompleted[i] = updated[i];
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kCardBg = isDark ? const Color(0xFF071728) : Colors.white;
    final kBorderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);
    final kTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final kSubtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final currentDayIndex = DateTime.now().weekday - 1; // 0 for Mon, 6 for Sun

    final completedDaysCount = _weekDaysCompleted.where((c) => c).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Weekly Consistency',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$completedDaysCount/7 Days Active',
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isToday = index == currentDayIndex;
              final isDone = _weekDaysCompleted[index];
              final isPast = index < currentDayIndex;

              return Column(
                children: [
                  Text(
                    dayNames[index],
                    style: TextStyle(
                      color: isToday
                          ? kPrimaryColor
                          : (isPast ? kTextColor : kSubtextColor.withValues(alpha: 0.6)),
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF10B981)
                          : (isToday
                              ? kPrimaryColor.withValues(alpha: 0.2)
                              : (isDark ? const Color(0xFF030814) : const Color(0xFFF1F5F9))),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isToday
                            ? kPrimaryColor
                            : (isDone ? const Color(0xFF10B981) : kBorderColor),
                        width: isToday ? 2.0 : 1.2,
                      ),
                      boxShadow: isDone
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : (isToday
                              ? [
                                  BoxShadow(
                                    color: kPrimaryColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : []),
                    ),
                    alignment: Alignment.center,
                    child: isDone
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                        : (isToday
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: kPrimaryColor,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

