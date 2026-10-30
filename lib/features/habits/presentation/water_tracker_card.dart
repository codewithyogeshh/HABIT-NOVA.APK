import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/gamification_service.dart';
import 'package:synvero/core/services/supabase_service.dart';
import 'package:synvero/core/widgets/celebration_dialog.dart';

/// Interactive bioluminescent Water Intake Tracker with 8 animated glass taps.
class WaterTrackerCard extends StatefulWidget {
  final VoidCallback? onWaterUpdated;

  const WaterTrackerCard({super.key, this.onWaterUpdated});

  @override
  State<WaterTrackerCard> createState() => _WaterTrackerCardState();
}

class _WaterTrackerCardState extends State<WaterTrackerCard> {
  int _glassesFilled = 0;
  static const int _targetGlasses = 8;
  static const int _mlPerGlass = 250;

  String get _currentUserId => SupabaseService.user?.id ?? 'guest';
  String get _waterPrefKey => 'user_${_currentUserId}_water_glasses_${DateTime.now().toIso8601String().split('T').first}';

  @override
  void initState() {
    super.initState();
    _loadWaterState();
  }

  Future<void> _loadWaterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_waterPrefKey) ?? 4; // Default starter for demo
      if (mounted) {
        setState(() {
          _glassesFilled = count.clamp(0, _targetGlasses);
        });
      }
    } catch (_) {}
  }

  Future<void> _setGlassCount(int count) async {
    final newCount = count.clamp(0, _targetGlasses);
    final previousCount = _glassesFilled;

    HapticFeedback.lightImpact();

    setState(() {
      _glassesFilled = newCount;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_waterPrefKey, newCount);

      // Award XP if completed full 8 glasses
      if (newCount == _targetGlasses && previousCount < _targetGlasses) {
        await GamificationService.addXP(GamificationService.xpPerWaterGoal, reason: 'Completed 8 glasses of water');
        await GamificationService.unlockBadge('hydration_hero');

        if (mounted) {
          CelebrationDialog.show(
            context,
            title: 'Hydration Goal Achieved! 💧',
            subtitle: '2000 ml water target complete! (+40 XP)',
            streakDays: 1,
          );
        }
      }

      widget.onWaterUpdated?.call();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kCardBg = isDark ? const Color(0xFF071728) : Colors.white;
    final kBorderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);
    final kTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final kSubtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final totalMl = _glassesFilled * _mlPerGlass;
    final targetMl = _targetGlasses * _mlPerGlass;
    final percent = (_glassesFilled / _targetGlasses).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _glassesFilled == _targetGlasses
              ? const Color(0xFF00F0FF).withValues(alpha: 0.6)
              : kBorderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: isDark ? 0.08 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('💧', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Hydration',
                        style: TextStyle(
                          color: kTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$totalMl / $targetMl ml ($glassesFilledCount)',
                        style: TextStyle(
                          color: kSubtextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Quick Add Button
              InkWell(
                onTap: () {
                  if (_glassesFilled < _targetGlasses) {
                    _setGlassCount(_glassesFilled + 1);
                  } else {
                    _setGlassCount(0); // Reset
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _glassesFilled < _targetGlasses ? Icons.add_rounded : Icons.refresh_rounded,
                        color: const Color(0xFF00F0FF),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _glassesFilled < _targetGlasses ? '+1 Glass' : 'Reset',
                        style: const TextStyle(
                          color: Color(0xFF00F0FF),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Liquid Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 7,
              backgroundColor: isDark ? const Color(0xFF030814) : const Color(0xFFE2E8F0),
              color: const Color(0xFF00F0FF),
            ),
          ),

          const SizedBox(height: 16),

          // 8 Interactive Glasses
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_targetGlasses, (index) {
              final isFilled = index < _glassesFilled;

              return GestureDetector(
                onTap: () {
                  if (index + 1 == _glassesFilled) {
                    _setGlassCount(index);
                  } else {
                    _setGlassCount(index + 1);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 32,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? const Color(0xFF00F0FF).withValues(alpha: 0.2)
                        : (isDark ? const Color(0xFF030814) : const Color(0xFFF1F5F9)),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                      bottom: Radius.circular(10),
                    ),
                    border: Border.all(
                      color: isFilled ? const Color(0xFF00F0FF) : kBorderColor,
                      width: isFilled ? 1.6 : 1.0,
                    ),
                    boxShadow: isFilled
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Water fill level
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: isFilled ? 32 : 0,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF00F0FF)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                        ),
                      ),
                      Center(
                        child: Text(
                          isFilled ? '💧' : '${index + 1}',
                          style: TextStyle(
                            fontSize: isFilled ? 13 : 10.5,
                            fontWeight: FontWeight.w700,
                            color: isFilled ? Colors.white : kSubtextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String get glassesFilledCount => '$_glassesFilled/$_targetGlasses glasses';
}
